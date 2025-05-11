; asm_rounder.asm
; NASM Assembly code (32-bit Linux) to round a float to the nearest integer.
; Input: float value [ebp+8], int pointer [ebp+12]
; Output: Writes rounded integer result to the location pointed to by [ebp+12].
; Method: Uses FPU instructions for rounding (default FPU mode is round-to-nearest).

section .text
    global asm_round  ; Export symbol for C linker

asm_round:
    ; --- Prologue ---
    push    ebp         ; 1. Save the caller's base pointer.
    mov     ebp, esp    ; 2. Set our own base pointer for accessing args/locals.
                        ;    Now [ebp] holds old ebp, [ebp+4] holds return addr,
                        ;    [ebp+8] holds float arg, [ebp+12] holds ptr arg.

    ; We need temporary stack space to store the integer result from the FPU.
    ; FISTP stores a signed integer (default size depends on operand).
    ; We want a 32-bit integer (dword). Allocate 4 bytes.
    ; Let's allocate 8 bytes for potential alignment benefits, though 4 is strictly needed.
    sub     esp, 8      ; 3. Allocate 8 bytes on the stack for local use.
                        ;    [ebp-4] and [ebp-8] are now available.
                        ;    We will use [ebp-8] as a dword to store the integer.

    ; --- FPU Calculation ---
    ; The default FPU rounding mode is usually "round to nearest or even",
    ; which handles the 0.5 case correctly (rounding away from zero for +/- 0.5).
    ; So, we don't need to change the FPU control word for standard rounding.

    fld     dword [ebp+8]   ; 4. Load the 4-byte float argument from the stack
                        ;    onto the FPU stack (st0).

    ; FISTP: Converts the float in st0 to an integer based on the current
    ;        FPU rounding mode, stores it to the specified memory location,
    ;        and pops st0 off the FPU stack.
    fistp   dword [ebp-8]   ; 5. Convert st0 to 32-bit integer (using default rounding),
                        ;    store it in our temporary stack space at [ebp-8],
                        ;    and pop the FPU stack.

    ; --- Store Result via Pointer ---
    mov     eax, [ebp-8]    ; 6. Load the rounded integer result from our temporary
                        ;    stack space into the EAX register.

    mov     edx, [ebp+12]   ; 7. Load the pointer argument (the address where C wants
                        ;    the result) from the stack into the EDX register.
                        ;    (Using EDX instead of EBX just to show we don't *have*
                        ;    to save/restore EBX if we don't use it).

    mov     [edx], eax      ; 8. Store the final rounded integer result (in EAX)
                        ;    into the memory location pointed to by EDX.
                        ;    *** This is where a crash would occur if EDX is invalid ***

    ; --- Epilogue ---
    ; Restore the stack and caller's state in reverse order of the prologue.
    mov     esp, ebp    ; 9. Deallocate local stack space (the 8 bytes from sub esp, 8).
                        ;    ESP now points to where 'old ebp' is stored ([ebp]).

    pop     ebp         ; 10. Restore the caller's base pointer from the stack.
                        ;     ESP now points to the return address ([ebp+4]).

    ret                 ; 11. Pop the return address from the stack into EIP,
                        ;     transferring control back to the C caller.
                        ;     According to cdecl, the C caller will clean up the
                        ;     arguments ([ebp+8] and [ebp+12]) from the stack.
