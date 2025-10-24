#!/bin/bash

# Script de Gestión de iptables
# Requiere privilegios de root

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Verificar si se ejecuta como root
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        echo -e "${RED}Este script debe ejecutarse como root (usa sudo)${NC}"
        exit 1
    fi
}

# Mostrar menú principal
show_menu() {
    clear
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}   Gestor de iptables${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
    echo "1.  Ver reglas actuales"
    echo "2.  Bloquear IP (DROP)"
    echo "3.  Bloquear IP (REJECT)"
    echo "4.  Desbloquear IP"
    echo "5.  Permitir puerto específico"
    echo "6.  Bloquear puerto específico"
    echo "7.  Permitir rango de puertos"
    echo "8.  Bloquear país (requiere geoip)"
    echo "9.  Limitar conexiones por IP"
    echo "10. Guardar reglas actuales"
    echo "11. Restaurar reglas guardadas"
    echo "12. Limpiar todas las reglas"
    echo "13. Configuración básica de seguridad"
    echo "14. Ver reglas de cadena específica"
    echo "15. Eliminar regla por número"
    echo "16. Permitir IP específica"
    echo "17. Bloquear rango de IPs"
    echo "18. Ver estadísticas de reglas"
    echo "19. Exportar reglas a archivo"
    echo "0.  Salir"
    echo ""
    echo -n "Selecciona una opción: "
}

# Ver reglas actuales
view_rules() {
    echo -e "\n${GREEN}=== Reglas INPUT ===${NC}"
    iptables -L INPUT -n -v --line-numbers
    echo -e "\n${GREEN}=== Reglas OUTPUT ===${NC}"
    iptables -L OUTPUT -n -v --line-numbers
    echo -e "\n${GREEN}=== Reglas FORWARD ===${NC}"
    iptables -L FORWARD -n -v --line-numbers
    echo -e "\n${GREEN}=== Reglas NAT ===${NC}"
    iptables -t nat -L -n -v --line-numbers
}

# Bloquear IP con DROP
block_ip_drop() {
    echo -n "Ingresa la IP a bloquear: "
    read ip
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        iptables -A INPUT -s $ip -j DROP
        echo -e "${GREEN}IP $ip bloqueada (DROP)${NC}"
    else
        echo -e "${RED}IP inválida${NC}"
    fi
}

# Bloquear IP con REJECT
block_ip_reject() {
    echo -n "Ingresa la IP a bloquear: "
    read ip
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        iptables -A INPUT -s $ip -j REJECT
        echo -e "${GREEN}IP $ip bloqueada (REJECT)${NC}"
    else
        echo -e "${RED}IP inválida${NC}"
    fi
}

# Desbloquear IP
unblock_ip() {
    echo -n "Ingresa la IP a desbloquear: "
    read ip
    iptables -D INPUT -s $ip -j DROP 2>/dev/null
    iptables -D INPUT -s $ip -j REJECT 2>/dev/null
    echo -e "${GREEN}IP $ip desbloqueada${NC}"
}

# Permitir puerto
allow_port() {
    echo -n "Ingresa el puerto a permitir: "
    read port
    echo -n "Protocolo (tcp/udp/both): "
    read proto
    
    case $proto in
        tcp)
            iptables -A INPUT -p tcp --dport $port -j ACCEPT
            echo -e "${GREEN}Puerto $port/tcp permitido${NC}"
            ;;
        udp)
            iptables -A INPUT -p udp --dport $port -j ACCEPT
            echo -e "${GREEN}Puerto $port/udp permitido${NC}"
            ;;
        both)
            iptables -A INPUT -p tcp --dport $port -j ACCEPT
            iptables -A INPUT -p udp --dport $port -j ACCEPT
            echo -e "${GREEN}Puerto $port/tcp y udp permitido${NC}"
            ;;
        *)
            echo -e "${RED}Protocolo inválido${NC}"
            ;;
    esac
}

# Bloquear puerto
block_port() {
    echo -n "Ingresa el puerto a bloquear: "
    read port
    echo -n "Protocolo (tcp/udp/both): "
    read proto
    
    case $proto in
        tcp)
            iptables -A INPUT -p tcp --dport $port -j DROP
            echo -e "${GREEN}Puerto $port/tcp bloqueado${NC}"
            ;;
        udp)
            iptables -A INPUT -p udp --dport $port -j DROP
            echo -e "${GREEN}Puerto $port/udp bloqueado${NC}"
            ;;
        both)
            iptables -A INPUT -p tcp --dport $port -j DROP
            iptables -A INPUT -p udp --dport $port -j DROP
            echo -e "${GREEN}Puerto $port/tcp y udp bloqueado${NC}"
            ;;
        *)
            echo -e "${RED}Protocolo inválido${NC}"
            ;;
    esac
}

# Permitir rango de puertos
allow_port_range() {
    echo -n "Puerto inicial: "
    read port_start
    echo -n "Puerto final: "
    read port_end
    echo -n "Protocolo (tcp/udp): "
    read proto
    
    iptables -A INPUT -p $proto --dport $port_start:$port_end -j ACCEPT
    echo -e "${GREEN}Rango de puertos $port_start:$port_end/$proto permitido${NC}"
}

# Limitar conexiones por IP
limit_connections() {
    echo -n "Ingresa el puerto a proteger: "
    read port
    echo -n "Máximo de conexiones por minuto: "
    read limit
    
    iptables -A INPUT -p tcp --dport $port -m state --state NEW -m recent --set
    iptables -A INPUT -p tcp --dport $port -m state --state NEW -m recent --update --seconds 60 --hitcount $limit -j DROP
    echo -e "${GREEN}Límite de $limit conexiones por minuto configurado en puerto $port${NC}"
}

