#!/bin/bash

# Gestor Interactivo de Aliases - Universal para todas las distros
# Autor: [Tu nombre]
# Versión: 4.0

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Archivos de configuración
ALIAS_FILE="$HOME/.bash_aliases"
BACKUP_DIR="$HOME/.alias_backups"
CONFIG_FILE="$HOME/.alias_manager.conf"

# Detectar distribución
detect_distro() {
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        DISTRO_NAME="$NAME"
        DISTRO_ID="$ID"
    else
        DISTRO_NAME="Desconocida"
        DISTRO_ID="unknown"
    fi
    
    # Detectar gestor de paquetes
    if command -v apt >/dev/null 2>&1; then
        PACKAGE_MANAGER="apt"
        PACKAGE_MANAGER_NAME="APT (Debian/Ubuntu)"
    elif command -v pacman >/dev/null 2>&1; then
        PACKAGE_MANAGER="pacman"
        PACKAGE_MANAGER_NAME="Pacman (Arch/Manjaro)"
    elif command -v dnf >/dev/null 2>&1; then
        PACKAGE_MANAGER="dnf"
        PACKAGE_MANAGER_NAME="DNF (Fedora)"
    elif command -v zypper >/dev/null 2>&1; then
        PACKAGE_MANAGER="zypper"
        PACKAGE_MANAGER_NAME="Zypper (openSUSE)"
    else
        PACKAGE_MANAGER="unknown"
        PACKAGE_MANAGER_NAME="Desconocido"
    fi
}

# Función mejorada para activar aliases
activate_aliases() {
    if [ -f "$ALIAS_FILE" ]; then
        # Verificar sintaxis primero
        if ! bash -n "$ALIAS_FILE" 2>/dev/null; then
            echo -e "${RED}❌ Error de sintaxis en el archivo de aliases${NC}"
            return 1
        fi
        
        # Cargar aliases en el shell actual
        if source "$ALIAS_FILE" 2>/dev/null; then
            echo -e "${GREEN}✓ Aliases activados correctamente${NC}"
            return 0
        else
            echo -e "${RED}❌ Error al cargar aliases${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠ No existe el archivo de aliases${NC}"
        return 1
    fi
}

# Función para verificar si un alias existe
alias_exists() {
    local alias_name="$1"
    # Verificar en el archivo
    grep -q "alias $alias_name=" "$ALIAS_FILE" 2>/dev/null
}

# Función para obtener el comando de un alias
get_alias_command() {
    local alias_name="$1"
    grep "alias $alias_name=" "$ALIAS_FILE" 2>/dev/null | cut -d"'" -f2
}

# Función para detectar si un comando necesita sudo - MEJORADA PARA TODAS LAS DISTROS
needs_sudo() {
    local command="$1"
    
    # Patrones de comandos que normalmente requieren sudo (multi-distro)
    local sudo_patterns=(
        # Gestores de paquetes
        "apt update" "apt upgrade" "apt install" "apt remove" "apt purge" "apt autoremove"
        "pacman -S" "pacman -Syu" "pacman -R" "pacman -Qs" "yay" "paru"
        "dnf install" "dnf update" "dnf remove" "dnf upgrade"
        "zypper install" "zypper update" "zypper remove"
        "snap install" "flatpak install"
        
        # Systemd y servicios
        "systemctl" "service" "journalctl" "loginctl"
        
        # Red y firewall
        "ufw" "iptables" "ip" "route" "dhcpcd" "netctl"
        
        # Discos y montaje
        "mount" "umount" "fdisk" "parted" "mkfs" "fsck" "blkid" "lsblk"
        
        # Usuarios y grupos
        "useradd" "userdel" "usermod" "groupadd" "groupdel" "passwd"
        "chown" "chmod" "chgrp" "visudo" "adduser" "deluser"
        
        # Sistema
        "reboot" "shutdown" "poweroff" "halt" "init" "telinit"
        "dmesg" "hwclock" "timedatectl" "localectl"
        
        # Otros
        "crontab" "at" "wall" "write" "mesg"
    )
    
    # Verificar si el comando contiene algún patrón que necesite sudo
    for pattern in "${sudo_patterns[@]}"; do
        if [[ "$command" == *"$pattern"* ]]; then
            return 0  # Necesita sudo
        fi
    done
    
    # Verificar si es un script que contiene comandos con sudo
    if [[ -f "$command" ]]; then
        if grep -q -E "sudo|root|apt|pacman|dnf|zypper|systemctl|mount|useradd|chown|chmod" "$command" 2>/dev/null; then
            return 0  # Probablemente necesita sudo
        fi
    fi
    
    return 1  # No necesita sudo
}

