#!/bin/bash

# Script: network_dashboard.sh
# Descripción: Dashboard web para monitoreo de red en tiempo real usando iftop, Flask y gráficos
# Compatible con distribuciones basadas en Arch Linux

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir mensajes
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar si somos root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_warning "Ejecutando como root"
    else
        print_error "Este script necesita privilegios de root para ejecutar iftop"
        print_error "Ejecuta con: sudo ./$0"
        exit 1
    fi
}

# Detectar distribución y instalar dependencias
install_dependencies() {
    print_status "Detectando distribución..."
    
    if command -v pacman &> /dev/null; then
        print_status "Distribución basada en Arch detectada"
        
        # Actualizar base de datos de paquetes
        pacman -Sy --noconfirm
        
        # Instalar dependencias del sistema
        local deps=("python" "python-pip" "iftop" "net-tools" "python-virtualenv")
        
        for dep in "${deps[@]}"; do
            if ! pacman -Qi "$dep" &> /dev/null; then
                print_status "Instalando $dep..."
                pacman -S --noconfirm "$dep"
            else
                print_status "$dep ya está instalado"
            fi
        done
        
    elif command -v apt &> /dev/null; then
        print_status "Distribución basada en Debian detectada"
        apt update
        apt install -y python3 python3-pip iftop net-tools python3-venv
        
    elif command -v yum &> /dev/null; then
        print_status "Distribución basada en RHEL detectada"
        yum install -y python3 python3-pip iftop net-tools python3-virtualenv
        
    else
        print_error "Distribución no soportada"
        exit 1
    fi
    
    # Crear entorno virtual para Python
    print_status "Creando entorno virtual Python..."
    python3 -m venv /tmp/network_dashboard_venv
    
    # Activar entorno virtual
    source /tmp/network_dashboard_venv/bin/activate
    
    # Instalar dependencias Python en el entorno virtual
    print_status "Instalando dependencias Python en el entorno virtual..."
    /tmp/network_dashboard_venv/bin/pip install flask flask-socketio eventlet
    
    print_success "Dependencias instaladas correctamente"
}

