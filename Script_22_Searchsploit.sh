#!/bin/bash

# Script básico para usar searchsploit

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # Sin color

# Verificar si searchsploit está instalado
if ! command -v searchsploit &> /dev/null; then
    echo -e "${RED}Error: searchsploit no está instalado${NC}"
    echo "Instálalo con: sudo apt install exploitdb"
    exit 1
fi

# Función de ayuda
mostrar_ayuda() {
    echo -e "${GREEN}Uso del script:${NC}"
    echo "  $0 <término_búsqueda>"
    echo "  $0 -u                  # Actualizar base de datos"
    echo "  $0 -h                  # Mostrar esta ayuda"
}

# Actualizar base de datos
actualizar_db() {
    echo -e "${YELLOW}Actualizando base de datos de exploits...${NC}"
    searchsploit -u
}

# Buscar exploit
buscar_exploit() {
    local termino="$1"
    echo -e "${GREEN}Buscando exploits para: ${YELLOW}$termino${NC}"
    echo "----------------------------------------"
    searchsploit "$termino"
}

# Menú principal
case "$1" in
    -h|--help)
        mostrar_ayuda
        ;;
    -u|--update)
        actualizar_db
        ;;
    "")
        echo -e "${RED}Error: Debes proporcionar un término de búsqueda${NC}"
        mostrar_ayuda
        exit 1
        ;;
    *)
        buscar_exploit "$*"
        ;;
esac
