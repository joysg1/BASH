#!/bin/bash

# Script universal para descomprimir archivos
# Soporta múltiples formatos de compresión

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Función para mostrar banner
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════╗"
    echo "║     Descompresor Universal                ║"
    echo "║     Soporta múltiples formatos            ║"
    echo "╚═══════════════════════════════════════════╝"
    echo -e "${NC}\n"
}

# Función para mostrar menú
show_menu() {
    show_banner
    echo -e "${YELLOW}1)${NC} Descomprimir un archivo específico"
    echo -e "${YELLOW}2)${NC} Descomprimir múltiples archivos"
    echo -e "${YELLOW}3)${NC} Descomprimir todos los archivos del directorio actual"
    echo -e "${YELLOW}4)${NC} Descomprimir y crear carpeta automáticamente"
    echo -e "${YELLOW}5)${NC} Listar contenido sin descomprimir"
    echo -e "${YELLOW}6)${NC} Ver formatos soportados"
    echo -e "${YELLOW}7)${NC} Verificar dependencias"
    echo -e "${YELLOW}0)${NC} Salir\n"
    echo -n "Selecciona una opción: "
}

# Función para verificar si existe el archivo
check_file() {
    if [ ! -f "$1" ]; then
        echo -e "${RED}Error: El archivo '$1' no existe${NC}"
        return 1
    fi
    return 0
}

# Función principal de descompresión
decompress_file() {
    local file="$1"
    local output_dir="$2"
    
    check_file "$file" || return 1
    
    # Extraer a directorio específico si se proporciona
    local extract_cmd=""
    if [ -n "$output_dir" ]; then
        mkdir -p "$output_dir"
        echo -e "${CYAN}Extrayendo a: $output_dir${NC}"
    fi
    
    echo -e "${GREEN}Descomprimiendo: ${YELLOW}$file${NC}"
    
    case "$file" in
        *.tar.bz2|*.tbz2|*.tb2)
            if [ -n "$output_dir" ]; then
                tar xjf "$file" -C "$output_dir"
            else
                tar xjf "$file"
            fi
            ;;
        *.tar.gz|*.tgz)
            if [ -n "$output_dir" ]; then
                tar xzf "$file" -C "$output_dir"
            else
                tar xzf "$file"
            fi
            ;;
        *.tar.xz|*.txz)
            if [ -n "$output_dir" ]; then
                tar xJf "$file" -C "$output_dir"
            else
                tar xJf "$file"
            fi
            ;;
        *.tar)
            if [ -n "$output_dir" ]; then
                tar xf "$file" -C "$output_dir"
            else
                tar xf "$file"
            fi
            ;;
        *.bz2)
            bunzip2 "$file"
            ;;
        *.gz)
            gunzip "$file"
            ;;
        *.zip)
            if [ -n "$output_dir" ]; then
                unzip -q "$file" -d "$output_dir"
            else
                unzip -q "$file"
            fi
            ;;
        *.rar)
            if command -v unrar &> /dev/null; then
                if [ -n "$output_dir" ]; then
                    unrar x "$file" "$output_dir/"
                else
                    unrar x "$file"
                fi
            else
                echo -e "${RED}Error: unrar no está instalado${NC}"
                return 1
            fi
            ;;
        *.7z)
            if command -v 7z &> /dev/null; then
                if [ -n "$output_dir" ]; then
                    7z x "$file" -o"$output_dir"
                else
                    7z x "$file"
                fi
            else
                echo -e "${RED}Error: 7z no está instalado${NC}"
                return 1
            fi
            ;;
        *.xz)
            unxz "$file"
            ;;
        *.Z)
            uncompress "$file"
            ;;
        *.lz)
            if command -v lzip &> /dev/null; then
                lzip -d "$file"
            else
                echo -e "${RED}Error: lzip no está instalado${NC}"
                return 1
            fi
            ;;
        *.lzma)
            unlzma "$file"
            ;;
        *.zst|*.zstd)
            if command -v zstd &> /dev/null; then
                zstd -d "$file"
            else
                echo -e "${RED}Error: zstd no está instalado${NC}"
                return 1
            fi
            ;;
        *.cab)
            if command -v cabextract &> /dev/null; then
                if [ -n "$output_dir" ]; then
                    cabextract -d "$output_dir" "$file"
                else
                    cabextract "$file"
                fi
            else
                echo -e "${RED}Error: cabextract no está instalado${NC}"
                return 1
            fi
            ;;
        *.deb)
            if [ -n "$output_dir" ]; then
                dpkg-deb -x "$file" "$output_dir"
            else
                dpkg-deb -x "$file" .
            fi
            ;;
        *.rpm)
            if command -v rpm2cpio &> /dev/null; then
                if [ -n "$output_dir" ]; then
                    mkdir -p "$output_dir"
                    cd "$output_dir" && rpm2cpio "../$file" | cpio -idmv && cd ..
                else
                    rpm2cpio "$file" | cpio -idmv
                fi
            else
                echo -e "${RED}Error: rpm2cpio no está instalado${NC}"
                return 1
            fi
            ;;
        *)
            echo -e "${RED}Error: Formato no soportado: $file${NC}"
            return 1
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Descompresión exitosa${NC}"
    else
        echo -e "${RED}✗ Error al descomprimir${NC}"
        return 1
    fi
}

