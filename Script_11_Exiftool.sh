#!/bin/bash

# Script para gestionar metadatos con ExifTool
# Compatible con: Ubuntu, Debian, Manjaro, Arch Linux
# Soporta: Imágenes, Videos, PDFs, Documentos
# Uso: ./exiftool_manager.sh

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
BACKUP_DIR="$HOME/.exiftool_backups"
mkdir -p "$BACKUP_DIR"

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

# Instalar ExifTool
instalar_exiftool() {
    local distro=$(detectar_distro)
    
    echo -e "${YELLOW}Instalando ExifTool...${NC}"
    echo ""
    
    case "$distro" in
        ubuntu|debian|linuxmint|pop)
            sudo apt update
            sudo apt install -y libimage-exiftool-perl
            ;;
        manjaro|arch|endeavouros|garuda)
            sudo pacman -Sy --noconfirm perl-image-exiftool
            ;;
        fedora|rhel|centos)
            sudo dnf install -y perl-Image-ExifTool
            ;;
        opensuse*)
            sudo zypper install -y exiftool
            ;;
        *)
            echo -e "${RED}Distribución no reconocida${NC}"
            echo "Instale ExifTool manualmente desde: https://exiftool.org/"
            return 1
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ ExifTool instalado exitosamente${NC}"
        return 0
    else
        echo -e "${RED}✗ Error al instalar ExifTool${NC}"
        return 1
    fi
}

# Verificar instalación
verificar_exiftool() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}VERIFICANDO EXIFTOOL${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if command -v exiftool &> /dev/null; then
        local version=$(exiftool -ver)
        echo -e "${GREEN}✓ ExifTool instalado: Versión $version${NC}"
        echo ""
        echo -e "${BLUE}Formatos soportados:${NC}"
        echo "  • Imágenes: JPG, PNG, GIF, TIFF, RAW, HEIC, WebP"
        echo "  • Videos: MP4, MOV, AVI, MKV, M4V"
        echo "  • Audio: MP3, WAV, FLAC, M4A"
        echo "  • Documentos: PDF, DOCX, XLSX, PPTX"
        echo "  • Y muchos más..."
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        return 0
    else
        echo -e "${RED}✗ ExifTool no está instalado${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        return 1
    fi
}

# Solicitar ruta
solicitar_ruta() {
    local tipo="$1"
    local ruta=""
    
    while true; do
        if [ "$tipo" = "archivo" ]; then
            echo -e "${BLUE}Ingrese la ruta del archivo:${NC}"
        else
            echo -e "${BLUE}Ingrese la ruta del directorio:${NC}"
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

# Ver metadatos de un archivo
ver_metadatos() {
    local archivo
    archivo=$(solicitar_ruta "archivo")
    
    if [ $? -ne 0 ] || [ -z "$archivo" ]; then
        return 1
    fi
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}METADATOS DEL ARCHIVO${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Archivo: $archivo${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    exiftool "$archivo"
    
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}¿Desea exportar estos metadatos?${NC}"
    echo "1) Exportar a TXT"
    echo "2) Exportar a JSON"
    echo "3) Exportar a HTML"
    echo "4) No exportar"
    read -p "Seleccione [1-4]: " exportar
    
    case "$exportar" in
        1)
            local output="${archivo}.metadata.txt"
            exiftool "$archivo" > "$output"
            echo -e "${GREEN}✓ Exportado a: $output${NC}"
            ;;
        2)
            local output="${archivo}.metadata.json"
            exiftool -json "$archivo" > "$output"
            echo -e "${GREEN}✓ Exportado a: $output${NC}"
            ;;
        3)
            local output="${archivo}.metadata.html"
            exiftool -h "$archivo" > "$output"
            echo -e "${GREEN}✓ Exportado a: $output${NC}"
            ;;
    esac
}

