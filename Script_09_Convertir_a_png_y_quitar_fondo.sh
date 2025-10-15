#!/bin/bash

# Script para eliminar fondo de imágenes y convertir a PNG
# Compatible con: Ubuntu, Debian, Manjaro, Arch Linux
# Usa: ImageMagick y rembg (Python)
# Uso: ./remove_bg.sh

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Variables globales
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/sin_fondo"

# Detectar distribución
detectar_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ -f /etc/arch-release ]; then
        echo "arch"
    else
        echo "unknown"
    fi
}

# Verificar si Python está instalado
verificar_python() {
    if command -v python3 &> /dev/null; then
        echo -e "${GREEN}✓ Python3 encontrado: $(python3 --version)${NC}"
        return 0
    else
        echo -e "${RED}✗ Python3 no está instalado${NC}"
        return 1
    fi
}

# Verificar si pip está instalado
verificar_pip() {
    if command -v pip3 &> /dev/null; then
        echo -e "${GREEN}✓ pip3 encontrado${NC}"
        return 0
    else
        echo -e "${RED}✗ pip3 no está instalado${NC}"
        return 1
    fi
}

# Instalar dependencias del sistema
instalar_dependencias_sistema() {
    local distro=$(detectar_distro)
    
    echo -e "${YELLOW}Instalando dependencias del sistema...${NC}"
    
    case "$distro" in
        ubuntu|debian|linuxmint|pop)
            sudo apt update
            sudo apt install -y python3 python3-pip imagemagick
            ;;
        manjaro|arch|endeavouros|garuda)
            sudo pacman -Sy --noconfirm python python-pip imagemagick
            ;;
        fedora|rhel|centos)
            sudo dnf install -y python3 python3-pip ImageMagick
            ;;
        opensuse*)
            sudo zypper install -y python3 python3-pip ImageMagick
            ;;
        *)
            echo -e "${RED}Distribución no reconocida${NC}"
            echo "Instale manualmente: python3, pip3, imagemagick"
            return 1
            ;;
    esac
    
    echo -e "${GREEN}✓ Dependencias del sistema instaladas${NC}"
}

# Instalar rembg (herramienta de IA para remover fondos)
instalar_rembg() {
    echo -e "${YELLOW}Instalando rembg (puede tardar unos minutos)...${NC}"
    echo -e "${BLUE}Esta herramienta usa IA para detectar y remover fondos${NC}"
    
    # Instalar rembg
    pip3 install --user rembg[cli] pillow
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ rembg instalado exitosamente${NC}"
        
        # Agregar PATH si no existe
        if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
            echo -e "${YELLOW}Agregando ~/.local/bin al PATH...${NC}"
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
            export PATH="$HOME/.local/bin:$PATH"
        fi
        
        # Descargar modelo la primera vez
        echo -e "${YELLOW}Descargando modelo de IA (solo la primera vez, ~180MB)...${NC}"
        ~/.local/bin/rembg d -o /tmp/test.png /dev/null 2>/dev/null || true
        
        return 0
    else
        echo -e "${RED}✗ Error al instalar rembg${NC}"
        return 1
    fi
}

# Verificar instalación completa
verificar_instalacion() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}VERIFICANDO INSTALACIÓN${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    local todo_ok=1
    
    # Verificar Python
    if verificar_python; then
        echo ""
    else
        todo_ok=0
    fi
    
    # Verificar pip
    if verificar_pip; then
        echo ""
    else
        todo_ok=0
    fi
    
    # Verificar ImageMagick
    if command -v convert &> /dev/null; then
        echo -e "${GREEN}✓ ImageMagick encontrado: $(convert -version | head -n1)${NC}"
        echo ""
    else
        echo -e "${RED}✗ ImageMagick no está instalado${NC}"
        echo ""
        todo_ok=0
    fi
    
    # Verificar rembg
    if command -v rembg &> /dev/null || [ -f "$HOME/.local/bin/rembg" ]; then
        echo -e "${GREEN}✓ rembg encontrado${NC}"
        echo ""
    else
        echo -e "${RED}✗ rembg no está instalado${NC}"
        echo ""
        todo_ok=0
    fi
    
    if [ $todo_ok -eq 1 ]; then
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}✓ Todas las herramientas están instaladas correctamente${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        return 0
    else
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}⚠ Faltan algunas herramientas${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        return 1
    fi
}

