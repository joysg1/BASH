#!/bin/bash

# Script para escaneo y diagnóstico de red usando nmap
# Herramienta completa de análisis de red

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Función para mostrar banner
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════╗"
    echo "║     Scanner de Red con Nmap               ║"
    echo "║     Herramienta de Análisis de Red        ║"
    echo "╚═══════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Función para mostrar menú
show_menu() {
    show_banner
    echo -e "${GREEN}Tu IP local: ${CYAN}$(hostname -I | awk '{print $1}')${NC}"
    echo -e "${GREEN}Gateway: ${CYAN}$(ip route | grep default | awk '{print $3}')${NC}\n"
    echo -e "${YELLOW}═══ Escaneos Básicos ═══${NC}"
    echo -e "${YELLOW}1)${NC}  Escanear hosts activos en la red local"
    echo -e "${YELLOW}2)${NC}  Escanear puertos de un host específico"
    echo -e "${YELLOW}3)${NC}  Escaneo rápido (puertos comunes)"
    echo -e "${YELLOW}4)${NC}  Escaneo completo de puertos (1-65535)"
    echo -e ""
    echo -e "${YELLOW}═══ Escaneos Avanzados ═══${NC}"
    echo -e "${YELLOW}5)${NC}  Detectar sistema operativo"
    echo -e "${YELLOW}6)${NC}  Detectar versiones de servicios"
    echo -e "${YELLOW}7)${NC}  Escaneo agresivo (OS + Servicios + Scripts)"
    echo -e "${YELLOW}8)${NC}  Escaneo sigiloso (SYN Scan)"
    echo -e ""
    echo -e "${YELLOW}═══ Escaneos Específicos ═══${NC}"
    echo -e "${YELLOW}9)${NC}  Escanear vulnerabilidades (scripts NSE)"
    echo -e "${YELLOW}10)${NC} Escanear red completa (subnet)"
    echo -e "${YELLOW}11)${NC} Escanear puertos UDP"
    echo -e "${YELLOW}12)${NC} Detectar firewalls/IDS"
    echo -e ""
    echo -e "${YELLOW}═══ Utilidades ═══${NC}"
    echo -e "${YELLOW}13)${NC} Ver información de red local"
    echo -e "${YELLOW}14)${NC} Ping a un host"
    echo -e "${YELLOW}15)${NC} Traceroute a un host"
    echo -e "${YELLOW}16)${NC} Ver conexiones activas"
    echo -e "${YELLOW}0)${NC}  Salir\n"
    echo -n "Selecciona una opción: "
}

# Verificar si nmap está instalado
check_nmap() {
    if ! command -v nmap &> /dev/null; then
        echo -e "${RED}Error: nmap no está instalado${NC}"
        echo -e "${YELLOW}Instálalo con:${NC}"
        echo -e "  Ubuntu/Debian: ${CYAN}sudo apt install nmap${NC}"
        echo -e "  Fedora: ${CYAN}sudo dnf install nmap${NC}"
        echo -e "  Arch: ${CYAN}sudo pacman -S nmap${NC}"
        exit 1
    fi
}

# Verificar permisos de root para ciertos escaneos
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        echo -e "${YELLOW}⚠ Advertencia: Algunos escaneos requieren privilegios de root${NC}"
        echo -e "${YELLOW}  Ejecuta con sudo para acceder a todas las funciones${NC}\n"
    fi
}

# Función para obtener la red local
get_local_network() {
    ip route | grep -v default | grep -oP '^\d+\.\d+\.\d+\.\d+/\d+' | head -1
}

# 1. Escanear hosts activos
scan_active_hosts() {
    local network=$(get_local_network)
    echo -e "\n${GREEN}=== Escaneando hosts activos en $network ===${NC}\n"
    nmap -sn "$network" -oG - | grep "Up" | awk '{print $2, $3}'
}

# 2. Escanear puertos de un host
scan_host_ports() {
    echo -n "Ingresa la IP del host a escanear: "
    read target
    echo -e "\n${GREEN}=== Escaneando puertos en $target ===${NC}\n"
    nmap "$target"
}

# 3. Escaneo rápido
quick_scan() {
    echo -n "Ingresa la IP del host: "
    read target
    echo -e "\n${GREEN}=== Escaneo rápido de $target ===${NC}\n"
    nmap -F "$target"
}

# 4. Escaneo completo
full_scan() {
    echo -n "Ingresa la IP del host: "
    read target
    echo -e "\n${GREEN}=== Escaneo completo (todos los puertos) de $target ===${NC}\n"
    echo -e "${YELLOW}Esto puede tardar varios minutos...${NC}\n"
    nmap -p- "$target"
}

# 5. Detectar sistema operativo
detect_os() {
    echo -n "Ingresa la IP del host: "
    read target
    echo -e "\n${GREEN}=== Detectando sistema operativo de $target ===${NC}\n"
    if [ "$EUID" -eq 0 ]; then
        nmap -O "$target"
    else
        echo -e "${RED}Requiere privilegios de root. Ejecuta con sudo${NC}"
    fi
}

