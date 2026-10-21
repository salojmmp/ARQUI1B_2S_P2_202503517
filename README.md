# MiniShell - Intérprete de Comandos ARM64

## 1. Descripción

MiniShell es un intérprete de comandos desarrollado en lenguaje ensamblador ARM64 puro mediante GNU Assembler (GAS). Permite leer comandos del usuario, procesar sus argumentos, ejecutar comandos internos y lanzar programas externos en Linux.

El proyecto utiliza llamadas al sistema de Linux ARM64 para gestionar la entrada y salida, crear procesos y ejecutar programas.

## 2. Requisitos

- Ubuntu o Linux.
- GNU Assembler para ARM64.
- GNU Linker.
- QEMU AArch64 para ejecutar el programa en equipos x86_64.
- GNU Make.

## 3. Instalación de herramientas

En Ubuntu, las herramientas principales se pueden instalar con:

    sudo apt update
    sudo apt install binutils-aarch64-linux-gnu qemu-user gdb-multiarch make

## 4. Compilación

Desde el directorio del proyecto, ejecutar:

    make

Para eliminar los archivos generados y volver a compilar:

    make clean
    make

El ejecutable generado se llama `minishell`.

## 5. Ejecución

En un sistema compatible con ARM64:

    ./minishell

En un equipo x86_64 utilizando QEMU:

    qemu-aarch64 ./minishell

## 6. Comandos disponibles

| Comando | Descripción |
|---|---|
| `help` | Muestra la ayuda. |
| `clear` | Limpia la terminal mediante secuencias ANSI. |
| `echo [texto]` | Imprime los argumentos recibidos. |
| `exit` | Finaliza MiniShell. |
| Comandos externos | Intenta ejecutar el programa indicado mediante `execve`. |

Para los comandos externos se debe proporcionar la ruta del ejecutable, por ejemplo:

    /bin/echo hola mundo
    /bin/uname -a

## 7. Arquitectura y funcionamiento

El programa está implementado en ensamblador ARM64 y utiliza llamadas al sistema de Linux.

El flujo principal es:

1. Mostrar el prompt `MiniShell>`.
2. Leer la entrada del usuario.
3. Eliminar el salto de línea.
4. Separar el comando y sus argumentos.
5. Comprobar si se trata de un comando interno.
6. Ejecutar el comando interno o intentar lanzar un programa externo.
7. Volver al prompt o finalizar si se introduce `exit`.

Para ejecutar programas externos se utiliza `clone` con `SIGCHLD`, seguido de `execve` en el proceso hijo. El proceso padre utiliza `wait4` para esperar su finalización.

## 8. Estructura del proyecto

    minishell_arm64/
    ├── Makefile
    ├── README.md
    ├── src/
    │   └── main.s
    ├── build/
    │   └── main.o
    └── minishell

Los directorios y archivos `build/` y `minishell` se generan durante la compilación.

## 9. Depuración

Para depurar el programa ARM64 mediante QEMU y GDB:

En una terminal:

    qemu-aarch64 -g 1234 ./minishell

En otra terminal:

    gdb-multiarch ./minishell

Dentro de GDB:

    set architecture aarch64
    set pagination off
    set debuginfod enabled off
    target remote :1234
    break _start
    break comparar_cadenas
    break comando_echo
    break ejecutar_externo
    continue

Para inspeccionar registros, memoria e instrucciones:

    info registers
    x/8gx $sp
    x/6i $pc

## 10. Limitaciones

- La separación de argumentos utiliza espacios como delimitadores; no implementa comillas ni argumentos con espacios agrupados.
- Los comandos externos requieren una ruta válida al ejecutable.
- No se implementan tuberías, redirecciones ni historial de comandos.
- La ejecución de programas depende de la compatibilidad del sistema y de las herramientas de emulación utilizadas.

