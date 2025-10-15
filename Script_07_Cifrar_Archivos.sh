#!/bin/bash

# Script universal para cifrar y descifrar archivos
# Compatible con: Ubuntu, Debian, Manjaro, Arch Linux
# Uso: ./encrypt.sh

set -e  # Salir si hay errores

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Sin color

# Función para detectar la distribución
detectar_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ -f /etc/arch-release ]; then
        echo "arch"
    else
        echo "unknown"
    fi
}

# Función para instalar OpenSSL según la distribución
instalar_openssl() {
    local distro=$(detectar_distro)
    
    echo -e "${YELLOW}OpenSSL no está instalado. Instalando...${NC}"
    
    case "$distro" in
        ubuntu|debian|linuxmint|pop)
            echo -e "${BLUE}Detectado: Sistema basado en Debian/Ubuntu${NC}"
            sudo apt update
            sudo apt install -y openssl
            ;;
        manjaro|arch|endeavouros|garuda)
            echo -e "${BLUE}Detectado: Sistema basado en Arch Linux${NC}"
            sudo pacman -Sy --noconfirm openssl
            ;;
        fedora|rhel|centos)
            echo -e "${BLUE}Detectado: Sistema basado en Red Hat${NC}"
            sudo dnf install -y openssl
            ;;
        opensuse*)
            echo -e "${BLUE}Detectado: openSUSE${NC}"
            sudo zypper install -y openssl
            ;;
        *)
            echo -e "${RED}Distribución no reconocida: $distro${NC}"
            echo "Por favor, instala OpenSSL manualmente"
            exit 1
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ OpenSSL instalado exitosamente${NC}"
    else
        echo -e "${RED}✗ Error al instalar OpenSSL${NC}"
        exit 1
    fi
}

# Verificar e instalar OpenSSL si es necesario
verificar_openssl() {
    if ! command -v openssl &> /dev/null; then
        instalar_openssl
    else
        echo -e "${GREEN}✓ OpenSSL ya está instalado ($(openssl version))${NC}"
    fi
}

# Función para solicitar ruta de archivo
solicitar_ruta() {
    local mensaje="$1"
    local ruta=""
    
    while true; do
        echo -e "${BLUE}$mensaje${NC}"
        read -e -p "Ruta: " ruta
        
        # Expandir ~ y variables
        ruta=$(eval echo "$ruta")
        
        if [ -f "$ruta" ]; then
            echo "$ruta"
            return 0
        else
            echo -e "${RED}Error: El archivo '$ruta' no existe${NC}"
            read -p "¿Desea intentar de nuevo? (s/n): " reintentar
            if [[ ! "$reintentar" =~ ^[Ss]$ ]]; then
                return 1
            fi
        fi
    done
}

# Función para cifrar archivo
cifrar_archivo() {
    local archivo
    archivo=$(solicitar_ruta "Ingrese la ruta del archivo a CIFRAR:")
    
    if [ $? -ne 0 ] || [ -z "$archivo" ]; then
        echo "Operación cancelada"
        return 1
    fi
    
    local archivo_cifrado="${archivo}.enc"
    
    if [ -f "$archivo_cifrado" ]; then
        echo -e "${YELLOW}Advertencia: '$archivo_cifrado' ya existe${NC}"
        read -p "¿Desea sobrescribirlo? (s/n): " respuesta
        if [[ ! "$respuesta" =~ ^[Ss]$ ]]; then
            echo "Operación cancelada"
            return 0
        fi
    fi
    
    echo -e "${YELLOW}Cifrando archivo: $archivo${NC}"
    echo -e "${BLUE}Ingrese una contraseña segura (mínimo 8 caracteres):${NC}"
    
    # Cifrar usando AES-256-CBC
    openssl enc -aes-256-cbc -salt -pbkdf2 -in "$archivo" -out "$archivo_cifrado"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}✓ Archivo cifrado exitosamente${NC}"
        echo -e "${GREEN}  Archivo original: $archivo${NC}"
        echo -e "${GREEN}  Archivo cifrado:  $archivo_cifrado${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        # Preguntar si desea eliminar el original
        echo ""
        read -p "¿Desea eliminar el archivo original? (s/n): " eliminar
        if [[ "$eliminar" =~ ^[Ss]$ ]]; then
            if command -v shred &> /dev/null; then
                shred -u "$archivo"
                echo -e "${GREEN}✓ Archivo original eliminado de forma segura (shred)${NC}"
            else
                rm -f "$archivo"
                echo -e "${GREEN}✓ Archivo original eliminado${NC}"
            fi
        fi
    else
        echo -e "${RED}✗ Error al cifrar el archivo${NC}"
        return 1
    fi
}

