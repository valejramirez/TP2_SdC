#!/bin/bash
# debug.sh: Compila los componentes C/ASM y gdb_test.c para depuración 32-bit
#           y lanza GDB sobre el ejecutable resultante.

# --- Funciones de color (igual que run.sh) ---
red() { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
bold() { echo -e "\033[1m$1\033[0m"; }

# --- Salir si cualquier comando falla ---
set -e

# --- Directorios y Archivos ---
SRC_DIR="src"
C_BRIDGE_DIR="${SRC_DIR}/c_bridge"
BUILD_DIR="build"
GDB_TEST_SRC="${SRC_DIR}/gdb_test.c"
C_SRC="${C_BRIDGE_DIR}/gini_processor.c"
ASM_SRC="${C_BRIDGE_DIR}/float_rounder.asm"
GDB_EXE="${BUILD_DIR}/gdb_test"
C_OBJ="${BUILD_DIR}/gini_processor_dbg.o" # Objeto C para debug
ASM_OBJ="${BUILD_DIR}/float_rounder_dbg.o" # Objeto ASM para debug
GDB_TEST_OBJ="${BUILD_DIR}/gdb_test_dbg.o"    # Objeto del test para debug

green "--- Iniciando Compilación para Depuración y Lanzamiento de GDB ---"

# --- 1. Verificar Existencia de Fuentes ---
bold "Paso 1: Verificando archivos fuente..."
if [ ! -f "$GDB_TEST_SRC" ] || [ ! -f "$C_SRC" ] || [ ! -f "$ASM_SRC" ]; then
    red "Error: No se encontraron todos los archivos fuente necesarios:"
    [ ! -f "$GDB_TEST_SRC" ] && red "  - $GDB_TEST_SRC"
    [ ! -f "$C_SRC" ] && red "  - $C_SRC"
    [ ! -f "$ASM_SRC" ] && red "  - $ASM_SRC"
    yellow "Asegúrate de que la estructura del proyecto sea correcta."
    exit 1
else
    green "Archivos fuente encontrados."
fi
echo

# --- 2. Crear Directorio de Build ---
bold "Paso 2: Asegurando directorio de build..."
mkdir -p "${BUILD_DIR}"
green "Directorio '${BUILD_DIR}' listo."
echo

# --- 3. Compilar Componentes C/ASM para Debug 32-bit ---
bold "Paso 3: Compilando componentes C/ASM para debug (32-bit)..."
echo "Compilando C: ${C_SRC} -> ${C_OBJ}"
gcc -m32 -g -Wall -Wextra -c "${C_SRC}" -o "${C_OBJ}" || { red "Error al compilar ${C_SRC}"; exit 1; }
green "  -> Compilación C OK."

echo "Ensamblando ASM: ${ASM_SRC} -> ${ASM_OBJ}"
nasm -f elf -g -F dwarf "${ASM_SRC}" -o "${ASM_OBJ}" || { red "Error al ensamblar ${ASM_SRC}"; exit 1; }
green "  -> Ensamblado ASM OK."

echo "Compilando Test GDB: ${GDB_TEST_SRC} -> ${GDB_TEST_OBJ}"
gcc -m32 -g -Wall -Wextra -c "${GDB_TEST_SRC}" -o "${GDB_TEST_OBJ}" || { red "Error al compilar ${GDB_TEST_SRC}"; exit 1; }
green "  -> Compilación Test GDB OK."
echo

# --- 4. Enlazar para Crear Ejecutable de Debug ---
bold "Paso 4: Enlazando objetos para crear ejecutable '${GDB_EXE}'..."
echo "Enlazando: ${GDB_TEST_OBJ}, ${C_OBJ}, ${ASM_OBJ} -> ${GDB_EXE}"
gcc -m32 -g "${GDB_TEST_OBJ}" "${C_OBJ}" "${ASM_OBJ}" -o "${GDB_EXE}" -no-pie || { red "Error al enlazar los objetos"; exit 1; }
green "Enlazado completado. Ejecutable creado en '${GDB_EXE}'."
echo

# --- 5. Lanzar GDB ---
bold "Paso 5: Lanzando GDB sobre '${GDB_EXE}'..."
if [ ! -f "$GDB_EXE" ]; then
    red "Error: El ejecutable '${GDB_EXE}' no se encontró después de la compilación/enlace."
    exit 1
fi

yellow "--------------------------------------------------"
yellow " Instrucciones básicas dentro de GDB:"
yellow "   - Poner breakpoints:"
yellow "     - b main                (Al inicio de main en gdb_test.c)"
yellow "     - b process_gini_float  (Al inicio de la función C puente)"
yellow "     - b asm_float_round     (Al inicio de la rutina ASM)"
yellow "     - b gdb_test.c:25       (En la línea *después* de llamar a process_gini_float)"
yellow "   - Ejecutar:"
yellow "     - run                   (Inicia la ejecución hasta el primer breakpoint)"
yellow "     - c (o continue)        (Continúa hasta el siguiente breakpoint)"
yellow "     - n (o next)            (Ejecuta la siguiente línea C, sin entrar en funciones)"
yellow "     - s (o step)            (Ejecuta la siguiente línea C, entrando en funciones)"
yellow "     - ni / si               (Como next/step pero a nivel instrucción ensamblador)"
yellow "   - Inspeccionar:"
yellow "     - info locals           (Muestra variables locales)"
yellow "     - p <variable>          (Imprime el valor de una variable)"
yellow "     - p &<variable>         (Imprime la dirección de una variable)"
yellow "     - x/Nwx \$esp           (Examina N words (4 bytes) en formato hexadecimal desde la pila)"
yellow "     - x/Nwx \$ebp           (Examina desde el puntero base)"
yellow "     - x/f \$ebp+8           (Examina el float en la pila en [ebp+8])"
yellow "     - x/a \$ebp+12          (Examina la dirección en la pila en [ebp+12])"
yellow "     - info reg ebp esp eax  (Muestra registros específicos)"
yellow "     - disas                 (Muestra el desensamblado alrededor del punto actual)"
yellow "     - bt                    (Muestra el backtrace/pila de llamadas)"
yellow "   - Salir:"
yellow "     - q (o quit)"
yellow "--------------------------------------------------"
echo "Lanzando GDB ahora..."

# Ejecuta gdb
gdb "${GDB_EXE}"

exit_status=$?
echo "--------------------------------------------------"

if [ $exit_status -eq 0 ]; then
    green "Sesión de GDB finalizada."
else
    yellow "GDB finalizó (código de salida: $exit_status)."
fi
echo

# --- Finalización ---
green "--- Script de Debug Finalizado ---"
exit $exit_status
