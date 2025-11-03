#!/bin/bash

# Colores para el menú
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar el menú
mostrar_menu() {
    clear
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}    SISTEMA DE GESTIÓN         ${NC}"
    echo -e "${BLUE}================================${NC}"
    echo -e "${GREEN}1. Instalar actualizaciones${NC}"
    echo -e "${GREEN}2. Crear contenedor Ubuntu${NC}"
    echo -e "${GREEN}3. Instalar firewall${NC}"
    echo -e "${GREEN}4. Instalar htop${NC}"
    echo -e "${GREEN}5. Instalar synaptic${NC}"
    echo -e "${GREEN}6. Instalar codecs${NC}"
    echo -e "${GREEN}7. Instalar tlp (mejorar batería)${NC}"
    echo -e "${GREEN}8. Instalar wine${NC}"
    echo -e "${GREEN}9. Instalar flatpak${NC}"
    echo -e "${GREEN}10. Instalar gimp${NC}"
    echo -e "${GREEN}11. Instalar python3${NC}"
    echo -e "${GREEN}12. Instalar java${NC}"
    echo -e "${GREEN}13. Desactivar telemetría${NC}"
    echo -e "${GREEN}14. Limpiar sistema${NC}"
    echo -e "${GREEN}15. Salir contenedor Ubuntu${NC}"
    echo -e "${RED}0. Salir${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Función para pausar y esperar entrada del usuario
pausa() {
    echo
    echo -e "${YELLOW}Presiona Enter para continuar...${NC}"
    read
}

# Función para ejecutar comandos con verificación
ejecutar_comando() {
    local comando="$1"
    local descripcion="$2"
    
    echo -e "${YELLOW}Ejecutando: $descripcion${NC}"
    echo -e "${BLUE}Comando: $comando${NC}"
    echo
    
    # Preguntar confirmación
    read -p "¿Ejecutar este comando? (s/N): " confirmacion
    if [[ $confirmacion =~ ^[Ss]$ ]]; then
        eval $comando
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Comando ejecutado correctamente${NC}"
        else
            echo -e "${RED}✗ Error al ejecutar el comando${NC}"
        fi
    else
        echo -e "${YELLOW}Comando cancelado${NC}"
    fi
    pausa
}

# Opción 1: Instalar actualizaciones
instalar_actualizaciones() {
    echo -e "${BLUE}=== INSTALAR ACTUALIZACIONES ===${NC}"
    ejecutar_comando "sudo vso update-check" "Verificar actualizaciones"
    ejecutar_comando "sudo vso trigger-update --now" "Ejecutar actualizaciones"
}

# Opción 2: Crear contenedor Ubuntu
crear_contenedor() {
    echo -e "${BLUE}=== CREAR CONTENEDOR UBUNTU ===${NC}"
    echo -e "${YELLOW}Inicializando contenedor...${NC}"
    apx init
    echo "y" | apx init  # Confirmar automáticamente
    echo -e "${GREEN}Contenedor inicializado${NC}"
    
    echo -e "${YELLOW}Entrando al contenedor...${NC}"
    echo -e "${BLUE}Ahora estás dentro del contenedor Ubuntu${NC}"
    echo -e "${YELLOW}Los siguientes comandos apt se ejecutarán dentro del contenedor${NC}"
    pausa
}

# Opción 3: Instalar firewall
instalar_firewall() {
    echo -e "${BLUE}=== INSTALAR FIREWALL ===${NC}"
    ejecutar_comando "sudo apt install ufw -y" "Instalar UFW"
    ejecutar_comando "sudo ufw enable" "Habilitar UFW"
    ejecutar_comando "sudo apt install gufw -y" "Instalar interfaz gráfica GUFW"
}

# Opción 4: Instalar htop
instalar_htop() {
    echo -e "${BLUE}=== INSTALAR HTOP ===${NC}"
    ejecutar_comando "sudo apt install htop -y" "Instalar htop"
}

# Opción 5: Instalar synaptic
instalar_synaptic() {
    echo -e "${BLUE}=== INSTALAR SYNAPTIC ===${NC}"
    ejecutar_comando "sudo apt-get install synaptic -y" "Instalar synaptic"
}

