#!/bin/bash

# Script: network_dashboard.sh
# Dashboard para monitoreo de red - Con gestión automática de permisos ethtool

cat > /tmp/network_dashboard.py << 'EOF'
#!/usr/bin/env python3
from flask import Flask, render_template, jsonify
import subprocess
import json
import time
import threading
import os
import re

app = Flask(__name__)

# Almacenamiento para datos en tiempo real
network_data = {
    'interfaces': {},
    'ethtool_stats': {},
    'last_update': None,
    'system_info': {}
}

def run_command(cmd, use_sudo=False):
    """Ejecuta un comando y retorna su salida"""
    try:
        if use_sudo:
            cmd = f"sudo {cmd}"
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=5)
        return result.stdout if result.returncode == 0 else ""
    except:
        return ""

def setup_ethtool_permissions():
    """Configura los permisos para ethtool"""
    print("🔧 Configurando permisos para ethtool...")
    
    # Verificar si ya tenemos permisos
    test_output = run_command("ethtool --version")
    if test_output:
        print("✅ Ethtool ya funciona sin sudo")
        return True
    
    # Solución 1: Configurar capabilities (recomendado)
    ethtool_path = run_command("which ethtool").strip()
    if ethtool_path:
        print(f"📍 Ruta de ethtool: {ethtool_path}")
        
        # Intentar configurar capabilities
        result = run_command(f"sudo setcap cap_net_admin,cap_net_raw+ep {ethtool_path}")
        if result == "":
            print("✅ Capabilities configuradas correctamente")
            
            # Verificar que funciona
            test_output = run_command("ethtool --version")
            if test_output:
                print("✅ Ethtool ahora funciona sin sudo")
                return True
            else:
                print("❌ Las capabilities no fueron suficientes")
        else:
            print("❌ No se pudieron configurar capabilities")
    
    # Solución 2: Verificar grupo netdev
    print("👥 Verificando grupo netdev...")
    groups_output = run_command("groups")
    if "netdev" in groups_output:
        print("✅ Usuario en grupo netdev")
    else:
        print("❌ Usuario NO está en grupo netdev")
        print("💡 Ejecuta: sudo usermod -aG netdev $USER")
    
    return False

def diagnose_ethtool():
    """Diagnóstico completo de ethtool"""
    diagnosis = {
        'installed': False,
        'version': '',
        'permissions': 'unknown',
        'working_interfaces': [],
        'problematic_interfaces': []
    }
    
    # Verificar si ethtool está instalado
    diagnosis['installed'] = run_command("which ethtool") != ""
    
    if diagnosis['installed']:
        # Obtener versión
        version_output = run_command("ethtool --version")
        diagnosis['version'] = version_output.split('\n')[0] if version_output else "Desconocida"
        
        # Probar permisos
        test_output = run_command("ethtool --version")
        if test_output:
            diagnosis['permissions'] = 'user'
        else:
            test_output_sudo = run_command("ethtool --version", use_sudo=True)
            diagnosis['permissions'] = 'sudo' if test_output_sudo else 'none'
    
    return diagnosis

def get_network_interfaces():
    """Obtiene lista de interfaces de red usando ip link"""
    interfaces = {}
    try:
        output = run_command("ip link show")
        current_interface = None
        
        for line in output.split('\n'):
            # Buscar líneas con interface (ej: "1: lo: <LOOPBACK,UP,LOWER_UP>")
            interface_match = re.match(r'^\d+:\s+([^:]+):\s+<([^>]+)>', line)
            if interface_match:
                current_interface = interface_match.group(1)
                flags = interface_match.group(2).split(',')
                status = 'UP' if 'UP' in flags else 'DOWN'
                interfaces[current_interface] = {
                    'name': current_interface,
                    'status': status,
                    'ip': '',
                    'mac': '',
                    'rx_bytes': 0,
                    'tx_bytes': 0,
                    'type': 'virtual' if current_interface.startswith(('virbr', 'veth', 'docker', 'br-')) else 'physical'
                }
            
            # Buscar MAC address (link/ether)
            if current_interface and 'link/ether' in line:
                mac_match = re.search(r'link/ether\s+([\da-fA-F:]+)', line)
                if mac_match:
                    interfaces[current_interface]['mac'] = mac_match.group(1)
        
        return interfaces
    except Exception as e:
        print(f"Error getting interfaces: {e}")
        return {}

