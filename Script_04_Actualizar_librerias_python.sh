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

# Variable global para --break-system-packages
USE_BREAK_SYSTEM=""

# Función para mostrar menú
show_menu() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  Actualizador de Librerías Python     ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}\n"
    echo -e "${YELLOW}1)${NC} Actualizar pip/pip3"
    echo -e "${YELLOW}2)${NC} Actualizar TODAS las librerías (Python 3)"
    echo -e "${YELLOW}3)${NC} Actualizar TODAS (método rápido con xargs)"
    echo -e "${YELLOW}4)${NC} Actualizar librerías seleccionadas"
    echo -e "${YELLOW}5)${NC} Ver librerías desactualizadas"
    echo -e "${YELLOW}6)${NC} Ver todas las librerías instaladas"
    echo -e "${YELLOW}7)${NC} Actualizar desde requirements.txt"
    echo -e "${YELLOW}8)${NC} Generar requirements.txt actualizado"
    echo -e "${YELLOW}9)${NC} Buscar una librería específica"
    echo -e "${YELLOW}10)${NC} Limpiar caché de pip"
    echo -e "${YELLOW}11)${NC} Configurar --break-system-packages"
    echo -e "${YELLOW}0)${NC} Salir\n"
    
    if [ "$USE_BREAK_SYSTEM" = "--break-system-packages" ]; then
        echo -e "${CYAN}[Modo actual: --break-system-packages ACTIVADO]${NC}\n"
    else
        echo -e "${CYAN}[Modo actual: instalación normal]${NC}\n"
    fi
    
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

# Función para configurar --break-system-packages
configure_break_system() {
    echo -e "\n${GREEN}=== Configurar --break-system-packages ===${NC}\n"
    echo -e "${YELLOW}Información:${NC}"
    echo -e "Este flag es necesario en sistemas Linux modernos (Debian 12+, Ubuntu 23.04+)"
    echo -e "que usan PEP 668 para proteger paquetes del sistema.\n"
    echo -e "${CYAN}¿Deseas ACTIVAR --break-system-packages?${NC}"
    echo -e "1) Sí, activar (recomendado si obtienes errores 'externally-managed')"
    echo -e "2) No, usar instalación normal"
    echo -n "Selecciona: "
    read choice
    
    case $choice in
        1)
            USE_BREAK_SYSTEM="--break-system-packages"
            echo -e "\n${GREEN}✓ --break-system-packages ACTIVADO${NC}"
            ;;
        2)
            USE_BREAK_SYSTEM=""
            echo -e "\n${GREEN}✓ Modo normal activado${NC}"
            ;;
        *)
            echo -e "\n${RED}Opción inválida${NC}"
            ;;
    esac
}

# Función para actualizar pip
update_pip() {
    echo -e "\n${GREEN}=== Actualizando pip ===${NC}\n"
    python3 -m pip install --upgrade pip $USE_BREAK_SYSTEM
    echo -e "\n${GREEN}✓ pip actualizado${NC}"
}

# Función para actualizar todas las librerías (método original)
update_all_packages() {
    echo -e "\n${GREEN}=== Actualizando TODAS las librerías ===${NC}\n"
    echo -e "${YELLOW}Esto puede tardar varios minutos...${NC}\n"
    
    # Obtener lista de paquetes desactualizados (sin formato freeze)
    pip3 list --outdated | tail -n +3 | awk '{print $1}' > /tmp/outdated_packages.txt
    
    # Contar paquetes
    total=$(wc -l < /tmp/outdated_packages.txt)
    
    if [ $total -eq 0 ]; then
        echo -e "${GREEN}¡Todas las librerías están actualizadas!${NC}"
        return
    fi
    
    echo -e "${CYAN}Se actualizarán $total paquetes${NC}\n"
    
    # Actualizar cada paquete
    while read package; do
        if [ ! -z "$package" ]; then
            echo -e "${BLUE}Actualizando: $package${NC}"
            pip3 install --upgrade "$package" $USE_BREAK_SYSTEM
        fi
    done < /tmp/outdated_packages.txt
    
    rm /tmp/outdated_packages.txt
    echo -e "\n${GREEN}✓ Todas las librerías actualizadas${NC}"
}

# Función para actualizar todas las librerías (método rápido con xargs)
update_all_packages_fast() {
    echo -e "\n${GREEN}=== Actualizando TODAS las librerías (Método Rápido) ===${NC}\n"
    echo -e "${YELLOW}Usando método con xargs para mayor velocidad...${NC}\n"
    
    # Verificar si hay paquetes desactualizados
    outdated_count=$(pip3 list --outdated | tail -n +3 | wc -l)
    
    if [ $outdated_count -eq 0 ]; then
        echo -e "${GREEN}¡Todas las librerías están actualizadas!${NC}"
        return
    fi
    
    echo -e "${CYAN}Se actualizarán aproximadamente $outdated_count paquetes${NC}\n"
    
    # Usar el comando con xargs (extrayendo la primera columna con awk)
    if [ "$USE_BREAK_SYSTEM" = "--break-system-packages" ]; then
        pip3 list --outdated | tail -n +3 | awk '{print $1}' | xargs -n1 pip3 install -U --break-system-packages
    else
        pip3 list --outdated | tail -n +3 | awk '{print $1}' | xargs -n1 pip3 install -U
    fi
    
    echo -e "\n${GREEN}✓ Todas las librerías actualizadas${NC}"
}

# Función para actualizar librerías específicas
update_selected_packages() {
    echo -e "\n${GREEN}=== Actualizar Librerías Específicas ===${NC}\n"
    echo -n "Ingresa los nombres de las librerías separados por espacios: "
    read packages
    
    for pkg in $packages; do
        echo -e "\n${BLUE}Actualizando: $pkg${NC}"
        pip3 install --upgrade "$pkg" $USE_BREAK_SYSTEM
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
        pip3 install --upgrade -r requirements.txt $USE_BREAK_SYSTEM
        echo -e "\n${GREEN}✓ Librerías actualizadas desde requirements.txt${NC}"
    else
        echo -n "Ingresa la ruta al archivo requirements.txt: "
        read req_file
        if [ -f "$req_file" ]; then
            pip3 install --upgrade -r "$req_file" $USE_BREAK_SYSTEM
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

# Detección automática de necesidad de --break-system-packages
echo -e "${CYAN}Detectando configuración del sistema...${NC}"
if python3 -m pip install --help 2>&1 | grep -q "break-system-packages"; then
    echo -e "${YELLOW}Sistema detectado: requiere --break-system-packages${NC}"
    echo -e "${YELLOW}Se recomienda activarlo en el menú (opción 11)${NC}"
fi

# Bucle principal
while true; do
    show_menu
    read option
    case $option in
        1) update_pip ;;
        2) update_all_packages ;;
        3) update_all_packages_fast ;;
        4) update_selected_packages ;;
        5) view_outdated ;;
        6) view_all_packages ;;
        7) update_from_requirements ;;
        8) generate_requirements ;;
        9) search_package ;;
        10) clean_cache ;;
        11) configure_break_system ;;
        0) echo -e "\n${GREEN}¡Hasta luego!${NC}\n"; exit 0 ;;
        *) echo -e "\n${RED}Opción inválida${NC}" ;;
    esac
    echo -e "\n${YELLOW}Presiona Enter para continuar...${NC}"
    read
done
