#!/bin/bash

# Colores para el menú
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar el menú
mostrar_menu() {
    clear
    echo -e "${BLUE}=================================${NC}"
    echo -e "${BLUE}    BUSCADOR DE ARCHIVOS         ${NC}"
    echo -e "${BLUE}=================================${NC}"
    echo -e "${GREEN}1. Buscar por nombre${NC}"
    echo -e "${GREEN}2. Buscar por extensión${NC}"
    echo -e "${GREEN}3. Buscar por tamaño${NC}"
    echo -e "${GREEN}4. Buscar por fecha de modificación${NC}"
    echo -e "${GREEN}5. Buscar combinando criterios${NC}"
    echo -e "${YELLOW}6. Salir${NC}"
    echo -e "${BLUE}=================================${NC}"
}

# Función para buscar por nombre
buscar_nombre() {
    echo -e "${YELLOW}Ingrese el nombre del archivo (puede usar patrones como *):${NC}"
    read -r nombre
    echo -e "${YELLOW}Ingrese el directorio donde buscar (presione Enter para buscar en el directorio actual):${NC}"
    read -r directorio
    
    if [ -z "$directorio" ]; then
        directorio="."
    fi
    
    if [ ! -d "$directorio" ]; then
        echo -e "${RED}Error: El directorio '$directorio' no existe.${NC}"
        return
    fi
    
    echo -e "${GREEN}Buscando archivos con nombre: $nombre en $directorio${NC}"
    echo -e "${BLUE}Resultados:${NC}"
    find "$directorio" -name "$nombre" -type f 2>/dev/null | while read -r archivo; do
        echo -e "${GREEN}$archivo${NC}"
    done
    
    echo -e "${YELLOW}Presione Enter para continuar...${NC}"
    read -r
}

# Función para buscar por extensión
buscar_extension() {
    echo -e "${YELLOW}Ingrese la extensión (sin el punto, ej: txt, pdf, jpg):${NC}"
    read -r extension
    echo -e "${YELLOW}Ingrese el directorio donde buscar (presione Enter para buscar en el directorio actual):${NC}"
    read -r directorio
    
    if [ -z "$directorio" ]; then
        directorio="."
    fi
    
    if [ ! -d "$directorio" ]; then
        echo -e "${RED}Error: El directorio '$directorio' no existe.${NC}"
        return
    fi
    
    echo -e "${GREEN}Buscando archivos con extensión: .$extension en $directorio${NC}"
    echo -e "${BLUE}Resultados:${NC}"
    find "$directorio" -name "*.$extension" -type f 2>/dev/null | while read -r archivo; do
        echo -e "${GREEN}$archivo${NC}"
    done
    
    echo -e "${YELLOW}Presione Enter para continuar...${NC}"
    read -r
}

# Función para buscar por tamaño
buscar_tamano() {
    echo -e "${YELLOW}Opciones de búsqueda por tamaño:${NC}"
    echo -e "1. Archivos mayores a un tamaño"
    echo -e "2. Archivos menores a un tamaño"
    echo -e "3. Archivos entre dos tamaños"
    read -r opcion_tamano
    
    echo -e "${YELLOW}Ingrese el directorio donde buscar (presione Enter para buscar en el directorio actual):${NC}"
    read -r directorio
    
    if [ -z "$directorio" ]; then
        directorio="."
    fi
    
    if [ ! -d "$directorio" ]; then
        echo -e "${RED}Error: El directorio '$directorio' no existe.${NC}"
        return
    fi
    
    case $opcion_tamano in
        1)
            echo -e "${YELLOW}Ingrese el tamaño mínimo (ej: 1M para 1MB, 100k para 100KB):${NC}"
            read -r tamano_min
            echo -e "${GREEN}Buscando archivos mayores a $tamano_min en $directorio${NC}"
            find "$directorio" -type f -size "+$tamano_min" 2>/dev/null | while read -r archivo; do
                tamanio=$(ls -lh "$archivo" | awk '{print $5}')
                echo -e "${GREEN}$archivo - $tamanio${NC}"
            done
            ;;
        2)
            echo -e "${YELLOW}Ingrese el tamaño máximo (ej: 1M para 1MB, 100k para 100KB):${NC}"
            read -r tamano_max
            echo -e "${GREEN}Buscando archivos menores a $tamano_max en $directorio${NC}"
            find "$directorio" -type f -size "-$tamano_max" 2>/dev/null | while read -r archivo; do
                tamanio=$(ls -lh "$archivo" | awk '{print $5}')
                echo -e "${GREEN}$archivo - $tamanio${NC}"
            done
            ;;
        3)
            echo -e "${YELLOW}Ingrese el tamaño mínimo (ej: 1M para 1MB):${NC}"
            read -r tamano_min
            echo -e "${YELLOW}Ingrese el tamaño máximo (ej: 10M para 10MB):${NC}"
            read -r tamano_max
            echo -e "${GREEN}Buscando archivos entre $tamano_min y $tamano_max en $directorio${NC}"
            find "$directorio" -type f -size "+$tamano_min" -size "-$tamano_max" 2>/dev/null | while read -r archivo; do
                tamanio=$(ls -lh "$archivo" | awk '{print $5}')
                echo -e "${GREEN}$archivo - $tamanio${NC}"
            done
            ;;
        *)
            echo -e "${RED}Opción inválida${NC}"
            ;;
    esac
    
    echo -e "${YELLOW}Presione Enter para continuar...${NC}"
    read -r
}

