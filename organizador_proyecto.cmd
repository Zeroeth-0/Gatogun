@echo off
:: Configurar la consola en UTF-8 para evitar problemas con tildes y ñ
chcp 65001 >nul
setlocal enabledelayedexpansion

set OUTPUT_FILE=estructura_y_codigo_proyecto.txt

echo ================================================== > "%OUTPUT_FILE%"
echo ESTRUCTURA COMPLETA DEL PROYECTO >> "%OUTPUT_FILE%"
echo ================================================== >> "%OUTPUT_FILE%"
echo. >> "%OUTPUT_FILE%"

echo Generando estructura del proyecto...

:: 1. Ocultar la carpeta .godot temporalmente para que 'tree' la ignore
if exist ".godot" attrib +h ".godot"

:: Generar el árbol de carpetas y archivos en formato ASCII
tree /A /F >> "%OUTPUT_FILE%"

:: Volver a hacer visible la carpeta .godot
if exist ".godot" attrib -h ".godot"

echo. >> "%OUTPUT_FILE%"
echo ================================================== >> "%OUTPUT_FILE%"
echo CÓDIGO FUENTE DE LOS SCRIPTS Y SHADERS >> "%OUTPUT_FILE%"
echo ================================================== >> "%OUTPUT_FILE%"
echo. >> "%OUTPUT_FILE%"

echo Volcando scripts y shaders...

:: 2. Buscar todos los archivos .gd y .gdshader, ignorando la carpeta .godot
for /f "delims=" %%F in ('dir /b /s *.gd *.gdshader 2^>nul ^| findstr /v /i "\\.godot\\"') do (
    
    :: Convertir la ruta absoluta a ruta relativa (reemplazar la ruta base con .\)
    set "filepath=%%F"
    set "relpath=!filepath:%CD%\=.\!"
    
    echo -------------------------------------------------- >> "%OUTPUT_FILE%"
    echo ARCHIVO: !relpath! >> "%OUTPUT_FILE%"
    echo -------------------------------------------------- >> "%OUTPUT_FILE%"
    echo. >> "%OUTPUT_FILE%"
    
    :: Volcar el contenido del script
    type "%%F" >> "%OUTPUT_FILE%" 2>nul
    
    echo. >> "%OUTPUT_FILE%"
    echo. >> "%OUTPUT_FILE%"
)

echo.
echo =========================================================
echo ¡Hecho! Se ha generado el archivo '%OUTPUT_FILE%'
echo =========================================================
pause