#!/bin/bash

# Script para ver paquetes instalados y procesos en ejecución
# Compatible con múltiples distribuciones Linux

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Detectar distribución
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    DISTRO="unknown"
fi

# Función para mostrar menú
show_menu() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  Monitor de Sistema Linux              ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo -e "${CYAN}Distribución: $PRETTY_NAME${NC}\n"
    echo -e "${YELLOW}1)${NC} Ver todos los paquetes instalados"
    echo -e "${YELLOW}2)${NC} Buscar un paquete específico"
    echo -e "${YELLOW}3)${NC} Ver procesos en ejecución (básico)"
    echo -e "${YELLOW}4)${NC} Ver procesos por uso de CPU"
    echo -e "${YELLOW}5)${NC} Ver procesos por uso de memoria"
    echo -e "${YELLOW}6)${NC} Ver árbol de procesos"
    echo -e "${YELLOW}7)${NC} Buscar un proceso específico"
    echo -e "${YELLOW}8)${NC} Ver información del sistema"
    echo -e "${YELLOW}9)${NC} Ver puertos abiertos"
    echo -e "${YELLOW}0)${NC} Salir\n"
    echo -n "Selecciona una opción: "
}

# Función para listar todos los paquetes
list_all_packages() {
    echo -e "\n${GREEN}=== Paquetes Instalados ===${NC}\n"
    case $DISTRO in
        ubuntu|debian|linuxmint|pop)
            echo -e "${CYAN}Total de paquetes: $(dpkg -l | grep ^ii | wc -l)${NC}\n"
            dpkg -l | grep ^ii | awk '{print $2 "\t" $3}' | column -t | less
            ;;
        fedora|centos|rhel|rocky|almalinux)
            echo -e "${CYAN}Total de paquetes: $(rpm -qa | wc -l)${NC}\n"
            rpm -qa --qf '%{NAME}\t%{VERSION}\n' | column -t | less
            ;;
        arch|manjaro|endeavouros)
            echo -e "${CYAN}Total de paquetes: $(pacman -Q | wc -l)${NC}\n"
            pacman -Q | less
            ;;
        opensuse*)
            echo -e "${CYAN}Total de paquetes: $(rpm -qa | wc -l)${NC}\n"
            rpm -qa --qf '%{NAME}\t%{VERSION}\n' | column -t | less
            ;;
        alpine)
            echo -e "${CYAN}Total de paquetes: $(apk info | wc -l)${NC}\n"
            apk info | less
            ;;
        *)
            echo -e "${RED}Distribución no soportada${NC}"
            ;;
    esac
}

# Función para buscar un paquete
search_package() {
    echo -n "Ingresa el nombre del paquete a buscar: "
    read pkg_name
    echo -e "\n${GREEN}=== Buscando '$pkg_name' ===${NC}\n"
    case $DISTRO in
        ubuntu|debian|linuxmint|pop)
            dpkg -l | grep -i "$pkg_name"
            ;;
        fedora|centos|rhel|rocky|almalinux)
            rpm -qa | grep -i "$pkg_name"
            ;;
        arch|manjaro|endeavouros)
            pacman -Q | grep -i "$pkg_name"
            ;;
        opensuse*)
            rpm -qa | grep -i "$pkg_name"
            ;;
        alpine)
            apk info | grep -i "$pkg_name"
            ;;
    esac
}

# Función para ver procesos básicos
view_processes() {
    echo -e "\n${GREEN}=== Procesos en Ejecución ===${NC}\n"
    ps aux | less
}

# Función para ver procesos por CPU
view_cpu_processes() {
    echo -e "\n${GREEN}=== Procesos Ordenados por Uso de CPU ===${NC}\n"
    ps aux --sort=-%cpu | head -20
}

# Función para ver procesos por memoria
view_memory_processes() {
    echo -e "\n${GREEN}=== Procesos Ordenados por Uso de Memoria ===${NC}\n"
    ps aux --sort=-%mem | head -20
}

# Función para ver árbol de procesos
view_process_tree() {
    echo -e "\n${GREEN}=== Árbol de Procesos ===${NC}\n"
    if command -v pstree &> /dev/null; then
        pstree -p | less
    else
        ps auxf | less
    fi
}

# Función para buscar un proceso
search_process() {
    echo -n "Ingresa el nombre del proceso a buscar: "
    read proc_name
    echo -e "\n${GREEN}=== Buscando proceso '$proc_name' ===${NC}\n"
    ps aux | grep -i "$proc_name" | grep -v grep
}

# Función para ver información del sistema
view_system_info() {
    echo -e "\n${GREEN}=== Información del Sistema ===${NC}\n"
    echo -e "${YELLOW}Sistema Operativo:${NC}"
    uname -a
    echo -e "\n${YELLOW}Uso de CPU:${NC}"
    top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}'
    echo -e "\n${YELLOW}Uso de Memoria:${NC}"
    free -h
    echo -e "\n${YELLOW}Uso de Disco:${NC}"
    df -h
    echo -e "\n${YELLOW}Tiempo de actividad:${NC}"
    uptime
}

# Función para ver puertos abiertos
view_open_ports() {
    echo -e "\n${GREEN}=== Puertos Abiertos ===${NC}\n"
    if command -v ss &> /dev/null; then
        ss -tuln
    elif command -v netstat &> /dev/null; then
        netstat -tuln
    else
        echo -e "${RED}ni 'ss' ni 'netstat' están disponibles${NC}"
    fi
}

# Bucle principal
while true; do
    show_menu
    read option
    case $option in
        1) list_all_packages ;;
        2) search_package ;;
        3) view_processes ;;
        4) view_cpu_processes ;;
        5) view_memory_processes ;;
        6) view_process_tree ;;
        7) search_process ;;
        8) view_system_info ;;
        9) view_open_ports ;;
        0) echo -e "\n${GREEN}¡Hasta luego!${NC}\n"; exit 0 ;;
        *) echo -e "\n${RED}Opción inválida${NC}" ;;
    esac
    echo -e "\n${YELLOW}Presiona Enter para continuar...${NC}"
    read
done
