#!/bin/bash

# Colores para el menú
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar el banner
mostrar_banner() {
    clear
    echo -e "${GREEN}"
    echo "=========================================="
    echo "         FOREMOST RECOVERY TOOL"
    echo "=========================================="
    echo -e "${NC}"
}

# Función para instalar foremost
instalar_foremost() {
    mostrar_banner
    echo -e "${YELLOW}[INFO] Verificando si foremost está instalado...${NC}"
    
    if command -v foremost &> /dev/null; then
        echo -e "${GREEN}[✓] Foremost ya está instalado${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}[INFO] Detectando distribución...${NC}"
    
    # Detectar distribución
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        case $ID in
            manjaro|arch)
                echo -e "${BLUE}[INFO] Detectado Manjaro/Arch Linux${NC}"
                echo -e "${YELLOW}[INFO] Instalando foremost...${NC}"
                sudo pacman -Sy --noconfirm foremost
                ;;
            ubuntu|debian)
                echo -e "${BLUE}[INFO] Detectado Ubuntu/Debian${NC}"
                echo -e "${YELLOW}[INFO] Instalando foremost...${NC}"
                sudo apt update
                sudo apt install -y foremost
                ;;
            fedora)
                echo -e "${BLUE}[INFO] Detectado Fedora${NC}"
                echo -e "${YELLOW}[INFO] Instalando foremost...${NC}"
                sudo dnf install -y foremost
                ;;
            *)
                echo -e "${RED}[ERROR] Distribución no soportada automáticamente${NC}"
                echo -e "${YELLOW}Por favor instala foremost manualmente:${NC}"
                echo "Manjaro/Arch: sudo pacman -S foremost"
                echo "Ubuntu/Debian: sudo apt install foremost"
                echo "Fedora: sudo dnf install foremost"
                return 1
                ;;
        esac
    else
        echo -e "${RED}[ERROR] No se pudo detectar la distribución${NC}"
        return 1
    fi
    
    # Verificar instalación
    if command -v foremost &> /dev/null; then
        echo -e "${GREEN}[✓] Foremost instalado correctamente${NC}"
        return 0
    else
        echo -e "${RED}[ERROR] Falló la instalación de foremost${NC}"
        return 1
    fi
}

# Función para listar discos
listar_discos() {
    mostrar_banner
    echo -e "${BLUE}[INFO] Listando discos disponibles...${NC}"
    echo -e "${YELLOW}================================${NC}"
    sudo fdisk -l
    echo -e "${YELLOW}================================${NC}"
}

# Función para recuperar archivos específicos
recuperar_archivos_especificos() {
    mostrar_banner
    echo -e "${BLUE}[INFO] Recuperación de tipos específicos de archivos${NC}"
    
    read -p "Ingresa la ruta de la unidad/dispositivo (ej: /dev/sdb1): " unidad
    read -p "Ingresa los tipos de archivo a recuperar (ej: jpg,jpeg,png,doc,pdf): " tipos
    read -p "Ingresa la ruta de salida (ej: /home/usuario/recuperacion): " salida
    
    if [ -z "$unidad" ] || [ -z "$tipos" ] || [ -z "$salida" ]; then
        echo -e "${RED}[ERROR] Todos los campos son obligatorios${NC}"
        read -p "Presiona Enter para continuar..."
        return
    fi
    
    # Crear directorio de salida si no existe
    mkdir -p "$salida"
    
    echo -e "${YELLOW}[INFO] Iniciando recuperación...${NC}"
    echo -e "${BLUE}Dispositivo: $unidad${NC}"
    echo -e "${BLUE}Tipos: $tipos${NC}"
    echo -e "${BLUE}Salida: $salida${NC}"
    
    sudo foremost -v -t "$tipos" -i "$unidad" -o "$salida"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[✓] Recuperación completada en: $salida${NC}"
    else
        echo -e "${RED}[ERROR] Ocurrió un error durante la recuperación${NC}"
    fi
    
    read -p "Presiona Enter para continuar..."
}

