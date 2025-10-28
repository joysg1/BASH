#!/bin/bash

# Script para deshabilitar el acceso de root por SSH
# Uso: sudo ./disable_root_ssh.sh

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar si se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Este script debe ejecutarse como root o con sudo${NC}"
    exit 1
fi

echo -e "${YELLOW}=== Script para deshabilitar acceso root por SSH ===${NC}\n"

# Archivo de configuración SSH
SSHD_CONFIG="/etc/ssh/sshd_config"
BACKUP_FILE="/etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)"

# Verificar que existe el archivo de configuración
if [ ! -f "$SSHD_CONFIG" ]; then
    echo -e "${RED}Error: No se encontró el archivo $SSHD_CONFIG${NC}"
    exit 1
fi

# Crear backup del archivo original
echo -e "${YELLOW}Creando backup en: $BACKUP_FILE${NC}"
cp "$SSHD_CONFIG" "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Backup creado exitosamente${NC}\n"
else
    echo -e "${RED}Error al crear backup${NC}"
    exit 1
fi

# Modificar la configuración
echo -e "${YELLOW}Modificando configuración SSH...${NC}"

# Verificar si ya existe la directiva PermitRootLogin
if grep -q "^PermitRootLogin" "$SSHD_CONFIG"; then
    # Si existe sin comentar, modificarla
    sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' "$SSHD_CONFIG"
    echo -e "${GREEN}Directiva PermitRootLogin modificada${NC}"
elif grep -q "^#PermitRootLogin" "$SSHD_CONFIG"; then
    # Si existe comentada, descomentar y modificar
    sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' "$SSHD_CONFIG"
    echo -e "${GREEN}Directiva PermitRootLogin descomentada y modificada${NC}"
else
    # Si no existe, agregarla al final
    echo "PermitRootLogin no" >> "$SSHD_CONFIG"
    echo -e "${GREEN}Directiva PermitRootLogin agregada${NC}"
fi

# Verificar la sintaxis del archivo de configuración
echo -e "\n${YELLOW}Verificando sintaxis de la configuración...${NC}"
sshd -t

if [ $? -eq 0 ]; then
    echo -e "${GREEN}La configuración es válida${NC}\n"
else
    echo -e "${RED}Error en la configuración. Restaurando backup...${NC}"
    cp "$BACKUP_FILE" "$SSHD_CONFIG"
    echo -e "${YELLOW}Backup restaurado${NC}"
    exit 1
fi

# Mostrar la configuración actual
echo -e "${YELLOW}Configuración actual:${NC}"
grep "^PermitRootLogin" "$SSHD_CONFIG"

# Preguntar si desea reiniciar el servicio SSH
echo -e "\n${YELLOW}¿Desea reiniciar el servicio SSH ahora? (s/n)${NC}"
read -r RESPUESTA

if [[ "$RESPUESTA" =~ ^[Ss]$ ]]; then
    echo -e "${YELLOW}Reiniciando servicio SSH...${NC}"
    
    # Intentar con systemctl primero
    if command -v systemctl &> /dev/null; then
        systemctl restart sshd || systemctl restart ssh
    else
        # Si no existe systemctl, usar service
        service sshd restart || service ssh restart
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Servicio SSH reiniciado exitosamente${NC}"
        echo -e "${GREEN}El acceso de root por SSH ha sido deshabilitado${NC}"
    else
        echo -e "${RED}Error al reiniciar el servicio SSH${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}Los cambios se aplicarán cuando reinicies el servicio SSH manualmente:${NC}"
    echo "  sudo systemctl restart sshd"
    echo "  o"
    echo "  sudo service ssh restart"
fi

echo -e "\n${GREEN}=== Proceso completado ===${NC}"
echo -e "${YELLOW}Archivo de backup: $BACKUP_FILE${NC}"
echo -e "${YELLOW}IMPORTANTE: Asegúrate de tener acceso con otro usuario antes de cerrar esta sesión${NC}"
