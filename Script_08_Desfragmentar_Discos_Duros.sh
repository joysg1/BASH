#!/bin/bash

# Script para optimizar discos en Linux
# Compatible con: Ubuntu, Debian, Manjaro, Arch Linux
# Soporta: ext4, Btrfs, XFS y SSD con TRIM
# Uso: ./disk_optimizer.sh

# NOTA: En Linux moderna con ext4/Btrfs, la desfragmentación tradicional
# no es necesaria como en Windows. Este script optimiza según el tipo de disco.

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Verificar si se ejecuta como root
verificar_root() {
    if [ "$EUID" -ne 0 ]; then 
        echo -e "${RED}Este script debe ejecutarse como root (sudo)${NC}"
        exit 1
    fi
}

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

# Instalar herramientas necesarias
instalar_herramientas() {
    local distro=$(detectar_distro)
    local herramientas_faltantes=()
    
    # Verificar herramientas
    command -v e4defrag &> /dev/null || herramientas_faltantes+=("e2fsprogs")
    command -v btrfs &> /dev/null || herramientas_faltantes+=("btrfs-progs")
    command -v xfs_fsr &> /dev/null || herramientas_faltantes+=("xfsprogs")
    command -v fstrim &> /dev/null || herramientas_faltantes+=("util-linux")
    command -v ntfsfix &> /dev/null || herramientas_faltantes+=("ntfs-3g")
    
    if [ ${#herramientas_faltantes[@]} -eq 0 ]; then
        echo -e "${GREEN}✓ Todas las herramientas están instaladas${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}Instalando herramientas necesarias...${NC}"
    
    case "$distro" in
        ubuntu|debian|linuxmint|pop)
            apt update
            apt install -y e2fsprogs btrfs-progs xfsprogs util-linux ntfs-3g
            ;;
        manjaro|arch|endeavouros|garuda)
            pacman -Sy --noconfirm e2fsprogs btrfs-progs xfsprogs util-linux ntfs-3g
            ;;
        fedora|rhel|centos)
            dnf install -y e2fsprogs btrfs-progs xfsprogs util-linux ntfs-3g
            ;;
        *)
            echo -e "${RED}Distribución no reconocida${NC}"
            return 1
            ;;
    esac
    
    echo -e "${GREEN}✓ Herramientas instaladas${NC}"
}

# Detectar tipo de disco (SSD o HDD)
detectar_tipo_disco() {
    local dispositivo=$1
    # Extraer nombre del dispositivo sin número de partición
    local disco=$(echo "$dispositivo" | sed 's/[0-9]*$//' | sed 's|/dev/||')
    
    if [ -f "/sys/block/$disco/queue/rotational" ]; then
        local rotational=$(cat "/sys/block/$disco/queue/rotational")
        if [ "$rotational" -eq 0 ]; then
            echo "SSD"
        else
            echo "HDD"
        fi
    else
        echo "UNKNOWN"
    fi
}

# Listar particiones montadas
listar_particiones() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}PARTICIONES MONTADAS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    local contador=1
    declare -g -A particiones_map
    
    while IFS= read -r linea; do
        local dispositivo=$(echo "$linea" | awk '{print $1}')
        local punto_montaje=$(echo "$linea" | awk '{print $3}')
        local tipo_fs=$(echo "$linea" | awk '{print $5}')
        local tipo_disco=$(detectar_tipo_disco "$dispositivo")
        
        # Filtrar solo sistemas de archivos relevantes
        if [[ "$tipo_fs" =~ ^(ext4|btrfs|xfs|fuseblk|ntfs)$ ]]; then
            particiones_map[$contador]="$dispositivo|$punto_montaje|$tipo_fs|$tipo_disco"
            
            # Obtener fragmentación para ext4
            local fragmentacion=""
            if [ "$tipo_fs" = "ext4" ]; then
                fragmentacion=$(e4defrag -c "$punto_montaje" 2>/dev/null | grep "fragmentation" | awk '{print $2}' || echo "N/A")
            fi
            
            # Mostrar NTFS de forma especial
            if [[ "$tipo_fs" =~ ^(fuseblk|ntfs)$ ]]; then
                tipo_fs="NTFS"
            fi
            
            printf "${GREEN}%2d)${NC} %-20s ${BLUE}%-15s${NC} %-10s ${YELLOW}%-6s${NC}" \
                "$contador" "$dispositivo" "$punto_montaje" "$tipo_fs" "$tipo_disco"
            
            if [ "$tipo_fs" = "ext4" ] && [ "$fragmentacion" != "N/A" ]; then
                printf " ${CYAN}Fragmentación: %s${NC}" "$fragmentacion"
            fi
            echo ""
            
            ((contador++))
        fi
    done < <(df -T | grep "^/dev")
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if [ $contador -eq 1 ]; then
        echo -e "${RED}No se encontraron particiones compatibles${NC}"
        return 1
    fi
}

