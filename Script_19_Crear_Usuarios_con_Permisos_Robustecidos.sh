#!/bin/bash

# Script para gestionar usuarios con permisos robustecidos
# Debe ejecutarse como root

set -e

# Colores para mensajes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # Sin color

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Error: Este script debe ejecutarse como root${NC}"
    echo -e "${YELLOW}Ejecuta: sudo $0${NC}"
    exit 1
fi

# Función para pausar
pausar() {
    echo ""
    read -p "Presiona ENTER para continuar..."
    clear
}

# Función para mostrar el banner
mostrar_banner() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                        ║${NC}"
    echo -e "${CYAN}║       ${GREEN}GESTOR DE USUARIOS CON SEGURIDAD ROBUSTECIDA${CYAN}   ║${NC}"
    echo -e "${CYAN}║                                                        ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Función para crear usuario con permisos robustecidos
crear_usuario_seguro() {
    mostrar_banner
    echo -e "${BLUE}═══ CREAR NUEVO USUARIO SEGURO ═══${NC}"
    echo ""
    
    read -p "Ingresa el nombre del nuevo usuario: " NUEVO_USUARIO
    
    # Verificar si el usuario ya existe
    if id "$NUEVO_USUARIO" &>/dev/null; then
        echo -e "${RED}❌ Error: El usuario '$NUEVO_USUARIO' ya existe${NC}"
        pausar
        return
    fi
    
    echo ""
    echo -e "${YELLOW}Creando usuario '$NUEVO_USUARIO'...${NC}"
    
    # Crear el usuario
    useradd -m -s /bin/bash "$NUEVO_USUARIO"
    echo -e "${GREEN}✓ Usuario creado${NC}"
    
    # Establecer contraseña
    echo ""
    echo -e "${YELLOW}Ahora debes establecer una contraseña segura:${NC}"
    passwd "$NUEVO_USUARIO"
    
    # Aplicar robustecimiento
    echo ""
    echo -e "${GREEN}═══ Aplicando Configuración de Seguridad ═══${NC}"
    sleep 1
    
    # 1. Proteger /etc/shadow
    chmod 000 /etc/shadow
    chown root:root /etc/shadow
    echo -e "${GREEN}✓${NC} Archivo /etc/shadow protegido (no visible para usuarios)"
    
    # 2. Proteger /etc/gshadow
    chmod 000 /etc/gshadow
    chown root:root /etc/gshadow
    echo -e "${GREEN}✓${NC} Archivo /etc/gshadow protegido"
    
    # 3. Asegurar archivos básicos
    chmod 644 /etc/passwd
    chmod 644 /etc/group
    echo -e "${GREEN}✓${NC} Archivos de configuración asegurados"
    
    # 4. Restringir directorio home
    chmod 750 /home/"$NUEVO_USUARIO"
    echo -e "${GREEN}✓${NC} Directorio home con acceso restringido"
    
    # 5. Configurar umask restrictivo
    echo "umask 027" >> /home/"$NUEVO_USUARIO"/.bashrc
    echo -e "${GREEN}✓${NC} Configurado umask restrictivo para archivos nuevos"
    
    # 6. Restringir logs
    if [ -d /var/log ]; then
        chmod 750 /var/log
        echo -e "${GREEN}✓${NC} Acceso a logs del sistema restringido"
    fi
    
    # 7. Proteger SSH si existe
    if [ -d /etc/ssh ]; then
        chmod 644 /etc/ssh/sshd_config 2>/dev/null || true
        chmod 600 /etc/ssh/ssh_host_*_key 2>/dev/null || true
        echo -e "${GREEN}✓${NC} Configuración SSH protegida"
    fi
    
    # 8. Restringir cron
    echo "$NUEVO_USUARIO" >> /etc/cron.deny 2>/dev/null || true
    echo -e "${GREEN}✓${NC} Acceso a tareas programadas (cron) restringido"
    
    # 9. Configurar límites de recursos
    cat >> /etc/security/limits.conf << EOF
$NUEVO_USUARIO    hard    nproc    100
$NUEVO_USUARIO    hard    nofile   1024
$NUEVO_USUARIO    hard    cpu      60
EOF
    echo -e "${GREEN}✓${NC} Límites de recursos del sistema configurados"
    
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ Usuario '$NUEVO_USUARIO' creado exitosamente${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}Restricciones aplicadas:${NC}"
    echo "  • No puede ver contraseñas del sistema (/etc/shadow)"
    echo "  • Su directorio home es privado"
    echo "  • No puede ver logs del sistema"
    echo "  • No puede programar tareas con cron"
    echo "  • Tiene límites en uso de recursos"
    echo "  • No tiene privilegios de administrador"
    
    pausar
}

# Función para verificar permisos actuales
verificar_permisos() {
    mostrar_banner
    echo -e "${BLUE}═══ VERIFICACIÓN DE PERMISOS DEL SISTEMA ═══${NC}"
    echo ""
    
    echo -e "${CYAN}Permisos de archivos sensibles:${NC}"
    echo ""
    ls -lh /etc/shadow /etc/gshadow /etc/passwd /etc/group 2>/dev/null || echo "Algunos archivos no encontrados"
    
    echo ""
    echo -e "${CYAN}Permisos del directorio de logs:${NC}"
    ls -ldh /var/log 2>/dev/null || echo "Directorio no encontrado"
    
    echo ""
    echo -e "${CYAN}Usuarios del sistema:${NC}"
    echo ""
    awk -F: '$3 >= 1000 {printf "%-20s UID: %-6s Home: %s\n", $1, $3, $6}' /etc/passwd
    
    pausar
}

