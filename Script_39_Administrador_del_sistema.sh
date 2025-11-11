#!/bin/bash

# Colores para el menú
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Función para mostrar el encabezado
mostrar_encabezado() {
    clear
    echo -e "${CYAN}"
    echo "=========================================="
    echo "    ADMINISTRADOR DEL SISTEMA"
    echo "=========================================="
    echo -e "${NC}"
}

# Función para pausar y esperar entrada
pausa() {
    echo -e "\n${YELLOW}Presiona Enter para continuar...${NC}"
    read
}

# Función para el menú principal
menu_principal() {
    while true; do
        mostrar_encabezado
        echo -e "${GREEN}MENÚ PRINCIPAL${NC}"
        echo "1. Gestión de Servicios (systemctl)"
        echo "2. Procesos del Sistema (ps/top)"
        echo "3. Gestión de Procesos (kill)"
        echo "4. 🕐 AUTOMATIZACIÓN DE TAREAS (crontab)"
        echo "5. Programación de Tareas Únicas (at)"
        echo "6. Salir"
        echo -e "\n${YELLOW}Selecciona una opción [1-6]: ${NC}"
        read opcion

        case $opcion in
            1) menu_systemctl ;;
            2) menu_procesos ;;
            3) menu_kill ;;
            4) menu_crontab ;;
            5) menu_at ;;
            6) 
                echo -e "${GREEN}Saliendo... ¡Hasta pronto!${NC}"
                exit 0
                ;;
            *) 
                echo -e "${RED}Opción inválida. Intenta nuevamente.${NC}"
                pausa
                ;;
        esac
    done
}

# Función para el menú de systemctl
menu_systemctl() {
    while true; do
        mostrar_encabezado
        echo -e "${BLUE}GESTIÓN DE SERVICIOS (systemctl)${NC}"
        echo "1. Listar servicios activos"
        echo "2. Estado de un servicio específico"
        echo "3. Iniciar un servicio"
        echo "4. Detener un servicio"
        echo "5. Reiniciar un servicio"
        echo "6. Recargar configuración de un servicio"
        echo "7. Habilitar servicio en el arranque"
        echo "8. Deshabilitar servicio en el arranque"
        echo "9. Volver al menú principal"
        echo -e "\n${YELLOW}Selecciona una opción [1-9]: ${NC}"
        read opcion

        case $opcion in
            1)
                echo -e "\n${GREEN}Servicios activos:${NC}"
                systemctl list-units --type=service --state=running
                ;;
            2)
                echo -e "\n${YELLOW}Ingresa el nombre del servicio: ${NC}"
                read servicio
                systemctl status "$servicio"
                ;;
            3)
                echo -e "\n${YELLOW}Ingresa el nombre del servicio a iniciar: ${NC}"
                read servicio
                sudo systemctl start "$servicio"
                ;;
            4)
                echo -e "\n${YELLOW}Ingresa el nombre del servicio a detener: ${NC}"
                read servicio
                sudo systemctl stop "$servicio"
                ;;
            5)
                echo -e "\n${YELLOW}Ingresa el nombre del servicio a reiniciar: ${NC}"
                read servicio
                sudo systemctl restart "$servicio"
                ;;
            6)
                echo -e "\n${YELLOW}Ingresa el nombre del servicio a recargar: ${NC}"
                read servicio
                sudo systemctl reload "$servicio"
                ;;
            7)
                echo -e "\n${YELLOW}Ingresa el nombre del servicio a habilitar: ${NC}"
                read servicio
                sudo systemctl enable "$servicio"
                ;;
            8)
                echo -e "\n${YELLOW}Ingresa el nombre del servicio a deshabilitar: ${NC}"
                read servicio
                sudo systemctl disable "$servicio"
                ;;
            9) return ;;
            *) 
                echo -e "${RED}Opción inválida.${NC}"
                ;;
        esac
        pausa
    done
}