# Instalar todo automáticamente
instalar_todo() {
    echo -e "${CYAN}Iniciando instalación completa...${NC}"
    echo ""
    
    instalar_dependencias_sistema
    echo ""
    
    if verificar_python && verificar_pip; then
        instalar_rembg
    else
        echo -e "${RED}Error: Python o pip no están disponibles${NC}"
        return 1
    fi
    
    echo ""
    verificar_instalacion
}

# Solicitar ruta de archivo o directorio
solicitar_ruta() {
    local tipo="$1"  # "archivo" o "directorio"
    local ruta=""
    
    while true; do
        if [ "$tipo" = "archivo" ]; then
            echo -e "${BLUE}Ingrese la ruta de la imagen:${NC}"
        else
            echo -e "${BLUE}Ingrese la ruta del directorio con imágenes:${NC}"
        fi
        
        read -e -p "Ruta: " ruta
        ruta=$(eval echo "$ruta")
        
        if [ "$tipo" = "archivo" ]; then
            if [ -f "$ruta" ]; then
                echo "$ruta"
                return 0
            else
                echo -e "${RED}Error: El archivo no existe${NC}"
            fi
        else
            if [ -d "$ruta" ]; then
                echo "$ruta"
                return 0
            else
                echo -e "${RED}Error: El directorio no existe${NC}"
            fi
        fi
        
        read -p "¿Desea intentar de nuevo? (s/n): " reintentar
        if [[ ! "$reintentar" =~ ^[Ss]$ ]]; then
            return 1
        fi
    done
}

# Procesar una sola imagen
procesar_imagen() {
    local archivo="$1"
    local output_dir="$2"
    local nombre_base=$(basename "$archivo")
    local nombre_sin_ext="${nombre_base%.*}"
    local output_file="$output_dir/${nombre_sin_ext}_sin_fondo.png"
    
    echo -e "${YELLOW}Procesando: $nombre_base${NC}"
    
    # Usar rembg para remover el fondo
    if command -v rembg &> /dev/null; then
        rembg i "$archivo" "$output_file" 2>/dev/null
    elif [ -f "$HOME/.local/bin/rembg" ]; then
        "$HOME/.local/bin/rembg" i "$archivo" "$output_file" 2>/dev/null
    else
        echo -e "${RED}✗ rembg no encontrado${NC}"
        return 1
    fi
    
    if [ -f "$output_file" ]; then
        echo -e "${GREEN}✓ Guardado: $output_file${NC}"
        return 0
    else
        echo -e "${RED}✗ Error al procesar la imagen${NC}"
        return 1
    fi
}