# Función para verificar si tenemos permisos de sudo
check_sudo_access() {
    if sudo -n true 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Función para sugerir comandos según la distribución
suggest_commands() {
    echo -e "${YELLOW}Comandos sugeridos para $DISTRO_NAME:${NC}"
    
    case "$PACKAGE_MANAGER" in
        "apt")
            echo "  sudo apt update && sudo apt upgrade"
            echo "  sudo apt install [paquete]"
            echo "  sudo apt remove [paquete]"
            echo "  sudo systemctl start [servicio]"
            ;;
        "pacman")
            echo "  sudo pacman -Syu"
            echo "  sudo pacman -S [paquete]"
            echo "  sudo pacman -R [paquete]"
            echo "  yay -S [paquete] (AUR)"
            echo "  sudo systemctl start [servicio]"
            ;;
        "dnf")
            echo "  sudo dnf update"
            echo "  sudo dnf install [paquete]"
            echo "  sudo dnf remove [paquete]"
            echo "  sudo systemctl start [servicio]"
            ;;
        "zypper")
            echo "  sudo zypper update"
            echo "  sudo zypper install [paquete]"
            echo "  sudo zypper remove [paquete]"
            echo "  sudo systemctl start [servicio]"
            ;;
        *)
            echo "  sudo [comando] (para comandos que requieren root)"
            echo "  systemctl [acción] [servicio]"
            ;;
    esac
    
    echo "  ls -la"
    echo "  cd [directorio] && [comando]"
    echo "  git [comando]"
    echo
}

# Función para ejecutar un alias - CON SOPORTE MULTI-DISTRO
execute_alias() {
    local alias_name="$1"
    local alias_command="$2"
    
    echo -e "\n${CYAN}🚀 Ejecutando: $alias_name${NC}"
    echo -e "${YELLOW}Comando: $alias_command${NC}"
    echo -e "${GREEN}Distro: $DISTRO_NAME | Gestor: $PACKAGE_MANAGER_NAME${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"
    
    # Verificar si el alias existe en el archivo
    if ! alias_exists "$alias_name"; then
        echo -e "${RED}❌ El alias '$alias_name' no existe en el archivo${NC}"
        echo -e "${BLUE}----------------------------------------${NC}"
        return 1
    fi
    
    # Verificar si es un script y tiene permisos
    if [[ -f "$alias_command" ]]; then
        if [ ! -x "$alias_command" ]; then
            echo -e "${YELLOW}⚠ El script no tiene permisos de ejecución, intentando corregir...${NC}"
            chmod +x "$alias_command"
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ Permisos de ejecución concedidos${NC}"
            else
                echo -e "${RED}❌ No se pudo dar permisos de ejecución${NC}"
                echo -e "${BLUE}----------------------------------------${NC}"
                return 1
            fi
        fi
    fi
    
    # Detectar si necesita sudo
    local need_sudo=false
    if needs_sudo "$alias_command"; then
        need_sudo=true
        echo -e "${YELLOW}⚠ Este comando parece requerir permisos de administrador${NC}"
        
        # Verificar acceso sudo
        if ! check_sudo_access; then
            echo -e "${YELLOW}🔐 Se solicitará contraseña de sudo...${NC}"
        fi
    fi
    
    # EJECUCIÓN DIRECTA - Método corregido
    if [[ -f "$alias_command" && -x "$alias_command" ]]; then
        # Es un script ejecutable
        echo -e "${GREEN}📁 Ejecutando script: $alias_command${NC}"
        if [ "$need_sudo" = true ]; then
            sudo "$alias_command"
        else
            "$alias_command"
        fi
    else
        # Es un comando normal
        echo -e "${GREEN}⚡ Ejecutando comando: $alias_command${NC}"
        if [ "$need_sudo" = true ]; then
            eval "sudo $alias_command"
        else
            eval "$alias_command"
        fi
    fi
    
    local exit_code=$?
    echo -e "${BLUE}----------------------------------------${NC}"
    
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}✓ Ejecución completada exitosamente${NC}"
    else
        echo -e "${RED}❌ Ejecución completada con código de error: $exit_code${NC}"
        if [ $exit_code -eq 1 ]; then
            echo -e "${YELLOW}💡 Posible problema de permisos. Intenta con sudo manualmente.${NC}"
        elif [ $exit_code -eq 127 ]; then
            echo -e "${YELLOW}💡 Comando no encontrado. Verifica la instalación del paquete.${NC}"
        fi
    fi
    
    return $exit_code
}

