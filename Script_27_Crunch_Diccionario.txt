#!/bin/bash

# Script masivo mejorado para grandes diccionarios con configuración completa
set -e

# Configuración por defecto
MIN_LENGTH=8
MAX_LENGTH=12
CHARSET="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
PATTERN=""
BASE_OUTPUT="diccionario_masivo"
CHUNK_SIZE="100M"
COMPRESS=true

show_help() {
    echo "=== GENERADOR MASIVO DE DICCIONARIOS CONFIGURABLE ==="
    echo ""
    echo "Uso: $0 [OPCIONES]"
    echo ""
    echo "Opciones:"
    echo "  -min N       Longitud mínima (default: 8)"
    echo "  -max N       Longitud máxima (default: 12)"
    echo "  -charset X   Conjunto de caracteres"
    echo "               Opciones predefinidas:"
    echo "                 lower     - solo minúsculas"
    echo "                 upper     - solo mayúsculas"
    echo "                 alpha     - letras min+may"
    echo "                 numeric   - solo números"
    echo "                 alnum     - letras + números"
    echo "                 full      - todos los caracteres"
    echo "                 custom    - personalizado"
    echo "  -pattern P   Patrón específico (ej: pass@@@)"
    echo "  -output X    Archivo de salida base (default: diccionario_masivo)"
    echo "  -chunk S     Tamaño de chunks (default: 100M)"
    echo "  -no-compress No comprimir el archivo final"
    echo "  -help        Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0 -min 6 -max 10 -charset alnum"
    echo "  $0 -min 8 -max 8 -charset numeric -pattern 19@@2024"
    echo "  $0 -min 4 -max 6 -charset custom"
}

# Procesar argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        -min)
            MIN_LENGTH="$2"
            shift 2
            ;;
        -max)
            MAX_LENGTH="$2"
            shift 2
            ;;
        -charset)
            case $2 in
                lower) CHARSET="abcdefghijklmnopqrstuvwxyz" ;;
                upper) CHARSET="ABCDEFGHIJKLMNOPQRSTUVWXYZ" ;;
                alpha) CHARSET="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ" ;;
                numeric) CHARSET="0123456789" ;;
                alnum) CHARSET="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789" ;;
                full) CHARSET="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_-+=[]{}|;:,.<>?/" ;;
                custom)
                    read -p "Ingresa los caracteres personalizados: " CUSTOM_CHARS
                    CHARSET="$CUSTOM_CHARS"
                    ;;
                *) CHARSET="$2" ;;
            esac
            shift 2
            ;;
        -pattern)
            PATTERN="$2"
            shift 2
            ;;
        -output)
            BASE_OUTPUT="$2"
            shift 2
            ;;
        -chunk)
            CHUNK_SIZE="$2"
            shift 2
            ;;
        -no-compress)
            COMPRESS=false
            shift
            ;;
        -help)
            show_help
            exit 0
            ;;
        *)
            echo "Opción desconocida: $1"
            show_help
            exit 1
            ;;
    esac
done

# Mostrar configuración
echo "=== CONFIGURACIÓN DEL DICCIONARIO MASIVO ==="
echo "Longitud: $MIN_LENGTH - $MAX_LENGTH caracteres"
echo "Charset: $CHARSET"
echo "Patrón: ${PATTERN:-Ninguno}"
echo "Chunk size: $CHUNK_SIZE"
echo "Output: $BASE_OUTPUT"
echo "Comprimir: $COMPRESS"
echo ""

# Calcular estimación
echo "Calculando estimación de tamaño..."
if [ -n "$PATTERN" ]; then
    ESTIMATE=$(crunch $MIN_LENGTH $MAX_LENGTH -t "$PATTERN" 2>/dev/null | grep -o " [0-9]* .* bytes" || echo " (ejecutando con patrón)")
else
    ESTIMATE=$(crunch $MIN_LENGTH $MAX_LENGTH $CHARSET 2>/dev/null | grep -o " [0-9]* .* bytes" || echo " (calculando...)")
fi
echo "Tamaño estimado:$ESTIMATE"
echo ""

# Confirmación
read -p "¿Continuar con la generación? (s/n): " confirm
if [[ ! $confirm =~ ^[Ss]$ ]]; then
    echo "Operación cancelada."
    exit 0
fi

# Crear directorio para chunks
CHUNK_DIR="${BASE_OUTPUT}_chunks"
mkdir -p "$CHUNK_DIR"
cd "$CHUNK_DIR"

echo "Iniciando generación en chunks..."
echo "Hora de inicio: $(date)"

# Generar con o sin patrón
if [ -n "$PATTERN" ]; then
    crunch $MIN_LENGTH $MAX_LENGTH -t "$PATTERN" -c "$CHUNK_SIZE"
else
    crunch $MIN_LENGTH $MAX_LENGTH $CHARSET -c "$CHUNK_SIZE"
fi

echo "Generación de chunks completada: $(date)"

# Combinar chunks
echo "Combinando chunks..."
COMBINED_FILE="../${BASE_OUTPUT}_completo.txt"
for chunk in crunch*.txt; do
    if [ -f "$chunk" ]; then
        cat "$chunk" >> "$COMBINED_FILE"
        echo "Procesado: $chunk"
    fi
done

# Volver al directorio original
cd ..

# Limpiar chunks
echo "Limpiando archivos temporales..."
rm -rf "$CHUNK_DIR"

# Comprimir si se solicita
if [ "$COMPRESS" = true ]; then
    echo "Comprimiendo archivo final..."
    gzip "$COMBINED_FILE"
    FINAL_FILE="${COMBINED_FILE}.gz"
else
    FINAL_FILE="$COMBINED_FILE"
fi

# Mostrar estadísticas finales
echo ""
echo "=== GENERACIÓN COMPLETADA ==="
echo "Archivo final: $FINAL_FILE"
echo "Tamaño: $(du -h "$FINAL_FILE" | cut -f1)"
echo "Líneas totales: $(wc -l < "${COMBINED_FILE%.gz}" 2>/dev/null || echo "N/A")"
echo "Hora de finalización: $(date)"