# Opción 6: Instalar codecs
instalar_codecs() {
    echo -e "${BLUE}=== INSTALAR CODECS ===${NC}"
    ejecutar_comando "sudo apt-get install ubuntu-restricted-extras -y" "Instalar codecs restringidos"
}

# Opción 7: Instalar tlp
instalar_tlp() {
    echo -e "${BLUE}=== INSTALAR TLP ===${NC}"
    ejecutar_comando "sudo apt install tlp tlp-rdw -y" "Instalar TLP"
    ejecutar_comando "sudo systemctl enable tlp" "Habilitar TLP"
}

# Opción 8: Instalar wine
instalar_wine() {
    echo -e "${BLUE}=== INSTALAR WINE ===${NC}"
    ejecutar_comando "sudo apt-get install wine64 -y" "Instalar Wine 64-bit"
}

# Opción 9: Instalar flatpak
instalar_flatpak() {
    echo -e "${BLUE}=== INSTALAR FLATPAK ===${NC}"
    ejecutar_comando "sudo apt-get install flatpak -y" "Instalar Flatpak"
}

# Opción 10: Instalar gimp
instalar_gimp() {
    echo -e "${BLUE}=== INSTALAR GIMP ===${NC}"
    ejecutar_comando "sudo apt-get install gimp -y" "Instalar GIMP"
}

# Opción 11: Instalar python
instalar_python() {
    echo -e "${BLUE}=== INSTALAR PYTHON3 ===${NC}"
    ejecutar_comando "sudo apt-get install python3 -y" "Instalar Python3"
}

# Opción 12: Instalar java
instalar_java() {
    echo -e "${BLUE}=== INSTALAR JAVA ===${NC}"
    ejecutar_comando "sudo apt install default-jdk -y" "Instalar JDK por defecto"
}

# Opción 13: Desactivar telemetría
desactivar_telemetria() {
    echo -e "${BLUE}=== DESACTIVAR TELEMETRÍA ===${NC}"
    echo -e "${YELLOW}Esta opción requiere intervención manual:${NC}"
    echo -e "1. Abre 'Configuración del sistema'"
    echo -e "2. Ve a 'Privacidad y seguridad'"
    echo -e "3. Selecciona 'Diagnósticos'" 
    echo -e "4. Desactiva 'Reporte automático de problemas'"
    echo
    echo -e "${YELLOW}Presiona Enter después de completar estos pasos...${NC}"
    read
}

# Opción 14: Limpiar sistema
limpiar_sistema() {
    echo -e "${BLUE}=== LIMPIAR SISTEMA ===${NC}"
    ejecutar_comando "sudo apt-get autoclean -y" "Limpiar paquetes descargados"
    ejecutar_comando "sudo apt-get autoremove -y" "Eliminar dependencias no usadas"
    ejecutar_comando "sudo apt-get clean -y" "Limpiar cache"
}

# Opción 15: Salir del contenedor
salir_contenedor() {
    echo -e "${BLUE}=== SALIR DEL CONTENEDOR ===${NC}"
    echo -e "${YELLOW}Saliendo del contenedor Ubuntu...${NC}"
    echo -e "${GREEN}Ahora los comandos apt no tendrán efecto (fuera del contenedor)${NC}"
    # En un caso real aquí iría el comando 'exit'
    # Pero en el script simulamos la salida
    pausa
}

# Bucle principal del menú
while true; do
    mostrar_menu
    read -p "Selecciona una opción [0-15]: " opcion
    
    case $opcion in
        1) instalar_actualizaciones ;;
        2) crear_contenedor ;;
        3) instalar_firewall ;;
        4) instalar_htop ;;
        5) instalar_synaptic ;;
        6) instalar_codecs ;;
        7) instalar_tlp ;;
        8) instalar_wine ;;
        9) instalar_flatpak ;;
        10) instalar_gimp ;;
        11) instalar_python ;;
        12) instalar_java ;;
        13) desactivar_telemetria ;;
        14) limpiar_sistema ;;
        15) salir_contenedor ;;
        0) 
            echo -e "${GREEN}Saliendo... ¡Hasta pronto!${NC}"
            exit 0 
            ;;
        *) 
            echo -e "${RED}Opción inválida. Presiona Enter para continuar.${NC}"
            pausa
            ;;
    esac
done
