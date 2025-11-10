#!/bin/bash

# Script para detectar permisos excesivos en archivos y directorios
# Autor: [Tu nombre]
# Fecha: $(date +%Y-%m-%d)

# Colores para la salida
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración
DIRECTORIO_BUSQUEDA="${1:-.}"  # Directorio a analizar (por defecto: actual)
REPORTE_ARCHIVO="reporte_permisos_$(date +%Y%m%d_%H%M%S).txt"
UMASK_RECOMENDADO="0022"

# Permisos considerados peligrosos
PERMISOS_PELIGROSOS=(
    "777"  # Todos los permisos para todos
    "666"  # Lectura/escritura para todos
    "444"  # Solo lectura para todos (puede ser problemático)
)

# Permisos para archivos sensibles que no deberían tener permisos amplios
ARCHIVOS_SENSIBLES=(
    "/etc/passwd"
    "/etc/shadow"
    "/etc/sudoers"
    "/etc/ssh/sshd_config"
    "~/.ssh/id_rsa"
    "~/.ssh/id_rsa.pub"
    "~/.ssh/authorized_keys"
)

# Función para mostrar uso del script
mostrar_uso() {
    echo "Uso: $0 [directorio]"
    echo "  directorio: Directorio a analizar (por defecto: directorio actual)"
    echo ""
    echo "Este script busca archivos y directorios con permisos excesivos."
    exit 1
}

# Función para verificar si un permiso es peligroso
es_permiso_peligroso() {
    local permiso="$1"
    for peligroso in "${PERMISOS_PELIGROSOS[@]}"; do
        if [[ "$permiso" == "$peligroso" ]]; then
            return 0  # Verdadero - es peligroso
        fi
    done
    return 1  # Falso - no es peligroso
}

# Función para obtener descripción del permiso
obtener_descripcion_permiso() {
    local permiso="$1"
    local tipo="$2"  # "archivo" o "directorio"
    
    case "$permiso" in
        "777")
            echo "Permisos completos para todos (muy peligroso)"
            ;;
        "666")
            if [[ "$tipo" == "archivo" ]]; then
                echo "Lectura/escritura para todos (peligroso)"
            else
                echo "Lectura/escritura para todos (muy peligroso en directorios)"
            fi
            ;;
        "444")
            echo "Solo lectura para todos (puede causar problemas)"
            ;;
        "755")
            if [[ "$tipo" == "directorio" ]]; then
                echo "Permisos estándar para directorios (aceptable)"
            else
                echo "Ejecutable para todos (revisar si es necesario)"
            fi
            ;;
        "644")
            if [[ "$tipo" == "archivo" ]]; then
                echo "Permisos estándar para archivos (aceptable)"
            else
                echo "Permisos inusuales para directorio"
            fi
            ;;
        *)
            echo "Permisos personalizados"
            ;;
    esac
}

# Función para recomendar permisos seguros
recomendar_permisos() {
    local ruta="$1"
    local tipo="$2"
    local permiso_actual="$3"
    
    echo -e "${BLUE}Recomendación:${NC}"
    
    if [[ -d "$ruta" ]]; then
        case "$permiso_actual" in
            "777")
                echo "  chmod 755 \"$ruta\"  # Directorio: propietario RWX, grupo RX, otros RX"
                ;;
            "666")
                echo "  chmod 755 \"$ruta\"  # Directorio necesita permisos de ejecución"
                ;;
            *)
                echo "  Considerar: chmod 755 para directorios de sistema"
                echo "  Considerar: chmod 700 para directorios personales privados"
                ;;
        esac
    else
        case "$permiso_actual" in
            "777"|"666")
                echo "  chmod 644 \"$ruta\"  # Archivo: propietario RW, grupo R, otros R"
                ;;
            "444")
                echo "  chmod 644 \"$ruta\"  # Archivo necesita permisos de escritura para propietario"
                ;;
            *)
                echo "  Considerar: chmod 644 para archivos regulares"
                echo "  Considerar: chmod 600 para archivos confidenciales"
                ;;
        esac
    fi
}