# Función para descifrar archivo
descifrar_archivo() {
    local archivo_cifrado
    archivo_cifrado=$(solicitar_ruta "Ingrese la ruta del archivo a DESCIFRAR:")
    
    if [ $? -ne 0 ] || [ -z "$archivo_cifrado" ]; then
        echo "Operación cancelada"
        return 1
    fi
    
    local archivo_descifrado
    
    # Remover extensión .enc si existe
    if [[ "$archivo_cifrado" == *.enc ]]; then
        archivo_descifrado="${archivo_cifrado%.enc}"
    else
        archivo_descifrado="${archivo_cifrado}.dec"
    fi
    
    if [ -f "$archivo_descifrado" ]; then
        echo -e "${YELLOW}Advertencia: '$archivo_descifrado' ya existe${NC}"
        read -p "¿Desea sobrescribirlo? (s/n): " respuesta
        if [[ ! "$respuesta" =~ ^[Ss]$ ]]; then
            echo "Operación cancelada"
            return 0
        fi
    fi
    
    echo -e "${YELLOW}Descifrando archivo: $archivo_cifrado${NC}"
    echo -e "${BLUE}Ingrese la contraseña:${NC}"
    
    # Descifrar
    openssl enc -aes-256-cbc -d -pbkdf2 -in "$archivo_cifrado" -out "$archivo_descifrado"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}✓ Archivo descifrado exitosamente${NC}"
        echo -e "${GREEN}  Archivo cifrado:    $archivo_cifrado${NC}"
        echo -e "${GREEN}  Archivo descifrado: $archivo_descifrado${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        # Preguntar si desea eliminar el cifrado
        echo ""
        read -p "¿Desea eliminar el archivo cifrado? (s/n): " eliminar
        if [[ "$eliminar" =~ ^[Ss]$ ]]; then
            rm -f "$archivo_cifrado"
            echo -e "${GREEN}✓ Archivo cifrado eliminado${NC}"
        fi
    else
        echo -e "${RED}✗ Error al descifrar el archivo (contraseña incorrecta?)${NC}"
        # Eliminar archivo parcial si existe
        [ -f "$archivo_descifrado" ] && rm -f "$archivo_descifrado"
        return 1
    fi
}

# Función para mostrar menú principal
mostrar_menu() {
    clear
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}    CIFRADO DE ARCHIVOS (AES-256)${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${BLUE}Distribución detectada: ${YELLOW}$(detectar_distro)${NC}"
    echo ""
    echo "1) Cifrar archivo"
    echo "2) Descifrar archivo"
    echo "3) Verificar/Instalar OpenSSL"
    echo "4) Salir"
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Programa principal
main() {
    # Verificar OpenSSL al inicio
    verificar_openssl
    
    while true; do
        mostrar_menu
        read -p "Seleccione una opción [1-4]: " opcion
        echo ""
        
        case "$opcion" in
            1)
                cifrar_archivo
                ;;
            2)
                descifrar_archivo
                ;;
            3)
                verificar_openssl
                ;;
            4)
                echo -e "${GREEN}¡Hasta luego!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Opción no válida${NC}"
                ;;
        esac
        
        echo ""
        read -p "Presione Enter para continuar..."
    done
}

# Ejecutar programa principal
main
