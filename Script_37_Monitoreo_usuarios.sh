#!/bin/bash

# Script para monitorear actividad de usuarios en el sistema
# Autor: [Tu nombre]
# Fecha: $(date +%Y-%m-%d)

# Colores para el menú
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Función para detectar la distribución
detectar_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ -f /etc/arch-release ]; then
        echo "arch"
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    else
        echo "unknown"
    fi
}

# Función para verificar e instalar finger
instalar_finger() {
    local distro=$(detectar_distro)
    
    case $distro in
        "arch"|"manjaro"|"endeavouros")
            echo -e "${YELLOW}Distribución basada en Arch detectada.${NC}"
            echo -e "${GREEN}Para instalar finger ejecuta: sudo pacman -S finger${NC}"
            ;;
        "debian"|"ubuntu"|"mint")
            echo -e "${YELLOW}Distribución basada en Debian detectada.${NC}"
            echo -e "${GREEN}Para instalar finger ejecuta: sudo apt install finger${NC}"
            ;;
        "fedora"|"rhel"|"centos")
            echo -e "${YELLOW}Distribución basada en Red Hat detectada.${NC}"
            echo -e "${GREEN}Para instalar finger ejecuta: sudo dnf install finger${NC}"
            ;;
        "opensuse"|"suse")
            echo -e "${YELLOW}Distribución basada en openSUSE detectada.${NC}"
            echo -e "${GREEN}Para instalar finger ejecuta: sudo zypper install finger${NC}"
            ;;
        *)
            echo -e "${YELLOW}Distribución no identificada.${NC}"
            echo -e "${GREEN}Intenta instalar finger con tu gestor de paquetes.${NC}"
            ;;
    esac
}

# Función para mostrar información de la distribución
info_distribucion() {
    local distro=$(detectar_distro)
    echo -e "${YELLOW}Distribución detectada:${NC} $distro"
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo -e "${YELLOW}Nombre:${NC} $NAME"
        echo -e "${YELLOW}Versión:${NC} $VERSION"
    fi
}

# Función para mostrar el encabezado
mostrar_encabezado() {
    clear
    echo -e "${CYAN}"
    echo "================================================"
    echo "    MONITOR DE ACTIVIDAD DE USUARIOS"
    echo "================================================"
    info_distribucion
    echo -e "${NC}"
}

# Función para pausar y esperar entrada del usuario
pausar() {
    echo -e "\n${YELLOW}Presiona Enter para continuar...${NC}"
    read
}

# Función para mostrar información del comando WHO
comando_who() {
    mostrar_encabezado
    echo -e "${GREEN}=== INFORMACIÓN DEL COMANDO WHO ===${NC}"
    echo -e "${YELLOW}Descripción: Muestra quién está actualmente conectado al sistema${NC}"
    echo -e "${BLUE}Sintaxis: who [opciones]${NC}"
    echo ""
    echo -e "${PURPLE}Opciones comunes:${NC}"
    echo "  -a: Muestra toda la información disponible"
    echo "  -H: Muestra encabezados de columnas"
    echo "  -q: Muestra solo los nombres y el número de usuarios"
    echo "  -b: Muestra la hora del último arranque del sistema"
    echo ""
    echo -e "${PURPLE}Ejecutando comando: who -aH${NC}"
    echo "----------------------------------------"
    who -aH
    pausar
}

# Función para mostrar información del comando LAST
comando_last() {
    mostrar_encabezado
    echo -e "${GREEN}=== INFORMACIÓN DEL COMANDO LAST ===${NC}"
    echo -e "${YELLOW}Descripción: Muestra el historial de inicios de sesión${NC}"
    echo -e "${BLUE}Sintaxis: last [opciones] [usuario] [terminal]${NC}"
    echo ""
    echo -e "${PURPLE}Opciones comunes:${NC}"
    echo "  -n N: Muestra solo las últimas N entradas"
    echo "  -x: Muestra eventos de apagado y cambios de nivel de ejecución"
    echo "  -a: Muestra el nombre de host en la última columna"
    echo "  -i: Muestra direcciones IP en lugar de nombres de host"
    echo "  -f archivo: Usa un archivo específico en lugar de /var/log/wtmp"
    echo ""
    echo -e "${PURPLE}Ejecutando comando: last -n 10${NC}"
    echo "----------------------------------------"
    last -n 10
    pausar
}

