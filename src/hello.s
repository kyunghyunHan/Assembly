
.syntax unified
.cpu cortex-m4
.thumb

/* Vector Table */
.section .isr_vector, "a", %progbits

.word _estack
.word Reset_Handler

/* Reset Handler */
.section .text
.global Reset_Handler
.thumb_func

Reset_Handler:
    /* Semihosting: 문자열 출력 */
    movs r0, #4
    ldr  r1, =message
    bkpt #0xAB

    /* Semihosting: 프로그램 종료 */
    movs r0, #0x18
    ldr  r1, =0x20026
    bkpt #0xAB

stop:
    b stop

.section .rodata
message:
    .asciz "Hello STM32 Startup!\n"
