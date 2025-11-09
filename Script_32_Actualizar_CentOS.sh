#!/bin/bash

# Script para actualizar CentOS con detección automática de versión
# Autor: Asistente
# Fecha: $(date +%Y-%m-%d)

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar mensajes informativos
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Función para mostrar mensajes de éxito
success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Función para mostrar mensajes de advertencia
warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Función para mostrar mensajes de error
error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Función para detectar la versión de CentOS
detectar_version() {
    if [ -f /etc/centos-release ]; then
        CENTOS_VERSION=$(grep -oE '[0-9]+\.[0-9]+' /etc/centos-release | cut -d. -f1)
        CENTOS_FULL_VERSION=$(cat /etc/centos-release)
    elif [ -f /etc/redhat-release ]; then
        CENTOS_VERSION=$(grep -oE '[0-9]+\.[0-9]+' /etc/redhat-release | cut -d. -f1)
        CENTOS_FULL_VERSION=$(cat /etc/redhat-release)
    else
        error "No se pudo detectar CentOS/RHEL"
        exit 1
    fi
    
    info "Sistema detectado: $CENTOS_FULL_VERSION"
    info "Versión principal: CentOS $CENTOS_VERSION"
}

# Función para verificar si el usuario es root
verificar_root() {
    if [ "$EUID" -ne 0 ]; then
        error "Este script debe ejecutarse como root"
        echo "Use: sudo $0"
        exit 1
    fi
}

# Función para hacer backup de repositorios importantes
backup_repos() {
    info "Haciendo backup de repositorios..."
    BACKUP_DIR="/tmp/yum_repos_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    if [ -d /etc/yum.repos.d ]; then
        cp -r /etc/yum.repos.d/* "$BACKUP_DIR/" 2>/dev/null
        success "Backup de repositorios guardado en: $BACKUP_DIR"
    else
        warning "No se encontró el directorio /etc/yum.repos.d"
    fi
}

# Función para actualizar CentOS 7
actualizar_centos7() {
    info "Iniciando actualización para CentOS 7..."
    
    # Actualizar yum
    yum update -y yum
    
    # Limpiar cache
    yum clean all
    
    # Actualizar sistema
    yum update -y
    
    # Actualizar paquetes de seguridad
    yum update --security -y
    
    success "Actualización de CentOS 7 completada"
}

# Función para actualizar CentOS 8
actualizar_centos8() {
    info "Iniciando actualización para CentOS 8..."
    
    # Actualizar dnf
    dnf update -y dnf
    
    # Limpiar cache
    dnf clean all
    
    # Actualizar sistema
    dnf update -y
    
    # Actualizar paquetes de seguridad
    dnf update --security -y
    
    success "Actualización de CentOS 8 completada"
}

# Función para actualizar CentOS 9
actualizar_centos9() {
    info "Iniciando actualización para CentOS 9..."
    
    # Actualizar dnf
    dnf update -y dnf
    
    # Limpiar cache
    dnf clean all
    
    # Actualizar sistema
    dnf update -y
    
    # Actualizar paquetes de seguridad
    dnf update --security -y
    
    success "Actualización de CentOS 9 completada"
}

# Función para mostrar información del sistema después de la actualización
mostrar_info_sistema() {
    info "=== INFORMACIÓN DEL SISTEMA DESPUÉS DE LA ACTUALIZACIÓN ==="
    echo "Versión del sistema: $(cat /etc/centos-release 2>/dev/null || cat /etc/redhat-release 2>/dev/null)"
    echo "Kernel: $(uname -r)"
    echo "Arquitectura: $(uname -m)"
    
    # Mostrar espacio en disco
    info "Espacio en disco disponible:"
    df -h / | tail -1
    
    # Mostrar memoria disponible
    info "Memoria disponible:"
    free -h
}

# Función principal
main() {
    echo "=========================================="
    echo "  ACTUALIZADOR DE CENTOS AUTOMÁTICO"
    echo "=========================================="
    echo ""
    
    # Verificar si es root
    verificar_root
    
    # Detectar versión
    detectar_version
    
    # Confirmar con el usuario
    echo ""
    warning "¿Está seguro de que desea continuar con la actualización?"
    warning "Se recomienda tener un backup del sistema antes de proceder."
    read -p "Presione Enter para continuar o Ctrl+C para cancelar..."
    
    # Hacer backup de repositorios
    backup_repos
    
    # Ejecutar actualización según la versión
    case $CENTOS_VERSION in
        7)
            actualizar_centos7
            ;;
        8)
            actualizar_centos8
            ;;
        9)
            actualizar_centos9
            ;;
        *)
            error "Versión de CentOS no soportada: $CENTOS_VERSION"
            error "Versiones soportadas: 7, 8, 9"
            exit 1
            ;;
    esac
    
    # Mostrar información del sistema
    mostrar_info_sistema
    
    # Recomendar reinicio si es necesario
    if [ -f /var/run/reboot-required ]; then
        warning "Se recomienda reiniciar el sistema para completar la actualización"
        echo "Puede reiniciar con: reboot"
    else
        # Verificar si se actualizó el kernel
        CURRENT_KERNEL=$(uname -r)
        LATEST_KERNEL=$(rpm -q kernel --last | head -1 | awk '{print $1}' | sed 's/kernel-//')
        
        if [ "$CURRENT_KERNEL" != "$LATEST_KERNEL" ]; then
            warning "Se ha actualizado el kernel. Se recomienda reiniciar el sistema."
            echo "Kernel actual: $CURRENT_KERNEL"
            echo "Último kernel instalado: $LATEST_KERNEL"
            echo "Puede reiniciar con: reboot"
        else
            success "Actualización completada sin necesidad de reinicio inmediato"
        fi
    fi
    
    echo ""
    success "Proceso de actualización finalizado"
}

# Manejar señal de interrupción (Ctrl+C)
trap 'echo ""; error "Actualización cancelada por el usuario"; exit 1' INT

# Ejecutar función principal
main
