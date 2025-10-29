#!/bin/bash

# Función para mostrar ayuda
show_help() {
    echo "Uso: $0 [OPCIONES]"
    echo ""
    echo "OPCIONES:"
    echo "  --break           Detener el escaneo después de encontrar vulnerabilidades"
    echo "  --break-system-packages  Usar flag --break-system-packages con pip"
    echo "  --fast            Modo rápido (menos pruebas, más velocidad)"
    echo "  --timeout <seg>   Timeout por request (default: 10)"
    echo "  -p, --ports       Puertos a escanear (default: 80,443)"
    echo "  -t, --target      URL objetivo"
    echo "  -h, --help        Mostrar esta ayuda"
    echo ""
    echo "EJEMPLOS RÁPIDOS:"
    echo "  $0 -t google.com --fast"
    echo "  $0 -t ejemplo.com --fast --timeout 5"
    echo "  $0 -t ejemplo.com --break --fast"
    echo ""
}

# Variables por defecto
TARGET=""
PORTS="80,443"
BREAK_MODE=false
BREAK_SYSTEM_PACKAGES=false
FAST_MODE=false
TIMEOUT=10
NIKTO_OUTPUT="nikto_scan_$(date +%Y%m%d_%H%M%S).xml"
IS_FULL_URL=false
TARGET_HOST=""

# Procesar parámetros
while [[ $# -gt 0 ]]; do
    case $1 in
        --break)
            BREAK_MODE=true
            shift
            ;;
        --break-system-packages)
            BREAK_SYSTEM_PACKAGES=true
            shift
            ;;
        --fast)
            FAST_MODE=true
            shift
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        -p|--ports)
            PORTS="$2"
            shift 2
            ;;
        -t|--target)
            TARGET="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Parámetro desconocido: $1"
            show_help
            exit 1
            ;;
    esac
done

# Función para mostrar estimación de tiempo
show_time_estimate() {
    echo "⏱️  Estimación de tiempo:"
    if [ "$FAST_MODE" = true ]; then
        echo "   - Modo RÁPIDO: 2-5 minutos"
        echo "   - Pruebas: Solo vulnerabilidades críticas"
    else
        echo "   - Modo COMPLETO: 10-30 minutos"
        echo "   - Pruebas: Todas las vulnerabilidades"
    fi
    if [ "$BREAK_MODE" = true ]; then
        echo "   - Modo BREAK: Se detendrá al encontrar problemas"
    fi
    echo ""
}

# Función para verificar dependencias
check_dependencies() {
    echo "Verificando dependencias..."
    
    # Verificar Nikto
    if ! command -v nikto &> /dev/null; then
        echo "Error: Nikto no está instalado"
        echo "Instala Nikto con: sudo apt install nikto"
        exit 1
    fi
    
    # Verificar Python
    if ! command -v python3 &> /dev/null; then
        echo "Error: Python3 no está instalado"
        exit 1
    fi
    
    # Verificar e instalar dependencias Python
    local pip_cmd="pip3 install"
    if [ "$BREAK_SYSTEM_PACKAGES" = true ]; then
        pip_cmd="pip3 install --break-system-packages"
    fi
    
    if ! python3 -c "import flask" 2>/dev/null; then
        echo "Instalando Flask..."
        eval "$pip_cmd flask -q"
    fi
    
    if ! python3 -c "import jinja2" 2>/dev/null; then
        echo "Instalando Jinja2..."
        eval "$pip_cmd jinja2 -q"
    fi
    
    echo "✓ Dependencias listas"
}

