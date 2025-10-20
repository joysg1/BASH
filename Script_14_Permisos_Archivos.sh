#!/bin/bash

# Script con opciones predefinidas para múltiples archivos
echo "=== MENÚ DE PERMISOS PARA MÚLTIPLES ARCHIVOS ==="
echo "1. Permisos seguros (644) - Lectura para todos, escritura solo propietario"
echo "2. Permisos ejecutables (755) - Ejecución para todos"
echo "3. Permisos privados (600) - Solo propietario"
echo "4. Permisos completos (777) - Lectura, escritura y ejecución para todos"
echo "5. Personalizado - Ingresar permisos manualmente"

read -p "Seleccione una opción (1-5): " opcion

case $opcion in
    1) permisos="644";;
    2) permisos="755";;
    3) permisos="600";;
    4) permisos="777";;
    5) 
        read -p "Ingrese los permisos personalizados: " permisos
        ;;
    *)
        echo "Opción inválida"
        exit 1
        ;;
esac

# Solicitar múltiples archivos
read -p "Ingrese las rutas de los archivos (separados por espacio): " archivos

# Convertir a array
IFS=' ' read -ra array_archivos <<< "$archivos"

# Verificar que todos los archivos existen
archivos_validos=()
archivos_invalidos=()

for archivo in "${array_archivos[@]}"; do
    if [ -e "$archivo" ]; then
        archivos_validos+=("$archivo")
    else
        archivos_invalidos+=("$archivo")
    fi
done

# Mostrar archivos inválidos si los hay
if [ ${#archivos_invalidos[@]} -gt 0 ]; then
    echo "Advertencia: Los siguientes archivos no existen y serán omitidos:"
    printf ' - %s\n' "${archivos_invalidos[@]}"
    echo ""
fi

# Verificar que hay al menos un archivo válido
if [ ${#archivos_validos[@]} -eq 0 ]; then
    echo "Error: No se encontraron archivos válidos."
    exit 1
fi

# Mostrar información antes de cambiar
echo "Archivos que se modificarán (${#archivos_validos[@]} archivos):"
for archivo in "${archivos_validos[@]}"; do
    echo " - $archivo"
done

echo ""
echo "Permisos actuales:"
for archivo in "${archivos_validos[@]}"; do
    ls -l "$archivo"
done

# Confirmar acción
read -p "¿Está seguro de cambiar los permisos a $permisos para estos archivos? (s/n): " confirmar

if [ "$confirmar" != "s" ] && [ "$confirmar" != "S" ]; then
    echo "Operación cancelada."
    exit 0
fi

# Cambiar permisos de todos los archivos válidos
echo "Cambiando permisos..."
chmod "$permisos" "${archivos_validos[@]}"

# Verificar resultado
if [ $? -eq 0 ]; then
    echo "¡Permisos cambiados exitosamente!"
    echo ""
    echo "Nuevos permisos:"
    for archivo in "${archivos_validos[@]}"; do
        ls -l "$archivo"
    done
else
    echo "Error al cambiar los permisos para algunos archivos."
fi