# Función para inicializar configuración
initialize_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        cat > "$CONFIG_FILE" << EOF
# Configuración del Gestor de Aliases
BACKUP_ENABLED=true
AUTO_SOURCE=true
COLOR_SCHEME=default
ASK_FOR_SUDO=true
DISTRO=$DISTRO_ID
PACKAGE_MANAGER=$PACKAGE_MANAGER
EOF
    fi
    
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
    fi
}

# Función para cargar configuración
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    else
        BACKUP_ENABLED=true
        AUTO_SOURCE=true
        ASK_FOR_SUDO=true
    fi
}

# Función para verificar archivo de aliases
check_alias_file() {
    if [ ! -f "$ALIAS_FILE" ]; then
        echo -e "${YELLOW}Creando archivo de aliases: $ALIAS_FILE${NC}"
        cat > "$ALIAS_FILE" << EOF
# Aliases personalizados
# Creado: $(date)
# Gestor: Gestor Interactivo de Aliases v4.0
# Distribución: $DISTRO_NAME
# Gestor de paquetes: $PACKAGE_MANAGER_NAME

EOF
    fi
}

# Función para crear backup automático
create_backup() {
    if [ "$BACKUP_ENABLED" = "true" ]; then
        local backup_file="$BACKUP_DIR/aliases_$(date +%Y%m%d_%H%M%S).backup"
        cp "$ALIAS_FILE" "$backup_file"
        echo -e "${GREEN}Backup creado: $(basename "$backup_file")${NC}"
    fi
}

# Función para mostrar el header
show_header() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║           GESTOR INTERACTIVO DE ALIASES      ║"
    echo "║                    v4.0                      ║"
    echo "║           Compatible Multi-Distros           ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${YELLOW}Distribución: $DISTRO_NAME${NC}"
    echo -e "${YELLOW}Gestor de paquetes: $PACKAGE_MANAGER_NAME${NC}"
    echo
}

# Función para pausar
pause() {
    echo -e "${YELLOW}"
    read -p "Presiona Enter para continuar..."
    echo -e "${NC}"
}

# Función para mostrar menú principal
show_main_menu() {
    show_header
    echo -e "${BLUE}MENÚ PRINCIPAL${NC}"
    echo -e "${GREEN}1.${NC} Agregar alias"
    echo -e "${GREEN}2.${NC} Agregar alias que ejecuta script"
    echo -e "${GREEN}3.${NC} Listar y ejecutar aliases"
    echo -e "${GREEN}4.${NC} Buscar aliases"
    echo -e "${GREEN}5.${NC} Eliminar alias"
    echo -e "${GREEN}6.${NC} Editar alias"
    echo -e "${GREEN}7.${NC} Backup y Restore"
    echo -e "${GREEN}8.${NC} Configuración"
    echo -e "${GREEN}9.${NC} Activar aliases (source)"
    echo -e "${GREEN}d.${NC} Info del sistema"
    echo -e "${GREEN}0.${NC} Salir"
    echo
}