# Función para el menú de procesos
menu_procesos() {
    while true; do
        mostrar_encabezado
        echo -e "${BLUE}PROCESOS DEL SISTEMA${NC}"
        echo "1. Listar todos los procesos (ps aux)"
        echo "2. Ver procesos en tiempo real (top)"
        echo "3. Ver procesos del usuario actual"
        echo "4. Ver árbol de procesos"
        echo "5. Volver al menú principal"
        echo -e "\n${YELLOW}Selecciona una opción [1-5]: ${NC}"
        read opcion

        case $opcion in
            1) ps aux | less ;;
            2) top ;;
            3) ps -u $USER ;;
            4) pstree ;;
            5) return ;;
            *) 
                echo -e "${RED}Opción inválida.${NC}"
                pausa
                ;;
        esac
        pausa
    done
}

# Función para el menú de kill
menu_kill() {
    while true; do
        mostrar_encabezado
        echo -e "${RED}GESTIÓN DE PROCESOS (kill)${NC}"
        echo "1. Listar procesos para identificar PID"
        echo "2. Terminar proceso por PID (SIGTERM)"
        echo "3. Forzar terminación de proceso (SIGKILL)"
        echo "4. Terminar proceso por nombre"
        echo "5. Volver al menú principal"
        echo -e "\n${YELLOW}Selecciona una opción [1-5]: ${NC}"
        read opcion

        case $opcion in
            1)
                echo -e "\n${GREEN}Lista de procesos:${NC}"
                ps aux --sort=-%cpu | head -20
                ;;
            2)
                echo -e "\n${YELLOW}Ingresa el PID del proceso a terminar: ${NC}"
                read pid
                kill $pid
                ;;
            3)
                echo -e "\n${YELLOW}Ingresa el PID del proceso a forzar: ${NC}"
                read pid
                kill -9 $pid
                ;;
            4)
                echo -e "\n${YELLOW}Ingresa el nombre del proceso a terminar: ${NC}"
                read proceso
                pkill "$proceso"
                ;;
            5) return ;;
            *) 
                echo -e "${RED}Opción inválida.${NC}"
                ;;
        esac
        pausa
    done
}

# Función para el menú de crontab (ENFATIZADO)
menu_crontab() {
    while true; do
        mostrar_encabezado
        echo -e "${PURPLE}🕐 AUTOMATIZACIÓN DE TAREAS (crontab)${NC}"
        echo -e "${CYAN}¡SECCIÓN PARA AUTOMATIZAR TAREAS!${NC}"
        echo "1. Ver tareas programadas actuales"
        echo "2. Editar tareas programadas"
        echo "3. Listar tareas programadas de forma legible"
        echo "4. Agregar tarea programada automáticamente"
        echo "5. Eliminar todas las tareas programadas"
        echo "6. Ejemplos de configuración crontab"
        echo "7. Ver log de crontab"
        echo "8. Volver al menú principal"
        echo -e "\n${YELLOW}Selecciona una opción [1-8]: ${NC}"
        read opcion

        case $opcion in
            1)
                echo -e "\n${GREEN}Tus tareas programadas actuales:${NC}"
                crontab -l
                ;;
            2)
                echo -e "\n${YELLOW}Editando crontab...${NC}"
                crontab -e
                ;;
            3)
                echo -e "\n${GREEN}Tareas programadas (formato legible):${NC}"
                crontab -l | while read line; do
                    if [[ ! $line =~ ^# ]]; then
                        echo "Tarea: $line"
                    fi
                done
                ;;
            4)
                agregar_tarea_crontab
                ;;
            5)
                echo -e "\n${RED}¿Estás seguro de eliminar todas las tareas programadas? (s/n): ${NC}"
                read confirmacion
                if [[ $confirmacion == "s" || $confirmacion == "S" ]]; then
                    crontab -r
                    echo -e "${GREEN}Todas las tareas programadas han sido eliminadas.${NC}"
                else
                    echo -e "${YELLOW}Operación cancelada.${NC}"
                fi
                ;;
            6)
                mostrar_ejemplos_crontab
                ;;
            7)
                echo -e "\n${GREEN}Últimas entradas del log de crontab:${NC}"
                if [ -f /var/log/syslog ]; then
                    grep CRON /var/log/syslog | tail -20
                elif [ -f /var/log/cron ]; then
                    tail -20 /var/log/cron
                else
                    echo "No se pudo encontrar el archivo de log de cron"
                fi
                ;;
            8) return ;;
            *) 
                echo -e "${RED}Opción inválida.${NC}"
                ;;
        esac
        pausa
    done
}