# Eliminar metadatos
eliminar_metadatos() {
    local archivo
    archivo=$(solicitar_ruta "archivo")
    
    if [ $? -ne 0 ] || [ -z "$archivo" ]; then
        return 1
    fi
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}ELIMINAR METADATOS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Archivo: $archivo${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}Metadatos actuales:${NC}"
    exiftool "$archivo" | head -20
    echo "..."
    echo ""
    echo -e "${RED}⚠ ADVERTENCIA: Esta acción eliminará TODOS los metadatos${NC}"
    echo -e "${YELLOW}Se creará un backup automático en: $BACKUP_DIR${NC}"
    echo ""
    read -p "¿Desea continuar? (s/n): " confirmar
    
    if [[ ! "$confirmar" =~ ^[Ss]$ ]]; then
        echo "Operación cancelada"
        return 0
    fi
    
    # Crear backup
    local nombre_archivo=$(basename "$archivo")
    local backup_file="$BACKUP_DIR/${nombre_archivo}_$(date +%Y%m%d_%H%M%S)"
    cp "$archivo" "$backup_file"
    echo -e "${GREEN}✓ Backup creado: $backup_file${NC}"
    echo ""
    
    # Eliminar metadatos
    echo -e "${YELLOW}Eliminando metadatos...${NC}"
    exiftool -all= -overwrite_original "$archivo"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Metadatos eliminados exitosamente${NC}"
        echo ""
        echo -e "${BLUE}Verificación - Metadatos restantes:${NC}"
        exiftool "$archivo" | head -10
    else
        echo -e "${RED}✗ Error al eliminar metadatos${NC}"
    fi
}

# Eliminar metadatos de ubicación (GPS)
eliminar_gps() {
    local archivo
    archivo=$(solicitar_ruta "archivo")
    
    if [ $? -ne 0 ] || [ -z "$archivo" ]; then
        return 1
    fi
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}ELIMINAR DATOS DE UBICACIÓN (GPS)${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Archivo: $archivo${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Verificar si tiene datos GPS
    local gps_data=$(exiftool -GPS* "$archivo" 2>/dev/null | grep -v "files read")
    
    if [ -z "$gps_data" ]; then
        echo -e "${YELLOW}Este archivo no contiene datos de GPS${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}Datos de GPS encontrados:${NC}"
    echo "$gps_data"
    echo ""
    
    read -p "¿Desea eliminar estos datos de ubicación? (s/n): " confirmar
    
    if [[ ! "$confirmar" =~ ^[Ss]$ ]]; then
        echo "Operación cancelada"
        return 0
    fi
    
    # Crear backup
    local nombre_archivo=$(basename "$archivo")
    local backup_file="$BACKUP_DIR/${nombre_archivo}_$(date +%Y%m%d_%H%M%S)"
    cp "$archivo" "$backup_file"
    
    # Eliminar datos GPS
    exiftool -GPS*= -overwrite_original "$archivo"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Datos de GPS eliminados exitosamente${NC}"
        echo -e "${GREEN}✓ Backup guardado: $backup_file${NC}"
    else
        echo -e "${RED}✗ Error al eliminar datos GPS${NC}"
    fi
}

# Modificar metadatos específicos
modificar_metadatos() {
    local archivo
    archivo=$(solicitar_ruta "archivo")
    
    if [ $? -ne 0 ] || [ -z "$archivo" ]; then
        return 1
    fi
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}MODIFICAR METADATOS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Archivo: $archivo${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}¿Qué desea modificar?${NC}"
    echo "1) Autor/Artista"
    echo "2) Título"
    echo "3) Copyright"
    echo "4) Descripción/Comentario"
    echo "5) Fecha de creación"
    echo "6) Otro (campo personalizado)"
    echo "7) Cancelar"
    echo ""
    read -p "Seleccione [1-7]: " opcion
    
    case "$opcion" in
        1)
            read -p "Ingrese el nombre del autor: " valor
            exiftool -Artist="$valor" -overwrite_original "$archivo"
            echo -e "${GREEN}✓ Autor actualizado${NC}"
            ;;
        2)
            read -p "Ingrese el título: " valor
            exiftool -Title="$valor" -overwrite_original "$archivo"
            echo -e "${GREEN}✓ Título actualizado${NC}"
            ;;
        3)
            read -p "Ingrese el copyright: " valor
            exiftool -Copyright="$valor" -overwrite_original "$archivo"
            echo -e "${GREEN}✓ Copyright actualizado${NC}"
            ;;
        4)
            read -p "Ingrese la descripción: " valor
            exiftool -Description="$valor" -overwrite_original "$archivo"
            echo -e "${GREEN}✓ Descripción actualizada${NC}"
            ;;
        5)
            echo "Formato: YYYY:MM:DD HH:MM:SS (ejemplo: 2024:01:15 14:30:00)"
            read -p "Ingrese la fecha: " valor
            exiftool -DateTimeOriginal="$valor" -overwrite_original "$archivo"
            echo -e "${GREEN}✓ Fecha actualizada${NC}"
            ;;
        6)
            read -p "Ingrese el nombre del campo (ej: Keywords): " campo
            read -p "Ingrese el valor: " valor
            exiftool -"$campo"="$valor" -overwrite_original "$archivo"
            echo -e "${GREEN}✓ Campo actualizado${NC}"
            ;;
        7)
            echo "Operación cancelada"
            return 0
            ;;
        *)
            echo -e "${RED}Opción inválida${NC}"
            return 1
            ;;
    esac
}

