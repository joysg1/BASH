#!/bin/bash

# history_dashboard.sh
# Dashboard web simple para monitoreo de comandos del history usando Flask

# Configuración
PORT=5000
DASHBOARD_DIR="/tmp/history_dashboard_$$"

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Crear script Python con Flask
create_flask_app() {
    cat > "$DASHBOARD_DIR/app.py" << 'FLASK_EOF'
#!/usr/bin/env python3
from flask import Flask, render_template, jsonify, request
import os
from collections import Counter, defaultdict
from datetime import datetime, timedelta
import subprocess

app = Flask(__name__)

def get_history_commands():
    """Obtener comandos del history"""
    commands = []
    try:
        # Intentar obtener history del usuario actual
        history_file = os.path.expanduser('~/.bash_history')
        if os.path.exists(history_file):
            with open(history_file, 'r', encoding='utf-8', errors='ignore') as f:
                commands = [line.strip() for line in f if line.strip()]
        
        # Si no hay comandos, generar algunos de ejemplo
        if not commands:
            commands = [
                "ls -la", "cd /home", "pwd", "git status", "python3 --version",
                "sudo apt update", "curl -I google.com", "docker ps", "find . -name '*.py'",
                "grep -r pattern .", "ssh user@server", "ping google.com", "netstat -tulpn",
                "mkdir proyecto", "cp archivo.txt backup/", "mv antiguo nuevo", "rm temporal.txt",
                "chmod 755 script.sh", "chown usuario:grupo archivo", "tar -czf backup.tar.gz directorio",
                "systemctl status nginx", "journalctl -xe", "top", "htop", "ps aux", "kill 1234",
                "git add .", "git commit -m 'update'", "git push origin main", "git pull",
                "docker build -t mi-app .", "docker-compose up", "kubectl get pods",
                "npm install", "node server.js", "python3 manage.py runserver",
                "ssh-keygen -t rsa", "scp archivo user@server:/path", "rsync -av source/ dest/",
                "wget https://example.com/file", "curl -O https://example.com/file",
                "ping -c 4 google.com", "traceroute google.com", "nmap -sP 192.168.1.0/24"
            ]
            
    except Exception as e:
        print(f"Error reading history: {e}")
        commands = ["ls", "cd", "pwd", "git status", "python3"]
    
    return commands

def categorize_command(command):
    """Categorizar comando"""
    categories = {
        'sistema': ['sudo', 'apt', 'yum', 'systemctl', 'service', 'ps', 'top', 'kill', 'journalctl', 'chmod', 'chown'],
        'archivos': ['ls', 'cd', 'cp', 'mv', 'rm', 'mkdir', 'find', 'grep', 'cat', 'tar', 'rsync'],
        'red': ['ssh', 'scp', 'ping', 'curl', 'wget', 'netstat', 'ifconfig', 'traceroute', 'nmap'],
        'git': ['git', 'commit', 'push', 'pull', 'clone', 'add', 'status'],
        'desarrollo': ['python', 'python3', 'node', 'npm', 'docker', 'kubectl'],
        'otros': []
    }
    
    command_lower = command.lower()
    for category, keywords in categories.items():
        if category == 'otros':
            continue
        for keyword in keywords:
            if keyword in command_lower.split():
                return category
    return 'otros'

@app.route('/')
def dashboard():
    return """
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard History</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: Arial, sans-serif; 
            background: #f0f2f5;
            padding: 20px;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            border-radius: 10px;
            margin-bottom: 20px;
            text-align: center;
        }
        .search-section {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            margin-bottom: 20px;
        }
        .search-box {
            display: flex;
            gap: 10px;
            align-items: center;
        }
        .search-input {
            flex: 1;
            padding: 12px;
            border: 2px solid #ddd;
            border-radius: 6px;
            font-size: 16px;
        }
        .search-input:focus {
            outline: none;
            border-color: #667eea;
        }
        .search-button {
            background: #667eea;
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 6px;
            cursor: pointer;
            font-size: 16px;
        }
        .search-button:hover {
            background: #5a6fd8;
        }
        .search-results {
            margin-top: 15px;
            display: none;
        }
        .search-stats {
            color: #666;
            margin-bottom: 10px;
        }
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-bottom: 20px;
        }
        .stat-card {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            text-align: center;
        }
        .stat-number {
            font-size: 2em;
            font-weight: bold;
            color: #667eea;
        }
        .charts-container {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin-bottom: 20px;
        }
        .chart-card {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .chart-container {
            height: 300px;
        }
        .commands-section {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .command-item {
            padding: 12px;
            border-bottom: 1px solid #eee;
            font-family: 'Courier New', monospace;
            display: flex;
            align-items: center;
            transition: background-color 0.2s;
        }
        .command-item:hover {
            background-color: #f8f9fa;
        }
        .command-item:last-child {
            border-bottom: none;
        }
        .category-badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 15px;
            font-size: 0.8em;
            margin-right: 15px;
            color: white;
            font-weight: bold;
            min-width: 80px;
            text-align: center;
        }
        .command-text {
            flex: 1;
            word-break: break-all;
        }
        .controls {
            margin-bottom: 20px;
            text-align: center;
        }
        button {
            background: #667eea;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 5px;
            cursor: pointer;
            margin: 0 5px;
        }
        button:hover {
            background: #5a6fd8;
        }
        .highlight {
            background-color: #fff3cd;
            padding: 2px 4px;
            border-radius: 3px;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📊 Dashboard de Comandos History</h1>
            <p>Análisis en tiempo real de los comandos ejecutados</p>
        </div>
        
        <div class="search-section">
            <div class="search-box">
                <input type="text" id="searchInput" class="search-input" 
                       placeholder="🔍 Buscar comandos (ej: git, docker, ssh...)">
                <button class="search-button" onclick="searchCommands()">Buscar</button>
            </div>
            <div class="search-results" id="searchResults">
                <div class="search-stats" id="searchStats"></div>
                <div id="searchCommandsList"></div>
            </div>
        </div>
        
        <div class="controls">
            <button onclick="loadData()">🔄 Actualizar Datos</button>
            <button onclick="clearSearch()">🗑️ Limpiar Búsqueda</button>
            <button onclick="location.reload()">🔄 Recargar Página</button>
        </div>
        
        <div class="stats-grid" id="statsGrid">
            <div class="stat-card">
                <h3>Total Comandos</h3>
                <div class="stat-number" id="totalCommands">0</div>
            </div>
        </div>
        
        <div class="charts-container">
            <div class="chart-card">
                <h3>Comandos por Categoría</h3>
                <div class="chart-container">
                    <canvas id="categoryChart"></canvas>
                </div>
            </div>
            <div class="chart-card">
                <h3>Top Comandos</h3>
                <div class="chart-container">
                    <canvas id="topCommandsChart"></canvas>
                </div>
            </div>
        </div>
        
        <div class="commands-section">
            <h3>Lista de Comandos Recientes</h3>
            <div id="commandsList">
                <div class="command-item">Cargando comandos...</div>
            </div>
        </div>
    </div>

    <script>
        let categoryChart, topCommandsChart;
        let allCommands = [];
        const categoryColors = {
            'sistema': '#e74c3c',
            'archivos': '#3498db', 
            'red': '#9b59b6',
            'git': '#2ecc71',
            'desarrollo': '#f39c12',
            'otros': '#95a5a6'
        };

        // Función para buscar comandos
        function searchCommands() {
            const searchTerm = document.getElementById('searchInput').value.toLowerCase().trim();
            const resultsContainer = document.getElementById('searchResults');
            const statsElement = document.getElementById('searchStats');
            const commandsListElement = document.getElementById('searchCommandsList');
            
            if (!searchTerm) {
                resultsContainer.style.display = 'none';
                return;
            }
            
            // Filtrar comandos que coincidan con la búsqueda
            const filteredCommands = allCommands.filter(cmd => 
                cmd.command.toLowerCase().includes(searchTerm)
            );
            
            if (filteredCommands.length === 0) {
                statsElement.innerHTML = `No se encontraron comandos que coincidan con "<strong>${searchTerm}</strong>"`;
                commandsListElement.innerHTML = '';
            } else {
                statsElement.innerHTML = `Se encontraron <strong>${filteredCommands.length}</strong> comandos que coinciden con "<strong>${searchTerm}</strong>"`;
                
                // Mostrar comandos filtrados con resaltado
                commandsListElement.innerHTML = filteredCommands.map(cmd => {
                    const highlightedCommand = highlightText(cmd.command, searchTerm);
                    return `
                        <div class="command-item">
                            <span class="category-badge" style="background: ${categoryColors[cmd.category]}">
                                ${cmd.category.toUpperCase()}
                            </span>
                            <div class="command-text">${highlightedCommand}</div>
                        </div>
                    `;
                }).join('');
            }
            
            resultsContainer.style.display = 'block';
        }

        // Función para resaltar texto en los resultados
        function highlightText(text, searchTerm) {
            const regex = new RegExp(`(${searchTerm})`, 'gi');
            return text.replace(regex, '<span class="highlight">$1</span>');
        }

        // Función para limpiar búsqueda
        function clearSearch() {
            document.getElementById('searchInput').value = '';
            document.getElementById('searchResults').style.display = 'none';
            // Mostrar todos los comandos nuevamente
            updateCommandsList(allCommands.slice(-20));
        }

        // Permitir búsqueda con Enter
        document.getElementById('searchInput').addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                searchCommands();
            }
        });

        async function loadData() {
            try {
                const response = await fetch('/api/data');
                const data = await response.json();
                allCommands = data.all_commands || [];
                updateDashboard(data);
            } catch (error) {
                console.error('Error loading data:', error);
            }
        }

        function updateDashboard(data) {
            // Actualizar estadísticas
            document.getElementById('totalCommands').textContent = data.total_commands;
            
            // Actualizar grid de estadísticas
            const statsGrid = document.getElementById('statsGrid');
            statsGrid.innerHTML = `
                <div class="stat-card">
                    <h3>Total Comandos</h3>
                    <div class="stat-number">${data.total_commands}</div>
                </div>
                ${Object.entries(data.category_counts).map(([category, count]) => `
                    <div class="stat-card">
                        <h3>${category.charAt(0).toUpperCase() + category.slice(1)}</h3>
                        <div class="stat-number" style="color: ${categoryColors[category]}">${count}</div>
                    </div>
                `).join('')}
            `;

            // Actualizar gráfico de categorías
            updateCategoryChart(data.category_counts);
            
            // Actualizar gráfico de top comandos
            updateTopCommandsChart(data.top_commands);
            
            // Actualizar lista de comandos
            updateCommandsList(data.recent_commands);
        }

        function updateCategoryChart(categoryCounts) {
            const ctx = document.getElementById('categoryChart').getContext('2d');
            
            if (categoryChart) {
                categoryChart.destroy();
            }
            
            categoryChart = new Chart(ctx, {
                type: 'doughnut',
                data: {
                    labels: Object.keys(categoryCounts).map(cat => cat.charAt(0).toUpperCase() + cat.slice(1)),
                    datasets: [{
                        data: Object.values(categoryCounts),
                        backgroundColor: Object.keys(categoryCounts).map(cat => categoryColors[cat]),
                        borderWidth: 2
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            position: 'bottom'
                        }
                    }
                }
            });
        }

        function updateTopCommandsChart(topCommands) {
            const ctx = document.getElementById('topCommandsChart').getContext('2d');
            
            if (topCommandsChart) {
                topCommandsChart.destroy();
            }
            
            const commands = Object.keys(topCommands).slice(0, 10);
            const counts = Object.values(topCommands).slice(0, 10);
            
            topCommandsChart = new Chart(ctx, {
                type: 'bar',
                data: {
                    labels: commands,
                    datasets: [{
                        label: 'Veces ejecutado',
                        data: counts,
                        backgroundColor: '#667eea',
                        borderWidth: 1
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: {
                        y: {
                            beginAtZero: true
                        }
                    },
                    plugins: {
                        legend: {
                            display: false
                        }
                    }
                }
            });
        }

        function updateCommandsList(commands) {
            const container = document.getElementById('commandsList');
            container.innerHTML = commands.map(cmd => {
                return `
                    <div class="command-item">
                        <span class="category-badge" style="background: ${categoryColors[cmd.category]}">
                            ${cmd.category.toUpperCase()}
                        </span>
                        <div class="command-text">${cmd.command}</div>
                    </div>
                `;
            }).join('');
        }

        // Cargar datos al iniciar
        document.addEventListener('DOMContentLoaded', loadData);
    </script>
</body>
</html>
"""
FLASK_EOF

    # Crear la segunda parte del script Python (API)
    cat >> "$DASHBOARD_DIR/app.py" << 'API_EOF'

@app.route('/api/data')
def api_data():
    commands = get_history_commands()
    
    # Categorizar comandos
    categorized_commands = []
    for cmd in commands:
        category = categorize_command(cmd)
        categorized_commands.append({
            'command': cmd,
            'category': category
        })
    
    # Estadísticas por categoría
    category_counts = defaultdict(int)
    for cmd in categorized_commands:
        category_counts[cmd['category']] += 1
    
    # Comandos más populares
    command_counter = Counter(commands)
    top_commands = dict(command_counter.most_common(10))
    
    # Comandos recientes (últimos 20)
    recent_commands = categorized_commands[-20:]
    
    return jsonify({
        'total_commands': len(commands),
        'category_counts': dict(category_counts),
        'top_commands': top_commands,
        'recent_commands': recent_commands,
        'all_commands': categorized_commands
    })

if __name__ == '__main__':
    print(f"🚀 Iniciando servidor Flask en http://localhost:5000")
    print("📊 Dashboard disponible en el navegador")
    print("🔍 Función de búsqueda incluida")
    print("⏹️  Presiona Ctrl+C para detener el servidor")
    app.run(host='0.0.0.0', port=5000, debug=False)
API_EOF

    print_status "Aplicación Flask creada con función de búsqueda"
}

