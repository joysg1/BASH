#!/bin/bash

# Script para cambiar el hostname del equipo
# Compatible con: Debian/Ubuntu, Red Hat/CentOS, Arch Linux
# Autor: $(whoami)
# Fecha: $(date)

# Verificar si se ejecuta como root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Este script debe ejecutarse como root o con sudo"
    echo "Por favor, ejecuta: sudo $0"
    exit 1
fi

# Función para detectar distribución
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

# Función específica para Arch Linux
configurar_hostname_arch() {
    local new_hostname=$1
    
    echo "🔧 Configurando hostname para Arch Linux..."
    
    # Método principal: archivo /etc/hostname
    echo "$new_hostname" > /etc/hostname
    echo "✅ Hostname actualizado en /etc/hostname"
    
    # Configurar en /etc/hosts
    configurar_hosts "$new_hostname"
    
    # Para Arch Linux, también podríamos usar hostnamectl si está disponible
    if command -v hostnamectl &> /dev/null; then
        hostnamectl set-hostname "$new_hostname"
        echo "✅ Hostname actualizado con hostnamectl"
    fi
    
    # Configuración adicional para servicios específicos de Arch
    configurar_servicios_arch "$new_hostname"
}

# Función para configurar servicios específicos de Arch
configurar_servicios_arch() {
    local new_hostname=$1
    
    echo "🔧 Revisando servicios específicos de Arch Linux..."
    
    # NetworkManager (común en Arch)
    if systemctl is-active --quiet NetworkManager 2>/dev/null; then
        echo "📡 NetworkManager detectado - reiniciando servicio"
        systemctl restart NetworkManager 2>/dev/null
    fi
    
    # systemd-resolved (resolución DNS)
    if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
        echo "🔍 systemd-resolved detectado - reiniciando servicio"
        systemctl restart systemd-resolved 2>/dev/null
    fi
    
    # Avahi (zeroconf/bonjour)
    if systemctl is-active --quiet avahi-daemon 2>/dev/null; then
        echo "🌐 Avahi detectado - será necesario reiniciar después del cambio"
    fi
}

# Función para configurar /etc/hosts
configurar_hosts() {
    local new_hostname=$1
    
    # Backup del archivo hosts
    cp /etc/hosts /etc/hosts.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null
    
    # Para Arch Linux, típicamente se usa una configuración simple en hosts
    if grep -q "127.0.1.1" /etc/hosts; then
        # Reemplazar línea existente
        sed -i "s/127.0.1.1.*/127.0.1.1\t$new_hostname/g" /etc/hosts
    else
        # Agregar entrada si no existe
        echo -e "127.0.0.1\tlocalhost" > /etc/hosts
        echo -e "::1\t\tlocalhost" >> /etc/hosts
        echo -e "127.0.1.1\t$new_hostname" >> /etc/hosts
    fi
    echo "✅ Archivo /etc/hosts actualizado"
}

# Función para configuraciones generales
configurar_hostname_general() {
    local new_hostname=$1
    
    echo "🔧 Configurando hostname (método universal)..."
    
    # Método 1: Archivo /etc/hostname
    if [ -f /etc/hostname ]; then
        echo "$new_hostname" > /etc/hostname
        echo "✅ Hostname actualizado en /etc/hostname"
    fi
    
    # Método 2: hostnamectl (systemd)
    if command -v hostnamectl &> /dev/null; then
        hostnamectl set-hostname "$new_hostname"
        echo "✅ Hostname actualizado con hostnamectl"
    fi
    
    # Método 3: Red Hat/CentOS
    if [ -f /etc/sysconfig/network ]; then
        sed -i "s/HOSTNAME=.*/HOSTNAME=$new_hostname/" /etc/sysconfig/network 2>/dev/null
        echo "✅ Hostname actualizado en /etc/sysconfig/network"
    fi
    
    # Configurar hosts
    configurar_hosts "$new_hostname"
}

# Mostrar hostname actual
echo "=========================================="
echo "    CAMBIO DE HOSTNAME DEL SISTEMA"
echo "=========================================="
echo ""
distro=$(detectar_distro)
echo "📊 Distribución detectada: $distro"
echo "📝 Hostname actual: $(hostname)"
echo ""

# Solicitar nuevo hostname
read -p "Ingresa el nuevo hostname: " new_hostname

# Validar que se ingresó un hostname
if [ -z "$new_hostname" ]; then
    echo "❌ Error: Debes ingresar un hostname válido"
    exit 1
fi

# Validar formato del hostname (solo letras, números y guiones)
if ! echo "$new_hostname" | grep -qE '^[a-zA-Z0-9-]{1,63}$'; then
    echo "❌ Error: El hostname solo puede contener:"
    echo "   - Letras (a-z, A-Z)"
    echo "   - Números (0-9)"
    echo "   - Guiones (-)"
    echo "   - Máximo 63 caracteres"
    exit 1