# Procesar directorio completo
procesar_directorio() {
    local directorio
    directorio=$(solicitar_ruta "directorio")
    
    if [ $? -ne 0 ] || [ -z "$directorio" ]; then
        return 1
    fi
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}PROCESAR DIRECTORIO${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Directorio: $directorio${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}¿Qué operación desea realizar?${NC}"
    echo "1) Ver metadatos de todos los archivos"
    echo "2) Eliminar todos los metadatos"
    echo "3) Eliminar solo datos GPS de todas las imágenes"
    echo "4) Exportar metadatos a CSV"
    echo "5) Cancelar"
    echo ""
    read -p "Seleccione [1-5]: " opcion
    
    case "$opcion" in
        1)
            echo ""
            exiftool -r "$directorio"
            ;;
        2)
            echo ""
            echo -e "${RED}⚠ ADVERTENCIA: Eliminará metadatos de TODOS los archivos${NC}"
            read -p "¿Está seguro? (s/n): " confirmar
            if [[ "$confirmar" =~ ^[Ss]$ ]]; then
                # Crear backup del directorio
                local backup_name="backup_$(basename "$directorio")_$(date +%Y%m%d_%H%M%S)"
                echo -e "${YELLOW}Creando backup...${NC}"
                cp -r "$directorio" "$BACKUP_DIR/$backup_name"
                echo -e "${GREEN}✓ Backup creado: $BACKUP_DIR/$backup_name${NC}"
                echo ""
                
                exiftool -all= -overwrite_original -r "$directorio"
                echo -e "${GREEN}✓ Metadatos eliminados de todos los archivos${NC}"
            fi
            ;;
        3)
            echo ""
            exiftool -GPS*= -overwrite_original -r "$directorio"
            echo -e "${GREEN}✓ Datos GPS eliminados de todas las imágenes${NC}"
            ;;
        4)
            local output="$directorio/metadata_export_$(date +%Y%m%d_%H%M%S).csv"
            exiftool -csv -r "$directorio" > "$output"
            echo -e "${GREEN}✓ Metadatos exportados a: $output${NC}"
            ;;
        5)
            echo "Operación cancelada"
            return 0
            ;;
        *)
            echo -e "${RED}Opción inválida${NC}"
            ;;
    esac
}

# Comparar metadatos de dos archivos
comparar_archivos() {
    echo -e "${BLUE}Primer archivo:${NC}"
    local archivo1
    archivo1=$(solicitar_ruta "archivo")
    
    if [ $? -ne 0 ] || [ -z "$archivo1" ]; then
        return 1
    fi
    
    echo ""
    echo -e "${BLUE}Segundo archivo:${NC}"
    local archivo2
    archivo2=$(solicitar_ruta "archivo")
    
    if [ $? -ne 0 ] || [ -z "$archivo2" ]; then
        return 1
    fi
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}COMPARACIÓN DE METADATOS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Archivo 1: $archivo1${NC}"
    echo -e "${BLUE}Archivo 2: $archivo2${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Crear archivos temporales con metadatos
    local temp1=$(mktemp)
    local temp2=$(mktemp)
    
    exiftool "$archivo1" > "$temp1"
    exiftool "$archivo2" > "$temp2"
    
    # Mostrar diferencias
    echo -e "${YELLOW}Diferencias encontradas:${NC}"
    diff -y --suppress-common-lines "$temp1" "$temp2" || true
    
    # Limpiar archivos temporales
    rm "$temp1" "$temp2"
}

