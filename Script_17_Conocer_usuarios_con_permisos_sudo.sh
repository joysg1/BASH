#!/bin/bash
# sudo_users.sh - Muestra usuarios con permisos sudo

echo "Usuarios con permisos de sudo:"
echo "=============================="

# Verificar grupo sudo (Debian/Ubuntu)
if getent group sudo &>/dev/null; then
    echo "Grupo sudo:"
    getent group sudo | cut -d: -f4 | tr ',' '\n'
fi

# Verificar grupo wheel (Red Hat/CentOS)
if getent group wheel &>/dev/null; then
    echo "Grupo wheel:"
    getent group wheel | cut -d: -f4 | tr ',' '\n'
fi

# Verificar permisos individuales en sudoers
echo -e "\nPermisos en /etc/sudoers:"
sudo cat /etc/sudoers /etc/sudoers.d/* 2>/dev/null | grep -vE '^($|#)' | grep -E '(ALL|sudo|wheel)'