# Función para restaurar permisos estándar
restaurar_permisos() {
    mostrar_banner
    echo -e "${BLUE}═══ RESTAURAR PERMISOS ESTÁNDAR ═══${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  ADVERTENCIA ⚠️${NC}"
    echo "Esta opción restaurará los permisos estándar del sistema."
    echo "Útil si experimentas problemas con servicios de autenticación."
    echo ""
    read -p "¿Estás seguro? (si/no): " confirmacion
    
    if [ "$confirmacion" != "si" ]; then
        echo -e "${YELLOW}Operación cancelada${NC}"
        pausar
        return
    fi
    
    echo ""
    echo -e "${GREEN}Restaurando permisos estándar...${NC}"
    
    chmod 640 /etc/shadow
    chown root:shadow /etc/shadow
    echo -e "${GREEN}✓${NC} /etc/shadow restaurado (640)"
    
    chmod 640 /etc/gshadow
    chown root:shadow /etc/gshadow
    echo -e "${GREEN}✓${NC} /etc/gshadow restaurado (640)"
    
    chmod 644 /etc/passwd
    chmod 644 /etc/group
    echo -e "${GREEN}✓${NC} Archivos básicos restaurados"
    
    chmod 755 /var/log
    echo -e "${GREEN}✓${NC} Permisos de logs restaurados"
    
    echo ""
    echo -e "${GREEN}✓ Permisos estándar restaurados${NC}"
    
    pausar
}

# Función para eliminar usuario
eliminar_usuario() {
    mostrar_banner
    echo -e "${BLUE}═══ ELIMINAR USUARIO ═══${NC}"
    echo ""
    
    echo -e "${CYAN}Usuarios disponibles:${NC}"
    awk -F: '$3 >= 1000 {print "  • " $1}' /etc/passwd
    echo ""
    
    read -p "Ingresa el nombre del usuario a eliminar: " USUARIO_ELIMINAR
    
    if ! id "$USUARIO_ELIMINAR" &>/dev/null; then
        echo -e "${RED}❌ Error: El usuario '$USUARIO_ELIMINAR' no existe${NC}"
        pausar
        return
    fi
    
    echo ""
    echo -e "${YELLOW}⚠️  Vas a eliminar el usuario '$USUARIO_ELIMINAR'${NC}"
    read -p "¿Eliminar también el directorio home? (si/no): " eliminar_home
    
    if [ "$eliminar_home" = "si" ]; then
        userdel -r "$USUARIO_ELIMINAR" 2>/dev/null
        echo -e "${GREEN}✓ Usuario y directorio home eliminados${NC}"
    else
        userdel "$USUARIO_ELIMINAR" 2>/dev/null
        echo -e "${GREEN}✓ Usuario eliminado (directorio home preservado)${NC}"
    fi
    
    pausar
}

# Función para mostrar ayuda
mostrar_ayuda() {
    mostrar_banner
    echo -e "${BLUE}═══ INFORMACIÓN Y AYUDA ═══${NC}"
    echo ""
    echo -e "${CYAN}¿Qué hace este script?${NC}"
    echo "Este script crea usuarios con configuraciones de seguridad robustecidas"
    echo "para proteger información sensible del sistema."
    echo ""
    echo -e "${CYAN}Medidas de seguridad aplicadas:${NC}"
    echo "  1. Protege el archivo /etc/shadow (contraseñas cifradas)"
    echo "  2. Restringe acceso al directorio home del usuario"
    echo "  3. Configura permisos restrictivos para archivos nuevos"
    echo "  4. Limita acceso a logs del sistema"
    echo "  5. Bloquea el uso de tareas programadas (cron)"
    echo "  6. Establece límites de recursos del sistema"
    echo ""
    echo -e "${YELLOW}⚠️  Nota importante:${NC}"
    echo "Los permisos 000 en /etc/shadow son MUY restrictivos."
    echo "Si experimentas problemas de autenticación, usa la opción"
    echo "'Restaurar permisos estándar' del menú."
    echo ""
    echo -e "${CYAN}Permisos recomendados alternativos:${NC}"
    echo "  • /etc/shadow: 640 (más compatible con servicios)"
    echo "  • /etc/shadow: 000 (máxima seguridad, puede causar problemas)"
    
    pausar
}

# Menú principal
menu_principal() {
    while true; do
        mostrar_banner
        echo -e "${CYAN}┌─────────────────────────────────────────────┐${NC}"
        echo -e "${CYAN}│${NC}              ${GREEN}MENÚ PRINCIPAL${NC}                 ${CYAN}│${NC}"
        echo -e "${CYAN}├─────────────────────────────────────────────┤${NC}"
        echo -e "${CYAN}│${NC}                                             ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC}  ${YELLOW}1.${NC} Crear usuario seguro                   ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC}  ${YELLOW}2.${NC} Verificar permisos del sistema         ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC}  ${YELLOW}3.${NC} Restaurar permisos estándar            ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC}  ${YELLOW}4.${NC} Eliminar usuario                       ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC}  ${YELLOW}5.${NC} Ayuda e información                    ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC}  ${YELLOW}6.${NC} Salir                                  ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC}                                             ${CYAN}│${NC}"
        echo -e "${CYAN}└─────────────────────────────────────────────┘${NC}"
        echo ""
        read -p "Selecciona una opción [1-6]: " opcion
        
        case $opcion in
            1)
                crear_usuario_seguro
                ;;
            2)
                verificar_permisos
                ;;
            3)
                restaurar_permisos
                ;;
            4)
                eliminar_usuario
                ;;
            5)
                mostrar_ayuda
                ;;
            6)
                clear
                echo -e "${GREEN}¡Hasta luego!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Opción inválida${NC}"
                sleep 1
                ;;
        esac
    done
}

# Iniciar el script
menu_principal