# Función para mostrar información del sistema
show_system_info() {
    show_header
    echo -e "${BLUE}INFORMACIÓN DEL SISTEMA${NC}"
    echo
    echo -e "${GREEN}Distribución:${NC} $DISTRO_NAME"
    echo -e "${GREEN}ID:${NC} $DISTRO_ID"
    echo -e "${GREEN}Gestor de paquetes:${NC} $PACKAGE_MANAGER_NAME"
    echo -e "${GREEN}Shell:${NC} $SHELL"
    echo -e "${GREEN}Usuario:${NC} $(whoami)"
    echo -e "${GREEN}Hostname:${NC} $(hostname)"
    echo -e "${GREEN}Directorio de aliases:${NC} $ALIAS_FILE"
    echo
    
    # Verificar paquetes esenciales
    echo -e "${CYAN}Paquetes disponibles:${NC}"
    local packages=("sudo" "bash" "git" "curl" "wget")
    for pkg in "${packages[@]}"; do
        if command -v "$pkg" >/dev/null 2>&1; then
            echo -e "  ${GREEN}✓${NC} $pkg"
        else
            echo -e "  ${RED}✗${NC} $pkg"
        fi
    done
    
    echo
    echo -e "${CYAN}Comandos de actualización para esta distro:${NC}"
    case "$PACKAGE_MANAGER" in
        "apt")
            echo "  sudo apt update && sudo apt upgrade"
            echo "  sudo apt autoremove"
            ;;
        "pacman")
            echo "  sudo pacman -Syu"
            echo "  yay -Syu (si usas AUR)"
            ;;
        "dnf")
            echo "  sudo dnf update"
            echo "  sudo dnf autoremove"
            ;;
        "zypper")
            echo "  sudo zypper update"
            echo "  sudo zypper patch"
            ;;
    esac
    pause
}