# Función para agregar tareas a crontab automáticamente
agregar_tarea_crontab() {
    mostrar_encabezado
    echo -e "${PURPLE}AGREGAR TAREA PROGRAMADA AUTOMÁTICAMENTE${NC}"
    echo -e "\n${YELLOW}Selecciona el tipo de tarea:${NC}"
    echo "1. Backup diario"
    echo "2. Limpieza semanal"
    echo "3. Monitoreo cada 5 minutos"
    echo "4. Tarea personalizada"
    echo "5. Cancelar"
    echo -e "\n${YELLOW}Selecciona una opción [1-5]: ${NC}"
    read tipo_tarea

    case $tipo_tarea in
        1)
            # Backup diario a las 2 AM
            (crontab -l; echo "0 2 * * * tar -czf /home/$USER/backup_$(date +\%Y\%m\%d).tar.gz /home/$USER/Documentos 2>/dev/null") | crontab -
            echo -e "${GREEN}Tarea de backup diario agregada (2:00 AM)${NC}"
            ;;
        2)
            # Limpieza semanal los domingos a las 3 AM
            (crontab -l; echo "0 3 * * 0 find /tmp -type f -mtime +7 -delete 2>/dev/null") | crontab -
            echo -e "${GREEN}Tarea de limpieza semanal agregada (Domingos 3:00 AM)${NC}"
            ;;
        3)
            # Monitoreo cada 5 minutos
            (crontab -l; echo "*/5 * * * * ps aux --sort=-%cpu | head -5 > /home/$USER/cpu_monitor.log 2>/dev/null") | crontab -
            echo -e "${GREEN}Tarea de monitoreo cada 5 minutos agregada${NC}"
            ;;
        4)
            agregar_tarea_personalizada
            ;;
        5)
            echo -e "${YELLOW}Operación cancelada.${NC}"
            return
            ;;
        *)
            echo -e "${RED}Opción inválida.${NC}"
            return
            ;;
    esac
    
    echo -e "\n${GREEN}Tareas programadas actualizadas:${NC}"
    crontab -l
}

# Función para agregar tarea personalizada
agregar_tarea_personalizada() {
    echo -e "\n${YELLOW}Configuración de tarea personalizada:${NC}"
    
    echo -e "Minuto (0-59, * para cualquier): "
    read minuto
    echo -e "Hora (0-23, * para cualquier): "
    read hora
    echo -e "Día del mes (1-31, * para cualquier): "
    read dia_mes
    echo -e "Mes (1-12, * para cualquier): "
    read mes
    echo -e "Día de la semana (0-7, 0=Dom, 7=Dom, * para cualquier): "
    read dia_semana
    echo -e "Comando a ejecutar: "
    read comando
    
    # Validar entradas básicas
    if [[ -z "$minuto" || -z "$hora" || -z "$dia_mes" || -z "$mes" || -z "$dia_semana" || -z "$comando" ]]; then
        echo -e "${RED}Error: Todos los campos son obligatorios.${NC}"
        return
    fi
    
    # Agregar la tarea
    (crontab -l; echo "$minuto $hora $dia_mes $mes $dia_semana $comando") | crontab -
    echo -e "${GREEN}Tarea personalizada agregada exitosamente.${NC}"
}