def get_interface_ip(interface):
    """Obtiene la IP de una interfaz usando ip addr"""
    try:
        output = run_command(f"ip addr show {interface}")
        ip_match = re.search(r'inet\s+(\d+\.\d+\.\d+\.\d+)/', output)
        return ip_match.group(1) if ip_match else ''
    except:
        return ''

def get_interface_stats(interface):
    """Obtiene estadísticas RX/TX de una interfaz"""
    try:
        rx_bytes = 0
        tx_bytes = 0
        
        # Leer directamente de /sys/class/net/
        rx_path = f"/sys/class/net/{interface}/statistics/rx_bytes"
        tx_path = f"/sys/class/net/{interface}/statistics/tx_bytes"
        
        if os.path.exists(rx_path):
            with open(rx_path, 'r') as f:
                rx_bytes = int(f.read().strip())
        
        if os.path.exists(tx_path):
            with open(tx_path, 'r') as f:
                tx_bytes = int(f.read().strip())
        
        return rx_bytes, tx_bytes
    except:
        return 0, 0

def get_ethtool_info(interface):
    """Obtiene información de ethtool para una interfaz"""
    stats = {
        'link': 'UNKNOWN',
        'speed': 'N/A',
        'duplex': 'N/A',
        'port': 'N/A',
        'supported': False,
        'detailed': {},
        'error': '',
        'diagnosis': ''
    }
    
    # Saltar interfaces virtuales
    if any(interface.startswith(prefix) for prefix in ['virbr', 'veth', 'docker', 'br-', 'lo']):
        stats['error'] = 'Interfaz virtual - no compatible con ethtool'
        return stats
    
    try:
        # Primero probar sin sudo (puede funcionar si configuramos capabilities)
        output = run_command(f"ethtool {interface} 2>&1")
        
        # Si falla, usar sudo automáticamente
        if not output or "Operation not permitted" in output:
            output = run_command(f"ethtool {interface} 2>&1", use_sudo=True)
            if output:
                stats['diagnosis'] = 'Usando sudo'
            else:
                stats['error'] = 'No se pudo ejecutar ethtool incluso con sudo'
                return stats
        
        if not output:
            stats['error'] = 'Sin respuesta de ethtool'
            return stats
        
        # Analizar errores comunes
        if "No such device" in output:
            stats['error'] = 'Interfaz no existe'
        elif "Operation not permitted" in output:
            stats['error'] = 'Permisos insuficientes'
        elif "get settings" in output and "not supported" in output:
            stats['error'] = 'Hardware no soportado'
        else:
            # Éxito - procesar información
            stats['supported'] = True
            
            # Buscar estado del enlace
            if "Link detected:" in output:
                if "yes" in output.lower():
                    stats['link'] = 'UP'
                elif "no" in output.lower():
                    stats['link'] = 'DOWN'
            
            # Buscar velocidad
            speed_match = re.search(r'Speed:\s*([^\n,]+)', output, re.IGNORECASE)
            if speed_match:
                stats['speed'] = speed_match.group(1).strip()
            
            # Buscar duplex
            duplex_match = re.search(r'Duplex:\s*([^\n,]+)', output, re.IGNORECASE)
            if duplex_match:
                stats['duplex'] = duplex_match.group(1).strip()
            
            # Buscar tipo de puerto
            port_match = re.search(r'Port:\s*([^\n,]+)', output, re.IGNORECASE)
            if port_match:
                stats['port'] = port_match.group(1).strip()
            
            # Obtener estadísticas detalladas
            stats_output = run_command(f"ethtool -S {interface} 2>&1")
            if not stats_output or "Operation not permitted" in stats_output:
                stats_output = run_command(f"ethtool -S {interface} 2>&1", use_sudo=True)
            
            if stats_output and not any(error in stats_output for error in ['not supported', 'No such device', 'Operation not permitted']):
                for line in stats_output.split('\n'):
                    if ':' in line and line.strip() and not line.strip().startswith('NIC'):
                        parts = line.split(':', 1)
                        if len(parts) == 2:
                            key = parts[0].strip()
                            value = parts[1].strip()
                            if key and value:
                                stats['detailed'][key] = value
        
    except Exception as e:
        stats['error'] = f'Error: {str(e)}'
    
    return stats