# Procesar una imagen individual
procesar_una_imagen() {
    local archivo
    archivo=$(solicitar_ruta "archivo")
    
    if [ $? -ne 0 ] || [ -z "$archivo" ]; then
        echo "Operación cancelada"
        return 1
    fi
    
    # Verificar que sea una imagen
    if ! file "$archivo" | grep -qE 'image|PNG|JPEG|JPG|GIF|BMP'; then
        echo -e "${RED}Error: El archivo no parece ser una imagen válida${NC}"
        return 1
    fi
    
    # Crear directorio de salida
    mkdir -p "$OUTPUT_DIR"
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}PROCESANDO IMAGEN${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    procesar_imagen "$archivo" "$OUTPUT_DIR"
    
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✓ Proceso completado${NC}"
    echo -e "${GREEN}Directorio de salida: $OUTPUT_DIR${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Procesar directorio completo
procesar_directorio() {
    local directorio
    directorio=$(solicitar_ruta "directorio")
    
    if [ $? -ne 0 ] || [ -z "$directorio" ]; then
        echo "Operación cancelada"
        return 1
    fi
    
    # Crear directorio de salida
    mkdir -p "$OUTPUT_DIR"
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}PROCESANDO DIRECTORIO${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    local total=0
    local exitosas=0
    local fallidas=0
    
    # Buscar todas las imágenes
    for archivo in "$directorio"/*.{jpg,jpeg,png,gif,bmp,JPG,JPEG,PNG,GIF,BMP} 2>/dev/null; do
        if [ -f "$archivo" ]; then
            ((total++))
            echo ""
            if procesar_imagen "$archivo" "$OUTPUT_DIR"; then
                ((exitosas++))
            else
                ((fallidas++))
            fi
        fi
    done
    
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✓ Proceso completado${NC}"
    echo -e "${GREEN}Total de imágenes: $total${NC}"
    echo -e "${GREEN}Exitosas: $exitosas${NC}"
    if [ $fallidas -gt 0 ]; then
        echo -e "${YELLOW}Fallidas: $fallidas${NC}"
    fi
    echo -e "${GREEN}Directorio de salida: $OUTPUT_DIR${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Cambiar directorio de salida
cambiar_output() {
    echo -e "${BLUE}Directorio actual de salida: ${YELLOW}$OUTPUT_DIR${NC}"
    echo ""
    read -e -p "Nuevo directorio de salida: " nuevo_dir
    nuevo_dir=$(eval echo "$nuevo_dir")
    
    if [ -z "$nuevo_dir" ]; then
        echo -e "${YELLOW}Operación cancelada${NC}"
        return
    fi
    
    mkdir -p "$nuevo_dir"
    OUTPUT_DIR="$nuevo_dir"
    echo -e "${GREEN}✓ Directorio de salida actualizado: $OUTPUT_DIR${NC}"
}

# Menú principal
mostrar_menu() {
    clear
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}    ELIMINAR FONDO DE IMÁGENES (IA)${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}Directorio de salida: ${YELLOW}$OUTPUT_DIR${NC}"
    echo ""
    echo "1) Procesar una imagen"
    echo "2) Procesar directorio completo"
    echo "3) Cambiar directorio de salida"
    echo "4) Verificar/Instalar herramientas"
    echo "5) Salir"
    echo ""
    echo -e "${BLUE}Formatos soportados: JPG, PNG, GIF, BMP${NC}"
    echo -e "${BLUE}Salida: PNG con transparencia${NC}"
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Programa principal
main() {
    # Verificar instalación al inicio
    if ! verificar_instalacion &>/dev/null; then
        echo -e "${YELLOW}Algunas herramientas no están instaladas.${NC}"
        read -p "¿Desea instalarlas ahora? (s/n): " instalar
        if [[ "$instalar" =~ ^[Ss]$ ]]; then
            instalar_todo
        else
            echo -e "${RED}No se puede continuar sin las herramientas necesarias${NC}"
            exit 1
        fi
    fi
    
    while true; do
        mostrar_menu
        read -p "Seleccione una opción [1-5]: " opcion
        echo ""
        
        case "$opcion" in
            1)
                procesar_una_imagen
                ;;
            2)
                procesar_directorio
                ;;
            3)
                cambiar_output
                ;;
            4)
                verificar_instalacion
                if [ $? -ne 0 ]; then
                    read -p "¿Desea instalar las herramientas faltantes? (s/n): " inst
                    if [[ "$inst" =~ ^[Ss]$ ]]; then
                        instalar_todo
                    fi
                fi
                ;;
            5)
                echo -e "${GREEN}¡Hasta luego!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Opción no válida${NC}"
                ;;
        esac
        
        echo ""
        read -p "Presione Enter para continuar..."
    done
}

main
