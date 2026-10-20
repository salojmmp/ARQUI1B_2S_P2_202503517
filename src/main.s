.section .data
    prompt: .ascii "MiniShell> "
    prompt_len = . - prompt

.section .text
.global _start

_start:
    // Mostrar el prompt
    mov x0, #1
    ldr x1, =prompt
    mov x2, #prompt_len
    mov x8, #64
    svc #0

    // Terminar el programa
    mov x0, #0
    mov x8, #93
    svc #0
