#!/bin/bash

# Script para actualizar librerías de Python
# Compatible con pip, pip3 y entornos virtuales

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Función para mostrar menú
show_menu() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  Actualizador de Librerías Python     ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}\n"
    echo -e "${YELLOW}1)${NC} Actualizar pip/pip3"
    echo -e "${YELLOW}2)${NC} Actualizar TODAS las librerías (Python 3)"
    echo -e "${YELLOW}3)${NC} Actualizar librerías seleccionadas"
    echo -e "${YELLOW}4)${NC} Ver librerías desactualizadas"
    echo -e "${YELLOW}5)${NC} Ver todas las librerías instaladas"
    echo -e "${YELLOW}6)${NC} Actualizar desde requirements.txt"
    echo -e "${YELLOW}7)${NC} Generar requirements.txt actualizado"
    echo -e "${YELLOW}8)${NC} Buscar una librería específica"
    echo -e "${YELLOW}9)${NC} Limpiar caché de pip"
    echo -e "${YELLOW}0)${NC} Salir\n"
    echo -n "Selecciona una opción: "
}

# Verificar si pip está instalado
check_pip() {
    if ! command -v pip3 &> /dev/null; then
        echo -e "${RED}Error: pip3 no está instalado${NC}"
        echo -e "${YELLOW}Instálalo con: sudo apt install python3-pip (Ubuntu/Debian)${NC}"
        exit 1
    fi
}

# Función para actualizar pip
update_pip() {
    echo -e "\n${GREEN}=== Actualizando pip ===${NC}\n"
    python3 -m pip install --upgrade pip
    echo -e "\n${GREEN}✓ pip actualizado${NC}"
}

# Función para actualizar todas las librerías
update_all_packages() {
    echo -e "\n${GREEN}=== Actualizando TODAS las librerías ===${NC}\n"
    echo -e "${YELLOW}Esto puede tardar varios minutos...${NC}\n"
    
    # Obtener lista de paquetes desactualizados
    pip3 list --outdated --format=freeze | cut -d = -f 1 > /tmp/outdated_packages.txt
    
    # Contar paquetes
    total=$(wc -l < /tmp/outdated_packages.txt)
    
    if [ $total -eq 0 ]; then
        echo -e "${GREEN}¡Todas las librerías están actualizadas!${NC}"
        return
    fi
    
    echo -e "${CYAN}Se actualizarán $total paquetes${NC}\n"
    
    # Actualizar cada paquete
    while read package; do
        echo -e "${BLUE}Actualizando: $package${NC}"
        pip3 install --upgrade "$package"
    done < /tmp/outdated_packages.txt
    
    rm /tmp/outdated_packages.txt
    echo -e "\n${GREEN}✓ Todas las librerías actualizadas${NC}"
}

# Función para actualizar librerías específicas
update_selected_packages() {
    echo -e "\n${GREEN}=== Actualizar Librerías Específicas ===${NC}\n"
    echo -n "Ingresa los nombres de las librerías separados por espacios: "
    read packages
    
    for pkg in $packages; do
        echo -e "\n${BLUE}Actualizando: $pkg${NC}"
        pip3 install --upgrade "$pkg"
    done
    
    echo -e "\n${GREEN}✓ Actualización completada${NC}"
}

# Función para ver librerías desactualizadas
view_outdated() {
    echo -e "\n${GREEN}=== Librerías Desactualizadas ===${NC}\n"
    pip3 list --outdated
}

# Función para ver todas las librerías
view_all_packages() {
    echo -e "\n${GREEN}=== Todas las Librerías Instaladas ===${NC}\n"
    echo -e "${CYAN}Total de paquetes: $(pip3 list | tail -n +3 | wc -l)${NC}\n"
    pip3 list
}

# Función para actualizar desde requirements.txt
update_from_requirements() {
    echo -e "\n${GREEN}=== Actualizar desde requirements.txt ===${NC}\n"
    
    if [ -f "requirements.txt" ]; then
        echo -e "${CYAN}Archivo requirements.txt encontrado${NC}\n"
        pip3 install --upgrade -r requirements.txt
        echo -e "\n${GREEN}✓ Librerías actualizadas desde requirements.txt${NC}"
    else
        echo -n "Ingresa la ruta al archivo requirements.txt: "
        read req_file
        if [ -f "$req_file" ]; then
            pip3 install --upgrade -r "$req_file"
            echo -e "\n${GREEN}✓ Librerías actualizadas${NC}"
        else
            echo -e "${RED}Error: Archivo no encontrado${NC}"
        fi
    fi
}

# Función para generar requirements.txt
generate_requirements() {
    echo -e "\n${GREEN}=== Generar requirements.txt ===${NC}\n"
    echo -n "¿Incluir versiones exactas? (s/n): "
    read include_versions
    
    if [ "$include_versions" = "s" ] || [ "$include_versions" = "S" ]; then
        pip3 freeze > requirements.txt
        echo -e "${GREEN}✓ requirements.txt generado con versiones exactas${NC}"
    else
        pip3 list --format=freeze | cut -d = -f 1 > requirements.txt
        echo -e "${GREEN}✓ requirements.txt generado sin versiones${NC}"
    fi
    
    echo -e "${CYAN}Archivo guardado en: $(pwd)/requirements.txt${NC}"
}

# Función para buscar una librería
search_package() {
    echo -e "\n${GREEN}=== Buscar Librería ===${NC}\n"
    echo -n "Ingresa el nombre de la librería: "
    read pkg_name
    echo -e "\n${CYAN}Buscando '$pkg_name'...${NC}\n"
    pip3 search "$pkg_name" 2>/dev/null || pip3 list | grep -i "$pkg_name"
}

# Función para limpiar caché
clean_cache() {
    echo -e "\n${GREEN}=== Limpiando caché de pip ===${NC}\n"
    pip3 cache purge
    echo -e "${GREEN}✓ Caché limpiado${NC}"
}

# Verificar pip antes de iniciar
check_pip

# Bucle principal
while true; do
    show_menu
    read option
    case $option in
        1) update_pip ;;
        2) update_all_packages ;;
        3) update_selected_packages ;;
        4) view_outdated ;;
        5) view_all_packages ;;
        6) update_from_requirements ;;
        7) generate_requirements ;;
        8) search_package ;;
        9) clean_cache ;;
        0) echo -e "\n${GREEN}¡Hasta luego!${NC}\n"; exit 0 ;;
        *) echo -e "\n${RED}Opción inválida${NC}" ;;
    esac
    echo -e "\n${YELLOW}Presiona Enter para continuar...${NC}"
    read
done