# Función para procesar target
process_target() {
    if [ -z "$TARGET" ]; then
        echo "Ingresa la URL o IP objetivo:"
        read -p "Target: " TARGET
        
        if [ -z "$TARGET" ]; then
            echo "Error: Debes especificar un target"
            exit 1
        fi
    fi
    
    if [[ $TARGET =~ ^https?:// ]]; then
        IS_FULL_URL=true
        TARGET_HOST=$(echo "$TARGET" | sed -E 's|^https?://||' | sed 's|/.*||')
    else
        IS_FULL_URL=false
        TARGET_HOST="$TARGET"
    fi
}

# Función para construir comando Nikto optimizado
build_nikto_command() {
    local nikto_cmd="nikto"
    
    if [ "$IS_FULL_URL" = true ]; then
        nikto_cmd="$nikto_cmd -h $TARGET"
    else
        nikto_cmd="$nikto_cmd -h $TARGET_HOST -p $PORTS"
    fi
    
    # Opciones comunes
    nikto_cmd="$nikto_cmd -Format xml -output $NIKTO_OUTPUT -timeout $TIMEOUT"
    
    # Modo rápido - menos pruebas
    if [ "$FAST_MODE" = true ]; then
        nikto_cmd="$nikto_cmd -Tuning 1238"
        echo "🚀 Modo RÁPIDO activado"
    else
        nikto_cmd="$nikto_cmd -Tuning 1234890abc"
        echo "🔍 Modo COMPLETO activado"
    fi
    
    # Modo break
    if [ "$BREAK_MODE" = true ]; then
        nikto_cmd="$nikto_cmd -pause 1"
        echo "⏹️  Modo BREAK activado"
    fi
    
    # Opciones de optimización
    nikto_cmd="$nikto_cmd -no404"
    
    echo "$nikto_cmd"
}

# Función simple para mostrar progreso
show_progress() {
    local pid=$1
    local delay=0.75
    local spinstr='|/-\'
    
    echo -n "⏳ Escaneando... "
    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
    echo -e "\r✅ Escaneo completado"
}

# Función para ejecutar Nikto con progreso
run_nikto() {
    local nikto_cmd=$(build_nikto_command)
    
    echo "Iniciando escaneo Nikto..."
    echo "Target: $TARGET"
    echo "Comando: $nikto_cmd"
    echo ""
    
    # Mostrar progreso aproximado
    echo "⏳ Escaneando... (Esto puede tomar varios minutos)"
    echo "   Puedes abrir otra terminal mientras tanto"
    echo ""
    
    # Ejecutar Nikto en segundo plano
    eval "$nikto_cmd" &
    local nikto_pid=$!
    
    # Mostrar progreso simple
    show_progress $nikto_pid
    
    wait $nikto_pid
    local exit_code=$?
    
    return $exit_code
}

# Función para generar reporte web
generate_web_report() {
    echo "Generando reporte web..."
    
    # Crear script Python para el servidor web
    cat > "nikto_web_report.py" << 'EOF'
#!/usr/bin/env python3
from flask import Flask, render_template_string
import xml.etree.ElementTree as ET
import datetime
import os
import sys

app = Flask(__name__)

HTML_TEMPLATE = '''
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reporte Nikto - {{ target }}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { background: #2c3e50; color: white; padding: 20px; border-radius: 5px; margin-bottom: 20px; }
        .vulnerability { border: 1px solid #ddd; margin: 10px 0; padding: 15px; border-radius: 5px; background: #fafafa; }
        .high { border-left: 5px solid #e74c3c; background: #ffeaea; }
        .medium { border-left: 5px solid #f39c12; background: #fff4e6; }
        .low { border-left: 5px solid #3498db; background: #eaf2f8; }
        .info { border-left: 5px solid #27ae60; background: #eafaf1; }
        .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin: 20px 0; }
        .stat-card { background: #34495e; color: white; padding: 15px; border-radius: 5px; text-align: center; }
        .risk-level { padding: 3px 8px; border-radius: 3px; font-weight: bold; font-size: 0.8em; }
        .risk-high { background: #e74c3c; color: white; }
        .risk-medium { background: #f39c12; color: white; }
        .risk-low { background: #3498db; color: white; }
        .risk-info { background: #27ae60; color: white; }
        .fast-mode { background: #9b59b6; color: white; padding: 10px; border-radius: 5px; margin: 10px 0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔍 Reporte de Escaneo Nikto</h1>
            <p><strong>Target:</strong> {{ target }}</p>
            <p><strong>Fecha:</strong> {{ scan_date }}</p>
            <p><strong>Total de hallazgos:</strong> {{ findings_count }}</p>
            {% if break_mode %}
            <div class="fast-mode"><strong>🔴 Modo BREAK activado</strong> - Escaneo detenido tras encontrar vulnerabilidades</div>
            {% endif %}
            {% if fast_mode %}
            <div class="fast-mode"><strong>🚀 Modo RÁPIDO activado</strong> - Escaneo optimizado para velocidad</div>
            {% endif %}
        </div>

        {% if error %}
        <div class="vulnerability high">
            <h3>❌ Error</h3>
            <p>{{ error }}</p>
        </div>
        {% else %}
        <div class="stats">
            <div class="stat-card">
                <h3>Alto</h3>
                <p style="font-size: 2em;">{{ stats.high }}</p>
            </div>
            <div class="stat-card">
                <h3>Medio</h3>
                <p style="font-size: 2em;">{{ stats.medium }}</p>
            </div>
            <div class="stat-card">
                <h3>Bajo</h3>
                <p style="font-size: 2em;">{{ stats.low }}</p>
            </div>
            <div class="stat-card">
                <h3>Información</h3>
                <p style="font-size: 2em;">{{ stats.info }}</p>
            </div>
        </div>

        <h2>Hallazgos Detallados</h2>
        {% if findings %}
            {% for finding in findings %}
            <div class="vulnerability {{ finding.risk_class }}">
                <h3>
                    <span class="risk-level {{ finding.risk_level_class }}">{{ finding.risk_level }}</span>
                    {{ finding.description }}
                </h3>
                <p><strong>URL:</strong> {{ finding.uri }}</p>
                <p><strong>Método:</strong> {{ finding.method }}</p>
                {% if finding.proof %}
                <p><strong>Prueba:</strong> <code>{{ finding.proof }}</code></p>
                {% endif %}
            </div>
            {% endfor %}
        {% else %}
            <div class="vulnerability info">
                <h3>✅ No se encontraron vulnerabilidades</h3>
                <p>El escaneo no detectó problemas de seguridad significativos.</p>
            </div>
        {% endif %}
        {% endif %}
    </div>
</body>
</html>
'''

def parse_nikto_xml(xml_file):
    try:
        tree = ET.parse(xml_file)
        root = tree.getroot()
        findings = []
        stats = {'high': 0, 'medium': 0, 'low': 0, 'info': 0}
        
        scan_info = root.find('scandetails')
        target = scan_info.get('targetip') if scan_info is not None else "Unknown"
        
        for item in root.findall('.//item'):
            description_elem = item.find('description')
            uri_elem = item.find('uri')
            
            finding = {
                'description': description_elem.text if description_elem is not None else "Sin descripción",
                'uri': uri_elem.text if uri_elem is not None else "N/A",
                'method': item.get('method', 'GET'),
                'proof': None
            }
            
            desc_lower = finding['description'].lower()
            if any(word in desc_lower for word in ['critical', 'high', 'vulnerability', 'exploit', 'attack', 'sql injection', 'xss']):
                finding['risk_level'] = 'ALTO'
                finding['risk_level_class'] = 'risk-high'
                finding['risk_class'] = 'high'
                stats['high'] += 1
            elif any(word in desc_lower for word in ['warning', 'medium', 'issue', 'problem', 'caution']):
                finding['risk_level'] = 'MEDIO'
                finding['risk_level_class'] = 'risk-medium'
                finding['risk_class'] = 'medium'
                stats['medium'] += 1
            elif any(word in desc_lower for word in ['low', 'minor']):
                finding['risk_level'] = 'BAJO'
                finding['risk_level_class'] = 'risk-low'
                finding['risk_class'] = 'low'
                stats['low'] += 1
            else:
                finding['risk_level'] = 'INFORMACIÓN'
                finding['risk_level_class'] = 'risk-info'
                finding['risk_class'] = 'info'
                stats['info'] += 1
            
            findings.append(finding)
        
        return target, findings, stats, None
    except Exception as e:
        return None, [], {'high': 0, 'medium': 0, 'low': 0, 'info': 0}, f"Error: {str(e)}"

@app.route('/')
def index():
    xml_file = sys.argv[1] if len(sys.argv) > 1 else 'nikto_scan.xml'
    break_mode = '--break' in sys.argv
    fast_mode = '--fast' in sys.argv
    
    if not os.path.exists(xml_file):
        return render_template_string(HTML_TEMPLATE, 
                                   target="Unknown",
                                   scan_date=datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                                   findings_count=0,
                                   findings=[],
                                   stats={'high': 0, 'medium': 0, 'low': 0, 'info': 0},
                                   break_mode=break_mode,
                                   fast_mode=fast_mode,
                                   error=f"Archivo {xml_file} no encontrado")
    
    target, findings, stats, error = parse_nikto_xml(xml_file)
    
    context = {
        'target': target if target else "Unknown",
        'scan_date': datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        'findings': findings,
        'findings_count': len(findings),
        'stats': stats,
        'break_mode': break_mode,
        'fast_mode': fast_mode,
        'error': error
    }
    
    return render_template_string(HTML_TEMPLATE, **context)

if __name__ == '__main__':
    print(f"📊 Servidor web iniciado en http://localhost:5000")
    print(f"Presiona Ctrl+C para detener el servidor")
    app.run(debug=False, host='0.0.0.0', port=5000)
EOF

    chmod +x "nikto_web_report.py"
    
    local python_params="$NIKTO_OUTPUT"
    [ "$BREAK_MODE" = true ] && python_params="$python_params --break"
    [ "$FAST_MODE" = true ] && python_params="$python_params --fast"
    
    echo "🌐 Abre http://localhost:5000 en tu navegador"
    python3 "nikto_web_report.py" $python_params
}

# Función principal
main() {
    echo "=== Escáner Nikto Optimizado ==="
    echo ""
    
    check_dependencies
    process_target
    show_time_estimate
    run_nikto
    
    if [ -f "$NIKTO_OUTPUT" ]; then
        echo "✓ Archivo de salida: $NIKTO_OUTPUT"
        generate_web_report
    else
        echo "Error: No se generó el archivo de salida"
        exit 1
    fi
}

main
