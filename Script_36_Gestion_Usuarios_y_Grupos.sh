#!/bin/bash

# Script de gestión de usuarios y grupos
# Autor: [Tu nombre]
# Fecha: $(date +%Y-%m-%d)

# Colores para el menú
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar el menú
mostrar_menu() {
    clear
    echo -e "${BLUE}=================================${NC}"
    echo -e "${BLUE}    GESTIÓN DE USUARIOS Y GRUPOS${NC}"
    echo -e "${BLUE}=================================${NC}"
    echo -e "${GREEN}1. Crear usuario${NC}"
    echo -e "${GREEN}2. Eliminar usuario${NC}"
    echo -e "${GREEN}3. Modificar usuario${NC}"
    echo -e "${GREEN}4. Crear grupo${NC}"
    echo -e "${GREEN}5. Eliminar grupo${NC}"
    echo -e "${GREEN}6. Listar usuarios${NC}"
    echo -e "${GREEN}7. Listar grupos${NC}"
    echo -e "${GREEN}8. Agregar usuario a grupo${NC}"
    echo -e "${GREEN}9. Cambiar grupo de un archivo${NC}"
    echo -e "${YELLOW}0. Salir${NC}"
    echo -e "${BLUE}=================================${NC}"
}

# Función para pausar y esperar entrada
pausa() {
    echo -e "\n${YELLOW}Presiona Enter para continuar...${NC}"
    read
}

# Función para crear usuario
crear_usuario() {
    echo -e "\n${BLUE}--- CREAR USUARIO ---${NC}"
    read -p "Nombre del nuevo usuario: " usuario
    
    if id "$usuario" &>/dev/null; then
        echo -e "${RED}El usuario $usuario ya existe${NC}"
    else
        read -p "¿Crear directorio home? (s/n): " crear_home
        if [[ $crear_home == "s" || $crear_home == "S" ]]; then
            useradd -m "$usuario"
        else
            useradd "$usuario"
        fi
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Usuario $usuario creado exitosamente${NC}"
            
            read -p "¿Establecer contraseña? (s/n): " set_pass
            if [[ $set_pass == "s" || $set_pass == "S" ]]; then
                passwd "$usuario"
            fi
        else
            echo -e "${RED}Error al crear el usuario${NC}"
        fi
    fi
    pausa
}

# Función para eliminar usuario
eliminar_usuario() {
    echo -e "\n${BLUE}--- ELIMINAR USUARIO ---${NC}"
    read -p "Nombre del usuario a eliminar: " usuario
    
    if id "$usuario" &>/dev/null; then
        read -p "¿Eliminar directorio home? (s/n): " eliminar_home
        read -p "¿Forzar eliminación? (s/n): " forzar
        
        if [[ $eliminar_home == "s" || $eliminar_home == "S" ]]; then
            if [[ $forzar == "s" || $forzar == "S" ]]; then
                userdel -r -f "$usuario"
            else
                userdel -r "$usuario"
            fi
        else
            if [[ $forzar == "s" || $forzar == "S" ]]; then
                userdel -f "$usuario"
            else
                userdel "$usuario"
            fi
        fi
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Usuario $usuario eliminado exitosamente${NC}"
        else
            echo -e "${RED}Error al eliminar el usuario${NC}"
        fi
    else
        echo -e "${RED}El usuario $usuario no existe${NC}"
    fi
    pausa
}

# Función para modificar usuario
modificar_usuario() {
    echo -e "\n${BLUE}--- MODIFICAR USUARIO ---${NC}"
    read -p "Nombre del usuario a modificar: " usuario
    
    if id "$usuario" &>/dev/null; then
        echo -e "${YELLOW}Opciones de modificación:${NC}"
        echo "1. Cambiar nombre de usuario"
        echo "2. Cambiar directorio home"
        echo "3. Cambiar shell por defecto"
        echo "4. Cambiar grupo principal"
        echo "5. Bloquear usuario"
        echo "6. Desbloquear usuario"
        read -p "Selecciona una opción: " opcion_mod
        
        case $opcion_mod in
            1)
                read -p "Nuevo nombre de usuario: " nuevo_nombre
                usermod -l "$nuevo_nombre" "$usuario"
                ;;
            2)
                read -p "Nuevo directorio home: " nuevo_home
                usermod -d "$nuevo_home" -m "$usuario"
                ;;
            3)
                read -p "Nuevo shell (ej. /bin/bash): " nuevo_shell
                usermod -s "$nuevo_shell" "$usuario"
                ;;
            4)
                read -p "Nuevo grupo principal: " nuevo_grupo
                if grep -q "^$nuevo_grupo:" /etc/group; then
                    usermod -g "$nuevo_grupo" "$usuario"
                else
                    echo -e "${RED}El grupo $nuevo_grupo no existe${NC}"
                fi
                ;;
            5)
                usermod -L "$usuario"
                echo -e "${GREEN}Usuario $usuario bloqueado${NC}"
                ;;
            6)
                usermod -U "$usuario"
                echo -e "${GREEN}Usuario $usuario desbloqueado${NC}"
                ;;
            *)
                echo -e "${RED}Opción inválida${NC}"
                ;;
        esac
    else
        echo -e "${RED}El usuario $usuario no existe${NC}"
    fi
    pausa
}

