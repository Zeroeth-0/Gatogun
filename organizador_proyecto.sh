#!/bin/bash

OUTPUT_FILE="estructura_y_codigo_proyecto.txt"

echo "==================================================" > "$OUTPUT_FILE"
echo "ESTRUCTURA COMPLETA DEL PROYECTO" >> "$OUTPUT_FILE"
echo "==================================================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 1. Generar la estructura de archivos (excluyendo la carpeta .godot interna)
if command -v tree &> /dev/null; then
    tree -A -I ".godot" >> "$OUTPUT_FILE"
else
    echo "Instalando 'tree' para una mejor visualización de la estructura..."
    sudo apt-get update && sudo apt-get install -y tree
    tree -A -I ".godot" >> "$OUTPUT_FILE"
fi

echo "" >> "$OUTPUT_FILE"
echo "==================================================" >> "$OUTPUT_FILE"
echo "CÓDIGO FUENTE DE LOS SCRIPTS Y SHADERS" >> "$OUTPUT_FILE"
echo "==================================================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 2. Buscar y volcar todos los archivos .gd y .gdshader
find . -type f \( -name "*.gd" -o -name "*.gdshader" \) ! -path "*/.godot/*" | sort | while read -r archivo; do
    echo "--------------------------------------------------" >> "$OUTPUT_FILE"
    echo "ARCHIVO: $archivo" >> "$OUTPUT_FILE"
    echo "--------------------------------------------------" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    # Volcar el contenido del script
    cat "$archivo" >> "$OUTPUT_FILE"
    
    echo "" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
done

echo "¡Hecho! Se ha generado el archivo '$OUTPUT_FILE' con todo el contexto para NotebookLM."
