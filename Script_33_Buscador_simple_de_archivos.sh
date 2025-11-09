#!/bin/bash

# Script simple para buscar archivos por tipo
# Uso: ./buscar_simple.sh

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

mostrar_menu() {
    clear
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}    BUSCADOR SIMPLE DE ARCHIVOS   ${NC}"
    echo -e "${GREEN}================================${NC}"
    echo ""
    echo -e "${YELLOW}¿Qué tipo de archivos buscas?${NC}"
    echo ""
    echo -e "  ${GREEN}1${NC}) Imágenes (jpg, png, gif, webp)"
    echo -e "  ${GREEN}2${NC}) Videos (mp4, avi, mkv, mov)"
    echo -e "  ${GREEN}3${NC}) Música (mp3, wav, flac, ogg)"
    echo -e "  ${GREEN}4${NC}) Documentos (pdf, doc, docx, txt)"
    echo -e "  ${GREEN}5${NC}) Archivos comprimidos (zip, rar, tar)"
    echo -e "  ${GREEN}6${NC}) Scripts (sh, bash, py, js)"
    echo -e "  ${GREEN}7${NC}) Buscar por extensión específica"
    echo -e "  ${GREEN}8${NC}) Buscar por nombre"
    echo -e "  ${GREEN}0${NC}) Salir"
    echo ""
}

buscar_imagenes() {
    echo -e "${BLUE}Buscando imágenes...${NC}"
    find . -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" -o -name "*.webp" -o -name "*.bmp" \) 2>/dev/null
}

buscar_videos() {
    echo -e "${BLUE}Buscando videos...${NC}"
    find . -type f \( -name "*.mp4" -o -name "*.avi" -o -name "*.mkv" -o -name "*.mov" -o -name "*.wmv" -o -name "*.flv" -o -name "*.webm" \) 2>/dev/null
}

buscar_musica() {
    echo -e "${BLUE}Buscando música...${NC}"
    find . -type f \( -name "*.mp3" -o -name "*.wav" -o -name "*.flac" -o -name "*.ogg" -o -name "*.m4a" -o -name "*.aac" \) 2>/dev/null
}

buscar_documentos() {
    echo -e "${BLUE}Buscando documentos...${NC}"
    find . -type f \( -name "*.pdf" -o -name "*.doc" -o -name "*.docx" -o -name "*.txt" -o -name "*.odt" -o -name "*.rtf" -o -name "*.xls" -o -name "*.xlsx" -o -name "*.ppt" -o -name "*.pptx" \) 2>/dev/null
}

buscar_comprimidos() {
    echo -e "${BLUE}Buscando archivos comprimidos...${NC}"
    find . -type f \( -name "*.zip" -o -name "*.rar" -o -name "*.tar" -o -name "*.gz" -o -name "*.7z" -o -name "*.tar.gz" \) 2>/dev/null
}

buscar_scripts() {
    echo -e "${BLUE}Buscando scripts...${NC}"
    find . -type f \( -name "*.sh" -o -name "*.bash" -o -name "*.py" -o -name "*.js" -o -name "*.php" -o -name "*.rb" \) 2>/dev/null
}

buscar_por_extension() {
    echo -n "¿Qué extensión buscas? (ej: pdf, txt, jpg): "
    read extension
    if [ -n "$extension" ]; then
        echo -e "${BLUE}Buscando .$extension ...${NC}"
        find . -type f -name "*.$extension" 2>/dev/null
    else
        echo -e "${RED}No ingresaste una extensión${NC}"
    fi
}

buscar_por_nombre() {
    echo -n "¿Qué nombre buscas? (puedes usar * como comodín): "
    read nombre
    if [ -n "$nombre" ]; then
        echo -e "${BLUE}Buscando: $nombre ${NC}"
        find . -type f -name "$nombre" 2>/dev/null
    else
        echo -e "${RED}No ingresaste un nombre${NC}"
    fi
}

contar_resultados() {
    local resultados=$1
    local contador=$(echo "$resultados" | grep -c "^")
    echo -e "${YELLOW}Se encontraron $contador archivos${NC}"
}

while true; do
    mostrar_menu
    echo -n "Selecciona una opción: "
    read opcion
    
    case $opcion in
        1)
            resultados=$(buscar_imagenes)
            echo "$resultados"
            contar_resultados "$resultados"
            ;;
        2)
            resultados=$(buscar_videos)
            echo "$resultados"
            contar_resultados "$resultados"
            ;;
        3)
            resultados=$(buscar_musica)
            echo "$resultados"
            contar_resultados "$resultados"
            ;;
        4)
            resultados=$(buscar_documentos)
            echo "$resultados"
            contar_resultados "$resultados"
            ;;
        5)
            resultados=$(buscar_comprimidos)
            echo "$resultados"
            contar_resultados "$resultados"
            ;;
        6)
            resultados=$(buscar_scripts)
            echo "$resultados"
            contar_resultados "$resultados"
            ;;
        7)
            buscar_por_extension
            ;;
        8)
            buscar_por_nombre
            ;;
        0)
            echo -e "${GREEN}¡Hasta luego!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Opción inválida${NC}"
            ;;
    esac
    
    echo ""
    echo -n "Presiona Enter para continuar..."
    read
done
