#!/bin/bash
# build.sh: Compila el código Ensamblador y C para crear la biblioteca compartida 32-bit.

# --- Funciones de color ---
red() { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
bold() { echo -e "\033[1m$1\033[0m"; }

# --- Salir si cualquier comando falla ---
set -e

green "--- Iniciando Compilación C/ASM (32-bit) ---"

# --- Definición de Archivos y Directorios ---
SRC_DIR="src"
C_BRIDGE_DIR="${SRC_DIR}/c_bridge"
LIB_DIR="../${SRC_DIR}/lib"

ASM_SOURCE="${C_BRIDGE_DIR}/float_rounder.asm"
ASM_OBJECT="${C_BRIDGE_DIR}/float_rounder.o" # Objeto intermedio

C_SOURCE="${C_BRIDGE_DIR}/gini_processor.c"
TARGET_LIB_NAME="libginiprocessor.so"
TARGET_LIB_PATH="${LIB_DIR}/${TARGET_LIB_NAME}"

# Compiladores y Flags
ASM_COMPILER="nasm"
# -f elf: Formato ELF 32-bit para Linux
# -g -F dwarf: Información de depuración (útil con GDB)
ASM_FLAGS="-f elf -g -F dwarf"

C_COMPILER="gcc"
# -m32: Compilar para arquitectura 32-bit
# -shared: Crear una biblioteca compartida (.so)
# -fPIC: Código independiente de posición (requerido para .so)
# -o <path>: Especificar archivo de salida
# -g: Información de depuración
# -Wall: Habilitar todas las advertencias comunes
C_FLAGS="-m32 -shared -fPIC -o ${TARGET_LIB_PATH} -g -Wall"

# --- 1. Verificar Archivos Fuente ---
bold "Paso 1: Verificando archivos fuente..."
if [ ! -f "$ASM_SOURCE" ]; then
    red "Error: No se encontró el archivo fuente ASM '$ASM_SOURCE'."
    exit 1
fi
if [ ! -f "$C_SOURCE" ]; then
    red "Error: No se encontró el archivo fuente C '$C_SOURCE'."
    exit 1
fi
green "Archivos fuente encontrados."
echo

# --- 2. Crear Directorio de Salida si no existe ---
bold "Paso 2: Asegurando directorio de salida '${LIB_DIR}'..."
mkdir -p "$LIB_DIR"
green "Directorio '${LIB_DIR}' listo."
echo

# --- 3. Compilar Ensamblador (ASM -> .o) ---
bold "Paso 3: Compilando Ensamblador (${ASM_SOURCE} -> ${ASM_OBJECT})..."
echo "Comando: ${ASM_COMPILER} ${ASM_FLAGS} ${ASM_SOURCE} -o ${ASM_OBJECT}"
if ${ASM_COMPILER} ${ASM_FLAGS} ${ASM_SOURCE} -o ${ASM_OBJECT}; then
    green "Compilación ASM exitosa."
else
    red "Error durante la compilación ASM."
    exit 1
fi
echo

# --- 4. Compilar C y Enlazar con Objeto ASM (C + .o -> .so) ---
bold "Paso 4: Compilando C y enlazando para crear biblioteca compartida (${TARGET_LIB_PATH})..."
# Es importante pasar el C_SOURCE y el ASM_OBJECT al compilador C
echo "Comando: ${C_COMPILER} ${C_FLAGS} ${C_SOURCE} ${ASM_OBJECT}"
if ${C_COMPILER} ${C_FLAGS} ${C_SOURCE} ${ASM_OBJECT}; then
    green "Compilación C y enlace exitosos."
    green "Biblioteca creada en: ${TARGET_LIB_PATH}"
else
    red "Error durante la compilación/enlace C."
    # Limpiar objeto ASM si falla el enlace? Opcional.
    # rm -f "$ASM_OBJECT"
    exit 1
fi
echo

# --- 5. Verificar Arquitectura de la Biblioteca (Opcional pero recomendado) ---
bold "Paso 5: Verificando arquitectura de la biblioteca generada..."
echo "Comando: file ${TARGET_LIB_PATH}"
if file "${TARGET_LIB_PATH}" | grep -q "ELF 32-bit LSB shared object"; then
    green "Verificación OK: La biblioteca es ELF 32-bit."
else
    yellow "Advertencia: No se pudo confirmar automáticamente que la biblioteca sea 32-bit ELF."
    yellow "Salida de 'file': $(file ${TARGET_LIB_PATH})"
    # No salimos con error, pero advertimos.
fi
echo

# --- 6. Limpieza (Opcional: eliminar objeto intermedio) ---
bold "Paso 6: Limpiando archivo objeto intermedio..."
rm -f "$ASM_OBJECT"
green "Archivo '${ASM_OBJECT}' eliminado."
echo

# --- Finalización ---
green "--- Compilación C/ASM Completada Exitosamente ---"
exit 0
