#!/bin/bash

# Script para escanear archivos y directorios con ClamAV
# Compatible con: Ubuntu, Debian, Manjaro, Arch Linux
# Uso: ./clamav_scanner.sh

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
LOG_DIR="$HOME/.clamav_scanner"
LOG_FILE="$LOG_DIR/scan_$(date +%Y%m%d_%H%M%S).log"
QUARANTINE_DIR="$LOG_DIR/cuarentena"

# Crear directorios necesarios
mkdir -p "$LOG_DIR"
mkdir -p "$QUARANTINE_DIR"

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

# Verificar si se ejecuta como root para algunas operaciones
verificar_permisos() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}⚠ Algunas funciones requieren privilegios de root (sudo)${NC}"
        echo -e "${YELLOW}  Para actualizar base de datos y escaneo del sistema completo${NC}"
        return 1
    fi
    return 0
}

# Instalar ClamAV
instalar_clamav() {
    local distro=$(detectar_distro)
    
    echo -e "${YELLOW}Instalando ClamAV...${NC}"
    echo -e "${BLUE}Esto puede tardar unos minutos...${NC}"
    echo ""
    
    case "$distro" in
        ubuntu|debian|linuxmint|pop)
            sudo apt update
            sudo apt install -y clamav clamav-daemon clamav-freshclam
            
            # Detener el servicio para actualizar
            sudo systemctl stop clamav-freshclam 2>/dev/null || true
            ;;
        manjaro|arch|endeavouros|garuda)
            sudo pacman -Sy --noconfirm clamav
            ;;
        fedora|rhel|centos)
            sudo dnf install -y clamav clamav-update clamd
            ;;
        opensuse*)
            sudo zypper install -y clamav
            ;;
        *)
            echo -e "${RED}Distribución no reconocida${NC}"
            return 1
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ ClamAV instalado exitosamente${NC}"
        return 0
    else
        echo -e "${RED}✗ Error al instalar ClamAV${NC}"
        return 1
    fi
}

# Verificar instalación de ClamAV
verificar_clamav() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}VERIFICANDO CLAMAV${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if command -v clamscan &> /dev/null; then
        local version=$(clamscan --version 2>/dev/null | head -n1)
        echo -e "${GREEN}✓ ClamAV instalado: $version${NC}"
        
        # Verificar base de datos
        if [ -f /var/lib/clamav/main.cvd ] || [ -f /var/lib/clamav/main.cld ] || \
           [ -f /usr/share/clamav/main.cvd ] || [ -f /usr/share/clamav/main.cld ]; then
            echo -e "${GREEN}✓ Base de datos de virus encontrada${NC}"
            
            # Mostrar última actualización
            local db_file=$(find /var/lib/clamav /usr/share/clamav -name "main.c*d" 2>/dev/null | head -n1)
            if [ -f "$db_file" ]; then
                local last_update=$(stat -c %y "$db_file" 2>/dev/null | cut -d' ' -f1)
                echo -e "${BLUE}  Última actualización: $last_update${NC}"
            fi
        else
            echo -e "${YELLOW}⚠ Base de datos de virus no encontrada${NC}"
            echo -e "${YELLOW}  Ejecute 'Actualizar base de datos' del menú${NC}"
        fi
        
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        return 0
    else
        echo -e "${RED}✗ ClamAV no está instalado${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        return 1
    fi
}

# Actualizar base de datos de virus
actualizar_base_datos() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}ACTUALIZANDO BASE DE DATOS DE VIRUS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}Esto descargará las últimas definiciones de virus...${NC}"
    echo -e "${YELLOW}Puede tardar varios minutos dependiendo de la conexión${NC}"
    echo ""
    
    # Detener servicio si está corriendo
    sudo systemctl stop clamav-freshclam 2>/dev/null || true
    
    # Actualizar con freshclam
    if command -v freshclam &> /dev/null; then
        echo -e "${BLUE}Descargando actualizaciones...${NC}"
        sudo freshclam
        
        if [ $? -eq 0 ]; then
            echo ""
            echo -e "${GREEN}✓ Base de datos actualizada exitosamente${NC}"
            
            # Reiniciar servicio
            sudo systemctl start clamav-freshclam 2>/dev/null || true
        else
            echo ""
            echo -e "${RED}✗ Error al actualizar la base de datos${NC}"
            echo -e "${YELLOW}Tip: Verifica tu conexión a internet${NC}"
        fi
    else
        echo -e "${RED}freshclam no encontrado${NC}"
        echo -e "${YELLOW}Intente reinstalar ClamAV${NC}"
    fi
}

