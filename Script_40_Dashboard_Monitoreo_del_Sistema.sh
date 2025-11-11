#!/bin/bash

# Script de monitoreo simplificado sin gráfico de red y con filtro de particiones
REPORT_DIR="/tmp/system_reports"
FLASK_APP="web_dashboard_simplificado.py"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}🚀 Iniciando sistema de monitoreo simplificado...${NC}"

# Crear directorio de reportes
mkdir -p "$REPORT_DIR"

# Función para abrir navegador
open_browser() {
    echo -e "${YELLOW}🌐 Abriendo navegador automáticamente...${NC}"
    sleep 3  # Esperar a que el servidor Flask inicie
    
    if command -v xdg-open > /dev/null; then
        xdg-open "http://localhost:5000" &
        echo -e "${GREEN}✅ Navegador abierto con xdg-open${NC}"
    elif command -v open > /dev/null; then
        open "http://localhost:5000" &
        echo -e "${GREEN}✅ Navegador abierto con open${NC}"
    elif command -v firefox > /dev/null; then
        firefox "http://localhost:5000" &
        echo -e "${GREEN}✅ Firefox abierto${NC}"
    elif command -v google-chrome > /dev/null; then
        google-chrome "http://localhost:5000" &
        echo -e "${GREEN}✅ Google Chrome abierto${NC}"
    elif command -v chromium-browser > /dev/null; then
        chromium-browser "http://localhost:5000" &
        echo -e "${GREEN}✅ Chromium abierto${NC}"
    else
        echo -e "${YELLOW}⚠️  No se pudo abrir el navegador automáticamente${NC}"
        echo -e "${BLUE}📍 Abre manualmente: http://localhost:5000${NC}"
    fi
}

# Verificar si Python y Flask están instalados
check_dependencies() {
    echo -e "${YELLOW}Verificando dependencias...${NC}"
    
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}❌ Python3 no está instalado${NC}"
        exit 1
    fi

    if ! python3 -c "import flask, psutil" 2>/dev/null; then
        echo -e "${YELLOW}Instalando dependencias de Python...${NC}"
        pip3 install flask psutil
    fi
    
    echo -e "${GREEN}✅ Dependencias verificadas${NC}"
}