# Función para crear grupo
crear_grupo() {
    echo -e "\n${BLUE}--- CREAR GRUPO ---${NC}"
    read -p "Nombre del nuevo grupo: " grupo
    
    if grep -q "^$grupo:" /etc/group; then
        echo -e "${RED}El grupo $grupo ya existe${NC}"
    else
        groupadd "$grupo"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Grupo $grupo creado exitosamente${NC}"
        else
            echo -e "${RED}Error al crear el grupo${NC}"
        fi
    fi
    pausa
}

# Función para eliminar grupo
eliminar_grupo() {
    echo -e "\n${BLUE}--- ELIMINAR GRUPO ---${NC}"
    read -p "Nombre del grupo a eliminar: " grupo
    
    if grep -q "^$grupo:" /etc/group; then
        groupdel "$grupo"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Grupo $grupo eliminado exitosamente${NC}"
        else
            echo -e "${RED}Error al eliminar el grupo. ¿Tiene usuarios asignados?${NC}"
        fi
    else
        echo -e "${RED}El grupo $grupo no existe${NC}"
    fi
    pausa
}

# Función para listar usuarios
listar_usuarios() {
    echo -e "\n${BLUE}--- LISTA DE USUARIOS ---${NC}"
    echo -e "${YELLOW}Usuarios del sistema:${NC}"
    cut -d: -f1 /etc/passwd | sort | column
    pausa
}

# Función para listar grupos
listar_grupos() {
    echo -e "\n${BLUE}--- LISTA DE GRUPOS ---${NC}"
    echo -e "${YELLOW}Grupos del sistema:${NC}"
    cut -d: -f1 /etc/group | sort | column
    pausa
}

# Función para agregar usuario a grupo
agregar_usuario_grupo() {
    echo -e "\n${BLUE}--- AGREGAR USUARIO A GRUPO ---${NC}"
    read -p "Nombre del usuario: " usuario
    read -p "Nombre del grupo: " grupo
    
    if id "$usuario" &>/dev/null && grep -q "^$grupo:" /etc/group; then
        usermod -a -G "$grupo" "$usuario"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Usuario $usuario agregado al grupo $grupo${NC}"
        else
            echo -e "${RED}Error al agregar usuario al grupo${NC}"
        fi
    else
        echo -e "${RED}Usuario o grupo no existe${NC}"
    fi
    pausa
}

# Función para cambiar grupo de archivo
cambiar_grupo_archivo() {
    echo -e "\n${BLUE}--- CAMBIAR GRUPO DE ARCHIVO ---${NC}"
    read -p "Ruta del archivo/directorio: " archivo
    read -p "Nuevo grupo: " grupo
    
    if [ -e "$archivo" ] && grep -q "^$grupo:" /etc/group; then
        chgrp "$grupo" "$archivo"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Grupo de $archivo cambiado a $grupo${NC}"
        else
            echo -e "${RED}Error al cambiar grupo${NC}"
        fi
    else
        echo -e "${RED}Archivo o grupo no existe${NC}"
    fi
    pausa
}

# Verificar si el script se ejecuta como root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Este script debe ejecutarse como root${NC}"
    exit 1
fi

# Bucle principal del menú
while true; do
    mostrar_menu
    read -p "Selecciona una opción (0-9): " opcion
    
    case $opcion in
        1) crear_usuario ;;
        2) eliminar_usuario ;;
        3) modificar_usuario ;;
        4) crear_grupo ;;
        5) eliminar_grupo ;;
        6) listar_usuarios ;;
        7) listar_grupos ;;
        8) agregar_usuario_grupo ;;
        9) cambiar_grupo_archivo ;;
        0)
            echo -e "${GREEN}Saliendo...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Opción inválida. Intenta nuevamente.${NC}"
            pausa
            ;;
    esac
done