# Función para recuperar todos los archivos
recuperar_todos_archivos() {
    mostrar_banner
    echo -e "${BLUE}[INFO] Recuperación de TODOS los tipos de archivos${NC}"
    
    read -p "Ingresa la ruta de la unidad/dispositivo (ej: /dev/sdb1): " unidad
    read -p "Ingresa la ruta de salida (ej: /home/usuario/recuperacion): " salida
    
    if [ -z "$unidad" ] || [ -z "$salida" ]; then
        echo -e "${RED}[ERROR] Todos los campos son obligatorios${NC}"
        read -p "Presiona Enter para continuar..."
        return
    fi
    
    # Crear directorio de salida si no existe
    mkdir -p "$salida"
    
    echo -e "${YELLOW}[INFO] Iniciando recuperación completa...${NC}"
    echo -e "${BLUE}Dispositivo: $unidad${NC}"
    echo -e "${BLUE}Salida: $salida${NC}"
    
    sudo foremost -v -t all -i "$unidad" -o "$salida"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[✓] Recuperación completada en: $salida${NC}"
    else
        echo -e "${RED}[ERROR] Ocurrió un error durante la recuperación${NC}"
    fi
    
    read -p "Presiona Enter para continuar..."
}

# Función para mostrar ayuda
mostrar_ayuda() {
    mostrar_banner
    echo -e "${BLUE}AYUDA Y EJEMPLOS DE USO:${NC}"
    echo -e "${YELLOW}================================${NC}"
    echo -e "${GREEN}Ejemplos de tipos de archivo:${NC}"
    echo "  jpg,jpeg,png,gif  - Imágenes"
    echo "  pdf,doc,docx      - Documentos"
    echo "  zip,rar,tar.gz    - Archivos comprimidos"
    echo "  mp4,avi,mkv       - Videos"
    echo "  mp3,wav           - Audio"
    echo "  all               - Todos los tipos"
    echo ""
    echo -e "${GREEN}Ejemplos de dispositivos:${NC}"
    echo "  /dev/sdb1         - USB, disco externo"
    echo "  /dev/sda2         - Partición del disco duro"
    echo "  /dev/mmcblk0p1    - Tarjeta SD"
    echo ""
    echo -e "${GREEN}Comandos útiles:${NC}"
    echo "  fdisk -l          - Listar todos los discos"
    echo "  lsblk             - Listar bloques de dispositivos"
    echo -e "${YELLOW}================================${NC}"
    read -p "Presiona Enter para continuar..."
}

# Función principal del menú
menu_principal() {
    while true; do
        mostrar_banner
        echo -e "${BLUE}MENÚ PRINCIPAL - FOREMOST${NC}"
        echo -e "${YELLOW}================================${NC}"
        echo -e "1) ${GREEN}Instalar Foremost${NC}"
        echo -e "2) ${GREEN}Listar discos disponibles${NC}"
        echo -e "3) ${GREEN}Recuperar tipos específicos de archivos${NC}"
        echo -e "4) ${GREEN}Recuperar TODOS los archivos${NC}"
        echo -e "5) ${GREEN}Ayuda y ejemplos${NC}"
        echo -e "6) ${RED}Salir${NC}"
        echo -e "${YELLOW}================================${NC}"
        
        read -p "Selecciona una opción [1-6]: " opcion
        
        case $opcion in
            1)
                instalar_foremost
                read -p "Presiona Enter para continuar..."
                ;;
            2)
                listar_discos
                read -p "Presiona Enter para continuar..."
                ;;
            3)
                recuperar_archivos_especificos
                ;;
            4)
                recuperar_todos_archivos
                ;;
            5)
                mostrar_ayuda
                ;;
            6)
                echo -e "${GREEN}[INFO] Saliendo...${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}[ERROR] Opción no válida${NC}"
                read -p "Presiona Enter para continuar..."
                ;;
        esac
    done
}

# Verificar si se está ejecutando como root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}[ADVERTENCIA] No se recomienda ejecutar este script como root${NC}"
    echo -e "${YELLOW}Ejecuta como usuario normal y se pedirán permisos cuando sea necesario${NC}"
    exit 1
fi

# Iniciar el menú principal
menu_principal