# Analizar fragmentación de ext4
analizar_ext4() {
    local punto_montaje=$1
    echo -e "${YELLOW}Analizando fragmentación en $punto_montaje...${NC}"
    e4defrag -c "$punto_montaje"
}

# Desfragmentar ext4
desfragmentar_ext4() {
    local punto_montaje=$1
    echo -e "${YELLOW}Desfragmentando sistema ext4: $punto_montaje${NC}"
    echo -e "${BLUE}Esto puede tomar varios minutos dependiendo del tamaño...${NC}"
    
    e4defrag -v "$punto_montaje"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Desfragmentación completada${NC}"
        echo ""
        echo -e "${CYAN}Análisis post-desfragmentación:${NC}"
        e4defrag -c "$punto_montaje"
    else
        echo -e "${RED}✗ Error durante la desfragmentación${NC}"
    fi
}

# Desfragmentar Btrfs
desfragmentar_btrfs() {
    local punto_montaje=$1
    echo -e "${YELLOW}Desfragmentando sistema Btrfs: $punto_montaje${NC}"
    echo -e "${BLUE}Esto puede tomar tiempo...${NC}"
    
    btrfs filesystem defragment -r -v "$punto_montaje"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Desfragmentación Btrfs completada${NC}"
    else
        echo -e "${RED}✗ Error durante la desfragmentación${NC}"
    fi
}

# Desfragmentar XFS
desfragmentar_xfs() {
    local punto_montaje=$1
    echo -e "${YELLOW}Optimizando sistema XFS: $punto_montaje${NC}"
    
    xfs_fsr -v "$punto_montaje"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Optimización XFS completada${NC}"
    else
        echo -e "${RED}✗ Error durante la optimización${NC}"
    fi
}

# Optimizar NTFS
optimizar_ntfs() {
    local dispositivo=$1
    local punto_montaje=$2
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}⚠ PARTICIÓN NTFS DETECTADA${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}IMPORTANTE:${NC}"
    echo "• NTFS es el sistema de archivos de Windows"
    echo "• Linux tiene soporte limitado para mantenimiento de NTFS"
    echo "• Para desfragmentación completa, use Windows"
    echo ""
    echo -e "${GREEN}Operaciones disponibles en Linux:${NC}"
    echo "1. Verificar y reparar errores del sistema de archivos"
    echo "2. Limpiar el journal NTFS"
    echo "3. Optimización básica de metadatos"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    read -p "¿Desea realizar mantenimiento básico de NTFS? (s/n): " confirmar
    if [[ ! "$confirmar" =~ ^[Ss]$ ]]; then
        echo "Operación cancelada"
        return 0
    fi
    
    # Desmontar la partición si está montada
    echo -e "${YELLOW}Verificando si la partición está montada...${NC}"
    if mountpoint -q "$punto_montaje"; then
        echo -e "${YELLOW}Desmontando $punto_montaje...${NC}"
        umount "$punto_montaje"
        local necesita_remontar=1
    else
        local necesita_remontar=0
    fi
    
    echo ""
    echo -e "${YELLOW}1. Verificando sistema de archivos NTFS...${NC}"
    ntfsfix -b -d "$dispositivo"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Verificación completada${NC}"
    else
        echo -e "${RED}✗ Se encontraron problemas${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}2. Limpiando journal NTFS...${NC}"
    ntfsfix -d "$dispositivo"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Journal limpiado${NC}"
    else
        echo -e "${YELLOW}⚠ No se pudo limpiar el journal completamente${NC}"
    fi
    
    # Remontar si era necesario
    if [ $necesita_remontar -eq 1 ]; then
        echo ""
        echo -e "${YELLOW}Remontando partición...${NC}"
        mount "$dispositivo" "$punto_montaje"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Partición remontada${NC}"
        fi
    fi
    
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✓ Mantenimiento básico de NTFS completado${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}RECOMENDACIÓN:${NC}"
    echo "Para desfragmentación completa de NTFS, arranque en Windows y use:"
    echo "  • Desfragmentador de disco (GUI)"
    echo "  • Comando: defrag C: /U /V"
    echo ""
}

# Ejecutar TRIM en SSD
ejecutar_trim() {
    local dispositivo=$1
    local punto_montaje=$2
    
    echo -e "${YELLOW}Ejecutando TRIM en SSD: $punto_montaje${NC}"
    
    fstrim -v "$punto_montaje"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ TRIM ejecutado exitosamente${NC}"
    else
        echo -e "${YELLOW}⚠ TRIM no disponible o ya ejecutado${NC}"
    fi
}

