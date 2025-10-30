#!/bin/bash

# Script para instalar VMware ovftool en Linux
# Autor: Script de instalación automatizada
# Fecha: 2025

set -e  # Salir si hay algún error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # Sin color

echo -e "${GREEN}=== Instalador de VMware ovftool ===${NC}\n"

# Verificar si ya está instalado
if command -v ovftool &> /dev/null; then
    echo -e "${YELLOW}ovftool ya está instalado:${NC}"
    ovftool --version
    read -p "¿Deseas reinstalar? (s/n): " reinstall
    if [[ ! $reinstall =~ ^[Ss]$ ]]; then
        echo "Instalación cancelada."
        exit 0
    fi
fi

# URL de descarga (versión 4.6.0 - última versión gratuita)
OVFTOOL_URL="https://developer.broadcom.com/tools/open-virtualization-format-ovf-tool/latest"
OVFTOOL_VERSION="4.6.2"
OVFTOOL_BUILD="22220919"
DOWNLOAD_FILE="VMware-ovftool-${OVFTOOL_VERSION}-${OVFTOOL_BUILD}-lin.x86_64.bundle"

echo -e "${YELLOW}Nota:${NC} Necesitas descargar ovftool manualmente desde:"
echo "https://developer.broadcom.com/tools/open-virtualization-format-ovf-tool/latest"
echo ""
echo -e "${YELLOW}Pasos:${NC}"
echo "1. Visita el enlace anterior"
echo "2. Regístrate/inicia sesión (es gratis)"
echo "3. Descarga la versión para Linux (.bundle)"
echo "4. Coloca el archivo .bundle en este directorio"
echo ""

# Buscar archivos .bundle en el directorio actual
BUNDLE_FILE=$(find . -maxdepth 1 -name "VMware-ovftool-*.bundle" -type f | head -n 1)

if [ -z "$BUNDLE_FILE" ]; then
    echo -e "${RED}Error:${NC} No se encontró ningún archivo .bundle en el directorio actual"
    echo ""
    read -p "¿Deseas especificar la ruta manualmente? (s/n): " manual
    if [[ $manual =~ ^[Ss]$ ]]; then
        read -p "Introduce la ruta completa al archivo .bundle: " BUNDLE_FILE
        if [ ! -f "$BUNDLE_FILE" ]; then
            echo -e "${RED}Error:${NC} El archivo no existe"
            exit 1
        fi
    else
        echo "Por favor, descarga el archivo y vuelve a ejecutar el script."
        exit 1
    fi
fi

echo -e "${GREEN}Archivo encontrado:${NC} $BUNDLE_FILE"
echo ""

# Hacer el archivo ejecutable
echo -e "${YELLOW}Haciendo el bundle ejecutable...${NC}"
chmod +x "$BUNDLE_FILE"

# Instalar ovftool
echo -e "${YELLOW}Instalando ovftool (requiere sudo)...${NC}"
sudo "$BUNDLE_FILE" --eulas-agreed --required

# Verificar instalación
if command -v ovftool &> /dev/null; then
    echo -e "\n${GREEN}✓ ovftool instalado correctamente${NC}"
    echo ""
    ovftool --version
    echo ""
    
    # Mostrar ubicación
    echo -e "${GREEN}Ubicación:${NC} $(which ovftool)"
    
    # Crear enlace simbólico si no existe en /usr/local/bin
    if [ ! -L "/usr/local/bin/ovftool" ]; then
        echo -e "\n${YELLOW}Creando enlace simbólico en /usr/local/bin...${NC}"
        sudo ln -sf /usr/bin/ovftool /usr/local/bin/ovftool 2>/dev/null || true
    fi
    
    echo -e "\n${GREEN}=== Instalación completada ===${NC}"
    echo ""
    echo "Ejemplo de uso:"
    echo "  ovftool archivo.vmx salida.ova"
    echo "  ovftool --compress=9 archivo.vmx salida.ova"
    
else
    echo -e "\n${RED}✗ Error en la instalación${NC}"
    exit 1
fi
