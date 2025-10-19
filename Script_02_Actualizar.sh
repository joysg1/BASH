#!/bin/bash

# Script para actualizar diferentes distribuciones Linux
# Detecta automáticamente la distro y ejecuta los comandos apropiados

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # Sin color

# Verificar si se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: Este script debe ejecutarse como root o con sudo${NC}"
    exit 1
fi

echo -e "${GREEN}=== Actualizador Universal de Linux ===${NC}\n"

# Detectar la distribución
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo -e "${RED}No se pudo detectar la distribución${NC}"
    exit 1
fi

echo -e "${YELLOW}Distribución detectada: $PRETTY_NAME${NC}\n"

# Función para Ubuntu/Debian
update_debian() {
    echo -e "${GREEN}Actualizando Ubuntu/Debian...${NC}"
    apt update && apt upgrade -y && apt dist-upgrade -y && apt autoremove -y && apt autoclean
}

# Función para Fedora
update_fedora() {
    echo -e "${GREEN}Actualizando Fedora...${NC}"
    dnf upgrade -y && dnf autoremove -y
}

# Función para Arch Linux
update_arch() {
    echo -e "${GREEN}Actualizando Arch Linux...${NC}"
    sudo pacman -Syu && yay -Syu
}

# Función para openSUSE
update_opensuse() {
    echo -e "${GREEN}Actualizando openSUSE...${NC}"
    zypper refresh && zypper update -y && zypper dist-upgrade -y
}

# Función para CentOS/RHEL
update_centos() {
    echo -e "${GREEN}Actualizando CentOS/RHEL...${NC}"
    yum update -y && yum autoremove -y
}

# Función para Alpine
update_alpine() {
    echo -e "${GREEN}Actualizando Alpine Linux...${NC}"
    apk update && apk upgrade
}

# Ejecutar actualización según la distro
case $DISTRO in
    ubuntu|debian|linuxmint|pop)
        update_debian
        ;;
    fedora)
        update_fedora
        ;;
    arch|manjaro|endeavouros)
        update_arch
        ;;
    opensuse|opensuse-leap|opensuse-tumbleweed)
        update_opensuse
        ;;
    centos|rhel|rocky|almalinux)
        update_centos
        ;;
    alpine)
        update_alpine
        ;;
    *)
        echo -e "${RED}Distribución no soportada: $DISTRO${NC}"
        echo "Distros soportadas: Ubuntu, Debian, Fedora, Arch, openSUSE, CentOS, Alpine"
        exit 1
        ;;
esac

echo -e "\n${GREEN}¡Actualización completada!${NC}"
echo -e "${YELLOW}Se recomienda reiniciar si hubo actualizaciones del kernel${NC}"
