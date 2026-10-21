.section .data
    prompt: .ascii "MiniShell> "
    prompt_len = . - prompt

    newline: .ascii "\n"
    space: .ascii " "

    msg_help:
        .ascii "\nMiniShell - Ayuda\n"
        .ascii "Comandos disponibles:\n"
        .ascii "  help          Mostrar esta ayuda\n"
        .ascii "  clear         Limpiar la pantalla\n"
        .ascii "  echo [texto]  Mostrar texto\n"
        .ascii "  exit          Salir de MiniShell\n"
        .ascii "  Otros comandos se ejecutan mediante execve.\n\n"
    msg_help_len = . - msg_help

    clear_seq: .ascii "\033[2J\033[H"
    clear_seq_len = . - clear_seq

    msg_exec_error: .ascii "Error: no se pudo ejecutar el programa.\n"
    msg_exec_error_len = . - msg_exec_error

    cmd_help: .asciz "help"
    cmd_clear: .asciz "clear"
    cmd_echo: .asciz "echo"
    cmd_exit: .asciz "exit"

.section .bss
    buffer: .skip 256
    argv: .skip 1024

.section .text
.global _start

_start:
bucle_principal:
    // Mostrar el prompt.
    mov x0, #1
    ldr x1, =prompt
    mov x2, #prompt_len
    mov x8, #64
    svc #0

    // Leer entrada.
    mov x0, #0
    ldr x1, =buffer
    mov x2, #255
    mov x8, #63
    svc #0

    // Finalizar si read devuelve cero o un error.
    cmp x0, #0
    ble terminar

    mov x19, x0

    // Agregar terminador NUL.
    ldr x1, =buffer
    mov w3, #0
    strb w3, [x1, x19]

    // Eliminar salto de linea.
    sub x2, x19, #1
    ldrb w3, [x1, x2]
    cmp w3, #10
    bne preparar_tokenizacion

    mov w3, #0
    strb w3, [x1, x2]
    sub x19, x19, #1

preparar_tokenizacion:
    // Separar palabras mediante espacios.
    mov x20, #0
    ldr x21, =buffer

separar_loop:
    cmp x20, x19
    bge buscar_argumentos

    ldrb w3, [x21, x20]
    cmp w3, #32
    bne siguiente_caracter

    mov w3, #0
    strb w3, [x21, x20]

siguiente_caracter:
    add x20, x20, #1
    b separar_loop

buscar_argumentos:
    // Construir el arreglo argv.
    mov x20, #0
    mov x24, #0
    ldr x21, =buffer
    ldr x25, =argv

buscar_token:
    cmp x20, x19
    bge finalizar_argv

    ldrb w3, [x21, x20]
    cmp w3, #0
    bne inicio_token

    add x20, x20, #1
    b buscar_token

