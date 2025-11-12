#!/bin/bash

# Script bash para crear dashboard web con información del sistema
DASHBOARD_SCRIPT="/tmp/network_dashboard.py"
PID_FILE="/tmp/network_dashboard.pid"

# Crear el script de Flask
cat > $DASHBOARD_SCRIPT << 'EOF'
#!/usr/bin/env python3
from flask import Flask, render_template, jsonify
import os
import time
import threading
from datetime import datetime

app = Flask(__name__)

def read_file_safe(filepath):
    """Leer archivo de forma segura"""
    try:
        if os.path.exists(filepath):
            with open(filepath, 'r') as f:
                return f.read().strip()
        else:
            return f"Archivo no encontrado: {filepath}"
    except Exception as e:
        return f"Error leyendo archivo: {str(e)}"

def read_directory_safe(dirpath):
    """Leer contenido de directorio de forma segura"""
    try:
        if os.path.exists(dirpath) and os.path.isdir(dirpath):
            files = os.listdir(dirpath)
            return "\n".join(files) if files else "Directorio vacío"
        else:
            return f"Directorio no encontrado: {dirpath}"
    except Exception as e:
        return f"Error leyendo directorio: {str(e)}"

def get_system_info():
    """Obtener información del sistema"""
    info = {}
    
    # Información de nsswitch.conf
    info['nsswitch'] = read_file_safe('/etc/nsswitch.conf')
    
    # Información del hostname
    info['hostname'] = read_file_safe('/etc/hostname')
    
    # Información de network (Red Hat/CentOS)
    info['network'] = read_file_safe('/etc/sysconfig/network')
    
    # Información de network-scripts
    info['network_scripts'] = read_directory_safe('/etc/sysconfig/network-scripts')
    
    # Información de resolv.conf
    info['resolv'] = read_file_safe('/etc/resolv.conf')
    
    # Información adicional del sistema
    info['timestamp'] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    return info

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/data')
def get_data():
    return jsonify(get_system_info())

@app.route('/api/update')
def update_data():
    return jsonify(get_system_info())

if __name__ == '__main__':
    # Crear directorio de templates si no existe
    template_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'templates')
    if not os.path.exists(template_dir):
        os.makedirs(template_dir)
    
    # Crear template HTML
    template_path = os.path.join(template_dir, 'index.html')
    
    with open(template_path, 'w') as f:
        f.write('''
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard de Red - Sistema</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .cards {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .card {
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .card h3 {
            margin-top: 0;
            color: #333;
            border-bottom: 2px solid #007bff;
            padding-bottom: 10px;
        }
        .card-content {
            max-height: 300px;
            overflow-y: auto;
            font-family: monospace;
            white-space: pre-wrap;
            background: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            font-size: 12px;
        }
        .status-bar {
            background: white;
            padding: 15px;
            border-radius: 10px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            margin-bottom: 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .last-update {
            color: #666;
            font-size: 14px;
        }
        .refresh-btn {
            background: #007bff;
            color: white;
            border: none;
            padding: 8px 16px;
            border-radius: 5px;
            cursor: pointer;
        }
        .refresh-btn:hover {
            background: #0056b3;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🖥️ Dashboard de Configuración de Red</h1>
            <p>Información en tiempo real del sistema</p>
        </div>
        
        <div class="status-bar">
            <div class="last-update" id="lastUpdate">
                Última actualización: <span id="timestamp">Cargando...</span>
            </div>
            <button class="refresh-btn" onclick="location.reload()">🔄 Actualizar</button>
        </div>

        <div class="cards">
            <div class="card">
                <h3>📁 /etc/nsswitch.conf</h3>
                <div class="card-content" id="nsswitch-content">Cargando...</div>
            </div>
            
            <div class="card">
                <h3>🖥️ /etc/hostname</h3>
                <div class="card-content" id="hostname-content">Cargando...</div>
            </div>
            
            <div class="card">
                <h3>🌐 /etc/sysconfig/network</h3>
                <div class="card-content" id="network-content">Cargando...</div>
            </div>
            
            <div class="card">
                <h3>📂 /etc/sysconfig/network-scripts</h3>
                <div class="card-content" id="network-scripts-content">Cargando...</div>
            </div>
            
            <div class="card">
                <h3>🔍 /etc/resolv.conf</h3>
                <div class="card-content" id="resolv-content">Cargando...</div>
            </div>
        </div>
    </div>

    <script>
        function updateDashboard() {
            fetch('/api/data')
                .then(response => response.json())
                .then(data => {
                    // Actualizar contenido de las tarjetas
                    document.getElementById('nsswitch-content').textContent = data.nsswitch;
                    document.getElementById('hostname-content').textContent = data.hostname;
                    document.getElementById('network-content').textContent = data.network;
                    document.getElementById('network-scripts-content').textContent = data.network_scripts;
                    document.getElementById('resolv-content').textContent = data.resolv;
                    document.getElementById('timestamp').textContent = data.timestamp;
                })
                .catch(error => {
                    console.error('Error:', error);
                    document.getElementById('timestamp').textContent = 'Error al cargar datos';
                });
        }

        // Actualizar al cargar la página
        document.addEventListener('DOMContentLoaded', function() {
            updateDashboard();
            
            // Actualizar automáticamente cada 5 segundos
            setInterval(updateDashboard, 5000);
        });
    </script>
</body>
</html>
        ''')
    
    print("🚀 Iniciando servidor Flask...")
    print("📊 Dashboard disponible en: http://localhost:5000")
    print("⏹️  Para detener el servidor, presiona Ctrl+C")
    
    app.run(debug=True, host='0.0.0.0', port=5000)
EOF

# Hacer el script ejecutable
chmod +x $DASHBOARD_SCRIPT

# Verificar dependencias
echo "🔍 Verificando dependencias..."

if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 no está instalado. Por favor instálalo primero."
    exit 1
fi

if ! python3 -c "import flask" 2>/dev/null; then
    echo "📦 Instalando Flask..."
    pip3 install flask
fi

# Función para limpiar al salir
cleanup() {
    echo -e "\n🛑 Deteniendo servidor..."
    if [ -f $PID_FILE ]; then
        kill $(cat $PID_FILE) 2>/dev/null
        rm -f $PID_FILE
    fi
    exit 0
}

trap cleanup SIGINT SIGTERM

# Iniciar el servidor Flask en segundo plano
echo "🚀 Iniciando dashboard..."
python3 $DASHBOARD_SCRIPT &
FLASK_PID=$!
echo $FLASK_PID > $PID_FILE

# Esperar a que el servidor esté listo
sleep 3

# Abrir el navegador por defecto
echo "🌐 Abriendo navegador..."
if command -v xdg-open &> /dev/null; then
    xdg-open "http://localhost:5000"
elif command -v open &> /dev/null; then
    open "http://localhost:5000"
elif command -v start &> /dev/null; then
    start "http://localhost:5000"
else
    echo "⚠️  No se pudo abrir el navegador automáticamente."
    echo "📋 Por favor abre manualmente: http://localhost:5000"
fi

echo ""
echo "✅ Dashboard ejecutándose..."
echo "📋 URL: http://localhost:5000"
echo "⏹️  Presiona Ctrl+C para detener el servidor"

# Esperar a que el proceso termine
wait $FLASK_PID
