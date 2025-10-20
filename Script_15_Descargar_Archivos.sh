#!/bin/bash

# Script avanzado con múltiples opciones
echo "=== DESCARGADOR AVANZADO ==="

read -p "URL del archivo: " url

if [ -z "$url" ]; then
    echo "Error: URL requerida."
    exit 1
fi

# Opciones avanzadas
read -p "¿Cambiar nombre del archivo? (s/n): " cambiar_nombre
if [ "$cambiar_nombre" = "s" ] || [ "$cambinar_nombre" = "S" ]; then
    read -p "Nuevo nombre: " nuevo_nombre
fi

read -p "¿Especificar directorio de descarga? (s/n): " especificar_dir
if [ "$especificar_dir" = "s" ] || [ "$especificar_dir" = "S" ]; then
    read -p "Directorio: " directorio
    mkdir -p "$directorio"
fi

read -p "¿Continuar descarga interrumpida? (s/n): " continuar
read -p "¿Limitar velocidad de descarga? (s/n): " limitar_velocidad

# Construir comando wget
comando="wget"

# Agregar opciones según selección
if [ ! -z "$nuevo_nombre" ]; then
    comando="$comando -O $nuevo_nombre"
fi

if [ ! -z "$directorio" ]; then
    comando="$comando -P $directorio"
fi

if [ "$continuar" = "s" ] || [ "$continuar" = "S" ]; then
    comando="$comando -c"
fi

if [ "$limitar_velocidad" = "s" ] || [ "$limitar_velocidad" = "S" ]; then
    read -p "Velocidad límite (ej: 100k, 1m): " velocidad
    comando="$comando --limit-rate=$velocidad"
fi

# Agregar opciones útiles por defecto
comando="$comando --progress=bar --show-progress $url"

echo ""
echo "Ejecutando: $comando"
echo ""

# Ejecutar descarga
$comando

if [ $? -eq 0 ]; then
    echo ""
    echo "¡Descarga completada exitosamente!"
else
    echo ""
    echo "Error en la descarga."
fi