# Solicitar ruta
solicitar_ruta() {
    local tipo="$1"
    local ruta=""
    
    while true; do
        if [ "$tipo" = "archivo" ]; then
            echo -e "${BLUE}Ingrese la ruta del archivo a escanear:${NC}"
        else
            echo -e "${BLUE}Ingrese la ruta del directorio a escanear:${NC}"
        fi
        
        read -e -p "Ruta: " ruta
        ruta=$(eval echo "$ruta")
        
        if [ -z "$ruta" ]; then
            echo -e "${YELLOW}Operación cancelada${NC}"
            return 1
        fi
        
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

# Escanear archivo individual
escanear_archivo() {
    local archivo
    archivo=$(solicitar_ruta "archivo")
    
    if [ $? -ne 0 ] || [ -z "$archivo" ]; then
        return 1
    fi
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}ESCANEANDO ARCHIVO${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Archivo: $archivo${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Escanear
    clamscan -v "$archivo" 2>&1 | tee -a "$LOG_FILE"
    local resultado=${PIPESTATUS[0]}
    
    echo ""
    if [ $resultado -eq 0 ]; then
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}✓ ARCHIVO LIMPIO - No se encontraron amenazas${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    elif [ $resultado -eq 1 ]; then
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}⚠ AMENAZA DETECTADA - Virus o malware encontrado${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        read -p "¿Desea mover el archivo a cuarentena? (s/n): " cuarentena
        if [[ "$cuarentena" =~ ^[Ss]$ ]]; then
            mover_a_cuarentena "$archivo"
        fi
    else
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}⚠ Error durante el escaneo${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    fi
    
    echo -e "${BLUE}Log guardado en: $LOG_FILE${NC}"
}

# Escanear directorio
escanear_directorio() {
    local directorio
    directorio=$(solicitar_ruta "directorio")
    
    if [ $? -ne 0 ] || [ -z "$directorio" ]; then
        return 1
    fi
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}ESCANEANDO DIRECTORIO${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Directorio: $directorio${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}Opciones de escaneo:${NC}"
    echo "1) Escaneo normal (solo directorio actual)"
    echo "2) Escaneo recursivo (incluye subdirectorios)"
    echo "3) Escaneo recursivo + mover infectados a cuarentena"
    echo ""
    read -p "Seleccione [1-3]: " opcion_scan
    
    local cmd="clamscan -v"
    
    case "$opcion_scan" in
        1)
            # Escaneo normal
            ;;
        2)
            cmd="$cmd -r"
            ;;
        3)
            cmd="$cmd -r --move=$QUARANTINE_DIR"
            echo -e "${YELLOW}Los archivos infectados se moverán a: $QUARANTINE_DIR${NC}"
            ;;
        *)
            echo -e "${RED}Opción inválida${NC}"
            return 1
            ;;
    esac
    
    echo ""
    echo -e "${YELLOW}Iniciando escaneo...${NC}"
    echo ""
    
    $cmd "$directorio" 2>&1 | tee -a "$LOG_FILE"
    local resultado=${PIPESTATUS[0]}
    
    echo ""
    if [ $resultado -eq 0 ]; then
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}✓ ESCANEO COMPLETADO - No se encontraron amenazas${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    elif [ $resultado -eq 1 ]; then
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}⚠ AMENAZAS DETECTADAS${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        if [ "$opcion_scan" != "3" ]; then
            echo ""
            read -p "¿Desea ver los archivos infectados? (s/n): " ver
            if [[ "$ver" =~ ^[Ss]$ ]]; then
                grep "FOUND" "$LOG_FILE" | tail -20
            fi
        fi
    else
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}⚠ Escaneo completado con advertencias${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    fi
    
    echo -e "${BLUE}Log guardado en: $LOG_FILE${NC}"
}