def get_interface_link_status(interface):
    """Método alternativo para obtener estado del enlace usando /sys/class/net/"""
    try:
        operstate_path = f"/sys/class/net/{interface}/operstate"
        carrier_path = f"/sys/class/net/{interface}/carrier"
        
        if os.path.exists(operstate_path):
            with open(operstate_path, 'r') as f:
                operstate = f.read().strip().upper()
                return operstate if operstate in ['UP', 'DOWN'] else 'UNKNOWN'
        
        elif os.path.exists(carrier_path):
            with open(carrier_path, 'r') as f:
                carrier = f.read().strip()
                return 'UP' if carrier == '1' else 'DOWN'
        
    except:
        pass
    
    return 'UNKNOWN'

def update_network_data():
    """Actualiza los datos de red en un hilo separado"""
    while True:
        try:
            interfaces = get_network_interfaces()
            ethtool_data = {}
            
            for interface_name, interface_info in interfaces.items():
                if interface_name == 'lo':  # Ignorar loopback
                    continue
                
                # Obtener IP
                interface_info['ip'] = get_interface_ip(interface_name)
                
                # Obtener estadísticas RX/TX
                rx_bytes, tx_bytes = get_interface_stats(interface_name)
                interface_info['rx_bytes'] = rx_bytes
                interface_info['tx_bytes'] = tx_bytes
                
                # Obtener información ethtool
                ethtool_info = get_ethtool_info(interface_name)
                
                # Si ethtool falla, usar método alternativo para el estado del enlace
                if ethtool_info.get('link') == 'UNKNOWN' and not ethtool_info.get('error'):
                    alternative_link_status = get_interface_link_status(interface_name)
                    if alternative_link_status != 'UNKNOWN':
                        ethtool_info['link'] = alternative_link_status
                        ethtool_info['link_source'] = 'sysfs'
                
                ethtool_data[interface_name] = ethtool_info
            
            # Actualizar datos globales
            network_data['interfaces'] = interfaces
            network_data['ethtool_stats'] = ethtool_data
            network_data['last_update'] = time.strftime('%Y-%m-%d %H:%M:%S')
            
        except Exception as e:
            print(f"Error updating network data: {e}")
            network_data['error'] = str(e)
        
        time.sleep(3)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/network-data')
def get_network_data():
    return jsonify(network_data)

