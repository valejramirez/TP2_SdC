// src/gdb_test.c
// Programa mínimo para depurar la interacción C <-> ASM con GDB.

#include <stdio.h>

// Declaración externa de la función puente C.
// GDB necesitará la información de depuración de gini_processor.c
// para saber cómo se implementa esta función.
extern int process_gini_float(float gini_value);

int main(void) {
    // Valor de prueba para pasar a la función C/ASM.
    // Puedes cambiar este valor para probar diferentes casos.
    float test_gini_value = 42.75f; // Ejemplo con parte fraccionaria > 0.5
    int result;

    printf("[gdb_test] Iniciando prueba con GINI = %f\n", test_gini_value);

    // Punto clave para poner un breakpoint *antes* de la llamada C->ASM
    printf("[gdb_test] Llamando a process_gini_float...\n");

    result = process_gini_float(test_gini_value); // LLAMADA A C (que llamará a ASM)

    // Punto clave para poner un breakpoint *después* de la llamada C->ASM
    printf("[gdb_test] Retorno de process_gini_float.\n");
    printf("[gdb_test] Resultado (int): %d\n", result);

    // Prueba con otro valor (opcional)
    test_gini_value = 35.2f; // Ejemplo con parte fraccionaria < 0.5
    printf("\n[gdb_test] Iniciando segunda prueba con GINI = %f\n", test_gini_value);
    printf("[gdb_test] Llamando a process_gini_float...\n");
    result = process_gini_float(test_gini_value);
    printf("[gdb_test] Retorno de process_gini_float.\n");
    printf("[gdb_test] Resultado (int): %d\n", result);


    printf("\n[gdb_test] Prueba finalizada.\n");
    return 0;
}