# Escaneo rápido del sistema
escaneo_rapido() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}ESCANEO RÁPIDO DEL SISTEMA${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}Se escanearán los siguientes directorios:${NC}"
    echo "  • $HOME (Tu directorio personal)"
    echo "  • /tmp (Archivos temporales)"
    echo "  • /var/tmp (Archivos temporales del sistema)"
    echo ""
    read -p "¿Desea continuar? (s/n): " confirmar
    
    if [[ ! "$confirmar" =~ ^[Ss]$ ]]; then
        echo "Operación cancelada"
        return
    fi
    
    echo ""
    echo -e "${YELLOW}Iniciando escaneo rápido...${NC}"
    echo ""
    
    clamscan -r -v "$HOME" /tmp /var/tmp 2>&1 | tee -a "$LOG_FILE"
    local resultado=${PIPESTATUS[0]}
    
    echo ""
    if [ $resultado -eq 0 ]; then
        echo -e "${GREEN}✓ ESCANEO COMPLETADO - Sistema limpio${NC}"
    elif [ $resultado -eq 1 ]; then
        echo -e "${RED}⚠ Se encontraron amenazas - Revise el log${NC}"
    fi
    
    echo -e "${BLUE}Log guardado en: $LOG_FILE${NC}"
}

# Escaneo completo del sistema
escaneo_completo() {
    if ! verificar_permisos; then
        echo -e "${RED}Se requieren permisos de root para escaneo completo${NC}"
        read -p "¿Desea ejecutar con sudo? (s/n): " usar_sudo
        if [[ "$usar_sudo" =~ ^[Ss]$ ]]; then
            sudo "$0" --escaneo-completo
            return
        else
            return 1
        fi
    fi
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}ESCANEO COMPLETO DEL SISTEMA${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${RED}⚠ ADVERTENCIA: Este escaneo puede tardar HORAS${NC}"
    echo -e "${YELLOW}Se escaneará TODO el sistema de archivos (/)${NC}"
    echo ""
    read -p "¿Está seguro que desea continuar? (s/n): " confirmar
    
    if [[ ! "$confirmar" =~ ^[Ss]$ ]]; then
        echo "Operación cancelada"
        return
    fi
    
    echo ""
    echo -e "${YELLOW}Iniciando escaneo completo del sistema...${NC}"
    echo -e "${BLUE}Puede tomar varias horas dependiendo del tamaño del disco${NC}"
    echo ""
    
    # Excluir ciertos directorios del sistema
    clamscan -r -v \
        --exclude-dir="^/sys" \
        --exclude-dir="^/proc" \
        --exclude-dir="^/dev" \
        / 2>&1 | tee -a "$LOG_FILE"
    
    local resultado=${PIPESTATUS[0]}
    
    echo ""
    if [ $resultado -eq 0 ]; then
        echo -e "${GREEN}✓ ESCANEO COMPLETADO - Sistema limpio${NC}"
    elif [ $resultado -eq 1 ]; then
        echo -e "${RED}⚠ Se encontraron amenazas - Revise el log${NC}"
    fi
    
    echo -e "${BLUE}Log guardado en: $LOG_FILE${NC}"
}

# Mover archivo a cuarentena
mover_a_cuarentena() {
    local archivo="$1"
    local nombre_archivo=$(basename "$archivo")
    local destino="$QUARANTINE_DIR/${nombre_archivo}_$(date +%Y%m%d_%H%M%S)"
    
    mv "$archivo" "$destino" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Archivo movido a cuarentena: $destino${NC}"
    else
        echo -e "${RED}✗ Error al mover archivo a cuarentena${NC}"
    fi
}