# Función para buscar por fecha de modificación
buscar_fecha() {
    echo -e "${YELLOW}Opciones de búsqueda por fecha:${NC}"
    echo -e "1. Archivos modificados en los últimos N días"
    echo -e "2. Archivos modificados hace más de N días"
    echo -e "3. Archivos modificados entre dos fechas"
    read -r opcion_fecha
    
    echo -e "${YELLOW}Ingrese el directorio donde buscar (presione Enter para buscar en el directorio actual):${NC}"
    read -r directorio
    
    if [ -z "$directorio" ]; then
        directorio="."
    fi
    
    if [ ! -d "$directorio" ]; then
        echo -e "${RED}Error: El directorio '$directorio' no existe.${NC}"
        return
    fi
    
    case $opcion_fecha in
        1)
            echo -e "${YELLOW}Ingrese el número de días:${NC}"
            read -r dias
            echo -e "${GREEN}Buscando archivos modificados en los últimos $dias días en $directorio${NC}"
            find "$directorio" -type f -mtime "-$dias" 2>/dev/null | while read -r archivo; do
                fecha=$(stat -c %y "$archivo" 2>/dev/null | cut -d' ' -f1)
                echo -e "${GREEN}$archivo - Modificado: $fecha${NC}"
            done
            ;;
        2)
            echo -e "${YELLOW}Ingrese el número de días:${NC}"
            read -r dias
            echo -e "${GREEN}Buscando archivos modificados hace más de $dias días en $directorio${NC}"
            find "$directorio" -type f -mtime "+$dias" 2>/dev/null | while read -r archivo; do
                fecha=$(stat -c %y "$archivo" 2>/dev/null | cut -d' ' -f1)
                echo -e "${GREEN}$archivo - Modificado: $fecha${NC}"
            done
            ;;
        3)
            echo -e "${YELLOW}Ingrese la fecha inicial (formato: YYYY-MM-DD):${NC}"
            read -r fecha_inicio
            echo -e "${YELLOW}Ingrese la fecha final (formato: YYYY-MM-DD):${NC}"
            read -r fecha_fin
            echo -e "${GREEN}Buscando archivos modificados entre $fecha_inicio y $fecha_fin en $directorio${NC}"
            find "$directorio" -type f -newermt "$fecha_inicio" ! -newermt "$fecha_fin" 2>/dev/null | while read -r archivo; do
                fecha=$(stat -c %y "$archivo" 2>/dev/null | cut -d' ' -f1)
                echo -e "${GREEN}$archivo - Modificado: $fecha${NC}"
            done
            ;;
        *)
            echo -e "${RED}Opción inválida${NC}"
            ;;
    esac
    
    echo -e "${YELLOW}Presione Enter para continuar...${NC}"
    read -r
}

# Función para búsqueda combinada
buscar_combinada() {
    echo -e "${YELLOW}Búsqueda combinada - Complete los criterios que desee (deje en blanco los que no):${NC}"
    
    echo -e "${YELLOW}Nombre del archivo (puede usar * como comodín):${NC}"
    read -r nombre
    
    echo -e "${YELLOW}Extensión (sin el punto):${NC}"
    read -r extension
    
    echo -e "${YELLOW}Tamaño (ej: +1M para mayor a 1MB, -100k para menor a 100KB):${NC}"
    read -r tamano
    
    echo -e "${YELLOW}Días desde la modificación (ej: -7 para últimos 7 días, +30 para más de 30 días):${NC}"
    read -r dias_mod
    
    echo -e "${YELLOW}Directorio donde buscar (presione Enter para directorio actual):${NC}"
    read -r directorio
    
    if [ -z "$directorio" ]; then
        directorio="."
    fi
    
    if [ ! -d "$directorio" ]; then
        echo -e "${RED}Error: El directorio '$directorio' no existe.${NC}"
        echo -e "${YELLOW}Presione Enter para continuar...${NC}"
        read -r
        return
    fi
    
    # Construir el comando find
    comando="find \"$directorio\" -type f"
    
    if [ ! -z "$nombre" ]; then
        comando="$comando -name \"$nombre\""
    fi
    
    if [ ! -z "$extension" ]; then
        comando="$comando -name \"*.$extension\""
    fi
    
    if [ ! -z "$tamano" ]; then
        comando="$comando -size \"$tamano\""
    fi
    
    if [ ! -z "$dias_mod" ]; then
        comando="$comando -mtime \"$dias_mod\""
    fi
    
    comando="$comando 2>/dev/null"
    
    echo -e "${GREEN}Ejecutando: $comando${NC}"
    echo -e "${BLUE}Resultados:${NC}"
    
    eval "$comando" | while read -r archivo; do
        if [ -f "$archivo" ]; then
            tamanio=$(ls -lh "$archivo" | awk '{print $5}')
            fecha=$(stat -c %y "$archivo" 2>/dev/null | cut -d' ' -f1)
            echo -e "${GREEN}$archivo - Tamaño: $tamanio - Modificado: $fecha${NC}"
        fi
    done
    
    echo -e "${YELLOW}Presione Enter para continuar...${NC}"
    read -r
}

# Loop principal del menú
while true; do
    mostrar_menu
    echo -e "${YELLOW}Seleccione una opción [1-6]:${NC}"
    read -r opcion
    
    case $opcion in
        1)
            buscar_nombre
            ;;
        2)
            buscar_extension
            ;;
        3)
            buscar_tamano
            ;;
        4)
            buscar_fecha
            ;;
        5)
            buscar_combinada
            ;;
        6)
            echo -e "${GREEN}¡Hasta luego!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Opción inválida. Presione Enter para continuar.${NC}"
            read -r
            ;;
    esac
done