# Guardar reglas
save_rules() {
    if command -v iptables-save &> /dev/null; then
        iptables-save > /etc/iptables/rules.v4 2>/dev/null || iptables-save > /tmp/iptables-rules.backup
        echo -e "${GREEN}Reglas guardadas${NC}"
        echo -e "${YELLOW}Ubicación: /etc/iptables/rules.v4 o /tmp/iptables-rules.backup${NC}"
    else
        echo -e "${RED}iptables-save no disponible${NC}"
    fi
}

# Restaurar reglas
restore_rules() {
    if [ -f /etc/iptables/rules.v4 ]; then
        iptables-restore < /etc/iptables/rules.v4
        echo -e "${GREEN}Reglas restauradas desde /etc/iptables/rules.v4${NC}"
    elif [ -f /tmp/iptables-rules.backup ]; then
        iptables-restore < /tmp/iptables-rules.backup
        echo -e "${GREEN}Reglas restauradas desde /tmp/iptables-rules.backup${NC}"
    else
        echo -e "${RED}No se encontró archivo de reglas${NC}"
    fi
}

# Limpiar todas las reglas
flush_rules() {
    echo -e "${YELLOW}¿Estás seguro? Esto eliminará TODAS las reglas (s/n): ${NC}"
    read confirm
    if [ "$confirm" = "s" ] || [ "$confirm" = "S" ]; then
        iptables -F
        iptables -X
        iptables -t nat -F
        iptables -t nat -X
        iptables -t mangle -F
        iptables -t mangle -X
        iptables -P INPUT ACCEPT
        iptables -P FORWARD ACCEPT
        iptables -P OUTPUT ACCEPT
        echo -e "${GREEN}Todas las reglas eliminadas${NC}"
    fi
}

# Configuración básica de seguridad
basic_security() {
    echo -e "${YELLOW}Aplicando configuración básica de seguridad...${NC}"
    
    # Permitir tráfico loopback
    iptables -A INPUT -i lo -j ACCEPT
    
    # Permitir conexiones establecidas
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    
    # Permitir SSH (puerto 22)
    iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    
    # Protección contra syn-flood
    iptables -A INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 3 -j ACCEPT
    
    # Bloquear ping floods
    iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s -j ACCEPT
    
    # Bloquear escaneo de puertos
    iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
    iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
    
    # Política por defecto
    echo -e "${YELLOW}¿Establecer política DROP por defecto? (s/n): ${NC}"
    read policy
    if [ "$policy" = "s" ] || [ "$policy" = "S" ]; then
        iptables -P INPUT DROP
        echo -e "${GREEN}Política INPUT establecida a DROP${NC}"
    fi
    
    echo -e "${GREEN}Configuración básica de seguridad aplicada${NC}"
}

# Ver reglas de cadena específica
view_chain() {
    echo -n "Ingresa la cadena (INPUT/OUTPUT/FORWARD): "
    read chain
    iptables -L $chain -n -v --line-numbers
}

# Eliminar regla por número
delete_rule_by_number() {
    echo -n "Cadena (INPUT/OUTPUT/FORWARD): "
    read chain
    echo -e "\n${GREEN}Reglas actuales:${NC}"
    iptables -L $chain -n --line-numbers
    echo -n "\nNúmero de regla a eliminar: "
    read num
    iptables -D $chain $num
    echo -e "${GREEN}Regla eliminada${NC}"
}

# Permitir IP específica
allow_ip() {
    echo -n "Ingresa la IP a permitir: "
    read ip
    iptables -I INPUT -s $ip -j ACCEPT
    echo -e "${GREEN}IP $ip permitida${NC}"
}

# Bloquear rango de IPs
block_ip_range() {
    echo -n "Ingresa el rango de IPs (ej: 192.168.1.0/24): "
    read range
    iptables -A INPUT -s $range -j DROP
    echo -e "${GREEN}Rango $range bloqueado${NC}"
}

# Ver estadísticas
view_stats() {
    echo -e "\n${GREEN}=== Estadísticas de Paquetes ===${NC}"
    iptables -L -n -v -x
}

# Exportar reglas
export_rules() {
    echo -n "Nombre del archivo (sin extensión): "
    read filename
    iptables-save > "${filename}.rules"
    echo -e "${GREEN}Reglas exportadas a ${filename}.rules${NC}"
}

# Función principal
main() {
    check_root
    
    while true; do
        show_menu
        read option
        
        case $option in
            1) view_rules ;;
            2) block_ip_drop ;;
            3) block_ip_reject ;;
            4) unblock_ip ;;
            5) allow_port ;;
            6) block_port ;;
            7) allow_port_range ;;
            8) echo -e "${YELLOW}Función de GeoIP requiere módulo adicional${NC}" ;;
            9) limit_connections ;;
            10) save_rules ;;
            11) restore_rules ;;
            12) flush_rules ;;
            13) basic_security ;;
            14) view_chain ;;
            15) delete_rule_by_number ;;
            16) allow_ip ;;
            17) block_ip_range ;;
            18) view_stats ;;
            19) export_rules ;;
            0) echo -e "${GREEN}Saliendo...${NC}"; exit 0 ;;
            *) echo -e "${RED}Opción inválida${NC}" ;;
        esac
        
        echo -e "\n${YELLOW}Presiona Enter para continuar...${NC}"
        read
    done
}

# Ejecutar script
main