# Copiar metadatos entre archivos
copiar_metadatos() {
    echo -e "${BLUE}Archivo origen (copiar desde):${NC}"
    local origen
    origen=$(solicitar_ruta "archivo")
    
    if [ $? -ne 0 ] || [ -z "$origen" ]; then
        return 1
    fi
    
    echo ""
    echo -e "${BLUE}Archivo destino (copiar hacia):${NC}"
    local destino
    destino=$(solicitar_ruta "archivo")
    
    if [ $? -ne 0 ] || [ -z "$destino" ]; then
        return 1
    fi
    
    echo ""
    echo -e "${YELLOW}Copiando metadatos...${NC}"
    exiftool -TagsFromFile "$origen" -all:all -overwrite_original "$destino"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Metadatos copiados exitosamente${NC}"
    else
        echo -e "${RED}✗ Error al copiar metadatos${NC}"
    fi
}

# Ver backups
ver_backups() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}ARCHIVOS DE BACKUP${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Directorio: $BACKUP_DIR${NC}"
    echo ""
    
    if [ "$(ls -A $BACKUP_DIR 2>/dev/null)" ]; then
        ls -lhtr "$BACKUP_DIR"
        echo ""
        local size=$(du -sh "$BACKUP_DIR" | cut -f1)
        echo -e "${BLUE}Tamaño total: $size${NC}"
        echo ""
        read -p "¿Desea limpiar backups antiguos (>30 días)? (s/n): " limpiar
        if [[ "$limpiar" =~ ^[Ss]$ ]]; then
            find "$BACKUP_DIR" -type f -mtime +30 -delete
            echo -e "${GREEN}✓ Backups antiguos eliminados${NC}"
        fi
    else
        echo -e "${YELLOW}No hay backups disponibles${NC}"
    fi
}

# Menú principal
mostrar_menu() {
    clear
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}    GESTOR DE METADATOS - EXIFTOOL${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo " 1) Ver metadatos de un archivo"
    echo " 2) Eliminar todos los metadatos"
    echo " 3) Eliminar solo datos de ubicación (GPS)"
    echo " 4) Modificar metadatos específicos"
    echo " 5) Procesar directorio completo"
    echo " 6) Comparar metadatos de dos archivos"
    echo " 7) Copiar metadatos entre archivos"
    echo " 8) Ver archivos de backup"
    echo " 9) Verificar/Instalar ExifTool"
    echo "10) Salir"
    echo ""
    echo -e "${BLUE}Backups: ${YELLOW}$BACKUP_DIR${NC}"
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Programa principal
main() {
    # Verificar instalación
    if ! command -v exiftool &> /dev/null; then
        echo -e "${YELLOW}ExifTool no está instalado${NC}"
        read -p "¿Desea instalarlo ahora? (s/n): " instalar
        if [[ "$instalar" =~ ^[Ss]$ ]]; then
            instalar_exiftool
        else
            echo -e "${RED}No se puede continuar sin ExifTool${NC}"
            exit 1
        fi
    fi
    
    while true; do
        mostrar_menu
        read -p "Seleccione una opción [1-10]: " opcion
        echo ""
        
        case "$opcion" in
            1)
                ver_metadatos
                ;;
            2)
                eliminar_metadatos
                ;;
            3)
                eliminar_gps
                ;;
            4)
                modificar_metadatos
                ;;
            5)
                procesar_directorio
                ;;
            6)
                comparar_archivos
                ;;
            7)
                copiar_metadatos
                ;;
            8)
                ver_backups
                ;;
            9)
                verificar_exiftool
                if [ $? -ne 0 ]; then
                    read -p "¿Desea instalar ExifTool? (s/n): " inst
                    if [[ "$inst" =~ ^[Ss]$ ]]; then
                        instalar_exiftool
                    fi
                fi
                ;;
            10)
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
