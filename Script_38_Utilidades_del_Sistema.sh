#!/bin/bash

# Función para mostrar el menú
mostrar_menu() {
    clear
    echo "=============================================="
    echo "           UTILIDADES DEL SISTEMA            "
    echo "=============================================="
    echo "1. Mostrar fecha y hora (date)"
    echo "2. Mostrar tiempo activo (uptime)"
    echo "3. Mostrar nombre del host (hostname)"
    echo "4. Mostrar información del sistema (uname)"
    echo "5. Mostrar ruta de comandos (which)"
    echo "6. Mostrar calendario (cal) - CON OPCIONES"
    echo "7. Calculadora (bc)"
    echo "8. Salir"
    echo "=============================================="
}

# Función para mostrar calendario con opciones
mostrar_calendario() {
    while true; do
        clear
        echo "=============================================="
        echo "              OPCIONES DE CALENDARIO          "
        echo "=============================================="
        echo "1. Calendario del mes actual"
        echo "2. Calendario de un mes específico"
        echo "3. Calendario de un año completo"
        echo "4. Calendario de un rango de meses"
        echo "5. Volver al menú principal"
        echo "=============================================="
        echo -n "Selecciona una opción [1-5]: "
        read opcion_cal
        
        case $opcion_cal in
            1)
                echo ""
                echo "=== CALENDARIO DEL MES ACTUAL ==="
                cal
                ;;
            2)
                echo ""
                echo -n "Ingresa el mes (1-12): "
                read mes
                echo -n "Ingresa el año (ej: 2024): "
                read anio
                echo ""
                echo "=== CALENDARIO DE $mes/$anio ==="
                cal $mes $anio
                ;;
            3)
                echo ""
                echo -n "Ingresa el año (ej: 2024): "
                read anio
                echo ""
                echo "=== CALENDARIO DEL AÑO $anio ==="
                cal -y $anio
                ;;
            4)
                echo ""
                echo "=== CALENDARIO DE RANGO DE MESES ==="
                echo -n "Ingresa el mes inicial (1-12): "
                read mes_inicio
                echo -n "Ingresa el año inicial (ej: 2024): "
                read anio_inicio
                echo -n "Ingresa el mes final (1-12): "
                read mes_final
                echo -n "Ingresa el año final (ej: 2024): "
                read anio_final
                echo ""
                
                # Validar que el rango sea válido
                if [ $anio_inicio -gt $anio_final ] || ([ $anio_inicio -eq $anio_final ] && [ $mes_inicio -gt $mes_final ]); then
                    echo "Error: El rango de fechas no es válido"
                else
                    current_mes=$mes_inicio
                    current_anio=$anio_inicio
                    
                    while true; do
                        echo "=== CALENDARIO DE $(date --date="$current_anio-$current_mes-01" +"%B %Y") ==="
                        cal $current_mes $current_anio
                        echo ""
                        
                        # Verificar si hemos llegado al final del rango
                        if [ $current_anio -eq $anio_final ] && [ $current_mes -eq $mes_final ]; then
                            break
                        fi
                        
                        # Incrementar mes
                        current_mes=$((current_mes + 1))
                        if [ $current_mes -gt 12 ]; then
                            current_mes=1
                            current_anio=$((current_anio + 1))
                        fi
                    done
                fi
                ;;
            5)
                return
                ;;
            *)
                echo "Opción no válida. Por favor, selecciona una opción del 1 al 5."
                ;;
        esac
        
        echo ""
        echo "Presiona Enter para continuar..."
        read
    done
}

# Función para pausar y esperar entrada del usuario
pausa() {
    echo ""
    echo "Presiona Enter para continuar..."
    read
}

# Bucle principal del menú
while true; do
    mostrar_menu
    echo -n "Selecciona una opción [1-8]: "
    read opcion
    
    case $opcion in
        1)
            echo ""
            echo "=== FECHA Y HORA ==="
            date
            pausa
            ;;
        2)
            echo ""
            echo "=== TIEMPO ACTIVO ==="
            uptime
            pausa
            ;;
        3)
            echo ""
            echo "=== NOMBRE DEL HOST ==="
            hostname
            pausa
            ;;
        4)
            echo ""
            echo "=== INFORMACIÓN DEL SISTEMA ==="
            uname -a
            pausa
            ;;
        5)
            echo ""
            echo "=== RUTA DE COMANDOS ==="
            echo -n "Ingresa el comando a buscar: "
            read comando
            which $comando
            pausa
            ;;
        6)
            mostrar_calendario
            ;;
        7)
            echo ""
            echo "=== CALCULADORA BC ==="
            echo "Ingresa operaciones matemáticas (ej: 2+2, 10*5, sqrt(16))"
            echo "Escribe 'quit' para salir de bc"
            echo ""
            bc
            pausa
            ;;
        8)
            echo ""
            echo "¡Gracias por usar Utilidades del Sistema!"
            echo "¡Hasta luego!"
            exit 0
            ;;
        *)
            echo ""
            echo "Opción no válida. Por favor, selecciona una opción del 1 al 8."
            pausa
            ;;
    esac
done