# Función para listar y ejecutar aliases - MEJORADA PARA MULTI-DISTRO
list_and_execute_aliases() {
    show_header
    echo -e "${BLUE}LISTA Y EJECUCIÓN DE ALIASES${NC}"
    echo
    
    if [ ! -f "$ALIAS_FILE" ] || [ ! -s "$ALIAS_FILE" ]; then
        echo -e "${YELLOW}No hay aliases definidos${NC}"
        pause
        return
    fi
    
    # Asegurar que los aliases estén cargados
    echo -e "${YELLOW}🔄 Cargando aliases...${NC}"
    if ! activate_aliases; then
        echo -e "${RED}❌ No se pudieron cargar los aliases. Verifica el archivo.${NC}"
        pause
        return
    fi
    
    local count=0
    declare -A alias_map
    declare -A command_map
    
    # Primera pasada: mostrar todos los aliases
    while IFS= read -r line; do
        if [[ "$line" =~ ^alias[[:space:]]+([a-zA-Z0-9_]+)= ]]; then
            ((count++))
            alias_name="${BASH_REMATCH[1]}"
            command=$(echo "$line" | cut -d"'" -f2)
            
            alias_map[$count]="$alias_name"
            command_map[$count]="$command"
            
            # Detectar si es un script
            local type_indicator=""
            local sudo_indicator=""
            
            if [[ -f "$command" && -x "$command" ]]; then
                type_indicator="${PURPLE}[SCRIPT]${NC}"
                if needs_sudo "$command"; then
                    sudo_indicator="${RED}[REQUIERE SUDO]${NC}"
                fi
            else
                if needs_sudo "$command"; then
                    sudo_indicator="${RED}[REQUIERE SUDO]${NC}"
                fi
            fi
            
            echo -e "${GREEN}$count. $alias_name${NC} -> ${CYAN}$command${NC} $type_indicator $sudo_indicator"
        fi
    done < "$ALIAS_FILE"
    
    echo
    echo -e "${BLUE}Total: $count aliases${NC}"
    
    if [ $count -eq 0 ]; then
        pause
        return
    fi
    
    echo
    echo -e "${YELLOW}Ingresa el número del alias para ejecutarlo${NC}"
    echo -e "${YELLOW}Ingresa '0' para volver al menú principal${NC}"
    echo
    
    while true; do
        read -p "Selecciona una opción [0-$count]: " choice
        
        # Validar entrada
        if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
            echo -e "${RED}❌ Entrada inválida. Debe ser un número.${NC}"
            continue
        fi
        
        if [ "$choice" -eq 0 ] 2>/dev/null; then
            break
        fi
        
        if [ "$choice" -lt 1 ] || [ "$choice" -gt "$count" ]; then
            echo -e "${RED}❌ Selección inválida. Elige entre 1 y $count.${NC}"
            continue
        fi
        
        local selected_alias="${alias_map[$choice]}"
        local selected_command="${command_map[$choice]}"
        
        # Mostrar confirmación con más información
        echo
        echo -e "${CYAN}¿Ejecutar el alias?${NC}"
        echo -e "  ${GREEN}Alias:${NC} $selected_alias"
        echo -e "  ${GREEN}Comando:${NC} $selected_command"
        
        # Información detallada
        if [[ -f "$selected_command" ]]; then
            if [ -x "$selected_command" ]; then
                echo -e "  ${GREEN}Tipo:${NC} Script ejecutable"
            else
                echo -e "  ${YELLOW}Tipo:${NC} Script (sin permisos de ejecución)"
            fi
        else
            echo -e "  ${GREEN}Tipo:${NC} Comando de terminal"
        fi
        
        # Advertencia sobre sudo
        if needs_sudo "$selected_command"; then
            echo -e "  ${RED}⚠ Este comando requiere permisos de administrador${NC}"
            if [ "$ASK_FOR_SUDO" = "true" ]; then
                echo -e "  ${YELLOW}Se solicitará contraseña de sudo si es necesario${NC}"
            fi
        fi
        
        echo
        read -p "Confirmar ejecución (s/n): " confirm
        
        if [[ "$confirm" =~ ^[Ss]$ ]]; then
            # Usar la función execute_alias corregida
            execute_alias "$selected_alias" "$selected_command"
            
            echo
            read -p "¿Ejecutar otro alias? (s/n): " another
            if [[ ! "$another" =~ ^[Ss]$ ]]; then
                break
            fi
            
            # Mostrar la lista nuevamente
            echo
            echo -e "${BLUE}Lista de aliases:${NC}"
            for i in $(seq 1 $count); do
                local type_indicator=""
                local sudo_indicator=""
                
                if [[ -f "${command_map[$i]}" && -x "${command_map[$i]}" ]]; then
                    type_indicator="${PURPLE}[SCRIPT]${NC}"
                    if needs_sudo "${command_map[$i]}"; then
                        sudo_indicator="${RED}[REQUIERE SUDO]${NC}"
                    fi
                else
                    if needs_sudo "${command_map[$i]}"; then
                        sudo_indicator="${RED}[REQUIERE SUDO]${NC}"
                    fi
                fi
                
                echo -e "${GREEN}$i. ${alias_map[$i]}${NC} -> ${CYAN}${command_map[$i]}${NC} $type_indicator $sudo_indicator"
            done
            echo
        else
            echo -e "${YELLOW}Ejecución cancelada${NC}"
            echo
        fi
    done
}