fi

# Confirmar el cambio
echo ""
echo "⚠️  ATENCIÓN: Estás a punto de cambiar el hostname"
echo "    De: $(hostname)"
echo "    A:  $new_hostname"
echo "    Distribución: $distro"
echo ""
read -p "¿Continuar con el cambio? (s/N): " confirm

if [[ ! $confirm =~ ^[Ss]$ ]]; then
    echo "❌ Operación cancelada por el usuario"
    exit 0
fi

# Realizar el cambio según la distribución
echo ""
echo "🔄 Realizando el cambio de hostname..."

case $distro in
    "arch"|"manjaro"|"endeavouros")
        configurar_hostname_arch "$new_hostname"
        ;;
    *)
        configurar_hostname_general "$new_hostname"
        ;;
esac

echo ""
echo "=========================================="
echo "           CAMBIO COMPLETADO"
echo "=========================================="
echo ""
echo "✅ Hostname cambiado exitosamente a: $new_hostname"
echo ""

# ⚠️ MENSAJE IMPORTANTE SOBRE REINICIO - ESPECÍFICO PARA ARCH
echo "🚨 ⚠️  ⚠️  ⚠️  ⚠️  ⚠️  ⚠️  ⚠️  ⚠️  ⚠️  ⚠️  ⚠️  ⚠️  ⚠️  ⚠️  ⚠️  🚨"
echo ""
echo "📢 IMPORTANCIA CRÍTICA DEL REINICIO:"
echo ""
echo "   🔄 El cambio de hostname REQUIERE un reinicio del sistema"

# Mensaje específico para Arch Linux
if [ "$distro" = "arch" ] || [ "$distro" = "manjaro" ] || [ "$distro" = "endeavouros" ]; then
    echo ""
    echo "   🐧 ESPECIALMENTE EN ARCH LINUX:"
    echo "      • Algunos servicios pueden necesitar reinicio manual"
    echo "      • Los servicios de red deben recargar la configuración"
    echo "      • Aplicaciones como Docker pueden requerir reinicio"
fi

echo ""
echo "   📍 Para que todos los servicios y aplicaciones reconozcan"
echo "   📍 el nuevo nombre del equipo."
echo ""
echo "   ❌ Sin reinicio, podrías experimentar:"
echo "      • Servicios que no inician correctamente"
echo "      • Problemas de red y conectividad"
echo "      • Conflictos en aplicaciones que cachean el hostname"
echo "      • Errores en sistemas de logging y monitoreo"
echo ""

# Soluciones alternativas para Arch (sin reinicio completo)
if [ "$distro" = "arch" ] || [ "$distro" = "manjaro" ] || [ "$distro" = "endeavouros" ]; then
    echo "   🔧 SOLUCIONES TEMPORALES (Arch Linux):"
    echo "      • Reiniciar servicios críticos:"
    echo "        sudo systemctl restart systemd-logind"
    echo "        sudo systemctl restart NetworkManager"
    echo "        sudo systemctl restart sshd"
    echo "      • Exportar variable: export HOSTNAME=$new_hostname"
    echo ""
    echo "   💡 Pero el REINICIO COMPLETO sigue siendo recomendado"
    echo ""
fi

echo "   ✅ Después del reinicio, verifica con:"
echo "      hostname"
echo "      hostnamectl"
echo "      cat /etc/hostname"
echo ""
echo "🔄 Para reiniciar inmediatamente, ejecuta:"
echo "   sudo reboot"
echo ""
echo "🚨 ⚠️  ⚠️  ⚠️  ⚠️  ⚠️  ⚠️  ⚠️  ⚠️  ⚠️  ⚠️  ⚠️  ⚠️  ⚠️  ⚠️  ⚠️  🚨"
echo ""

# Mostrar información actual vs futuro
echo "📊 Resumen del cambio:"
echo "   Distribución:    $distro"
echo "   Hostname anterior: $(hostname)"
echo "   Hostname nuevo:     $new_hostname"
echo "   Estado: Cambio configurado, pendiente de reinicio"
echo ""

# Información adicional específica para Arch
if [ "$distro" = "arch" ] || [ "$distro" = "manjaro" ] || [ "$distro" = "endeavouros" ]; then
    echo "📝 Notas adicionales para Arch Linux:"
    echo "   • Verifica que /etc/hosts tenga el formato correcto"
    echo "   • Algunos servicios pueden necesitar reinicio manual"
    echo "   • Considera usar 'hostnamectl' para cambios futuros"
    echo ""
fi

exit 0