# Función para mostrar información del comando W
comando_w() {
    mostrar_encabezado
    echo -e "${GREEN}=== INFORMACIÓN DEL COMANDO W ===${NC}"
    echo -e "${YELLOW}Descripción: Muestra quién está conectado y qué está haciendo${NC}"
    echo -e "${BLUE}Sintaxis: w [opciones] [usuario]${NC}"
    echo ""
    echo -e "${PURPLE}Opciones comunes:${NC}"
    echo "  -h: No muestra el encabezado"
    echo "  -s: Formato corto (sin tiempo de inicio, JCPU, PCPU)"
    echo "  -f: Muestra/oculta el campo FROM (origen)"
    echo "  -i: Muestra direcciones IP en lugar de nombres de host"
    echo "  -u: Ignora el nombre de usuario cuando se muestra el proceso actual"
    echo ""
    echo -e "${PURPLE}Ejecutando comando: w${NC}"
    echo "----------------------------------------"
    w
    pausar
}

# Función para mostrar información del comando FINGER
comando_finger() {
    mostrar_encabezado
    echo -e "${GREEN}=== INFORMACIÓN DEL COMANDO FINGER ===${NC}"
    echo -e "${YELLOW}Descripción: Muestra información sobre usuarios del sistema${NC}"
    echo -e "${BLUE}Sintaxis: finger [opciones] [usuario]${NC}"
    echo ""
    echo -e "${PURPLE}Opciones comunes:${NC}"
    echo "  -l: Formato largo de salida"
    echo "  -s: Formato corto de salida"
    echo "  -p: No muestra el contenido del archivo .plan"
    echo "  -m: Coincide con nombres de usuario exactos"
    echo ""
    
    # Verificar si finger está instalado
    if command -v finger &> /dev/null; then
        echo -e "${PURPLE}Ejecutando comando: finger -s${NC}"
        echo "----------------------------------------"
        finger -s 2>/dev/null
        
        # Verificar si hay usuarios conectados para mostrar con más detalle
        if who | grep -q .; then
            echo -e "\n${PURPLE}Información detallada de usuarios conectados:${NC}"
            echo "----------------------------------------"
            for user in $(who | awk '{print $1}' | sort -u); do
                echo -e "${CYAN}Usuario: $user${NC}"
                finger -l "$user" 2>/dev/null | head -10
                echo "---"
            done
        fi
    else
        echo -e "${RED}El comando 'finger' no está instalado en el sistema.${NC}"
        echo ""
        echo -e "${YELLOW}Instrucciones de instalación:${NC}"
        instalar_finger
        
        echo ""
        echo -e "${YELLOW}Alternativas disponibles:${NC}"
        echo "  • getent passwd [usuario] - Información básica de usuario"
        echo "  • chage -l [usuario] - Información de caducidad de contraseña"
        echo "  • passwd -S [usuario] - Estado de la contraseña"
        
        # Mostrar alternativas con información disponible
        echo ""
        echo -e "${PURPLE}Información básica de usuarios (alternativa):${NC}"
        echo "----------------------------------------"
        echo -e "${CYAN}Usuarios conectados:${NC}"
        who | awk '{print $1}' | sort -u | while read user; do
            echo "Usuario: $user"
            getent passwd "$user" | cut -d: -f5,6,7
            echo "---"
        done
    fi
    pausar
}