# Optimizar partición seleccionada
optimizar_particion() {
    listar_particiones
    
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    echo ""
    read -p "Seleccione la partición a optimizar [número]: " seleccion
    
    if [ -z "${particiones_map[$seleccion]}" ]; then
        echo -e "${RED}Selección inválida${NC}"
        return 1
    fi
    
    IFS='|' read -r dispositivo punto_montaje tipo_fs tipo_disco <<< "${particiones_map[$seleccion]}"
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Dispositivo:${NC} $dispositivo"
    echo -e "${GREEN}Punto montaje:${NC} $punto_montaje"
    echo -e "${GREEN}Sistema archivos:${NC} $tipo_fs"
    echo -e "${GREEN}Tipo disco:${NC} $tipo_disco"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Advertencia para SSD
    if [ "$tipo_disco" = "SSD" ]; then
        echo -e "${YELLOW}⚠ ADVERTENCIA: Este es un SSD${NC}"
        echo -e "${YELLOW}Los SSDs NO necesitan desfragmentación tradicional.${NC}"
        echo -e "${YELLOW}Se ejecutará TRIM en su lugar para optimizar el rendimiento.${NC}"
        echo ""
    fi
    
    read -p "¿Desea continuar? (s/n): " confirmar
    if [[ ! "$confirmar" =~ ^[Ss]$ ]]; then
        echo "Operación cancelada"
        return 0
    fi
    
    echo ""
    
    # Optimizar según tipo de disco y sistema de archivos
    if [ "$tipo_disco" = "SSD" ]; then
        ejecutar_trim "$dispositivo" "$punto_montaje"
    else
        case "$tipo_fs" in
            ext4)
                analizar_ext4 "$punto_montaje"
                echo ""
                read -p "¿Desea proceder con la desfragmentación? (s/n): " proceder
                if [[ "$proceder" =~ ^[Ss]$ ]]; then
                    desfragmentar_ext4 "$punto_montaje"
                fi
                ;;
            btrfs)
                desfragmentar_btrfs "$punto_montaje"
                ;;
            xfs)
                desfragmentar_xfs "$punto_montaje"
                ;;
            fuseblk|ntfs|NTFS)
                optimizar_ntfs "$dispositivo" "$punto_montaje"
                ;;
        esac
    fi
}

# Ejecutar TRIM en todos los SSD
trim_todos_ssd() {
    echo -e "${YELLOW}Buscando SSD montados...${NC}"
    echo ""
    
    local ssd_encontrados=0
    
    while IFS= read -r linea; do
        local dispositivo=$(echo "$linea" | awk '{print $1}')
        local punto_montaje=$(echo "$linea" | awk '{print $3}')
        local tipo_disco=$(detectar_tipo_disco "$dispositivo")
        
        if [ "$tipo_disco" = "SSD" ]; then
            echo -e "${CYAN}SSD encontrado: $dispositivo ($punto_montaje)${NC}"
            ejecutar_trim "$dispositivo" "$punto_montaje"
            echo ""
            ((ssd_encontrados++))
        fi
    done < <(df -T | grep "^/dev")
    
    if [ $ssd_encontrados -eq 0 ]; then
        echo -e "${YELLOW}No se encontraron SSD montados${NC}"
    else
        echo -e "${GREEN}✓ TRIM ejecutado en $ssd_encontrados SSD(s)${NC}"
    fi
}

# Mostrar información del sistema
mostrar_info_sistema() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}INFORMACIÓN DEL SISTEMA${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GREEN}Distribución:${NC} $(detectar_distro)"
    echo ""
    echo -e "${YELLOW}Discos instalados:${NC}"
    lsblk -d -o NAME,SIZE,TYPE,MODEL | grep disk
    echo ""
    echo -e "${YELLOW}Uso de espacio:${NC}"
    df -h --output=source,fstype,size,used,avail,pcent,target | grep "^/dev"
    echo ""
}

# Menú principal
mostrar_menu() {
    clear
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}    OPTIMIZADOR DE DISCOS PARA LINUX${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "1) Optimizar/Desfragmentar partición específica"
    echo "2) Ejecutar TRIM en todos los SSD"
    echo "3) Analizar fragmentación (solo ext4)"
    echo "4) Mostrar información del sistema"
    echo "5) Instalar/Verificar herramientas"
    echo "6) Salir"
    echo ""
    echo -e "${YELLOW}Nota: Los SSD no necesitan desfragmentación tradicional.${NC}"
    echo -e "${YELLOW}      Use TRIM para mantener el rendimiento óptimo.${NC}"
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Programa principal
main() {
    verificar_root
    
    echo -e "${BLUE}Verificando herramientas...${NC}"
    instalar_herramientas
    echo ""
    
    while true; do
        mostrar_menu
        read -p "Seleccione una opción [1-6]: " opcion
        echo ""
        
        case "$opcion" in
            1)
                optimizar_particion
                ;;
            2)
                trim_todos_ssd
                ;;
            3)
                listar_particiones
                echo ""
                read -p "Seleccione partición ext4 para analizar [número]: " sel
                if [ ! -z "${particiones_map[$sel]}" ]; then
                    IFS='|' read -r disp pm fs td <<< "${particiones_map[$sel]}"
                    if [ "$fs" = "ext4" ]; then
                        analizar_ext4 "$pm"
                    else
                        echo -e "${RED}Solo ext4 soporta análisis de fragmentación${NC}"
                    fi
                fi
                ;;
            4)
                mostrar_info_sistema
                ;;
            5)
                instalar_herramientas
                ;;
            6)
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
