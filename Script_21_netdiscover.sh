#!/bin/bash

# Script simple para ejecutar netdiscover y generar imagen PNG
# Requiere: netdiscover, python3, matplotlib, seaborn

# Colores
VERDE='\033[0;32m'
AZUL='\033[0;34m'
ROJO='\033[0;31m'
AMARILLO='\033[1;33m'
NC='\033[0m'

# Archivos
RESULTS_FILE="netdiscover_results.txt"
OUTPUT_IMAGE="dispositivos_red.png"
PYTHON_SCRIPT="generar_imagen.py"

# Verificar root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${ROJO}Este script debe ejecutarse como root (sudo)${NC}"
    exit 1
fi

# Verificar netdiscover
if ! command -v netdiscover &> /dev/null; then
    echo -e "${ROJO}netdiscover no está instalado${NC}"
    echo "Instalar con: sudo apt install netdiscover"
    exit 1
fi

echo -e "${AZUL}========================================${NC}"
echo -e "${VERDE}  NETDISCOVER - GENERADOR DE IMAGEN${NC}"
echo -e "${AZUL}========================================${NC}"
echo ""

# Obtener interfaz
echo -e "${AMARILLO}Interfaces de red disponibles:${NC}"
ip link show | grep -E "^[0-9]" | awk '{print $2}' | sed 's/://' | nl
echo ""
read -p "Selecciona el número de interfaz (Enter para auto): " num_interfaz

if [ -z "$num_interfaz" ]; then
    INTERFAZ=$(ip route | grep default | awk '{print $5}' | head -1)
else
    INTERFAZ=$(ip link show | grep -E "^[0-9]" | awk '{print $2}' | sed 's/://' | sed -n "${num_interfaz}p")
fi

echo -e "${VERDE}Usando interfaz: $INTERFAZ${NC}"
echo ""

# Ejecutar netdiscover
read -p "¿Cuántos segundos quieres escanear? (default: 30): " tiempo
tiempo=${tiempo:-30}

echo -e "${AZUL}Ejecutando netdiscover...${NC}"
timeout $tiempo netdiscover -i $INTERFAZ -P -N > "$RESULTS_FILE" 2>&1 &
netdiscover_pid=$!

# Barra de progreso
for ((i=0; i<=$tiempo; i++)); do
    porcentaje=$((i * 100 / tiempo))
    printf "\r${VERDE}Progreso: [%-50s] %d%%${NC}" $(printf '#%.0s' $(seq 1 $((porcentaje / 2)))) $porcentaje
    sleep 1
done
echo ""

wait $netdiscover_pid 2>/dev/null
echo -e "${VERDE}Escaneo completado${NC}"
echo ""

# Crear script Python para generar imagen
cat > "$PYTHON_SCRIPT" << 'PYTHON_EOF'
#!/usr/bin/env python3
import re
import matplotlib.pyplot as plt
import seaborn as sns
from matplotlib.patches import Rectangle
import matplotlib.patches as mpatches

# Configurar estilo
sns.set_theme(style="white")
plt.rcParams['font.family'] = 'monospace'

# Leer resultados
devices = []
try:
    with open('netdiscover_results.txt', 'r') as f:
        content = f.read()
        lines = content.split('\n')
        
        for line in lines:
            match = re.search(r'(\d+\.\d+\.\d+\.\d+)\s+([0-9a-fA-F:]+)\s+\d+\s+(.*)', line)
            if match:
                ip = match.group(1)
                mac = match.group(2)
                vendor = match.group(3).strip() if match.group(3).strip() else 'Desconocido'
                devices.append({'ip': ip, 'mac': mac, 'vendor': vendor})
except Exception as e:
    print(f"Error al leer archivo: {e}")

if not devices:
    print("No se encontraron dispositivos")
    exit(1)

# Crear figura
fig, ax = plt.subplots(figsize=(14, max(8, len(devices) * 0.6 + 2)))
fig.patch.set_facecolor('#f8f9fa')
ax.set_facecolor('#ffffff')

# Título principal
fig.suptitle('🌐 DISPOSITIVOS DETECTADOS EN LA RED', 
             fontsize=22, fontweight='bold', y=0.98, color='#2c3e50')

# Colores
colors = sns.color_palette("husl", len(devices))
header_color = '#3498db'
text_color = '#2c3e50'

# Configurar ejes
ax.set_xlim(0, 10)
ax.set_ylim(0, len(devices) + 2)
ax.axis('off')

# Encabezados
y_pos = len(devices) + 1
header_height = 0.5

# Rectángulo de encabezado
header_rect = Rectangle((0.2, y_pos - 0.1), 9.6, header_height, 
                        facecolor=header_color, edgecolor='none', alpha=0.9)
ax.add_patch(header_rect)

# Textos de encabezado
ax.text(1, y_pos + 0.15, '#', fontsize=12, fontweight='bold', 
        color='white', ha='center', va='center')
ax.text(2.5, y_pos + 0.15, 'DIRECCIÓN IP', fontsize=12, fontweight='bold', 
        color='white', ha='left', va='center')
ax.text(5.5, y_pos + 0.15, 'DIRECCIÓN MAC', fontsize=12, fontweight='bold', 
        color='white', ha='left', va='center')