# Función para mostrar información del comando ID
comando_id() {
    mostrar_encabezado
    echo -e "${GREEN}=== INFORMACIÓN DEL COMANDO ID ===${NC}"
    echo -e "${YELLOW}Descripción: Muestra identidades de usuario y grupo${NC}"
    echo -e "${BLUE}Sintaxis: id [opciones] [usuario]${NC}"
    echo ""
    echo -e "${PURPLE}Opciones comunes:${NC}"
    echo "  -u: Muestra solo el UID (User ID)"
    echo "  -g: Muestra solo el GID (Group ID)"
    echo "  -G: Muestra todos los GIDs (grupos)"
    echo "  -n: Muestra nombres en lugar de números"
    echo "  -r: Muestra el ID real en lugar del efectivo"
    echo "  -Z: Muestra contexto de seguridad SELinux (solo con SELinux)"
    echo ""
    echo -e "${PURPLE}Ejecutando comando: id${NC}"
    echo "----------------------------------------"
    id
    echo ""
    echo -e "${PURPLE}Información detallada:${NC}"
    echo "----------------------------------------"
    echo -e "${CYAN}Usuario actual:${NC} $(id -un)"
    echo -e "${CYAN}UID:${NC} $(id -u)"
    echo -e "${CYAN}Grupo primario:${NC} $(id -gn)"
    echo -e "${CYAN}GID:${NC} $(id -g)"
    echo -e "${CYAN}Grupos secundarios:${NC} $(id -Gn)"
    
    # Verificar si estamos en sistema con SELinux
    if command -v sestatus &> /dev/null; then
        echo ""
        echo -e "${PURPLE}Contexto SELinux:${NC}"
        id -Z 2>/dev/null || echo "SELinux no activo o no disponible"
    fi
    pausar
}

# Función para mostrar información del sistema
info_sistema() {
    mostrar_encabezado
    echo -e "${GREEN}=== INFORMACIÓN DEL SISTEMA ===${NC}"
    echo -e "${YELLOW}Hostname:${NC} $(hostname)"
    echo -e "${YELLOW}Sistema operativo:${NC} $(uname -o)"
    echo -e "${YELLOW}Kernel:${NC} $(uname -r)"
    echo -e "${YELLOW}Arquitectura:${NC} $(uname -m)"
    echo -e "${YELLOW}Usuarios conectados:${NC} $(who | wc -l)"
    echo -e "${YELLOW}Tiempo de actividad del sistema:${NC}"
    uptime
    echo ""
    echo -e "${YELLOW}Fecha y hora actual:${NC} $(date)"
    echo -e "${YELLOW}Zona horaria:${NC} $(timedatectl show --property=Timezone --value 2>/dev/null || date +%Z)"
    
    # Información de memoria
    echo ""
    echo -e "${YELLOW}Uso de memoria:${NC}"
    free -h | head -2
    
    pausar
}

# Función para mostrar el menú principal
mostrar_menu() {
    mostrar_encabezado
    echo -e "${GREEN}Selecciona una opción:${NC}"
    echo ""
    echo -e "${BLUE}1.${NC} Comando WHO - Usuarios conectados"
    echo -e "${BLUE}2.${NC} Comando LAST - Historial de inicios de sesión"
    echo -e "${BLUE}3.${NC} Comando W - Usuarios y sus procesos"
    echo -e "${BLUE}4.${NC} Comando FINGER - Información de usuarios"
    echo -e "${BLUE}5.${NC} Comando ID - Identidades de usuario/grupo"
    echo -e "${BLUE}6.${NC} Información del sistema"
    echo -e "${BLUE}7.${NC} Mostrar todos los comandos (resumen)"
    echo -e "${BLUE}8.${NC} Verificar e instalar finger"
    echo -e "${RED}0.${NC} Salir"
    echo ""
    echo -n -e "${YELLOW}Ingresa tu opción [0-8]: ${NC}"
}

