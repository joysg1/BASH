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
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}    MENÚ CUT Y AWK - PROCESAR ARCHIVOS${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "${BLUE}1.${NC} Cut - Extraer columnas por delimitador"
    echo -e "${BLUE}2.${NC} Cut - Extraer caracteres por posición"
    echo -e "${BLUE}3.${NC} Cut - Extraer campos por delimitador específico"
    echo -e "${BLUE}4.${NC} Awk - Imprimir columnas específicas"
    echo -e "${BLUE}5.${NC} Awk - Filtrar líneas por condición"
    echo -e "${BLUE}6.${NC} Awk - Calcular suma de columna numérica"
    echo -e "${BLUE}7.${NC} Awk - Formatear y reorganizar datos"
    echo -e "${BLUE}8.${NC} Mostrar contenido del archivo"
    echo -e "${BLUE}9.${NC} Cambiar archivo de trabajo"
    echo -e "${BLUE}0.${NC} Salir"
    echo -e "${GREEN}========================================${NC}"
}

# Función para seleccionar archivo
seleccionar_archivo() {
    if [ -n "$archivo" ]; then
        echo -e "${YELLOW}Archivo actual: $archivo${NC}"
        echo -n "¿Desea cambiar el archivo? (s/n): "
        read respuesta
        if [ "$respuesta" != "s" ]; then
            return
        fi
    fi
    
    echo -n "Ingrese la ruta del archivo: "
    read archivo
    
    if [ ! -f "$archivo" ]; then
        echo -e "${RED}Error: El archivo no existe${NC}"
        archivo=""
        sleep 2
        return 1
    fi
    
    echo -e "${GREEN}Archivo seleccionado: $archivo${NC}"
    sleep 1
}

# Función para mostrar contenido del archivo
mostrar_contenido() {
    if [ -z "$archivo" ]; then
        echo -e "${RED}Primero seleccione un archivo (opción 9)${NC}"
        sleep 2
        return
    fi
    
    echo -e "${YELLOW}Contenido de $archivo:${NC}"
    echo "----------------------------------------"
    head -n 10 "$archivo"
    if [ $(wc -l < "$archivo") -gt 10 ]; then
        echo "... (archivo muy largo, mostrando primeras 10 líneas)"
    fi
    echo "----------------------------------------"
    read -p "Presione Enter para continuar..."
}

# Función para extraer columnas con cut por delimitador
cut_columnas() {
    if [ -z "$archivo" ]; then
        echo -e "${RED}Primero seleccione un archivo (opción 9)${NC}"
        sleep 2
        return
    fi
    
    echo -n "Ingrese el delimitador (por defecto TAB): "
    read delimitador
    delimitador=${delimitador:-$'\t'}
    
    echo -n "Ingrese las columnas a extraer (ej: 1,3,5 o 1-5): "
    read columnas
    
    echo -e "${GREEN}Resultado:${NC}"
    echo "----------------------------------------"
    cut -d "$delimitador" -f "$columnas" "$archivo" | head -n 20
    if [ $(wc -l < "$archivo") -gt 20 ]; then
        echo "... (mostrando primeras 20 líneas)"
    fi
    echo "----------------------------------------"
    read -p "Presione Enter para continuar..."
}

# Función para extraer caracteres por posición
cut_caracteres() {
    if [ -z "$archivo" ]; then
        echo -e "${RED}Primero seleccione un archivo (opción 9)${NC}"
        sleep 2
        return
    fi
    
    echo -n "Ingrese las posiciones de caracteres (ej: 1-5,10,15-20): "
    read posiciones
    
    echo -e "${GREEN}Resultado:${NC}"
    echo "----------------------------------------"
    cut -c "$posiciones" "$archivo" | head -n 20
    if [ $(wc -l < "$archivo") -gt 20 ]; then
        echo "... (mostrando primeras 20 líneas)"
    fi
    echo "----------------------------------------"
    read -p "Presione Enter para continuar..."
}

# Función para extraer campos con delimitador específico
cut_campos() {
    if [ -z "$archivo" ]; then
        echo -e "${RED}Primero seleccione un archivo (opción 9)${NC}"
        sleep 2
        return
    fi
    
    echo -n "Ingrese el delimitador: "
    read delimitador
    
    echo -n "Ingrese los campos a extraer (ej: 1,3,5): "
    read campos
    
    echo -e "${GREEN}Resultado:${NC}"
    echo "----------------------------------------"
    cut -d "$delimitador" -f "$campos" "$archivo" | head -n 20
    if [ $(wc -l < "$archivo") -gt 20 ]; then
        echo "... (mostrando primeras 20 líneas)"
    fi
    echo "----------------------------------------"
    read -p "Presione Enter para continuar..."
}