# 1. Descomprimir archivo específico
decompress_single() {
    echo -n "Ingresa la ruta del archivo: "
    read file
    
    echo -n "¿Deseas especificar un directorio de salida? (s/n): "
    read use_output
    
    if [ "$use_output" = "s" ] || [ "$use_output" = "S" ]; then
        echo -n "Ingresa el directorio de salida: "
        read output_dir
        decompress_file "$file" "$output_dir"
    else
        decompress_file "$file"
    fi
}

# 2. Descomprimir múltiples archivos
decompress_multiple() {
    echo -n "Ingresa las rutas de los archivos separadas por espacios: "
    read -a files
    
    for file in "${files[@]}"; do
        echo ""
        decompress_file "$file"
    done
}

# 3. Descomprimir todos los archivos del directorio
decompress_all() {
    echo -e "${CYAN}Buscando archivos comprimidos en el directorio actual...${NC}\n"
    
    local count=0
    for file in *.{tar.gz,tar.bz2,tar.xz,zip,rar,7z,gz,bz2,xz,tgz,tbz2}; do
        if [ -f "$file" ]; then
            echo ""
            decompress_file "$file"
            ((count++))
        fi
    done
    
    if [ $count -eq 0 ]; then
        echo -e "${YELLOW}No se encontraron archivos comprimidos${NC}"
    else
        echo -e "\n${GREEN}Total de archivos descomprimidos: $count${NC}"
    fi
}

# 4. Descomprimir creando carpeta automáticamente
decompress_auto_folder() {
    echo -n "Ingresa la ruta del archivo: "
    read file
    
    check_file "$file" || return
    
    # Crear nombre de carpeta basado en el archivo
    local filename=$(basename "$file")
    local dirname="${filename%.*}"
    
    # Para archivos .tar.gz, .tar.bz2, etc., quitar ambas extensiones
    if [[ "$filename" =~ \.tar\. ]]; then
        dirname="${filename%.tar.*}"
    fi
    
    echo -e "${CYAN}Creando carpeta: $dirname${NC}"
    decompress_file "$file" "$dirname"
}

# 5. Listar contenido sin descomprimir
list_content() {
    echo -n "Ingresa la ruta del archivo: "
    read file
    
    check_file "$file" || return
    
    echo -e "\n${GREEN}Contenido de: ${YELLOW}$file${NC}\n"
    
    case "$file" in
        *.tar.bz2|*.tbz2|*.tb2|*.tar.gz|*.tgz|*.tar.xz|*.txz|*.tar)
            tar -tf "$file"
            ;;
        *.zip)
            unzip -l "$file"
            ;;
        *.rar)
            unrar l "$file"
            ;;
        *.7z)
            7z l "$file"
            ;;
        *)
            echo -e "${RED}No se puede listar el contenido de este formato${NC}"
            ;;
    esac
}

# 6. Ver formatos soportados
show_formats() {
    echo -e "\n${GREEN}=== Formatos Soportados ===${NC}\n"
    echo -e "${CYAN}Archivos TAR:${NC}"
    echo "  .tar.gz, .tgz"
    echo "  .tar.bz2, .tbz2, .tb2"
    echo "  .tar.xz, .txz"
    echo "  .tar"
    echo -e "\n${CYAN}Archivos comprimidos:${NC}"
    echo "  .gz (gzip)"
    echo "  .bz2 (bzip2)"
    echo "  .xz (xz)"
    echo "  .Z (compress)"
    echo "  .lz (lzip)"
    echo "  .lzma"
    echo "  .zst, .zstd (zstandard)"
    echo -e "\n${CYAN}Archivos:${NC}"
    echo "  .zip"
    echo "  .rar"
    echo "  .7z"
    echo "  .cab"
    echo "  .deb"
    echo "  .rpm"
}

# 7. Verificar dependencias
check_dependencies() {
    echo -e "\n${GREEN}=== Verificando Herramientas ===${NC}\n"
    
    local tools=("tar" "gzip" "bzip2" "xz" "unzip" "unrar" "7z" "zstd" "lzip" "cabextract" "rpm2cpio")
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            echo -e "${GREEN}✓${NC} $tool instalado"
        else
            echo -e "${RED}✗${NC} $tool NO instalado"
        fi
    done
    
    echo -e "\n${YELLOW}Comandos de instalación:${NC}"
    echo -e "${CYAN}Ubuntu/Debian:${NC}"
    echo "  sudo apt install tar gzip bzip2 xz-utils unzip unrar p7zip-full zstd lzip cabextract rpm2cpio"
    echo -e "${CYAN}Fedora:${NC}"
    echo "  sudo dnf install tar gzip bzip2 xz unzip unrar p7zip zstd lzip cabextract rpm"
    echo -e "${CYAN}Arch:${NC}"
    echo "  sudo pacman -S tar gzip bzip2 xz unzip unrar p7zip zstd lzip cabextract rpm-tools"
}

# Bucle principal
while true; do
    show_menu
    read option
    case $option in
        1) decompress_single ;;
        2) decompress_multiple ;;
        3) decompress_all ;;
        4) decompress_auto_folder ;;
        5) list_content ;;
        6) show_formats ;;
        7) check_dependencies ;;
        0) echo -e "\n${GREEN}¡Hasta luego!${NC}\n"; exit 0 ;;
        *) echo -e "\n${RED}Opción inválida${NC}" ;;
    esac
    echo -e "\n${YELLOW}Presiona Enter para continuar...${NC}"
    read
done