if __name__ == '__main__':
    # Configuración inicial
    print("=== Dashboard de Red - Configuración Automática ===")
    print("🔧 Configurando permisos para ethtool...")
    
    # Diagnóstico inicial
    diagnosis = diagnose_ethtool()
    network_data['system_info'] = diagnosis
    
    print(f"Ethtool instalado: {diagnosis['installed']}")
    print(f"Versión: {diagnosis['version']}")
    print(f"Permisos: {diagnosis['permissions']}")
    
    # Configurar permisos si es necesario
    if diagnosis['installed'] and diagnosis['permissions'] != 'user':
        print("\n🚀 Intentando configurar permisos automáticamente...")
        setup_success = setup_ethtool_permissions()
        
        if setup_success:
            print("✅ Permisos configurados correctamente")
            # Actualizar diagnóstico
            diagnosis = diagnose_ethtool()
            network_data['system_info'] = diagnosis
        else:
            print("⚠️  No se pudieron configurar permisos automáticamente")
            print("💡 El dashboard usará sudo cuando sea necesario")
    
    print("\n🌐 Iniciando servidor Flask en http://localhost:5000")
    
    # Iniciar hilo para actualizar datos
    update_thread = threading.Thread(target=update_network_data, daemon=True)
    update_thread.start()
    
    # Crear directorio de templates
    os.makedirs('/tmp/templates', exist_ok=True)
    
    # Crear template HTML CORREGIDO
    with open('/tmp/templates/index.html', 'w') as f:
        f.write('''
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard de Red - Arch Linux</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { background: rgba(255, 255, 255, 0.95); color: #2c3e50; padding: 25px; border-radius: 15px; margin-bottom: 25px; box-shadow: 0 8px 32px rgba(0,0,0,0.1); }
        .card { background: rgba(255, 255, 255, 0.95); padding: 25px; margin-bottom: 25px; border-radius: 15px; box-shadow: 0 8px 32px rgba(0,0,0,0.1); }
        .status-card { background: linear-gradient(135deg, #a8edea 0%, #fed6e3 100%); border-left: 5px solid #27ae60; }
        .status-card.warning { background: linear-gradient(135deg, #ffecd2 0%, #fcb69f 100%); border-left: 5px solid #e74c3c; }
        .interface-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 20px; }
        .interface-card { border: none; padding: 20px; border-radius: 12px; color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2); }
        .status-up { color: #2ecc71; font-weight: bold; }
        .status-down { color: #e74c3c; font-weight: bold; }
        .status-unknown { color: #f39c12; font-weight: bold; }
        .chart-container { height: 350px; margin: 20px 0; background: rgba(255,255,255,0.8); padding: 15px; border-radius: 12px; }
        .permission-badge { background: #3498db; color: white; padding: 3px 8px; border-radius: 12px; font-size: 0.7em; margin-left: 5px; }
        .permission-badge.sudo { background: #e74c3c; }
        .permission-badge.user { background: #27ae60; }
        .ethtool-status { font-weight: bold; }
        .ethtool-status.working { color: #27ae60; }
        .ethtool-status.sudo { color: #f39c12; }
        .ethtool-status.error { color: #e74c3c; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🛰️ Dashboard de Monitoreo de Red <span style="background: #1793d1; color: white; padding: 5px 10px; border-radius: 20px; font-size: 0.8em; margin-left: 10px;">Arch Linux</span></h1>
            <p>Monitoreo en tiempo real de interfaces de red</p>
        </div>

        <div id="statusInfo" class="card status-card">
            <h2>🔍 Estado del Sistema</h2>
            <div id="statusContent">
                <p>Verificando configuración...</p>
            </div>
        </div>

        <div class="card">
            <h2>📡 Interfaces de Red</h2>
            <div id="interfaces" class="interface-grid">
                <div class="interface-card">
                    <p>Cargando interfaces...</p>
                </div>
            </div>
        </div>

        <div class="card">
            <h2>📊 Tráfico de Red</h2>
            <div class="chart-container">
                <canvas id="trafficChart"></canvas>
            </div>
        </div>

        <div class="card">
            <h2>🔧 Información Ethtool</h2>
            <div id="ethtoolInfo" style="margin-bottom: 15px; padding: 15px; background: #e8f4fd; border-radius: 8px;">
                <p><strong>Estado de ethtool:</strong> <span id="ethtoolStatus">Verificando...</span></p>
            </div>
            <div id="ethtoolStats">
                <p>Cargando información de ethtool...</p>
            </div>
        </div>

        <div style="text-align: center; color: rgba(255,255,255,0.9); font-size: 14px; margin-top: 20px;">
            Última actualización: <span id="lastUpdate">-</span>
        </div>
    </div>

    <script>
        let trafficChart = null;

        function formatBytes(bytes) {
            if (bytes === 0) return '0 B';
            const k = 1024;
            const sizes = ['B', 'KB', 'MB', 'GB'];
            const i = Math.floor(Math.log(bytes) / Math.log(k));
            return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
        }

        function updateSystemStatus(systemInfo) {
            const statusDiv = document.getElementById('statusContent');
            const statusCard = document.getElementById('statusInfo');
            const ethtoolStatus = document.getElementById('ethtoolStatus');
            
            let statusHTML = '';
            let ethtoolStatusHTML = '';
            let ethtoolStatusClass = '';
            let isHealthy = true;

            if (!systemInfo.installed) {
                statusHTML = `
                    <p><strong>❌ Ethtool no está instalado</strong></p>
                    <p>Ejecuta: <code>sudo pacman -S ethtool</code></p>
                `;
                ethtoolStatusHTML = 'No instalado';
                ethtoolStatusClass = 'error';
                isHealthy = false;
            } else if (systemInfo.permissions === 'user') {
                statusHTML = `
                    <p><strong>✅ Sistema configurado correctamente</strong></p>
                    <p><strong>Versión:</strong> ${systemInfo.version}</p>
                    <p><strong>Permisos:</strong> <span class="permission-badge user">Usuario normal</span></p>
                `;
                ethtoolStatusHTML = 'Funcionando';
                ethtoolStatusClass = 'working';
            } else if (systemInfo.permissions === 'sudo') {
                statusHTML = `
                    <p><strong>⚠️ Ethtool requiere sudo</strong></p>
                    <p><strong>Versión:</strong> ${systemInfo.version}</p>
                    <p><strong>Permisos:</strong> <span class="permission-badge sudo">Requiere sudo</span></p>
                    <p><em>El dashboard funciona pero usa sudo internamente</em></p>
                `;
                ethtoolStatusHTML = 'Usando sudo';
                ethtoolStatusClass = 'sudo';
                isHealthy = false;
            } else {
                statusHTML = `
                    <p><strong>❌ Problema de permisos</strong></p>
                    <p>Ethtool no funciona incluso con sudo</p>
                `;
                ethtoolStatusHTML = 'Error grave';
                ethtoolStatusClass = 'error';
                isHealthy = false;
            }

            statusDiv.innerHTML = statusHTML;
            ethtoolStatus.innerHTML = ethtoolStatusHTML;
            ethtoolStatus.className = `ethtool-status ${ethtoolStatusClass}`;
            
            // Cambiar color de la tarjeta de estado
            statusCard.className = isHealthy ? 'card status-card' : 'card status-card warning';
        }

        function updateDashboard() {
            fetch('/api/network-data')
                .then(response => response.json())
                .then(data => {
                    updateSystemStatus(data.system_info);
                    updateInterfaces(data.interfaces);
                    updateTrafficChart(data.interfaces);
                    updateEthtoolStats(data.ethtool_stats);
                    document.getElementById('lastUpdate').textContent = data.last_update || '-';
                })
                .catch(error => {
                    console.error('Error:', error);
                });
        }

        function updateInterfaces(interfaces) {
            const container = document.getElementById('interfaces');
            
            if (!interfaces || Object.keys(interfaces).length === 0) {
                container.innerHTML = '<div class="interface-card"><p>No se encontraron interfaces de red</p></div>';
                return;
            }

            container.innerHTML = '';

            for (const [name, info] of Object.entries(interfaces)) {
                const statusClass = `status-${info.status ? info.status.toLowerCase() : 'unknown'}`;
                const statusText = info.status || 'UNKNOWN';
                const bgColor = info.type === 'physical' ? 
                    'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)' : 
                    'linear-gradient(135deg, #fa709a 0%, #fee140 100%)';
                
                const card = document.createElement('div');
                card.className = 'interface-card';
                card.style.background = bgColor;
                card.innerHTML = `
                    <h3>🔌 ${name} ${info.type === 'virtual' ? '(Virtual)' : ''}</h3>
                    <p><strong>Estado:</strong> <span class="${statusClass}">${statusText}</span></p>
                    <p><strong>IP:</strong> ${info.ip || 'Sin dirección IP'}</p>
                    <p><strong>MAC:</strong> ${info.mac || 'N/A'}</p>
                    <p><strong>📥 RX:</strong> ${formatBytes(info.rx_bytes || 0)}</p>
                    <p><strong>📤 TX:</strong> ${formatBytes(info.tx_bytes || 0)}</p>
                `;
                container.appendChild(card);
            }
        }

        function updateTrafficChart(interfaces) {
            const ctx = document.getElementById('trafficChart').getContext('2d');
            
            if (!interfaces || Object.keys(interfaces).length === 0) {
                if (trafficChart) {
                    trafficChart.destroy();
                    trafficChart = null;
                }
                return;
            }

            const validInterfaces = Object.keys(interfaces).filter(name => name !== 'lo');

            if (validInterfaces.length === 0) {
                if (trafficChart) {
                    trafficChart.destroy();
                    trafficChart = null;
                }
                return;
            }

            const labels = validInterfaces;
            const rxData = labels.map(name => interfaces[name].rx_bytes || 0);
            const txData = labels.map(name => interfaces[name].tx_bytes || 0);

            if (trafficChart) {
                trafficChart.data.labels = labels;
                trafficChart.data.datasets[0].data = rxData;
                trafficChart.data.datasets[1].data = txData;
                trafficChart.update();
            } else {
                trafficChart = new Chart(ctx, {
                    type: 'bar',
                    data: {
                        labels: labels,
                        datasets: [
                            {
                                label: '📥 RX Bytes',
                                data: rxData,
                                backgroundColor: 'rgba(54, 162, 235, 0.8)',
                                borderColor: 'rgba(54, 162, 235, 1)',
                                borderWidth: 2,
                                borderRadius: 5
                            },
                            {
                                label: '📤 TX Bytes',
                                data: txData,
                                backgroundColor: 'rgba(255, 99, 132, 0.8)',
                                borderColor: 'rgba(255, 99, 132, 1)',
                                borderWidth: 2,
                                borderRadius: 5
                            }
                        ]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        scales: {
                            y: {
                                beginAtZero: true,
                                title: { display: true, text: 'Bytes' },
                                ticks: { callback: value => formatBytes(value) }
                            }
                        },
                        plugins: {
                            tooltip: {
                                callbacks: {
                                    label: context => context.dataset.label + ': ' + formatBytes(context.raw)
                                }
                            }
                        }
                    }
                });
            }
        }

        function updateEthtoolStats(ethtoolStats) {
            const container = document.getElementById('ethtoolStats');
            
            if (!ethtoolStats || Object.keys(ethtoolStats).length === 0) {
                container.innerHTML = '<p>No se pudieron obtener estadísticas ethtool</p>';
                return;
            }

            let hasValidData = false;
            container.innerHTML = '';

            for (const [interface, stats] of Object.entries(ethtoolStats)) {
                const section = document.createElement('div');
                section.style.marginBottom = '20px';
                section.style.padding = '15px';
                section.style.background = 'rgba(255,255,255,0.9)';
                section.style.borderRadius = '8px';
                
                let statusHTML = '';
                
                if (stats.error) {
                    statusHTML = `
                        <p><strong>Estado:</strong> <span class="status-unknown">ERROR</span></p>
                        <p><strong>Error:</strong> ${stats.error}</p>
                        ${stats.diagnosis ? `<p><strong>Nota:</strong> ${stats.diagnosis}</p>` : ''}
                    `;
                } else {
                    hasValidData = true;
                    const linkClass = `status-${stats.link ? stats.link.toLowerCase() : 'unknown'}`;
                    const linkText = stats.link || 'UNKNOWN';
                    
                    statusHTML = `
                        <p><strong>🔗 Enlace:</strong> <span class="${linkClass}">${linkText}</span></p>
                        <p><strong>⚡ Velocidad:</strong> ${stats.speed || 'N/A'}</p>
                        <p><strong>🔄 Duplex:</strong> ${stats.duplex || 'N/A'}</p>
                        <p><strong>🔌 Puerto:</strong> ${stats.port || 'N/A'}</p>
                        ${stats.diagnosis ? `<p><strong>Modo:</strong> ${stats.diagnosis}</p>` : ''}
                    `;
                }

                section.innerHTML = `
                    <h3>🔧 ${interface}</h3>
                    ${statusHTML}
                `;
                container.appendChild(section);
            }

            if (!hasValidData) {
                container.innerHTML = '<p>No se pudo obtener información ethtool para ninguna interfaz física</p>';
            }
        }

        setInterval(updateDashboard, 3000);
        updateDashboard();
    </script>
</body>
</html>
        ''')
    
    app.run(host='0.0.0.0', port=5000, debug=False, use_reloader=False)

