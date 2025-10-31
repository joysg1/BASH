#!/bin/bash

# Script para ejecutar SQLMap con diferentes niveles de crawl
# Permite al usuario ingresar la URL y seleccionar el nivel de profundidad

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Sin color

# Banner
print_banner() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════╗"
    echo "║   SQLMap Crawl Automation Script     ║"
    echo "║   Todos los niveles de crawl          ║"
    echo "╚═══════════════════════════════════════╝"
    echo -e "${NC}"
}

# Verificar si SQLMap está instalado
check_sqlmap() {
    if command -v sqlmap &> /dev/null; then
        echo -e "${GREEN}[✓] SQLMap detectado correctamente${NC}"
        return 0
    else
        echo -e "${RED}[✗] SQLMap no está instalado o no se encuentra en el PATH${NC}"
        echo -e "${YELLOW}[i] Instala SQLMap desde: https://github.com/sqlmapproject/sqlmap${NC}"
        exit 1
    fi
}

# Obtener URL del usuario
get_url() {
    while true; do
        echo -e "\n${YELLOW}[+] Ingresa la URL objetivo (ej: http://ejemplo.com/page.php?id=1):${NC}"
        read -r url
        
        if [[ -z "$url" ]]; then
            echo -e "${RED}[!] Debes ingresar una URL válida${NC}"
            continue
        fi
        
        if [[ ! "$url" =~ ^https?:// ]]; then
            echo -e "${RED}[!] La URL debe comenzar con http:// o https://${NC}"
            continue
        fi
        
        echo "$url"
        return 0
    done
}

# Obtener nivel de crawl
get_crawl_depth() {
    echo -e "\n${BLUE}[i] Niveles de crawl disponibles:${NC}"
    echo "    1 - Nivel 1 (Superficial)"
    echo "    2 - Nivel 2 (Moderado)"
    echo "    3 - Nivel 3 (Profundo)"
    echo "    4 - Nivel 4 (Muy profundo)"
    echo "    5 - Nivel 5 (Máximo)"
    echo "    0 - Todos los niveles (1-5)"
    
    while true; do
        echo -e "\n${YELLOW}[+] Selecciona el nivel de crawl (0-5):${NC}"
        read -r depth
        
        if [[ "$depth" =~ ^[0-5]$ ]]; then
            echo "$depth"
            return 0
        fi
        
        echo -e "${RED}[!] Debes ingresar un número entre 0 y 5${NC}"
    done
}

# Obtener opciones adicionales
get_additional_options() {
    echo -e "\n${BLUE}[i] Opciones adicionales:${NC}"
    
    local options=""
    
    # Batch mode
    echo -e "${YELLOW}[?] ¿Usar modo batch (sin confirmaciones)? (s/n):${NC}"
    read -r batch
    if [[ "$batch" == "s" || "$batch" == "S" ]]; then
        options="$options --batch"
    fi
    
    # Random agent
    echo -e "${YELLOW}[?] ¿Usar user-agent aleatorio? (s/n):${NC}"
    read -r random_agent
    if [[ "$random_agent" == "s" || "$random_agent" == "S" ]]; then
        options="$options --random-agent"
    fi
    
    # Forms
    echo -e "${YELLOW}[?] ¿Buscar y testear formularios? (s/n):${NC}"
    read -r forms
    if [[ "$forms" == "s" || "$forms" == "S" ]]; then
        options="$options --forms"
    fi
    
    # Level
    echo -e "${YELLOW}[?] Nivel de tests (1-5, Enter para default):${NC}"
    read -r level
    if [[ "$level" =~ ^[1-5]$ ]]; then
        options="$options --level=$level"
    fi
    
    # Risk
    echo -e "${YELLOW}[?] Nivel de riesgo (1-3, Enter para default):${NC}"
    read -r risk
    if [[ "$risk" =~ ^[1-3]$ ]]; then
        options="$options --risk=$risk"
    fi
    
    # Threads
    echo -e "${YELLOW}[?] ¿Usar múltiples threads? (1-10, Enter para default):${NC}"
    read -r threads
    if [[ "$threads" =~ ^[1-9]$|^10$ ]]; then
        options="$options --threads=$threads"
    fi
    
    echo "$options"
}

# Ejecutar un solo nivel de crawl
execute_single_crawl() {
    local url=$1
    local depth=$2
    local additional_options=$3
    
    echo -e "\n${GREEN}[>] Comando: sqlmap -u $url --crawl=$depth $additional_options${NC}\n"
    
    sqlmap -u "$url" --crawl="$depth" $additional_options
    
    if [ $? -eq 0 ]; then
        echo -e "\n${GREEN}[✓] Crawl nivel $depth completado${NC}"
    else
        echo -e "\n${RED}[✗] Error al ejecutar crawl nivel $depth${NC}"
    fi
}

# Ejecutar SQLMap con los parámetros especificados
run_sqlmap() {
    local url=$1
    local crawl_depth=$2
    local additional_options=$3
    
    if [ "$crawl_depth" -eq 0 ]; then
        # Ejecutar todos los niveles
        echo -e "\n${GREEN}[*] Ejecutando SQLMap con todos los niveles de crawl (1-5)...${NC}"
        for depth in {1..5}; do
            echo -e "\n${BLUE}============================================================${NC}"
            echo -e "${GREEN}[*] Iniciando crawl nivel $depth${NC}"
            echo -e "${BLUE}============================================================${NC}"
            execute_single_crawl "$url" "$depth" "$additional_options"
            
            if [ $depth -lt 5 ]; then
                echo -e "\n${YELLOW}[i] Presiona Enter para continuar con el siguiente nivel...${NC}"
                read -r
            fi
        done
    else
        # Ejecutar nivel específico
        echo -e "\n${GREEN}[*] Ejecutando SQLMap con nivel de crawl $crawl_depth...${NC}"
        execute_single_crawl "$url" "$crawl_depth" "$additional_options"
    fi
}

# Función principal
main() {
    print_banner
    
    # Verificar SQLMap
    check_sqlmap
    
    # Obtener datos del usuario
    url=$(get_url)
    crawl_depth=$(get_crawl_depth)
    additional_options=$(get_additional_options)
    
    # Confirmación
    echo -e "\n${BLUE}============================================================${NC}"
    echo -e "${BLUE}[i] Resumen de la configuración:${NC}"
    echo -e "    URL: ${GREEN}$url${NC}"
    if [ "$crawl_depth" -eq 0 ]; then
        echo -e "    Nivel de crawl: ${GREEN}Todos (1-5)${NC}"
    else
        echo -e "    Nivel de crawl: ${GREEN}$crawl_depth${NC}"
    fi
    if [[ -n "$additional_options" ]]; then
        echo -e "    Opciones adicionales: ${GREEN}$additional_options${NC}"
    else
        echo -e "    Opciones adicionales: ${YELLOW}Ninguna${NC}"
    fi
    echo -e "${BLUE}============================================================${NC}"
    
    echo -e "\n${YELLOW}[?] ¿Deseas continuar? (s/n):${NC}"
    read -r confirm
    if [[ "$confirm" != "s" && "$confirm" != "S" ]]; then
        echo -e "${RED}[!] Operación cancelada${NC}"
        exit 0
    fi
    
    # Ejecutar SQLMap
    run_sqlmap "$url" "$crawl_depth" "$additional_options"
    
    echo -e "\n${GREEN}[✓] Script finalizado${NC}"
}

# Manejo de Ctrl+C
trap 'echo -e "\n${RED}[!] Script interrumpido por el usuario${NC}"; exit 1' INT

# Ejecutar script
main