inicio_token:
    // Reservar espacio para el NULL final.
    cmp x24, #127
    bge finalizar_argv

    add x1, x21, x20
    str x1, [x25, x24, lsl #3]
    add x24, x24, #1

avanzar_token:
    cmp x20, x19
    bge buscar_token

    ldrb w3, [x21, x20]
    cmp w3, #0
    beq siguiente_token

    add x20, x20, #1
    b avanzar_token

siguiente_token:
    add x20, x20, #1
    b buscar_token

finalizar_argv:
    // Terminar argv con NULL.
    mov x26, #0
    str x26, [x25, x24, lsl #3]

    // Ignorar entradas vacias.
    cmp x24, #0
    beq bucle_principal

    // Comando exit.
    ldr x0, [x25]
    ldr x1, =cmd_exit
    bl comparar_cadenas
    cmp x0, #0
    beq terminar

    // Comando help.
    ldr x0, [x25]
    ldr x1, =cmd_help
    bl comparar_cadenas
    cmp x0, #0
    beq ejecutar_help

    // Comando clear.
    ldr x0, [x25]
    ldr x1, =cmd_clear
    bl comparar_cadenas
    cmp x0, #0
    beq ejecutar_clear

    // Comando echo.
    ldr x0, [x25]
    ldr x1, =cmd_echo
    bl comparar_cadenas
    cmp x0, #0
    beq ejecutar_echo

    // Si no es interno, intentar ejecutar un programa externo.
    bl ejecutar_externo
    b bucle_principal

ejecutar_help:
    bl comando_help
    b bucle_principal

ejecutar_clear:
    bl comando_clear
    b bucle_principal

ejecutar_echo:
    bl comando_echo
    b bucle_principal


// --------------------------------------------------
// Funcion: comparar_cadenas
// Compara dos cadenas terminadas en NUL.
// x0 = primera cadena; x1 = segunda cadena.
// Devuelve cero si son iguales.
// --------------------------------------------------
comparar_cadenas:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

comparar_loop:
    ldrb w9, [x0], #1
    ldrb w10, [x1], #1

    cmp w9, w10
    bne cadenas_diferentes

    cbz w9, cadenas_iguales
    b comparar_loop

cadenas_diferentes:
    mov x0, #1
    b fin_comparar

cadenas_iguales:
    mov x0, #0

fin_comparar:
    ldp x29, x30, [sp], #16
    ret


// --------------------------------------------------
// Funcion: comando_help
// Muestra la ayuda.
// --------------------------------------------------
comando_help:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    mov x0, #1
    ldr x1, =msg_help
    mov x2, #msg_help_len
    mov x8, #64
    svc #0

    ldp x29, x30, [sp], #16
    ret


// --------------------------------------------------
// Funcion: comando_clear
// Limpia la terminal mediante secuencias ANSI.
// --------------------------------------------------
comando_clear:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    mov x0, #1
    ldr x1, =clear_seq
    mov x2, #clear_seq_len
    mov x8, #64
    svc #0

    ldp x29, x30, [sp], #16
    ret


// --------------------------------------------------
// Funcion: comando_echo
// Imprime los argumentos separados por espacios.
// --------------------------------------------------
comando_echo:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    mov x9, #1
    ldr x25, =argv

echo_loop:
    cmp x9, x24
    bge echo_finalizar

    ldr x10, [x25, x9, lsl #3]
    mov x11, #0

echo_longitud:
    ldrb w12, [x10, x11]
    cbz w12, echo_imprimir

    add x11, x11, #1
    b echo_longitud

echo_imprimir:
    mov x0, #1
    mov x1, x10
    mov x2, x11
    mov x8, #64
    svc #0

    add x9, x9, #1
    cmp x9, x24
    bge echo_loop

    mov x0, #1
    ldr x1, =space
    mov x2, #1
    mov x8, #64
    svc #0

    b echo_loop

echo_finalizar:
    mov x0, #1
    ldr x1, =newline
    mov x2, #1
    mov x8, #64
    svc #0

    ldp x29, x30, [sp], #16
    ret


// --------------------------------------------------
// Funcion: ejecutar_externo
// Crea un proceso hijo con clone(SIGCHLD).
// El hijo ejecuta execve y el padre espera con wait4.
// Se debe proporcionar una ruta al ejecutable.
// --------------------------------------------------
ejecutar_externo:
    stp x29, x30, [sp, #-48]!
    stp x19, x20, [sp, #16]
    str x25, [sp, #32]
    mov x29, sp

    // clone(SIGCHLD, NULL, NULL, NULL, NULL).
    mov x0, #17
    mov x1, #0
    mov x2, #0
    mov x3, #0
    mov x4, #0
    mov x8, #220
    svc #0

    // x0 = 0 en el hijo; x0 > 0 en el padre.
    cmp x0, #0
    beq proceso_hijo
    blt error_crear_proceso

    // El padre conserva el PID del hijo.
    mov x19, x0

    // wait4(pid, NULL, 0, NULL).
    mov x0, x19
    mov x1, #0
    mov x2, #0
    mov x3, #0
    mov x8, #260
    svc #0

    b fin_ejecutar_externo

proceso_hijo:
    // execve(argv[0], argv, NULL).
    ldr x25, =argv
    ldr x0, [x25]
    mov x1, x25
    mov x2, #0
    mov x8, #221
    svc #0

    // Si execve retorna, ocurrio un error.
    mov x0, #2
    ldr x1, =msg_exec_error
    mov x2, #msg_exec_error_len
    mov x8, #64
    svc #0

    // El hijo termina con codigo 127.
    mov x0, #127
    mov x8, #93
    svc #0

error_crear_proceso:
    mov x0, #2
    ldr x1, =msg_exec_error
    mov x2, #msg_exec_error_len
    mov x8, #64
    svc #0

fin_ejecutar_externo:
    ldr x25, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret


// --------------------------------------------------
// Funcion: terminar
// Finaliza MiniShell.
// --------------------------------------------------
terminar:
    mov x0, #0
    mov x8, #93
    svc #0