# Verificar e instalar Flask si es necesario
check_flask() {
    if ! python3 -c "import flask" 2>/dev/null; then
        print_status "Instalando Flask..."
        pip3 install flask > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            print_status "Flask instalado correctamente"
        else
            print_error "Error instalando Flask. Instálalo manualmente: pip3 install flask"
            exit 1
        fi
    else
        print_status "Flask ya está instalado"
    fi
}

# Abrir navegador
open_browser() {
    local url="http://localhost:$PORT"
    print_status "Abriendo navegador en: $url"
    
    sleep 2  # Esperar a que Flask se inicie
    
    # Intentar diferentes métodos para abrir el navegador
    if command -v xdg-open > /dev/null; then
        xdg-open "$url" &
    elif command -v open > /dev/null; then
        open "$url" &
    elif command -v firefox > /dev/null; then
        firefox "$url" &
    elif command -v google-chrome > /dev/null; then
        google-chrome "$url" &
    elif command -v chromium-browser > /dev/null; then
        chromium-browser "$url" &
    else
        print_status "Abre manualmente: $url"
    fi
}

# Limpieza
cleanup() {
    print_status "Deteniendo servidor y limpiando..."
    rm -rf "$DASHBOARD_DIR"
}

# Configurar trap para limpieza
trap cleanup EXIT INT TERM

# Función principal
main() {
    echo "==========================================="
    echo "   🚀 Dashboard History - Flask Version"
    echo "==========================================="
    echo ""
    
    # Crear directorio temporal
    mkdir -p "$DASHBOARD_DIR"
    
    # Verificar Flask
    check_flask
    
    # Crear aplicación Flask
    create_flask_app
    
    # Navegar al directorio y ejecutar
    cd "$DASHBOARD_DIR"
    
    print_status "Iniciando servidor Flask en puerto $PORT..."
    
    # Ejecutar Flask en background y abrir navegador
    python3 app.py &
    FLASK_PID=$!
    
    # Abrir navegador después de un breve retraso
    open_browser
    
    echo ""
    print_status "Dashboard ejecutándose..."
    echo "📍 URL: http://localhost:$PORT"
    echo "🔍 Busca comandos usando el cuadro de búsqueda"
    echo "⏹️  Presiona Ctrl+C para salir"
    echo ""
    
    # Esperar a que el usuario presione Ctrl+C
    wait $FLASK_PID
}

# Ejecutar
main "$@"
