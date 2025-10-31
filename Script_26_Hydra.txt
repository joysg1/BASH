#!/bin/bash

# Script para ejecutar Hydra con opciones comunes
# Uso: ./hydra_script.sh

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # Sin color

# Banner
echo -e "${GREEN}"
echo "================================================"
echo "    Script de Hydra - Herramienta de Fuerza Bruta"
echo "================================================"
echo -e "${NC}"

# Verificar si hydra está instalado
if ! command -v hydra &> /dev/null; then
    echo -e "${RED}Error: Hydra no está instalado${NC}"
    echo "Instala con: sudo apt-get install hydra"
    exit 1
fi

# Menú de selección de servicio
echo -e "${YELLOW}Selecciona el servicio a atacar:${NC}"
echo "1) SSH"
echo "2) FTP"
echo "3) HTTP-GET"
echo "4) HTTP-POST-FORM"
echo "5) MySQL"
echo "6) PostgreSQL"
echo "7) RDP"
echo "8) SMB"
echo "9) Telnet"
echo "10) VNC"
read -p "Opción: " SERVICE_OPTION

# Solicitar datos comunes
read -p "Host objetivo (IP o dominio): " TARGET
read -p "Puerto (dejar vacío para usar puerto por defecto): " PORT
read -p "Usuario específico (dejar vacío para usar lista): " SINGLE_USER
read -p "Contraseña específica (dejar vacío para usar lista): " SINGLE_PASS

# Opciones de listas
if [ -z "$SINGLE_USER" ]; then
    read -p "Ruta al archivo de usuarios: " USER_FILE
    if [ ! -f "$USER_FILE" ]; then
        echo -e "${RED}Error: Archivo de usuarios no encontrado${NC}"
        exit 1
    fi
fi

if [ -z "$SINGLE_PASS" ]; then
    read -p "Ruta al archivo de contraseñas: " PASS_FILE
    if [ ! -f "$PASS_FILE" ]; then
        echo -e "${RED}Error: Archivo de contraseñas no encontrado${NC}"
        exit 1
    fi
fi

# Opciones avanzadas
read -p "Número de tareas paralelas (default 16): " TASKS
TASKS=${TASKS:-16}

read -p "¿Detener al encontrar primera contraseña válida? (s/n): " STOP_FIRST
read -p "¿Modo verbose? (s/n): " VERBOSE
read -p "¿Guardar output en archivo? (s/n): " SAVE_OUTPUT

if [ "$SAVE_OUTPUT" == "s" ]; then
    read -p "Nombre del archivo de output: " OUTPUT_FILE
fi

# Construir comando base
CMD="hydra"

# Añadir opciones de usuario/contraseña
if [ -n "$SINGLE_USER" ]; then
    CMD="$CMD -l $SINGLE_USER"
else
    CMD="$CMD -L $USER_FILE"
fi

if [ -n "$SINGLE_PASS" ]; then
    CMD="$CMD -p $SINGLE_PASS"
else
    CMD="$CMD -P $PASS_FILE"
fi

# Opciones adicionales
CMD="$CMD -t $TASKS"

if [ "$STOP_FIRST" == "s" ]; then
    CMD="$CMD -f"
fi

if [ "$VERBOSE" == "s" ]; then
    CMD="$CMD -V"
fi

if [ "$SAVE_OUTPUT" == "s" ]; then
    CMD="$CMD -o $OUTPUT_FILE"
fi

# Añadir puerto si se especificó
if [ -n "$PORT" ]; then
    CMD="$CMD -s $PORT"
fi

# Configurar servicio según selección
case $SERVICE_OPTION in
    1)
        CMD="$CMD $TARGET ssh"
        ;;
    2)
        CMD="$CMD $TARGET ftp"
        ;;
    3)
        read -p "Ruta del formulario (ej: /admin/login.php): " HTTP_PATH
        CMD="$CMD $TARGET http-get $HTTP_PATH"
        ;;
    4)
        read -p "Ruta del formulario (ej: /login.php): " HTTP_PATH
        read -p "Parámetros POST (ej: user=^USER^&pass=^PASS^): " POST_PARAMS
        read -p "Mensaje de error en página (ej: 'Invalid credentials'): " FAIL_MSG
        CMD="$CMD $TARGET http-post-form \"$HTTP_PATH:$POST_PARAMS:$FAIL_MSG\""
        ;;
    5)
        CMD="$CMD $TARGET mysql"
        ;;
    6)
        CMD="$CMD $TARGET postgres"
        ;;
    7)
        CMD="$CMD $TARGET rdp"
        ;;
    8)
        CMD="$CMD $TARGET smb"
        ;;
    9)
        CMD="$CMD $TARGET telnet"
        ;;
    10)
        CMD="$CMD $TARGET vnc"
        ;;
    *)
        echo -e "${RED}Opción inválida${NC}"
        exit 1
        ;;
esac

# Mostrar comando a ejecutar
echo -e "${YELLOW}\nComando a ejecutar:${NC}"
echo "$CMD"
echo ""

read -p "¿Ejecutar comando? (s/n): " CONFIRM

if [ "$CONFIRM" == "s" ]; then
    echo -e "${GREEN}\nIniciando ataque...${NC}\n"
    eval $CMD
    
    echo -e "\n${GREEN}Proceso completado${NC}"
    
    if [ "$SAVE_OUTPUT" == "s" ]; then
        echo -e "${GREEN}Resultados guardados en: $OUTPUT_FILE${NC}"
    fi
else
    echo -e "${YELLOW}Operación cancelada${NC}"
fi
