#!/bin/bash

# Script para crear la estructura de directorios y archivos con permisos 777

# Crear directorio principal
mkdir -p proyecto_presentacion

# Cambiar al directorio del proyecto
cd proyecto_presentacion

# Crear archivos en la raíz
touch app.py
touch requirements.txt

# Crear directorio templates y sus archivos
mkdir -p templates
touch templates/base.html

# Crear archivos slide1.html a slide10.html
for i in {1..10}; do
    touch templates/slide${i}.html
done

# Crear directorio static con sus subdirectorios y archivos
mkdir -p static/css
mkdir -p static/js
touch static/css/style.css
touch static/js/script.js

# Asignar permisos 777 a toda la estructura
chmod -R 777 .

# Mostrar la estructura creada
echo "Estructura creada exitosamente con permisos 777:"
echo ""
echo "proyecto_presentacion/"
echo "├── app.py"
echo "├── requirements.txt"
echo "├── templates/"
echo "│   ├── base.html"
for i in {1..9}; do
    echo "│   ├── slide${i}.html"
done
echo "│   └── slide10.html"
echo "└── static/"
echo "    ├── css/"
echo "    │   └── style.css"
echo "    └── js/"
echo "        └── script.js"
echo ""
echo "Permisos asignados:"
ls -la