# 6. Detectar versiones de servicios
detect_services() {
    echo -n "Ingresa la IP del host: "
    read target
    echo -e "\n${GREEN}=== Detectando versiones de servicios en $target ===${NC}\n"
    nmap -sV "$target"
}

# 7. Escaneo agresivo
aggressive_scan() {
    echo -n "Ingresa la IP del host: "
    read target
    echo -e "\n${GREEN}=== Escaneo agresivo de $target ===${NC}\n"
    echo -e "${YELLOW}Incluye: OS, versiones, scripts y traceroute${NC}\n"
    if [ "$EUID" -eq 0 ]; then
        nmap -A "$target"
    else
        echo -e "${RED}Requiere privilegios de root. Ejecuta con sudo${NC}"
    fi
}

# 8. Escaneo sigiloso
stealth_scan() {
    echo -n "Ingresa la IP del host: "
    read target
    echo -e "\n${GREEN}=== Escaneo sigiloso (SYN) de $target ===${NC}\n"
    if [ "$EUID" -eq 0 ]; then
        nmap -sS "$target"
    else
        echo -e "${RED}Requiere privilegios de root. Ejecuta con sudo${NC}"
    fi
}

# 9. Escanear vulnerabilidades
scan_vulnerabilities() {
    echo -n "Ingresa la IP del host: "
    read target
    echo -e "\n${GREEN}=== Escaneando vulnerabilidades en $target ===${NC}\n"
    nmap --script vuln "$target"
}

# 10. Escanear red completa
scan_network() {
    local network=$(get_local_network)
    echo -e "\n${GREEN}=== Escaneando toda la red $network ===${NC}\n"
    echo -e "${YELLOW}Esto puede tardar varios minutos...${NC}\n"
    nmap -sP "$network"
}

# 11. Escanear puertos UDP
scan_udp() {
    echo -n "Ingresa la IP del host: "
    read target
    echo -e "\n${GREEN}=== Escaneando puertos UDP en $target ===${NC}\n"
    if [ "$EUID" -eq 0 ]; then
        nmap -sU --top-ports 20 "$target"
    else
        echo -e "${RED}Requiere privilegios de root. Ejecuta con sudo${NC}"
    fi
}

# 12. Detectar firewalls
detect_firewall() {
    echo -n "Ingresa la IP del host: "
    read target
    echo -e "\n${GREEN}=== Detectando firewall/IDS en $target ===${NC}\n"
    if [ "$EUID" -eq 0 ]; then
        nmap -sA "$target"
    else
        echo -e "${RED}Requiere privilegios de root. Ejecuta con sudo${NC}"
    fi
}

# 13. Ver información de red local
view_network_info() {
    echo -e "\n${GREEN}=== Información de Red Local ===${NC}\n"
    echo -e "${CYAN}Interfaces de red:${NC}"
    ip addr show | grep -E "^[0-9]+:|inet "
    echo -e "\n${CYAN}Tabla de enrutamiento:${NC}"
    ip route
    echo -e "\n${CYAN}Servidores DNS:${NC}"
    cat /etc/resolv.conf | grep nameserver
}

# 14. Ping
ping_host() {
    echo -n "Ingresa la IP o dominio: "
    read target
    echo -e "\n${GREEN}=== Ping a $target ===${NC}\n"
    ping -c 4 "$target"
}

# 15. Traceroute
traceroute_host() {
    echo -n "Ingresa la IP o dominio: "
    read target
    echo -e "\n${GREEN}=== Traceroute a $target ===${NC}\n"
    if command -v traceroute &> /dev/null; then
        traceroute "$target"
    else
        echo -e "${YELLOW}traceroute no está instalado, usando mtr...${NC}"
        mtr -r -c 4 "$target"
    fi
}

# 16. Ver conexiones activas
view_connections() {
    echo -e "\n${GREEN}=== Conexiones Activas ===${NC}\n"
    if command -v ss &> /dev/null; then
        ss -tunapl
    else
        netstat -tunapl
    fi
}

# Verificar requisitos
check_nmap
check_root

# Bucle principal
while true; do
    show_menu
    read option
    case $option in
        1) scan_active_hosts ;;
        2) scan_host_ports ;;
        3) quick_scan ;;
        4) full_scan ;;
        5) detect_os ;;
        6) detect_services ;;
        7) aggressive_scan ;;
        8) stealth_scan ;;
        9) scan_vulnerabilities ;;
        10) scan_network ;;
        11) scan_udp ;;
        12) detect_firewall ;;
        13) view_network_info ;;
        14) ping_host ;;
        15) traceroute_host ;;
        16) view_connections ;;
        0) echo -e "\n${GREEN}¡Hasta luego!${NC}\n"; exit 0 ;;
        *) echo -e "\n${RED}Opción inválida${NC}" ;;
    esac
    echo -e "\n${YELLOW}Presiona Enter para continuar...${NC}"
    read
done