# Función para mostrar ejemplos de crontab
mostrar_ejemplos_crontab() {
    echo -e "\n${CYAN}EJEMPLOS DE CONFIGURACIÓN CRONTAB:${NC}"
    echo -e "${GREEN}Formato: minuto hora dia_mes mes dia_semana comando${NC}"
    echo ""
    echo "Ejemplos útiles:"
    echo "*/5 * * * *  /ruta/script.sh        # Cada 5 minutos"
    echo "0 * * * *    /ruta/script.sh        # Cada hora en punto"
    echo "0 2 * * *    /ruta/backup.sh        # Diario a las 2:00 AM"
    echo "0 3 * * 1    /ruta/limpieza.sh      # Cada lunes a las 3:00 AM"
    echo "0 0 1 * *    /ruta/mensual.sh       # El primer día de cada mes"
    echo "0 9-17 * * 1-5 /ruta/oficina.sh     # Horario laboral (L-V 9AM-5PM)"
    echo "*/10 * * * * /ruta/monitor.sh       # Cada 10 minutos"
    echo ""
    echo -e "${YELLOW}Variables especiales:${NC}"
    echo "@reboot      /ruta/script.sh        # Al iniciar el sistema"
    echo "@daily       /ruta/script.sh        # Una vez al día"
    echo "@weekly      /ruta/script.sh        # Una vez por semana"
    echo "@monthly     /ruta/script.sh        # Una vez al mes"
    echo "@yearly      /ruta/script.sh        # Una vez al año"
}

# Función para el menú de at
menu_at() {
    while true; do
        mostrar_encabezado
        echo -e "${BLUE}PROGRAMACIÓN DE TAREAS ÚNICAS (at)${NC}"
        echo "1. Programar tarea para ejecución única"
        echo "2. Listar tareas programadas con at"
        echo "3. Eliminar tarea programada con at"
        echo "4. Ver ejemplos de uso de at"
        echo "5. Volver al menú principal"
        echo -e "\n${YELLOW}Selecciona una opción [1-5]: ${NC}"
        read opcion

        case $opcion in
            1)
                echo -e "\n${YELLOW}Ingresa el tiempo de ejecución (ej: 14:30, now + 1 hour, tomorrow 09:00): ${NC}"
                read tiempo
                echo -e "${YELLOW}Ingresa el comando a ejecutar: ${NC}"
                read comando
                echo "$comando" | at $tiempo
                echo -e "${GREEN}Tarea programada exitosamente.${NC}"
                ;;
            2)
                echo -e "\n${GREEN}Tareas programadas con at:${NC}"
                atq
                ;;
            3)
                echo -e "\n${YELLOW}Ingresa el número de trabajo a eliminar: ${NC}"
                read job_num
                atrm $job_num
                echo -e "${GREEN}Tarea eliminada.${NC}"
                ;;
            4)
                echo -e "\n${CYAN}EJEMPLOS DE USO DE AT:${NC}"
                echo "echo 'ls -la' | at 14:30           # Hoy a las 2:30 PM"
                echo "echo 'backup.sh' | at now + 2 hours # En 2 horas"
                echo "echo 'script.sh' | at tomorrow 09:00 # Mañana a las 9:00 AM"
                echo "echo 'task.sh' | at noon           # Al mediodía"
                echo "echo 'clean.sh' | at midnight      # A la medianoche"
                ;;
            5) return ;;
            *) 
                echo -e "${RED}Opción inválida.${NC}"
                ;;
        esac
        pausa
    done
}

# Verificar si el script se ejecuta como root para algunas funciones
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}Advertencia: Algunas funciones pueden requerir privilegios de root.${NC}"
    echo -e "${YELLOW}Ejecuta el script con sudo para acceso completo.${NC}"
    echo ""
fi

# Iniciar el menú principal
menu_principal