ax.text(8.5, y_pos + 0.15, 'FABRICANTE', fontsize=12, fontweight='bold', 
        color='white', ha='left', va='center')

# Dibujar dispositivos
for idx, device in enumerate(devices):
    y = len(devices) - idx
    
    # Fondo alternado
    if idx % 2 == 0:
        bg_rect = Rectangle((0.2, y - 0.4), 9.6, 0.8, 
                           facecolor='#ecf0f1', edgecolor='none', alpha=0.5)
        ax.add_patch(bg_rect)
    
    # Círculo de color
    circle = plt.Circle((0.8, y), 0.15, color=colors[idx], zorder=3)
    ax.add_patch(circle)
    
    # Número
    ax.text(1, y, f'{idx + 1}', fontsize=11, fontweight='bold', 
            color=text_color, ha='center', va='center')
    
    # IP
    ax.text(2.5, y, device['ip'], fontsize=11, fontweight='bold', 
            color='#e74c3c', ha='left', va='center', family='monospace')
    
    # MAC
    ax.text(5.5, y, device['mac'], fontsize=10, 
            color='#34495e', ha='left', va='center', family='monospace')
    
    # Vendor (truncar si es muy largo)
    vendor_text = device['vendor'][:25] + '...' if len(device['vendor']) > 25 else device['vendor']
    ax.text(8.5, y, vendor_text, fontsize=10, 
            color='#27ae60', ha='left', va='center', style='italic')

# Información adicional en la parte inferior
info_y = -0.5
ax.text(5, info_y, f'Total de dispositivos encontrados: {len(devices)}', 
        fontsize=12, ha='center', va='center', 
        bbox=dict(boxstyle='round,pad=0.5', facecolor='#3498db', 
                 edgecolor='none', alpha=0.8), color='white', fontweight='bold')

# Timestamp
from datetime import datetime
timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
ax.text(9.8, -1, f'Generado: {timestamp}', 
        fontsize=8, ha='right', va='center', color='#95a5a6', style='italic')

plt.tight_layout()
plt.savefig('dispositivos_red.png', dpi=150, bbox_inches='tight', 
           facecolor='#f8f9fa', edgecolor='none')
print(f"\n✅ Imagen generada: dispositivos_red.png")
print(f"📊 Total de dispositivos: {len(devices)}")
PYTHON_EOF

chmod +x "$PYTHON_SCRIPT"

# Verificar e instalar librerías de Python
echo -e "${AMARILLO}Verificando librerías de Python...${NC}"

instalar_libreria() {
    local libreria=$1
    if ! python3 -c "import $libreria" 2>/dev/null; then
        echo -e "${AMARILLO}Instalando $libreria...${NC}"
        
        # Intentar instalar normalmente
        if ! pip3 install "$libreria" --quiet 2>/dev/null; then
            # Si falla, preguntar si usar --break-system-packages
            echo -e "${ROJO}No se pudo instalar $libreria con pip normal${NC}"
            echo -e "${AMARILLO}¿Deseas instalar con --break-system-packages? (s/n)${NC}"
            echo -e "${AMARILLO}(Recomendado: Instalar con apt si está disponible)${NC}"
            read -p "Respuesta: " respuesta
            
            if [ "$respuesta" = "s" ] || [ "$respuesta" = "S" ]; then
                pip3 install "$libreria" --break-system-packages --quiet
                echo -e "${VERDE}$libreria instalado${NC}"
            else
                echo -e "${ROJO}No se instaló $libreria${NC}"
                echo -e "${AMARILLO}Intenta instalar manualmente:${NC}"
                echo "  sudo apt install python3-matplotlib python3-seaborn"
                exit 1
            fi
        fi
    else
        echo -e "${VERDE}$libreria ya está instalado${NC}"
    fi
}

instalar_libreria "matplotlib"
instalar_libreria "seaborn"

# Generar imagen
echo -e "${AZUL}Generando imagen PNG...${NC}"
python3 "$PYTHON_SCRIPT"

# Verificar si se creó la imagen
if [ -f "$OUTPUT_IMAGE" ]; then
    echo -e "${VERDE}========================================${NC}"
    echo -e "${VERDE}✅ ¡Proceso completado!${NC}"
    echo -e "${VERDE}========================================${NC}"
    echo -e "${AMARILLO}Imagen guardada en: ${NC}$(pwd)/$OUTPUT_IMAGE"
    echo ""
    
    # Intentar abrir la imagen automáticamente
    if command -v xdg-open &> /dev/null; then
        read -p "¿Deseas abrir la imagen ahora? (s/n): " abrir
        if [ "$abrir" = "s" ] || [ "$abrir" = "S" ]; then
            xdg-open "$OUTPUT_IMAGE" 2>/dev/null &
            echo -e "${VERDE}Imagen abierta${NC}"
        fi
    fi
else
    echo -e "${ROJO}Error: No se pudo generar la imagen${NC}"
fi

# Limpiar archivos temporales
rm -f "$PYTHON_SCRIPT" "$RESULTS_FILE"

echo ""
echo -e "${AZUL}========================================${NC}"