# Función para mostrar resumen de todos los comandos
mostrar_resumen() {
    mostrar_encabezado
    echo -e "${GREEN}=== RESUMEN DE ACTIVIDAD DE USUARIOS ===${NC}"
    
    echo -e "\n${CYAN}1. WHO - Usuarios actualmente conectados:${NC}"
    echo "----------------------------------------"
    who -H
    
    echo -e "\n${CYAN}2. W - Qué están haciendo los usuarios:${NC}"
    echo "----------------------------------------"
    w -h
    
    echo -e "\n${CYAN}3. LAST - Últimos 5 inicios de sesión:${NC}"
    echo "----------------------------------------"
    last -n 5
    
    echo -e "\n${CYAN}4. ID - Información del usuario actual:${NC}"
    echo "----------------------------------------"
    id
    
    if command -v finger &> /dev/null; then
        echo -e "\n${CYAN}5. FINGER - Información de usuarios conectados:${NC}"
        echo "----------------------------------------"
        who | awk '{print $1}' | sort -u | head -3 | while read user; do
            echo "Usuario: $user"
            finger -s "$user" 2>/dev/null | grep -v "Login" | head -2
            echo "---"
        done
    else
        echo -e "\n${CYAN}5. FINGER - No disponible${NC}"
        echo "----------------------------------------"
        echo "Comando finger no instalado"
    fi
    
    pausar
}

# Función específica para instalar finger
instalar_finger_menu() {
    mostrar_encabezado
    echo -e "${GREEN}=== INSTALACIÓN DE FINGER ===${NC}"
    
    instalar_finger
    
    echo ""
    echo -e "${YELLOW}¿Quieres intentar instalar finger ahora? (s/N): ${NC}"
    read -r respuesta
    
    if [[ $respuesta =~ ^[Ss]$ ]]; then
        local distro=$(detectar_distro)
        
        case $distro in
            "arch"|"manjaro"|"endeavouros")
                if command -v sudo &> /dev/null && command -v pacman &> /dev/null; then
                    echo -e "${YELLOW}Ejecutando: sudo pacman -S finger${NC}"
                    sudo pacman -S finger
                else
                    echo -e "${RED}Error: sudo o pacman no disponibles${NC}"
                fi
                ;;
            "debian"|"ubuntu"|"mint")
                if command -v sudo &> /dev/null && command -v apt &> /dev/null; then
                    echo -e "${YELLOW}Ejecutando: sudo apt update && sudo apt install finger${NC}"
                    sudo apt update && sudo apt install finger
                else
                    echo -e "${RED}Error: sudo o apt no disponibles${NC}"
                fi
                ;;
            "fedora"|"rhel"|"centos")
                if command -v sudo &> /dev/null && command -v dnf &> /dev/null; then
                    echo -e "${YELLOW}Ejecutando: sudo dnf install finger${NC}"
                    sudo dnf install finger
                elif command -v sudo &> /dev/null && command -v yum &> /dev/null; then
                    echo -e "${YELLOW}Ejecutando: sudo yum install finger${NC}"
                    sudo yum install finger
                else
                    echo -e "${RED}Error: sudo o gestor de paquetes no disponibles${NC}"
                fi
                ;;
            *)
                echo -e "${RED}No se pudo determinar el comando de instalación${NC}"
                ;;
        esac
        
        # Verificar si la instalación fue exitosa
        if command -v finger &> /dev/null; then
            echo -e "${GREEN}¡Finger instalado correctamente!${NC}"
        else
            echo -e "${RED}La instalación falló. Revisa los mensajes de error.${NC}"
        fi
    else
        echo -e "${YELLOW}Instalación cancelada.${NC}"
    fi
    
    pausar
}

# Función principal
main() {
    # Verificar si el script se ejecuta como root
    if [[ $EUID -eq 0 ]]; then
        echo -e "${YELLOW}Advertencia: Ejecutando como root${NC}"
        sleep 1
    fi

    while true; do
        mostrar_menu
        read opcion
        
        case $opcion in
            1) comando_who ;;
            2) comando_last ;;
            3) comando_w ;;
            4) comando_finger ;;
            5) comando_id ;;
            6) info_sistema ;;
            7) mostrar_resumen ;;
            8) instalar_finger_menu ;;
            0) 
                echo -e "\n${GREEN}Saliendo del monitor de actividad...${NC}"
                exit 0 
                ;;
            *) 
                echo -e "\n${RED}Opción inválida. Por favor, selecciona una opción del 0 al 8.${NC}"
                sleep 2
                ;;
        esac
    done
}

# Manejar señal de interrupción (Ctrl+C)
trap 'echo -e "\n${RED}Interrumpido por el usuario. Saliendo...${NC}"; exit 1' INT

# Ejecutar función principal
main
