#!/bin/bash

# Colores para el menú
VERDE='\033[0;32m'
AZUL='\033[0;34m'
ROJO='\033[0;31m'
AMARILLO='\033[1;33m'
NC='\033[0m' # Sin color

# Función para pausar
pausar() {
    echo ""
    read -p "Presiona ENTER para continuar..."
}

# Función para limpiar pantalla
limpiar() {
    clear
}

# Función principal del menú
mostrar_menu() {
    limpiar
    echo -e "${AZUL}========================================${NC}"
    echo -e "${VERDE}    MENÚ DE BÚSQUEDA CON GREP${NC}"
    echo -e "${AZUL}========================================${NC}"
    echo ""
    echo "1) Buscar texto en un archivo"
    echo "2) Buscar texto en múltiples archivos"
    echo "3) Buscar sin distinguir mayúsculas/minúsculas"
    echo "4) Buscar y mostrar número de línea"
    echo "5) Buscar líneas que NO contienen el patrón"
    echo "6) Contar coincidencias"
    echo "7) Buscar recursivamente en directorios"
    echo "8) Buscar con expresión regular"
    echo "9) Buscar y mostrar contexto (líneas antes/después)"
    echo "0) Salir"
    echo ""
    echo -e "${AZUL}========================================${NC}"
}

# Opción 1: Buscar texto en un archivo
buscar_en_archivo() {
    limpiar
    echo -e "${VERDE}=== Buscar texto en un archivo ===${NC}"
    read -p "Ingresa el archivo: " archivo
    read -p "Ingresa el texto a buscar: " texto
    
    if [ -f "$archivo" ]; then
        echo -e "\n${AMARILLO}Resultados:${NC}"
        grep "$texto" "$archivo"
        [ $? -ne 0 ] && echo -e "${ROJO}No se encontraron coincidencias${NC}"
    else
        echo -e "${ROJO}El archivo no existe${NC}"
    fi
    pausar
}

# Opción 2: Buscar en múltiples archivos
buscar_multiples_archivos() {
    limpiar
    echo -e "${VERDE}=== Buscar en múltiples archivos ===${NC}"
    read -p "Ingresa el patrón de archivos (ej: *.txt): " patron
    read -p "Ingresa el texto a buscar: " texto
    
    echo -e "\n${AMARILLO}Resultados:${NC}"
    grep "$texto" $patron 2>/dev/null
    [ $? -ne 0 ] && echo -e "${ROJO}No se encontraron coincidencias${NC}"
    pausar
}

# Opción 3: Buscar sin distinguir mayúsculas
buscar_sin_mayusculas() {
    limpiar
    echo -e "${VERDE}=== Buscar sin distinguir mayúsculas/minúsculas ===${NC}"
    read -p "Ingresa el archivo: " archivo
    read -p "Ingresa el texto a buscar: " texto
    
    if [ -f "$archivo" ]; then
        echo -e "\n${AMARILLO}Resultados:${NC}"
        grep -i "$texto" "$archivo"
        [ $? -ne 0 ] && echo -e "${ROJO}No se encontraron coincidencias${NC}"
    else
        echo -e "${ROJO}El archivo no existe${NC}"
    fi
    pausar
}

# Opción 4: Buscar con número de línea
buscar_con_numero() {
    limpiar
    echo -e "${VERDE}=== Buscar mostrando número de línea ===${NC}"
    read -p "Ingresa el archivo: " archivo
    read -p "Ingresa el texto a buscar: " texto
    
    if [ -f "$archivo" ]; then
        echo -e "\n${AMARILLO}Resultados:${NC}"
        grep -n "$texto" "$archivo"
        [ $? -ne 0 ] && echo -e "${ROJO}No se encontraron coincidencias${NC}"
    else
        echo -e "${ROJO}El archivo no existe${NC}"
    fi
    pausar
}

# Opción 5: Buscar líneas que NO contienen el patrón
buscar_inverso() {
    limpiar
    echo -e "${VERDE}=== Buscar líneas que NO contienen el patrón ===${NC}"
    read -p "Ingresa el archivo: " archivo
    read -p "Ingresa el texto a excluir: " texto
    
    if [ -f "$archivo" ]; then
        echo -e "\n${AMARILLO}Resultados:${NC}"
        grep -v "$texto" "$archivo"
    else
        echo -e "${ROJO}El archivo no existe${NC}"
    fi
    pausar
}

# Opción 6: Contar coincidencias
contar_coincidencias() {
    limpiar
    echo -e "${VERDE}=== Contar coincidencias ===${NC}"
    read -p "Ingresa el archivo: " archivo
    read -p "Ingresa el texto a buscar: " texto
    
    if [ -f "$archivo" ]; then
        cuenta=$(grep -c "$texto" "$archivo")
        echo -e "\n${AMARILLO}Se encontraron ${cuenta} líneas con coincidencias${NC}"
    else
        echo -e "${ROJO}El archivo no existe${NC}"
    fi
    pausar
}

# Opción 7: Buscar recursivamente
buscar_recursivo() {
    limpiar
    echo -e "${VERDE}=== Buscar recursivamente en directorios ===${NC}"
    read -p "Ingresa el directorio: " directorio
    read -p "Ingresa el texto a buscar: " texto
    
    if [ -d "$directorio" ]; then
        echo -e "\n${AMARILLO}Resultados:${NC}"
        grep -r "$texto" "$directorio" 2>/dev/null
        [ $? -ne 0 ] && echo -e "${ROJO}No se encontraron coincidencias${NC}"
    else
        echo -e "${ROJO}El directorio no existe${NC}"
    fi
    pausar
}

# Opción 8: Buscar con expresión regular
buscar_regex() {
    limpiar
    echo -e "${VERDE}=== Buscar con expresión regular ===${NC}"
    read -p "Ingresa el archivo: " archivo
    read -p "Ingresa la expresión regular: " regex
    
    if [ -f "$archivo" ]; then
        echo -e "\n${AMARILLO}Resultados:${NC}"
        grep -E "$regex" "$archivo"
        [ $? -ne 0 ] && echo -e "${ROJO}No se encontraron coincidencias${NC}"
    else
        echo -e "${ROJO}El archivo no existe${NC}"
    fi
    pausar
}

# Opción 9: Buscar con contexto
buscar_con_contexto() {
    limpiar
    echo -e "${VERDE}=== Buscar mostrando contexto ===${NC}"
    read -p "Ingresa el archivo: " archivo
    read -p "Ingresa el texto a buscar: " texto
    read -p "¿Cuántas líneas de contexto? (antes y después): " lineas
    
    if [ -f "$archivo" ]; then
        echo -e "\n${AMARILLO}Resultados:${NC}"
        grep -C "$lineas" "$texto" "$archivo"
        [ $? -ne 0 ] && echo -e "${ROJO}No se encontraron coincidencias${NC}"
    else
        echo -e "${ROJO}El archivo no existe${NC}"
    fi
    pausar
}

# Bucle principal
while true; do
    mostrar_menu
    read -p "Selecciona una opción: " opcion
    
    case $opcion in
        1) buscar_en_archivo ;;
        2) buscar_multiples_archivos ;;
        3) buscar_sin_mayusculas ;;
        4) buscar_con_numero ;;
        5) buscar_inverso ;;
        6) contar_coincidencias ;;
        7) buscar_recursivo ;;
        8) buscar_regex ;;
        9) buscar_con_contexto ;;
        0) 
            limpiar
            echo -e "${VERDE}¡Hasta luego!${NC}"
            exit 0
            ;;
        *)
            echo -e "${ROJO}Opción inválida${NC}"
            sleep 2
            ;;
    esac
done
