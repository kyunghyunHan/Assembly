.section __TEXT,__text
.global _hello_asm
.extern _printf
.p2align 2

_hello_asm:
    stp x29, x30, [sp, #-16]!

    adrp x0, message@PAGE
    add  x0, x0, message@PAGEOFF

    bl _printf

    ldp x29, x30, [sp], #16
    ret

.section __TEXT,__cstring
message:
    .asciz "Hello World\n"