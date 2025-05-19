#!/bin/bash
# test_c_bridge.sh: Compila y ejecuta una prueba dedicada para la interfaz C-ASM.
#                   Crea un ejecutable 32-bit independiente.

# --- Funciones de color (opcional) ---
red() { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
bold() { echo -e "\033[1m$1\033[0m"; }

# --- Salir si cualquier comando falla ---
set -e

green "--- Iniciando Prueba del Puente C <-> ASM ---"

# --- Definición de Archivos ---
SRC_C_BRIDGE_DIR="src/c_bridge"
ASM_SOURCE="${SRC_C_BRIDGE_DIR}/float_rounder.asm"
ASM_OBJECT="float_rounder.o" # Objeto intermedio en la raíz

C_BRIDGE_SOURCE="${SRC_C_BRIDGE_DIR}/gini_processor.c"
C_BRIDGE_OBJECT="gini_processor.o" # Objeto intermedio en la raíz

C_TEST_SOURCE="test_c_bridge.c" # Asume que está en la raíz
TEST_EXECUTABLE="test_c_bridge_exe" # Ejecutable final en la raíz

# Compiladores y Flags
ASM_COMPILER="nasm"
ASM_FLAGS="-f elf -g -F dwarf" # 32-bit ELF, con debug info

C_COMPILER="gcc"
# -m32: Compilar para 32-bit
# -c: Compilar solo, no enlazar (para crear .o)
# -g: Info de debug
# -Wall: Warnings
C_COMPILE_FLAGS="-m32 -c -g -Wall"
# Flags para enlazar el ejecutable final
# -lm: Enlazar con la librería matemática (libm) necesaria para roundf/fabsf en test_c_bridge.c
C_LINK_FLAGS="-m32 -o ${TEST_EXECUTABLE} -g -Wall -lm"

# --- 1. Compilar Ensamblador (ASM -> .o) ---
bold "Paso 1: Compilando ASM (${ASM_SOURCE} -> ${ASM_OBJECT})..."
if ${ASM_COMPILER} ${ASM_FLAGS} "${ASM_SOURCE}" -o "${ASM_OBJECT}"; then
    green "Compilación ASM exitosa."
else
    red "Error compilando ASM."
    exit 1
fi
echo

# --- 2. Compilar Puente C (C -> .o) ---
bold "Paso 2: Compilando Puente C (${C_BRIDGE_SOURCE} -> ${C_BRIDGE_OBJECT})..."
if ${C_COMPILER} ${C_COMPILE_FLAGS} "${C_BRIDGE_SOURCE}" -o "${C_BRIDGE_OBJECT}"; then
    green "Compilación del Puente C exitosa."
else
    red "Error compilando el Puente C."
    rm -f "${ASM_OBJECT}" # Limpiar objeto ASM si falla C
    exit 1
fi
echo

# --- 3. Compilar Programa de Prueba y Enlazar Todo (Test C + Objetos -> exe) ---
bold "Paso 3: Compilando Programa de Prueba y Enlazando (${C_TEST_SOURCE} + .o -> ${TEST_EXECUTABLE})..."
if ${C_COMPILER} ${C_LINK_FLAGS} "${C_TEST_SOURCE}" "${C_BRIDGE_OBJECT}" "${ASM_OBJECT}"; then
    green "Compilación y Enlace del Ejecutable de Prueba exitoso."
    green "Ejecutable creado: ${TEST_EXECUTABLE}"
else
    red "Error compilando/enlazando el ejecutable de prueba."
    rm -f "${ASM_OBJECT}" "${C_BRIDGE_OBJECT}" # Limpiar objetos
    exit 1
fi
echo

# --- 4. Ejecutar la Prueba ---
bold "Paso 4: Ejecutando ${TEST_EXECUTABLE}..."
echo "------------------------------------------"
if ./${TEST_EXECUTABLE}; then
    # El ejecutable retorna 0 en éxito (ningún fallo)
    echo "------------------------------------------"
    green "Prueba del Puente C <-> ASM completada exitosamente (Todos los casos PASS)."
    EXIT_CODE=0
else
    # El ejecutable retorna != 0 si hubo fallos
    echo "------------------------------------------"
    red "Prueba del Puente C <-> ASM completada con FALLOS."
    EXIT_CODE=1 # O podríamos usar el código de salida del exe: $?
fi
echo

# --- 5. Limpieza (Opcional) ---
bold "Paso 5: Limpiando archivos objeto intermedios..."
rm -f "${ASM_OBJECT}" "${C_BRIDGE_OBJECT}"
green "Archivos '${ASM_OBJECT}' y '${C_BRIDGE_OBJECT}' eliminados."
echo

# --- Finalización ---
if [ $EXIT_CODE -eq 0 ]; then
    green "--- Prueba Finalizada: ÉXITO ---"
else
    red "--- Prueba Finalizada: FALLO ---"
fi

exit $EXIT_CODE