# Función principal de análisis
analizar_permisos() {
    local directorio="$1"
    
    echo -e "${GREEN}=== Análisis de Permisos Excesivos ===${NC}"
    echo "Directorio analizado: $directorio"
    echo "Fecha: $(date)"
    echo "----------------------------------------"
    
    # Contadores
    local total_archivos=0
    local problemas_encontrados=0
    
    # Buscar archivos y directorios con permisos peligrosos
    while IFS= read -r -d '' item; do
        ((total_archivos++))
        
        if [[ -e "$item" ]]; then
            local permiso=$(stat -c "%a" "$item" 2>/dev/null)
            local usuario=$(stat -c "%U" "$item" 2>/dev/null)
            local grupo=$(stat -c "%G" "$item" 2>/dev/null)
            
            if es_permiso_peligroso "$permiso"; then
                ((problemas_encontrados++))
                
                local tipo="archivo"
                [[ -d "$item" ]] && tipo="directorio"
                
                local descripcion=$(obtener_descripcion_permiso "$permiso" "$tipo")
                
                echo -e "\n${RED}⚠  PROBLEMA ENCONTRADO${NC}"
                echo -e "Ruta: $item"
                echo -e "Tipo: $tipo"
                echo -e "Permisos: ${RED}$permiso${NC} ($descripcion)"
                echo -e "Propietario/Grupo: $usuario/$grupo"
                
                recomendar_permisos "$item" "$tipo" "$permiso"
            fi
        fi
    done < <(find "$directorio" -type f -o -type d -print0 2>/dev/null)
    
    # Verificar archivos sensibles específicos
    echo -e "\n${YELLOW}=== Verificación de Archivos Sensibles ===${NC}"
    for archivo_sensible in "${ARCHIVOS_SENSIBLES[@]}"; do
        # Expandir ~ si está presente
        archivo_sensible="${archivo_sensible/#\~/$HOME}"
        
        if [[ -e "$archivo_sensible" ]]; then
            local permiso=$(stat -c "%a" "$archivo_sensible" 2>/dev/null)
            local usuario=$(stat -c "%U" "$archivo_sensible" 2>/dev/null)
            
            # Verificar permisos para archivos sensibles
            if [[ "$permiso" -gt 600 && "$archivo_sensible" == *"shadow"* ]]; then
                echo -e "${RED}⚠  Archivo sensible con permisos excesivos:${NC}"
                echo "  $archivo_sensible - Permisos: $permiso"
                echo "  Recomendado: 400 o 600"
            elif [[ "$permiso" -gt 644 && "$archivo_sensible" == *".ssh"* ]]; then
                echo -e "${YELLOW}⚠  Archivo SSH con permisos amplios:${NC}"
                echo "  $archivo_sensible - Permisos: $permiso"
                echo "  Recomendado: 600 para claves privadas"
            fi
        fi
    done
    
    # Resumen
    echo -e "\n${GREEN}=== RESUMEN ===${NC}"
    echo "Total de elementos analizados: $total_archivos"
    echo "Problemas de seguridad encontrados: $problemas_encontrados"
    
    if [[ $problemas_encontrados -eq 0 ]]; then
        echo -e "${GREEN}✓ No se encontraron permisos excesivos${NC}"
    else
        echo -e "${RED}✗ Se encontraron $problemas_encontrados elementos con permisos excesivos${NC}"
        echo "Revisa las recomendaciones anteriores para corregir los problemas."
    fi
}

# Función para generar reporte
generar_reporte() {
    analizar_permisos "$DIRECTORIO_BUSQUEDA" | tee "$REPORTE_ARCHIVO"
    echo -e "\n${GREEN}Reporte guardado en: $REPORTE_ARCHIVO${NC}"
}

# Validaciones iniciales
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    mostrar_uso
fi

if [[ ! -d "$DIRECTORIO_BUSQUEDA" ]]; then
    echo -e "${RED}Error: El directorio '$DIRECTORIO_BUSQUEDA' no existe.${NC}"
    exit 1
fi

# Verificar si el usuario tiene permisos de lectura
if [[ ! -r "$DIRECTORIO_BUSQUEDA" ]]; then
    echo -e "${RED}Error: No tienes permisos de lectura en '$DIRECTORIO_BUSQUEDA'.${NC}"
    exit 1
fi

# Ejecutar análisis
echo -e "${BLUE}Iniciando análisis de permisos...${NC}"
generar_reporte

# Mostrar recomendaciones generales
echo -e "\n${YELLOW}=== RECOMENDACIONES GENERALES ===${NC}"
echo "1. Directorios: 755 (rwxr-xr-x) o 700 (rwx------) para privados"
echo "2. Archivos regulares: 644 (rw-r--r--) o 600 (rw-------) para confidenciales"
echo "3. Scripts ejecutables: 755 (rwxr-xr-x)"
echo "4. Archivos de configuración sensibles: 600 (rw-------)"
echo "5. Nunca usar 777 (rwxrwxrwx) o 666 (rw-rw-rw-) en producción"