# Función para agregar alias normal - CON SUGERENCIAS POR DISTRO
add_alias() {
    show_header
    echo -e "${BLUE}AGREGAR NUEVO ALIAS${NC}"
    echo
    
    while true; do
        read -p "Nombre del alias: " alias_name
        if [ -z "$alias_name" ]; then
            echo -e "${RED}El nombre del alias no puede estar vacío${NC}"
            continue
        fi
        
        # Verificar que el nombre sea válido
        if [[ ! "$alias_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
            echo -e "${RED}Nombre de alias inválido. Use solo letras, números y guiones bajos${NC}"
            continue
        fi
        
        # Verificar si el alias ya existe
        if grep -q "alias $alias_name=" "$ALIAS_FILE"; then
            echo -e "${YELLOW}El alias '$alias_name' ya existe.${NC}"
            read -p "¿Sobrescribir? (s/n): " overwrite
            if [[ ! "$overwrite" =~ ^[Ss]$ ]]; then
                return 1
            fi
            # Eliminar el alias existente
            remove_alias_silent "$alias_name"
        fi
        break
    done
    
    echo
    suggest_commands
    
    while true; do
        read -p "Comando para el alias: " alias_command
        if [ -z "$alias_command" ]; then
            echo -e "${RED}El comando no puede estar vacío${NC}"
            continue
        fi
        break
    done
    
    # Preguntar si necesita sudo (para comandos que no lo detectan automáticamente)
    if [[ "$alias_command" != *"sudo"* ]] && needs_sudo "$alias_command"; then
        echo
        read -p "¿Este comando requiere permisos de administrador? (s/n): " need_sudo
        if [[ "$need_sudo" =~ ^[Ss]$ ]]; then
            alias_command="sudo $alias_command"
            echo -e "${YELLOW}✓ Se agregará 'sudo' al comando${NC}"
        fi
    fi
    
    # Agregar el alias
    echo "alias $alias_name='$alias_command'" >> "$ALIAS_FILE"
    create_backup
    
    echo
    echo -e "${GREEN}✓ Alias '$alias_name' agregado correctamente${NC}"
    
    # Verificar sintaxis y activar
    if bash -n "$ALIAS_FILE" 2>/dev/null; then
        if activate_aliases; then
            echo -e "${GREEN}✓ Alias '$alias_name' ahora está disponible${NC}"
            
            # Preguntar si ejecutar inmediatamente
            echo
            read -p "¿Ejecutar el alias ahora? (s/n): " ejecutar_ahora
            if [[ "$ejecutar_ahora" =~ ^[Ss]$ ]]; then
                execute_alias "$alias_name" "$alias_command"
            fi
        else
            echo -e "${YELLOW}⚠ El alias se guardó pero no se pudo activar${NC}"
        fi
    else
        echo -e "${RED}❌ Error de sintaxis. El alias no se activó.${NC}"
    fi
    pause
}

# Función para agregar alias de script
add_script_alias() {
    show_header
    echo -e "${BLUE}AGREGAR ALIAS QUE EJECUTA SCRIPT${NC}"
    echo
    
    while true; do
        read -p "Nombre del alias: " alias_name
        if [ -z "$alias_name" ]; then
            echo -e "${RED}El nombre del alias no puede estar vacío${NC}"
            continue
        fi
        
        # Verificar que el nombre sea válido
        if [[ ! "$alias_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
            echo -e "${RED}Nombre de alias inválido. Use solo letras, números y guiones bajos${NC}"
            continue
        fi
        
        if grep -q "alias $alias_name=" "$ALIAS_FILE"; then
            echo -e "${YELLOW}El alias '$alias_name' ya existe.${NC}"
            read -p "¿Sobrescribir? (s/n): " overwrite
            if [[ ! "$overwrite" =~ ^[Ss]$ ]]; then
                return 1
            fi
            remove_alias_silent "$alias_name"
        fi
        break
    done
    
    echo
    echo -e "${YELLOW}Ejemplos de rutas:${NC}"
    echo "  /home/usuario/scripts/mi-script.sh"
    echo "  ./scripts/backup.sh"
    echo "  /ruta/completa/al/script.py"
    echo
    
    while true; do
        read -p "Ruta completa del script: " script_path
        
        if [ -z "$script_path" ]; then
            echo -e "${RED}La ruta no puede estar vacía${NC}"
            continue
        fi
        
        # Expandir ~ y variables
        script_path=$(eval echo "$script_path")
        
        if [ ! -f "$script_path" ]; then
            echo -e "${RED}❌ El archivo '$script_path' no existe${NC}"
            read -p "¿Intentar con otra ruta? (s/n): " retry
            if [[ ! "$retry" =~ ^[Ss]$ ]]; then
                return 1
            fi
            continue
        fi
        
        # Verificar permisos de ejecución
        if [ ! -x "$script_path" ]; then
            echo -e "${YELLOW}El script no tiene permisos de ejecución${NC}"
            read -p "¿Dar permisos de ejecución? (s/n): " make_executable
            if [[ "$make_executable" =~ ^[Ss]$ ]]; then
                chmod +x "$script_path"
                echo -e "${GREEN}✓ Permisos de ejecución concedidos${NC}"
            else
                echo -e "${YELLOW}⚠ El alias funcionará pero el script necesita permisos de ejecución${NC}"
            fi
        fi
        
        break
    done
    
    # Preguntar si el script necesita sudo
    local final_command="$script_path"
    if needs_sudo "$script_path"; then
        echo
        read -p "¿Este script requiere permisos de administrador? (s/n): " need_sudo
        if [[ "$need_sudo" =~ ^[Ss]$ ]]; then
            final_command="sudo $script_path"
            echo -e "${YELLOW}✓ Se ejecutará con 'sudo'${NC}"
        fi
    fi
    
    # Agregar el alias
    echo "alias $alias_name='$final_command'" >> "$ALIAS_FILE"
    create_backup
    
    echo
    echo -e "${GREEN}✓ Alias '$alias_name' agregado correctamente${NC}"
    echo -e "${CYAN}Script: $script_path${NC}"
    
    # Verificar sintaxis y activar
    if bash -n "$ALIAS_FILE" 2>/dev/null; then
        if activate_aliases; then
            echo -e "${GREEN}✓ Alias '$alias_name' ahora está disponible${NC}"
            
            # Preguntar si ejecutar inmediatamente
            echo
            read -p "¿Ejecutar el alias ahora? (s/n): " ejecutar_ahora
            if [[ "$ejecutar_ahora" =~ ^[Ss]$ ]]; then
                execute_alias "$alias_name" "$final_command"
            fi
        else
            echo -e "${YELLOW}⚠ El alias se guardó pero no se pudo activar${NC}"
        fi
    else
        echo -e "${RED}❌ Error de sintaxis. El alias no se activó.${NC}"
    fi
    pause
}

# Función silenciosa para eliminar alias (uso interno)
remove_alias_silent() {
    local alias_name="$1"
    local temp_file=$(mktemp)
    
    grep -v "alias $alias_name=" "$ALIAS_FILE" > "$temp_file"
    mv "$temp_file" "$ALIAS_FILE"
}

# [Las funciones delete_alias, search_aliases, edit_alias, backup_restore_menu, config_menu 
# se mantienen igual que en la versión anterior pero adaptadas al nuevo header]

# Función principal
main() {
    # Detectar distribución al inicio
    detect_distro
    
    # Inicializar
    initialize_config
    load_config
    check_alias_file
    
    # Verificar sintaxis al inicio
    if ! bash -n "$ALIAS_FILE" 2>/dev/null; then
        echo -e "${RED}❌ Hay errores de sintaxis en el archivo de aliases${NC}"
        echo -e "${YELLOW}Puedes usar 'bash -n $ALIAS_FILE' para ver los errores${NC}"
        pause
    else
        # Solo activar si la sintaxis es correcta
        echo -e "${YELLOW}🔄 Cargando aliases...${NC}"
        activate_aliases
    fi
    
    while true; do
        show_main_menu
        read -p "Selecciona una opción: " choice
        
        case $choice in
            1) add_alias ;;
            2) add_script_alias ;;
            3) list_and_execute_aliases ;;
            4) search_aliases ;;
            5) delete_alias ;;
            6) edit_alias ;;
            7) backup_restore_menu ;;
            8) config_menu ;;
            9) 
                activate_aliases
                pause 
                ;;
            d|D)
                show_system_info
                ;;
            0) 
                echo -e "${GREEN}¡Hasta pronto!${NC}"
                exit 0 
                ;;
            *) 
                echo -e "${RED}Opción inválida${NC}"
                pause 
                ;;
        esac
    done
}

# Ejecutar función principal
main "$@"
