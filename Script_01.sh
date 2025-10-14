#!/bin/bash

# Título
echo "Información del Equipo"
echo "---------------------"
echo "Fecha y hora: $(date +'%d/%m/%Y %H:%M:%S')"
echo ""

# Sistema
echo "### Sistema ###"
echo "Sistema operativo: $(cat /etc/os-release | grep "NAME" | awk -F "=" '{print $2}' | tr -d '"')"
echo "Versión del sistema operativo: $(cat /etc/os-release | grep "VERSION_ID" | awk -F "=" '{print $2}' | tr -d '"')"
echo "Arquitectura: $(uname -m)"
echo ""

# Procesador
echo "### Procesador ###"
echo "Arquitectura del procesador: $(lscpu | grep "Architecture" | awk '{print $2}')"
echo "Número de CPUs: $(lscpu | grep "CPU(s)" | awk '{print $2}')"
echo ""

# Memoria RAM
echo "### Memoria RAM ###"
echo "Memoria total: $(free -h | grep "Mem" | awk '{print $2}')"
echo "Memoria utilizada: $(free -h | grep "Mem" | awk '{print $3}')"
echo "Memoria disponible: $(free -h | grep "Mem" | awk '{print $4}')"
echo ""

# Disco duro
echo "### Disco duro ###"
echo "Uso del disco duro:"
df -h | grep "/dev" | awk '{print $5, $6}'
echo ""

# Tarjeta gráfica
echo "### Tarjeta gráfica ###"
echo "Tarjeta gráfica: $(lspci | grep " VGA")"
echo ""

# Red
echo "### Red ###"
echo "Dirección IP: $(ip addr show | grep "inet " | awk '{print $2}')"
echo ""

# Pausa antes de cerrar
read -p "Presiona enter para continuar..."