# Ver cuarentena
ver_cuarentena() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}ARCHIVOS EN CUARENTENA${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Directorio: $QUARANTINE_DIR${NC}"
    echo ""
    
    if [ "$(ls -A $QUARANTINE_DIR 2>/dev/null)" ]; then
        ls -lh "$QUARANTINE_DIR"
        echo ""
        echo -e "${RED}ADVERTENCIA: Estos archivos contienen amenazas detectadas${NC}"
        echo ""
        read -p "¿Desea eliminar todos los archivos en cuarentena? (s/n): " eliminar
        if [[ "$eliminar" =~ ^[Ss]$ ]]; then
            rm -rf "$QUARANTINE_DIR"/*
            echo -e "${GREEN}✓ Cuarentena limpiada${NC}"
        fi
    else
        echo -e "${GREEN}La cuarentena está vacía${NC}"
    fi
}

# Ver logs
ver_logs() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}LOGS DE ESCANEO${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if [ "$(ls -A $LOG_DIR/*.log 2>/dev/null)" ]; then
        echo -e "${YELLOW}Logs disponibles:${NC}"
        ls -lht "$LOG_DIR"/*.log | head -10
        echo ""
        read -p "¿Desea ver el último log? (s/n): " ver
        if [[ "$ver" =~ ^[Ss]$ ]]; then
            local ultimo_log=$(ls -t "$LOG_DIR"/*.log | head -1)
            echo ""
            echo -e "${BLUE}Mostrando: $ultimo_log${NC}"
            echo ""
            less "$ultimo_log"
        fi
    else
        echo -e "${YELLOW}No hay logs disponibles${NC}"
    fi
}

# Menú principal
mostrar_menu() {
    clear
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}    ESCÁNER ANTIVIRUS - CLAMAV${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "1) Escanear archivo individual"
    echo "2) Escanear directorio"
    echo "3) Escaneo rápido del sistema"
    echo "4) Escaneo completo del sistema (requiere sudo)"
    echo "5) Ver archivos en cuarentena"
    echo "6) Ver logs de escaneos"
    echo "7) Actualizar base de datos de virus (requiere sudo)"
    echo "8) Verificar/Instalar ClamAV"
    echo "9) Salir"
    echo ""
    echo -e "${BLUE}Directorio de logs: ${YELLOW}$LOG_DIR${NC}"
    echo -e "${BLUE}Cuarentena: ${YELLOW}$QUARANTINE_DIR${NC}"
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Programa principal
main() {
    # Argumento especial para escaneo completo con sudo
    if [ "$1" = "--escaneo-completo" ]; then
        escaneo_completo
        exit 0
    fi
    
    # Verificar instalación
    if ! command -v clamscan &> /dev/null; then
        echo -e "${YELLOW}ClamAV no está instalado${NC}"
        read -p "¿Desea instalarlo ahora? (s/n): " instalar
        if [[ "$instalar" =~ ^[Ss]$ ]]; then
            instalar_clamav
            echo ""
            echo -e "${YELLOW}Actualizando base de datos...${NC}"
            actualizar_base_datos
        else
            echo -e "${RED}No se puede continuar sin ClamAV${NC}"
            exit 1
        fi
    fi
    
    while true; do
        mostrar_menu
        read -p "Seleccione una opción [1-9]: " opcion
        echo ""
        
        case "$opcion" in
            1)
                escanear_archivo
                ;;
            2)
                escanear_directorio
                ;;
            3)
                escaneo_rapido
                ;;
            4)
                escaneo_completo
                ;;
            5)
                ver_cuarentena
                ;;
            6)
                ver_logs
                ;;
            7)
                actualizar_base_datos
                ;;
            8)
                verificar_clamav
                if [ $? -ne 0 ]; then
                    read -p "¿Desea instalar ClamAV? (s/n): " inst
                    if [[ "$inst" =~ ^[Ss]$ ]]; then
                        instalar_clamav
                        actualizar_base_datos
                    fi
                fi
                ;;
            9)
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

main "$@"