# Función para imprimir columnas con awk
awk_columnas() {
    if [ -z "$archivo" ]; then
        echo -e "${RED}Primero seleccione un archivo (opción 9)${NC}"
        sleep 2
        return
    fi
    
    echo -n "Ingrese las columnas a imprimir (ej: 1,3 o \$1,\$3): "
    read columnas
    
    # Remover signos $ si el usuario los incluye
    columnas=$(echo "$columnas" | sed 's/\$//g')
    
    echo -e "${GREEN}Resultado:${NC}"
    echo "----------------------------------------"
    awk "{print $columnas}" "$archivo" | head -n 20
    if [ $(wc -l < "$archivo") -gt 20 ]; then
        echo "... (mostrando primeras 20 líneas)"
    fi
    echo "----------------------------------------"
    read -p "Presione Enter para continuar..."
}

# Función para filtrar líneas con awk
awk_filtrar() {
    if [ -z "$archivo" ]; then
        echo -e "${RED}Primero seleccione un archivo (opción 9)${NC}"
        sleep 2
        return
    fi
    
    echo "Ejemplos de condiciones:"
    echo "  - \$1 > 100 (columna 1 mayor que 100)"
    echo "  - \$2 == \"texto\" (columna 2 igual a texto)"
    echo "  - /patron/ (contiene patrón)"
    echo "  - NF > 3 (más de 3 campos)"
    echo -n "Ingrese la condición: "
    read condicion
    
    echo -e "${GREEN}Resultado:${NC}"
    echo "----------------------------------------"
    awk "$condicion" "$archivo" | head -n 20
    if [ $(awk "$condicion" "$archivo" | wc -l) -gt 20 ]; then
        echo "... (mostrando primeras 20 líneas)"
    fi
    echo "----------------------------------------"
    read -p "Presione Enter para continuar..."
}

# Función para calcular suma con awk
awk_suma() {
    if [ -z "$archivo" ]; then
        echo -e "${RED}Primero seleccione un archivo (opción 9)${NC}"
        sleep 2
        return
    fi
    
    echo -n "Ingrese el número de columna a sumar: "
    read columna
    
    echo -e "${GREEN}Resultado:${NC}"
    echo "----------------------------------------"
    awk -v col="$columna" '{
        suma += $col
        print $0
    } 
    END {
        print "----------------------------------------"
        print "Suma de la columna " col ": " suma
    }' "$archivo"
    echo "----------------------------------------"
    read -p "Presione Enter para continuar..."
}

# Función para formatear datos con awk
awk_formatear() {
    if [ -z "$archivo" ]; then
        echo -e "${RED}Primero seleccione un archivo (opción 9)${NC}"
        sleep 2
        return
    fi
    
    echo "Ejemplos de formato:"
    echo "  - '{print \"Nombre: \" \$1 \", Edad: \" \$2}'"
    echo "  - '{printf \"%-10s %-10s\\n\", \$1, \$2}'"
    echo -n "Ingrese el formato awk: "
    read formato
    
    echo -e "${GREEN}Resultado:${NC}"
    echo "----------------------------------------"
    awk "$formato" "$archivo" | head -n 20
    if [ $(wc -l < "$archivo") -gt 20 ]; then
        echo "... (mostrando primeras 20 líneas)"
    fi
    echo "----------------------------------------"
    read -p "Presione Enter para continuar..."
}

# Archivo de trabajo
archivo=""

# Mensaje inicial
echo -e "${GREEN}Script de procesamiento de archivos con Cut y Awk${NC}"
echo -e "${YELLOW}Primero seleccione un archivo para trabajar${NC}"
sleep 2

# Bucle principal
while true; do
    mostrar_menu
    echo -n "Seleccione una opción: "
    read opcion
    
    case $opcion in
        1) cut_columnas ;;
        2) cut_caracteres ;;
        3) cut_campos ;;
        4) awk_columnas ;;
        5) awk_filtrar ;;
        6) awk_suma ;;
        7) awk_formatear ;;
        8) mostrar_contenido ;;
        9) seleccionar_archivo ;;
        0) 
            echo -e "${GREEN}Saliendo...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Opción no válida${NC}"
            sleep 2
            ;;
    esac
done