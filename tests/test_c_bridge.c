// test_c_bridge.c
// Programa C simple para probar la función 'process_gini_float' (que llama a ASM).
// No depende de Python ni msl-loadlib. Se compila como un ejecutable 32-bit.

#include <stdio.h>
#include <math.h> // Para roundf() y fabsf() para calcular el valor esperado
#include <stdbool.h> // Para bool type

// --- Declaración Externa ---
// Declara la función del puente C (definida en gini_processor.c)
// para que este programa sepa cómo llamarla. El enlazador la encontrará.
extern int process_gini_float(float gini_value);

// --- Constantes para el Test ---
#define ANSI_COLOR_GREEN   "\x1b[32m"
#define ANSI_COLOR_RED     "\x1b[31m"
#define ANSI_COLOR_YELLOW  "\x1b[33m"
#define ANSI_COLOR_RESET   "\x1b[0m"

// --- Función Principal de Prueba ---
int main() {
    printf("--- Iniciando Prueba del Puente C <-> ASM ---\n");

    // --- Casos de Prueba ---
    float test_values[] = {
        // Positivos
        42.7f, 42.3f, 42.0f, 0.0f, 0.8f, 1.0f,
        // Casos .5 (importantes para FPU round-to-even)
        42.5f, 41.5f, 0.5f, 1.5f, 2.5f,
        // Negativos
        -0.2f, -0.8f, -1.0f, -42.7f, -42.3f,
        // Casos negativos .5
        -0.5f, -1.5f, -2.5f, -41.5f, -42.5f
    };
    int num_tests = sizeof(test_values) / sizeof(test_values[0]);
    int failures = 0;

    // --- Bucle de Pruebas ---
    for (int i = 0; i < num_tests; ++i) {
        float input = test_values[i];
        printf("\nCaso %d: Entrada = %.2f\n", i + 1, input);

        // Llama a la función C que a su vez llama a ASM
        int actual_output = process_gini_float(input);
        printf("  Salida de process_gini_float (ASM): %d\n", actual_output);

        // --- Calcular Valor Esperado ---
        // La FPU por defecto usa "round half to even".
        // `roundf` a menudo usa "round half away from zero".
        // Calcularemos "away from zero" y luego ajustaremos para "to even" en .5 casos.
        int expected_away_from_zero;
        if (input >= 0.0f) {
            expected_away_from_zero = (int)(input + 0.5f);
        } else {
            expected_away_from_zero = (int)(input - 0.5f); // Redondeo se aleja de cero
        }
        printf("  Esperado (Round Half Away From Zero): %d\n", expected_away_from_zero);

        // --- Comparación y Verificación ---
        bool pass = false;
        // ¿Es un caso .5? Comprobar si la parte fraccional está muy cerca de 0.5
        float fractional_part = fabsf(input - (int)input);
        bool is_half_case = fabsf(fractional_part - 0.5f) < 0.00001f;

        if (actual_output == expected_away_from_zero) {
             // Coincide con el redondeo simple (lejos de cero)
             if (is_half_case) {
                 printf("  " ANSI_COLOR_YELLOW "Nota:" ANSI_COLOR_RESET " Es caso .5, FPU podría redondear diferente (a par).\n");
             }
             pass = true; // Pasa si coincide con el redondeo simple
        } else if (is_half_case) {
            // No coincidió con el redondeo simple, PERO es un caso .5
            // Verificar si la salida es PAR (comportamiento FPU round-to-even)
            if (actual_output % 2 == 0) {
                 printf("  " ANSI_COLOR_YELLOW "Nota:" ANSI_COLOR_RESET " Caso .5, salida ASM es PAR (%d) -> Correcto para FPU round-to-even.\n", actual_output);
                 pass = true; // Pasa porque es la salida esperada de FPU para .5
            } else {
                // Es .5 pero la salida no es ni "away-from-zero" ni "par". Raro.
                 printf("  " ANSI_COLOR_YELLOW "Nota:" ANSI_COLOR_RESET " Caso .5, salida ASM IMPAR (%d) e inesperada.\n", actual_output);
                 pass = false;
            }
        } else {
            // No es caso .5 y no coincide con el redondeo simple. Falla.
            pass = false;
        }

        // Imprimir resultado del caso
        if (pass) {
            printf("  Resultado: " ANSI_COLOR_GREEN "PASS" ANSI_COLOR_RESET "\n");
        } else {
            printf("  Resultado: " ANSI_COLOR_RED "FAIL" ANSI_COLOR_RESET "\n");
            failures++;
        }
    }

    // --- Resumen Final ---
    printf("\n--- Resumen de la Prueba ---\n");
    if (failures == 0) {
        printf(ANSI_COLOR_GREEN "Todos los %d casos pasaron (considerando FPU round-to-even para .5)!" ANSI_COLOR_RESET "\n", num_tests);
    } else {
        printf(ANSI_COLOR_RED "%d de %d casos fallaron." ANSI_COLOR_RESET "\n", failures, num_tests);
    }
    printf("---------------------------\n");

    // Retorna 0 si todo OK, >0 si hubo fallos (útil para scripts)
    return failures;
}