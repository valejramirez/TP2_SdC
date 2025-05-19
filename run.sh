#!/bin/bash
# run.sh: Activa el entorno virtual y ejecuta la aplicación Python principal.

# --- Funciones de color ---
red() { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
bold() { echo -e "\033[1m$1\033[0m"; }

# --- Salir si cualquier comando falla (excepto la comprobación inicial) ---
# set -e # Desactivado temporalmente para poder dar mensajes de error más útiles

green "--- Iniciando Ejecución de la Aplicación GINI Fetcher ---"

# --- 1. Verificar y Activar Entorno Virtual ---
VENV_DIR="venv"
bold "Paso 1: Activando entorno virtual Python..."
if [ -f "${VENV_DIR}/bin/activate" ]; then
    source "${VENV_DIR}/bin/activate" || { red "Error al activar el entorno virtual '${VENV_DIR}'."; exit 1; }
    green "Entorno virtual activado. (Python: $(which python))"
else
    red "Error: Entorno virtual '${VENV_DIR}' no encontrado."
    yellow "Asegúrate de haber ejecutado './setup.sh' primero."
    exit 1
fi
echo

# --- 2. Verificar Existencia de la Biblioteca Compilada ---
LIB_PATH="lib/libginiprocessor.so"
bold "Paso 2: Verificando biblioteca C/ASM compilada..."
if [ ! -f "$LIB_PATH" ]; then
    red "Error: Biblioteca C/ASM '${LIB_PATH}' no encontrada."
    yellow "Asegúrate de haber ejecutado './build.sh' después de './setup.sh'."
    deactivate # Desactivar venv antes de salir
    exit 1
else
    green "Biblioteca '${LIB_PATH}' encontrada."
fi
echo

# --- 3. Ejecutar la Aplicación Python ---
PYTHON_ENTRY_POINT="src/main.py"
bold "Paso 3: Lanzando aplicación Python (${PYTHON_ENTRY_POINT})..."
echo "Comando: python ${PYTHON_ENTRY_POINT}"
echo "--------------------------------------------------"
# Ejecuta python. Salir con el código de estado de python.
python "${PYTHON_ENTRY_POINT}"
exit_status=$?
echo "--------------------------------------------------"

if [ $exit_status -eq 0 ]; then
    green "Aplicación Python finalizada correctamente."
else
    red "Aplicación Python finalizó con errores (código de salida: $exit_status)."
fi
echo

# --- 4. Desactivar Entorno Virtual ---
bold "Paso 4: Desactivando entorno virtual..."
deactivate
green "Entorno virtual desactivado."
echo

# --- Finalización ---
green "--- Ejecución Finalizada ---"
exit $exit_status # Sale con el mismo código que la aplicación Python