# Crear la aplicación Flask simplificada
create_flask_app() {
    cat > "$FLASK_APP" << 'EOF'
from flask import Flask, render_template, jsonify
import subprocess
import psutil
import json
from datetime import datetime
import threading
import time
import collections

app = Flask(__name__)

# Datos en cache
system_data = {}
data_lock = threading.Lock()

# Variables para cálculo de tráfico de red
prev_net_io = None
prev_time = None

def get_network_traffic():
    global prev_net_io, prev_time
    
    current_net_io = psutil.net_io_counters()
    current_time = time.time()
    
    if prev_net_io is None or prev_time is None:
        prev_net_io = current_net_io
        prev_time = current_time
        return {
            'bytes_sent': 0, 
            'bytes_recv': 0, 
            'packets_sent': 0, 
            'packets_recv': 0,
            'bytes_sent_kb': 0,
            'bytes_recv_kb': 0
        }
    
    time_diff = current_time - prev_time
    if time_diff == 0:
        return {
            'bytes_sent': 0, 
            'bytes_recv': 0, 
            'packets_sent': 0, 
            'packets_recv': 0,
            'bytes_sent_kb': 0,
            'bytes_recv_kb': 0
        }
    
    # Calcular tasas por segundo
    bytes_sent_per_sec = (current_net_io.bytes_sent - prev_net_io.bytes_sent) / time_diff
    bytes_recv_per_sec = (current_net_io.bytes_recv - prev_net_io.bytes_recv) / time_diff
    packets_sent_per_sec = (current_net_io.packets_sent - prev_net_io.packets_sent) / time_diff
    packets_recv_per_sec = (current_net_io.packets_recv - prev_net_io.packets_recv) / time_diff
    
    # Actualizar valores anteriores
    prev_net_io = current_net_io
    prev_time = current_time
    
    return {
        'bytes_sent': bytes_sent_per_sec,
        'bytes_recv': bytes_recv_per_sec,
        'packets_sent': packets_sent_per_sec,
        'packets_recv': packets_recv_per_sec,
        'bytes_sent_kb': bytes_sent_per_sec / 1024,  # KB/s
        'bytes_recv_kb': bytes_recv_per_sec / 1024,  # KB/s
        'bytes_sent_mb': bytes_sent_per_sec / (1024 * 1024),  # MB/s
        'bytes_recv_mb': bytes_recv_per_sec / (1024 * 1024),  # MB/s
        'total_bytes_sent': current_net_io.bytes_sent,
        'total_bytes_recv': current_net_io.bytes_recv
    }

def collect_system_data():
    global system_data
    while True:
        try:
            # Información del sistema
            info = {
                'timestamp': datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                'cpu_percent': psutil.cpu_percent(interval=1),
                'memory': dict(psutil.virtual_memory()._asdict()),
                'swap': dict(psutil.swap_memory()._asdict()),
                'disk_usage': [],
                'network_connections': len(psutil.net_connections()),
                'load_avg': psutil.getloadavg(),
                'disk_io': psutil.disk_io_counters()._asdict() if psutil.disk_io_counters() else {},
                'network_traffic': get_network_traffic()
            }
            
            # Uso de disco - FILTRAR particiones mayores a 20 GB
            for partition in psutil.disk_partitions():
                try:
                    usage = psutil.disk_usage(partition.mountpoint)
                    total_gb = usage.total / (1024**3)
                    
                    # Filtrar particiones mayores a 20 GB
                    if total_gb >= 20:
                        disk_info = {
                            'device': partition.device,
                            'mountpoint': partition.mountpoint,
                            'total_gb': round(total_gb, 1),
                            'used_gb': round(usage.used / (1024**3), 1),
                            'free_gb': round(usage.free / (1024**3), 1),
                            'percent': usage.percent,
                            'used_percent': usage.percent,
                            'free_percent': 100 - usage.percent
                        }
                        info['disk_usage'].append(disk_info)
                        print(f"✅ Partición incluida: {partition.mountpoint} ({total_gb:.1f} GB)")
                    else:
                        print(f"❌ Partición filtrada: {partition.mountpoint} ({total_gb:.1f} GB) - Menor a 20 GB")
                        
                except Exception as e:
                    print(f"Error reading disk {partition.mountpoint}: {e}")
            
            with data_lock:
                system_data = info
                
        except Exception as e:
            print(f"Error collecting data: {e}")
        
        time.sleep(2)  # Actualizar cada 2 segundos

@app.route('/')
def dashboard():
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <title>Dashboard del Sistema - Monitoreo Simplificado</title>
        <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
        <style>
            body { 
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
                margin: 0; 
                padding: 20px; 
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                min-height: 100vh;
            }
            .container {
                max-width: 1400px;
                margin: 0 auto;
            }
            .header {
                text-align: center;
                color: white;
                margin-bottom: 30px;
            }
            .header h1 {
                font-size: 2.5em;
                margin: 0;
                text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
            }
            .header .subtitle {
                font-size: 1.2em;
                opacity: 0.9;
            }
            .grid { 
                display: grid; 
                grid-template-columns: repeat(auto-fit, minmax(500px, 1fr)); 
                gap: 25px; 
                margin-bottom: 30px;
            }
            .card { 
                background: rgba(255, 255, 255, 0.95); 
                padding: 25px; 
                border-radius: 15px; 
                box-shadow: 0 8px 32px rgba(0,0,0,0.1);
                backdrop-filter: blur(10px);
                border: 1px solid rgba(255, 255, 255, 0.2);
            }
            .chart-container { 
                height: 350px; 
                margin: 20px 0; 
                position: relative;
            }
            .metric-grid {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                gap: 15px;
                margin: 15px 0;
            }
            .metric-card {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                padding: 15px;
                border-radius: 10px;
                text-align: center;
            }
            .metric-value {
                font-size: 1.8em;
                font-weight: bold;
                margin: 5px 0;
            }
            .metric-label {
                font-size: 0.9em;
                opacity: 0.9;
            }
            .last-update { 
                text-align: center; 
                color: white; 
                margin-bottom: 20px;
                font-size: 1.1em;
            }
            .network-stats {
                display: grid;
                grid-template-columns: 1fr 1fr;
                gap: 20px;
                margin-top: 20px;
            }
            .network-stat-card {
                background: linear-gradient(135deg, #17a2b8, #6f42c1);
                color: white;
                padding: 20px;
                border-radius: 10px;
                text-align: center;
            }
            .stat-value {
                font-size: 2em;
                font-weight: bold;
                margin: 10px 0;
            }
            .stat-label {
                font-size: 1em;
                opacity: 0.9;
            }
            .status-indicator {
                display: inline-block;
                width: 10px;
                height: 10px;
                border-radius: 50%;
                margin-right: 8px;
            }
            .status-active {
                background-color: #28a745;
                animation: pulse 2s infinite;
            }
            @keyframes pulse {
                0% { opacity: 1; }
                50% { opacity: 0.5; }
                100% { opacity: 1; }
            }
            .info-note {
                text-align: center;
                color: #666;
                font-size: 0.9em;
                margin-top: 10px;
                font-style: italic;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🖥️ Dashboard de Monitoreo del Sistema</h1>
                <div class="subtitle">
                    <span class="status-indicator status-active"></span>
                    Monitoreo en Tiempo Real - Actualización cada 2 segundos
                </div>
            </div>
            
            <div class="last-update" id="lastUpdate"></div>
            
            <div class="grid">
                <!-- CPU -->
                <div class="card">
                    <h2>📊 CPU</h2>
                    <div class="chart-container">
                        <canvas id="cpuChart"></canvas>
                    </div>
                    <div class="metric-grid">
                        <div class="metric-card">
                            <div class="metric-label">Uso Actual</div>
                            <div class="metric-value" id="cpuUsage">0%</div>
                        </div>
                        <div class="metric-card">
                            <div class="metric-label">Load Average</div>
                            <div class="metric-value" id="loadAvg">0</div>
                        </div>
                    </div>
                </div>
                
                <!-- Memoria - Gráfico de Barras -->
                <div class="card">
                    <h2>💾 Memoria</h2>
                    <div class="chart-container">
                        <canvas id="memoryBarChart"></canvas>
                    </div>
                    <div class="metric-grid" id="memoryMetrics"></div>
                </div>
                
                <!-- Almacenamiento - Gráfico de Barras -->
                <div class="card">
                    <h2>🗂️ Almacenamiento</h2>
                    <div class="info-note">Mostrando solo particiones mayores a 20 GB</div>
                    <div class="chart-container">
                        <canvas id="storageBarChart"></canvas>
                    </div>
                    <div class="metric-grid" id="diskMetrics"></div>
                </div>
                
                <!-- Tráfico de Red - SOLO ESTADÍSTICAS -->
                <div class="card">
                    <h2>🌐 Tráfico de Red</h2>
                    <div class="network-stats" id="networkStats"></div>
                    <div class="info-note">Velocidad actual de subida y descarga</div>
                </div>
            </div>
        </div>

        <script>
            let cpuChart, memoryBarChart, storageBarChart;
            const colors = {
                primary: 'rgba(102, 126, 234, 0.8)',
                secondary: 'rgba(118, 75, 162, 0.8)',
                success: 'rgba(40, 167, 69, 0.8)',
                warning: 'rgba(255, 193, 7, 0.8)',
                danger: 'rgba(220, 53, 69, 0.8)',
                info: 'rgba(23, 162, 184, 0.8)',
                lightBlue: 'rgba(77, 192, 181, 0.8)',
                orange: 'rgba(255, 159, 64, 0.8)'
            };

            // Configuración común para gráficos de barras
            const barChartConfig = {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Porcentaje (%)'
                        }
                    }
                },
                plugins: {
                    legend: {
                        position: 'top',
                    }
                }
            };

            function formatBytes(bytes) {
                if (bytes === 0) return '0 B';
                const k = 1024;
                const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
                const i = Math.floor(Math.log(bytes) / Math.log(k));
                return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
            }

            function formatSpeed(bytesPerSec) {
                return formatBytes(bytesPerSec) + '/s';
            }

            async function loadData() {
                try {
                    const response = await fetch('/api/system-data');
                    const data = await response.json();
                    
                    updateCharts(data);
                    updateMetrics(data);
                    updateNetworkStats(data.network_traffic);
                    
                    document.getElementById('lastUpdate').textContent = 
                        `Última actualización: ${data.timestamp}`;
                } catch (error) {
                    console.error('Error loading data:', error);
                }
            }

            function updateCharts(data) {
                // Gráfico de CPU (doughnut)
                updateCPUChart(data);
                
                // Gráfico de Barras para Memoria
                updateMemoryBarChart(data);
                
                // Gráfico de Barras para Almacenamiento
                updateStorageBarChart(data);
            }

            function updateCPUChart(data) {
                if (!cpuChart) {
                    const ctx = document.getElementById('cpuChart').getContext('2d');
                    cpuChart = new Chart(ctx, {
                        type: 'doughnut',
                        data: {
                            labels: ['Usado', 'Libre'],
                            datasets: [{
                                data: [data.cpu_percent, 100 - data.cpu_percent],
                                backgroundColor: [colors.danger, '#e0e0e0'],
                                borderWidth: 2,
                                borderColor: '#fff'
                            }]
                        },
                        options: {
                            responsive: true,
                            maintainAspectRatio: false,
                            cutout: '70%',
                            plugins: {
                                legend: {
                                    position: 'bottom'
                                },
                                tooltip: {
                                    callbacks: {
                                        label: function(context) {
                                            return `${context.label}: ${context.raw}%`;
                                        }
                                    }
                                }
                            }
                        }
                    });
                } else {
                    cpuChart.data.datasets[0].data = [data.cpu_percent, 100 - data.cpu_percent];
                    cpuChart.update();
                }
                
                document.getElementById('cpuUsage').textContent = `${data.cpu_percent.toFixed(1)}%`;
                document.getElementById('loadAvg').textContent = data.load_avg.map(v => v.toFixed(2)).join(', ');
            }

            function updateMemoryBarChart(data) {
                const mem = data.memory;
                const swap = data.swap;
                
                const memUsedPercent = (mem.used / mem.total) * 100;
                const memAvailablePercent = (mem.available / mem.total) * 100;
                const swapUsedPercent = swap.total > 0 ? (swap.used / swap.total) * 100 : 0;
                
                if (!memoryBarChart) {
                    const ctx = document.getElementById('memoryBarChart').getContext('2d');
                    memoryBarChart = new Chart(ctx, {
                        type: 'bar',
                        data: {
                            labels: ['Memoria Usada', 'Memoria Disponible', 'Swap Usado'],
                            datasets: [{
                                label: 'Uso de Memoria (%)',
                                data: [memUsedPercent, memAvailablePercent, swapUsedPercent],
                                backgroundColor: [
                                    colors.danger,
                                    colors.success,
                                    colors.warning
                                ],
                                borderColor: [
                                    colors.danger,
                                    colors.success,
                                    colors.warning
                                ],
                                borderWidth: 2
                            }]
                        },
                        options: {
                            ...barChartConfig,
                            scales: {
                                ...barChartConfig.scales,
                                y: {
                                    ...barChartConfig.scales.y,
                                    max: 100
                                }
                            }
                        }
                    });
                } else {
                    memoryBarChart.data.datasets[0].data = [memUsedPercent, memAvailablePercent, swapUsedPercent];
                    memoryBarChart.update();
                }
                
                // Actualizar métricas de memoria
                updateMemoryMetrics(data);
            }

            function updateMemoryMetrics(data) {
                const mem = data.memory;
                const swap = data.swap;
                const memUsedGB = (mem.used / (1024**3)).toFixed(1);
                const memTotalGB = (mem.total / (1024**3)).toFixed(1);
                const swapUsedGB = (swap.used / (1024**3)).toFixed(1);
                const swapTotalGB = (swap.total / (1024**3)).toFixed(1);
                
                const metricsHtml = `
                    <div class="metric-card" style="background: linear-gradient(135deg, ${colors.danger}, #dc3545);">
                        <div class="metric-label">Memoria Usada</div>
                        <div class="metric-value">${memUsedGB} GB</div>
                        <div class="metric-label">de ${memTotalGB} GB</div>
                    </div>
                    <div class="metric-card" style="background: linear-gradient(135deg, ${colors.success}, #28a745);">
                        <div class="metric-label">Memoria Disponible</div>
                        <div class="metric-value">${(mem.available / (1024**3)).toFixed(1)} GB</div>
                    </div>
                    <div class="metric-card" style="background: linear-gradient(135deg, ${colors.warning}, #fd7e14);">
                        <div class="metric-label">Swap Usado</div>
                        <div class="metric-value">${swapUsedGB} GB</div>
                        <div class="metric-label">de ${swapTotalGB} GB</div>
                    </div>
                `;
                document.getElementById('memoryMetrics').innerHTML = metricsHtml;
            }

            function updateStorageBarChart(data) {
                const diskData = data.disk_usage;
                
                if (diskData.length > 0) {
                    const labels = diskData.map(disk => {
                        const mountpoint = disk.mountpoint;
                        return mountpoint.length > 15 ? 
                            mountpoint.substring(0, 12) + '...' : 
                            mountpoint;
                    });
                    
                    const usageData = diskData.map(disk => disk.percent);
                    const colorsPalette = diskData.map((disk, index) => {
                        const colorsArray = [
                            colors.primary, colors.secondary, colors.info, 
                            colors.warning, colors.danger, colors.lightBlue, colors.orange
                        ];
                        return colorsArray[index % colorsArray.length];
                    });
                    
                    if (!storageBarChart) {
                        const ctx = document.getElementById('storageBarChart').getContext('2d');
                        storageBarChart = new Chart(ctx, {
                            type: 'bar',
                            data: {
                                labels: labels,
                                datasets: [{
                                    label: 'Uso de Disco (%)',
                                    data: usageData,
                                    backgroundColor: colorsPalette,
                                    borderColor: colorsPalette.map(color => color.replace('0.8', '1')),
                                    borderWidth: 2
                                }]
                            },
                            options: {
                                ...barChartConfig,
                                scales: {
                                    ...barChartConfig.scales,
                                    y: {
                                        ...barChartConfig.scales.y,
                                        max: 100
                                    }
                                },
                                plugins: {
                                    ...barChartConfig.plugins,
                                    tooltip: {
                                        callbacks: {
                                            label: function(context) {
                                                const disk = diskData[context.dataIndex];
                                                return [
                                                    `Montaje: ${disk.mountpoint}`,
                                                    `Uso: ${context.raw}%`,
                                                    `Usado: ${disk.used_gb} GB de ${disk.total_gb} GB`,
                                                    `Dispositivo: ${disk.device}`
                                                ];
                                            }
                                        }
                                    }
                                }
                            }
                        });
                    } else {
                        storageBarChart.data.labels = labels;
                        storageBarChart.data.datasets[0].data = usageData;
                        storageBarChart.data.datasets[0].backgroundColor = colorsPalette;
                        storageBarChart.data.datasets[0].borderColor = colorsPalette.map(color => color.replace('0.8', '1'));
                        storageBarChart.update();
                    }
                    
                    // Actualizar métricas de disco
                    updateDiskMetrics(diskData);
                } else {
                    // Si no hay particiones que mostrar
                    document.getElementById('storageBarChart').innerHTML = 
                        '<div style="text-align: center; padding: 50px; color: #666;">No hay particiones mayores a 20 GB para mostrar</div>';
                    document.getElementById('diskMetrics').innerHTML = 
                        '<div class="metric-card"><div class="metric-label">Sin particiones</div><div class="metric-value">-</div></div>';
                }
            }

            function updateDiskMetrics(disks) {
                const metricsHtml = disks.map((disk, index) => {
                    const colorsArray = [
                        'linear-gradient(135deg, #667eea, #764ba2)',
                        'linear-gradient(135deg, #28a745, #20c997)',
                        'linear-gradient(135deg, #fd7e14, #ffc107)',
                        'linear-gradient(135deg, #dc3545, #e83e8c)',
                        'linear-gradient(135deg, #6f42c1, #e83e8c)',
                        'linear-gradient(135deg, #17a2b8, #6f42c1)'
                    ];
                    
                    const bgColor = colorsArray[index % colorsArray.length];
                    
                    return `
                        <div class="metric-card" style="background: ${bgColor}">
                            <div class="metric-label">${disk.mountpoint}</div>
                            <div class="metric-value">${disk.percent}%</div>
                            <div class="metric-label">${disk.used_gb} GB / ${disk.total_gb} GB</div>
                        </div>
                    `;
                }).join('');
                document.getElementById('diskMetrics').innerHTML = metricsHtml;
            }

            function updateNetworkStats(networkTraffic) {
                // Mostrar en la unidad más apropiada
                let sentSpeed, recvSpeed;
                if (networkTraffic.bytes_sent_kb > 1024) {
                    sentSpeed = `${(networkTraffic.bytes_sent_kb / 1024).toFixed(2)} MB/s`;
                } else {
                    sentSpeed = `${networkTraffic.bytes_sent_kb.toFixed(2)} KB/s`;
                }
                
                if (networkTraffic.bytes_recv_kb > 1024) {
                    recvSpeed = `${(networkTraffic.bytes_recv_kb / 1024).toFixed(2)} MB/s`;
                } else {
                    recvSpeed = `${networkTraffic.bytes_recv_kb.toFixed(2)} KB/s`;
                }
                
                const statsHtml = `
                    <div class="network-stat-card">
                        <div class="stat-label">📤 Subida Actual</div>
                        <div class="stat-value">${sentSpeed}</div>
                        <div class="stat-label">${formatBytes(networkTraffic.total_bytes_sent)} total</div>
                    </div>
                    <div class="network-stat-card">
                        <div class="stat-label">📥 Descarga Actual</div>
                        <div class="stat-value">${recvSpeed}</div>
                        <div class="stat-label">${formatBytes(networkTraffic.total_bytes_recv)} total</div>
                    </div>
                `;
                document.getElementById('networkStats').innerHTML = statsHtml;
            }

            function updateMetrics(data) {
                // Métricas generales ya están incluidas en otras funciones
            }

            // Cargar datos cada 2 segundos
            loadData();
            setInterval(loadData, 2000);

            // Mostrar mensaje de conexión
            console.log('🔄 Dashboard conectado - Actualizando cada 2 segundos');
        </script>
    </body>
    </html>
    '''

@app.route('/api/system-data')
def system_data():
    with data_lock:
        return jsonify(system_data)

if __name__ == '__main__':
    # Iniciar recolección de datos en segundo plano
    data_thread = threading.Thread(target=collect_system_data, daemon=True)
    data_thread.start()
    
    print("🚀 Servidor de monitoreo simplificado iniciado!")
    print("📊 Dashboard disponible en: http://localhost:5000")
    print("🗂️ Mostrando solo particiones > 20 GB")
    print("🌐 Estadísticas de red sin gráfico")
    print("🔄 Actualización automática cada 2 segundos")
    print("⏹️  Presiona Ctrl+C para detener el servidor")
    
    app.run(host='0.0.0.0', port=5000, debug=False)
EOF

    echo -e "${GREEN}✅ Aplicación Flask simplificada creada: $FLASK_APP${NC}"
}

# Función para iniciar el servidor
start_monitoring_server() {
    echo -e "${YELLOW}🌐 Iniciando servidor web de monitoreo...${NC}"
    echo -e "${CYAN}📍 El navegador se abrirá automáticamente en: http://localhost:5000${NC}"
    
    # Iniciar el servidor Flask en background
    python3 "$FLASK_APP" &
    FLASK_PID=$!
    
    # Esperar un momento y abrir el navegador
    open_browser
    
    # Esperar a que el proceso de Flask termine
    wait $FLASK_PID
}

# Función principal
main() {
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${CYAN}   SISTEMA DE MONITOREO SIMPLIFICADO    ${NC}"
    echo -e "${CYAN}=========================================${NC}"
    
    # Verificar dependencias
    check_dependencies
    
    # Crear aplicación Flask
    create_flask_app
    
    # Información del sistema
    echo -e "\n${BLUE}📊 Información del sistema:${NC}"
    echo "Hostname: $(hostname)"
    echo "Fecha: $(date)"
    echo "Uptime: $(uptime -p)"
    echo -e "${GREEN}✅ Filtro activado: solo particiones > 20 GB${NC}"
    echo -e "${GREEN}✅ Dashboard simplificado sin gráfico de red${NC}"
    
    # Iniciar servidor de monitoreo
    start_monitoring_server
}

# Manejar señal de interrupción
cleanup() {
    echo -e "\n${YELLOW}🛑 Deteniendo servidor de monitoreo...${NC}"
    if [ -f "$FLASK_APP" ]; then
        rm -f "$FLASK_APP"
    fi
    # Matar el proceso de Flask si todavía está corriendo
    if [ ! -z "$FLASK_PID" ]; then
        kill $FLASK_PID 2>/dev/null
    fi
    echo -e "${GREEN}✅ Limpieza completada${NC}"
    exit 0
}

trap cleanup SIGINT SIGTERM

# Ejecutar función principal
main