EOF

# Hacer el script Python ejecutable
chmod +x /tmp/network_dashboard.py

echo "=== Dashboard de Red - Con Gestión Automática de Permisos ==="
echo "🔧 Este script configurará automáticamente los permisos de ethtool"

# Verificar y instalar dependencias
if ! command -v python3 > /dev/null; then
    echo "Instalando Python..."
    sudo pacman -Sy --noconfirm python
fi

if ! python3 -c "import flask" 2>/dev/null; then
    echo "Instalando Flask..."
    pip3 install flask
fi

if ! command -v ethtool > /dev/null; then
    echo "Instalando ethtool..."
    sudo pacman -Sy --noconfirm ethtool
fi

# Configurar permisos para ethtool
echo "🔧 Configurando permisos para ethtool..."
ETHTOOL_PATH=$(which ethtool)
if [ -n "$ETHTOOL_PATH" ]; then
    echo "📍 Configurando capabilities para: $ETHTOOL_PATH"
    sudo setcap cap_net_admin,cap_net_raw+ep "$ETHTOOL_PATH"
    
    # Verificar que funciona
    if ethtool --version > /dev/null 2>&1; then
        echo "✅ Ethtool ahora funciona sin sudo"
    else
        echo "⚠️  Ethtool aún requiere sudo, pero el dashboard lo manejará automáticamente"
    fi
fi

# Abrir navegador
echo "🌐 Abriendo navegador..."
if command -v xdg-open > /dev/null; then
    (sleep 3 && xdg-open "http://localhost:5000") &
fi

echo "🚀 Iniciando dashboard..."
echo "💡 El dashboard usará sudo automáticamente cuando sea necesario"
python3 /tmp/network_dashboard.py
