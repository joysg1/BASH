#!/bin/bash

echo "Opciones:"
echo "1. Ver todos los logs"
echo "2. Ver logs desde una fecha específica"
echo "3. Ver logs de un servicio específico"
echo "4. Ver logs de un servicio específico con rango de fechas"
echo "5. Ver logs en tiempo real"
echo "6. Buscar logs con un mensaje específico"

read -p "Ingrese el número de la opción deseada: " opcion

case $opcion in
  1)
    journalctl
    ;;
  2)
    read -p "Ingrese la fecha y hora desde (YYYY-MM-DD HH:MM:SS) o '1 hour ago', '1 day ago', etc.: " fecha
    journalctl --since "$fecha"
    ;;
  3)
    read -p "Ingrese el nombre del servicio (por ejemplo, ssh): " servicio
    journalctl -u $servicio
    ;;
  4)
    read -p "Ingrese el nombre del servicio (por ejemplo, ssh): " servicio
    read -p "Ingrese la fecha y hora desde (YYYY-MM-DD HH:MM:SS) o '1 hour ago', '1 day ago', etc.: " fecha
    journalctl -u $servicio --since "$fecha"
    ;;
  5)
    journalctl -f
    ;;
  6)
    read -p "Ingrese el nombre del servicio (por ejemplo, ssh): " servicio
    read -p "Ingrese la cadena de texto a buscar: " texto
    read -p "Ingrese la fecha y hora desde (YYYY-MM-DD HH:MM:SS) o '1 hour ago', '1 day ago', etc. (opcional): " fecha
    if [ -n "$fecha" ]; then
      journalctl -u $servicio --since "$fecha" | grep "$texto"
    else
      journalctl -u $servicio | grep "$texto"
    fi
    ;;
  *)
    echo "Opción inválida"
    ;;
esac