# Crear aplicación Flask
create_flask_app() {
    local app_file="/tmp/network_dashboard.py"
    
    cat > "$app_file" << 'EOF'
#!/usr/bin/env python3
"""
Dashboard web para monitoreo de red en tiempo real
"""
import json
import subprocess
import threading
import time
import re
import sys
import os
from flask import Flask, render_template_string, jsonify
from flask_socketio import SocketIO
import eventlet
eventlet.monkey_patch()

app = Flask(__name__)
app.config['SECRET_KEY'] = 'network_dashboard_secret'
socketio = SocketIO(app, async_mode='eventlet')

# Datos para gráficos
network_data = {
    'timestamps': [],
    'upload_speeds': [],
    'download_speeds': [],
    'connections': []
}

def parse_iftop_output(line):
    """Parsear salida de iftop para extraer datos de red"""
    try:
        # Patrones para detectar líneas de datos de iftop
        # Ejemplo: 1.0Mb  2.0Mb  3.0Mb
        pattern = r'(\d+\.\d+[KM]?b)\s+(\d+\.\d+[KM]?b)\s+(\d+\.\d+[KM]?b)'
        match = re.search(pattern, line)
        
        if match:
            cumulative_send = match.group(1)
            cumulative_receive = match.group(2)
            peak_send = match.group(3)
            
            # Convertir a Mbps
            def to_mbps(value):
                if 'Kb' in value:
                    return float(value.replace('Kb', '')) / 1000
                elif 'Mb' in value:
                    return float(value.replace('Mb', ''))
                elif 'Gb' in value:
                    return float(value.replace('Gb', '')) * 1000
                else:
                    return float(value.replace('b', '')) / 1000000
            
            upload_mbps = to_mbps(cumulative_send)
            download_mbps = to_mbps(cumulative_receive)
            
            return upload_mbps, download_mbps, None
        
        # Buscar información de conexiones
        conn_pattern = r'(\d+)\s+connections'
        conn_match = re.search(conn_pattern, line)
        if conn_match:
            return None, None, int(conn_match.group(1))
            
    except Exception as e:
        print(f"Error parsing iftop output: {e}")
    
    return None, None, None

def run_iftop():
    """Ejecutar iftop y capturar su salida"""
    try:
        # Ejecutar iftop en modo batch
        cmd = ['iftop', '-t', '-P', '-N', '-n', '-s', '2']
        
        process = subprocess.Popen(
            cmd, 
            stdout=subprocess.PIPE, 
            stderr=subprocess.PIPE,
            universal_newlines=True,
            bufsize=1
        )
        
        return process
        
    except Exception as e:
        print(f"Error ejecutando iftop: {e}")
        return None

def monitor_network():
    """Hilo para monitorear la red en tiempo real"""
    print("Iniciando monitor de red...")
    
    while True:
        try:
            process = run_iftop()
            if not process:
                time.sleep(2)
                continue
            
            connection_count = 0
            
            for line in iter(process.stdout.readline, ''):
                upload, download, conns = parse_iftop_output(line)
                
                current_time = time.strftime('%H:%M:%S')
                
                if upload is not None and download is not None:
                    # Mantener solo los últimos 50 puntos de datos
                    if len(network_data['timestamps']) >= 50:
                        network_data['timestamps'].pop(0)
                        network_data['upload_speeds'].pop(0)
                        network_data['download_speeds'].pop(0)
                    
                    network_data['timestamps'].append(current_time)
                    network_data['upload_speeds'].append(upload)
                    network_data['download_speeds'].append(download)
                
                if conns is not None:
                    connection_count = conns
                    if len(network_data['connections']) >= 50:
                        network_data['connections'].pop(0)
                    network_data['connections'].append(connection_count)
                
                # Enviar datos a través de WebSocket
                socketio.emit('network_update', {
                    'timestamps': network_data['timestamps'][-20:],  # Últimos 20 puntos
                    'upload_speeds': network_data['upload_speeds'][-20:],
                    'download_speeds': network_data['download_speeds'][-20:],
                    'connections': network_data['connections'][-10:] if network_data['connections'] else [0],
                    'current_upload': network_data['upload_speeds'][-1] if network_data['upload_speeds'] else 0,
                    'current_download': network_data['download_speeds'][-1] if network_data['download_speeds'] else 0,
                    'current_connections': connection_count
                })
                
                time.sleep(0.5)
            
            process.terminate()
            
        except Exception as e:
            print(f"Error en monitor_network: {e}")
            time.sleep(2)

# HTML template para el dashboard
HTML_TEMPLATE = '''
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard de Red - Monitor en Tiempo Real</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/socket.io/4.0.1/socket.io.js"></script>
    <style>
        body {
            font-family: 'Arial', sans-serif;
            margin: 0;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #333;
            min-height: 100vh;
        }
        .dashboard {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            padding: 20px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
        }
        .header h1 {
            color: #4a5568;
            margin-bottom: 10px;
        }
        .stats-container {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .stat-card {
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: white;
            padding: 20px;
            border-radius: 10px;
            text-align: center;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
        }
        .stat-value {
            font-size: 2em;
            font-weight: bold;
            margin: 10px 0;
        }
        .stat-label {
            font-size: 0.9em;
            opacity: 0.9;
        }
        .chart-container {
            background: white;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 20px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
        }
        .chart-wrapper {
            position: relative;
            height: 400px;
        }
        .info-box {
            background: #f8f9fa;
            border-left: 4px solid #667eea;
            padding: 15px;
            margin-bottom: 20px;
            border-radius: 5px;
        }
    </style>
</head>
<body>
    <div class="dashboard">
        <div class="header">
            <h1>🚀 Dashboard de Red - Monitor en Tiempo Real</h1>
            <p>Monitoreo de tráfico de red usando iftop</p>
        </div>
        
        <div class="info-box">
            <strong>Información:</strong> Este dashboard muestra el tráfico de red en tiempo real. 
            Los datos se actualizan automáticamente cada segundo.
        </div>
        
        <div class="stats-container">
            <div class="stat-card">
                <div class="stat-label">Subida Actual</div>
                <div class="stat-value" id="current-upload">0 Mbps</div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Bajada Actual</div>
                <div class="stat-value" id="current-download">0 Mbps</div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Conexiones</div>
                <div class="stat-value" id="current-connections">0</div>
            </div>
        </div>
        
        <div class="chart-container">
            <h3>📊 Velocidad de Red (Mbps)</h3>
            <div class="chart-wrapper">
                <canvas id="speedChart"></canvas>
            </div>
        </div>
        
        <div class="chart-container">
            <h3>🔗 Conexiones Activas</h3>
            <div class="chart-wrapper">
                <canvas id="connectionsChart"></canvas>
            </div>
        </div>
    </div>

    <script>
        // Conectar WebSocket
        const socket = io();
        
        // Configurar gráficos
        const speedCtx = document.getElementById('speedChart').getContext('2d');
        const connectionsCtx = document.getElementById('connectionsChart').getContext('2d');
        
        const speedChart = new Chart(speedCtx, {
            type: 'line',
            data: {
                labels: [],
                datasets: [
                    {
                        label: 'Subida (Mbps)',
                        data: [],
                        borderColor: 'rgb(255, 99, 132)',
                        backgroundColor: 'rgba(255, 99, 132, 0.1)',
                        tension: 0.4,
                        fill: true,
                        borderWidth: 2
                    },
                    {
                        label: 'Bajada (Mbps)',
                        data: [],
                        borderColor: 'rgb(54, 162, 235)',
                        backgroundColor: 'rgba(54, 162, 235, 0.1)',
                        tension: 0.4,
                        fill: true,
                        borderWidth: 2
                    }
                ]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                animation: {
                    duration: 0
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Mbps'
                        }
                    }
                }
            }
        });
        
        const connectionsChart = new Chart(connectionsCtx, {
            type: 'bar',
            data: {
                labels: [],
                datasets: [{
                    label: 'Conexiones',
                    data: [],
                    backgroundColor: 'rgba(75, 192, 192, 0.6)',
                    borderColor: 'rgba(75, 192, 192, 1)',
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                animation: {
                    duration: 0
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Número de Conexiones'
                        }
                    }
                }
            }
        });
        
        // Escuchar actualizaciones del servidor
        socket.on('network_update', function(data) {
            // Actualizar estadísticas
            document.getElementById('current-upload').textContent = data.current_upload.toFixed(2) + ' Mbps';
            document.getElementById('current-download').textContent = data.current_download.toFixed(2) + ' Mbps';
            document.getElementById('current-connections').textContent = data.current_connections;
            
            // Actualizar gráfico de velocidad
            speedChart.data.labels = data.timestamps;
            speedChart.data.datasets[0].data = data.upload_speeds;
            speedChart.data.datasets[1].data = data.download_speeds;
            speedChart.update('none');
            
            // Actualizar gráfico de conexiones
            if (data.connections && data.connections.length > 0) {
                const connLabels = Array.from({length: data.connections.length}, (_, i) => (i + 1).toString());
                connectionsChart.data.labels = connLabels;
                connectionsChart.data.datasets[0].data = data.connections;
                connectionsChart.update('none');
            }
        });
        
        // Manejar reconexión
        socket.on('connect', function() {
            console.log('Conectado al servidor');
        });
        
        socket.on('disconnect', function() {
            console.log('Desconectado del servidor');
        });
    </script>
</body>
</html>
'''

@app.route('/')
def index():
    """Página principal del dashboard"""
    return render_template_string(HTML_TEMPLATE)

@app.route('/api/data')
def get_data():
    """API para obtener datos actuales"""
    return jsonify(network_data)

if __name__ == '__main__':
    # Iniciar hilo de monitoreo
    monitor_thread = threading.Thread(target=monitor_network, daemon=True)
    monitor_thread.start()
    
    print("Servidor Flask iniciando...")
    print("Dashboard disponible en: http://localhost:5000")
    print("Presiona Ctrl+C para detener el servidor")
    
    # Ejecutar servidor
    try:
        socketio.run(app, host='0.0.0.0', port=5000, debug=False, log_output=False)
    except KeyboardInterrupt:
        print("\nDeteniendo servidor...")
        sys.exit(0)

EOF

    chmod +x "$app_file"
    print_success "Aplicación Flask creada en: $app_file"
}

# Abrir navegador por defecto
open_browser() {
    print_status "Abriendo navegador web..."
    
    # Pequeña pausa para dar tiempo al servidor de iniciar
    sleep 3
    
    local url="http://localhost:5000"
    
    if command -v xdg-open &> /dev/null; then
        xdg-open "$url" 2>/dev/null &
    elif command -v gnome-open &> /dev/null; then
        gnome-open "$url" 2>/dev/null &
    elif command -v kde-open &> /dev/null; then
        kde-open "$url" 2>/dev/null &
    elif command -v firefox &> /dev/null; then
        firefox "$url" 2>/dev/null &
    elif command -v chromium &> /dev/null; then
        chromium "$url" 2>/dev/null &
    elif command -v google-chrome &> /dev/null; then
        google-chrome "$url" 2>/dev/null &
    else
        print_warning "No se pudo detectar el navegador por defecto"
        print_status "Abre manualmente: $url"
    fi
}

# Función principal
main() {
    clear
    print_status "Iniciando Network Dashboard..."
    
    # Verificar permisos
    check_root
    
    # Instalar dependencias
    install_dependencies
    
    # Crear aplicación Flask
    create_flask_app
    
    # Abrir navegador en segundo plano
    open_browser &
    
    # Ejecutar aplicación Flask usando el entorno virtual
    print_success "Iniciando servidor web..."
    print_status "Presiona Ctrl+C para detener el dashboard"
    echo ""
    
    # Usar el Python del entorno virtual
    /tmp/network_dashboard_venv/bin/python /tmp/network_dashboard.py
}

# Manejar señal de interrupción
trap 'print_status "Deteniendo dashboard..."; exit 0' INT TERM

# Ejecutar función principal
main
