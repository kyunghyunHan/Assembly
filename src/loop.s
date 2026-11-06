
.syntax unified
.cpu cortex-m4
.thumb

.section .isr_vector, "a", %progbits
.word _stack_top
.word Reset_Handler

.section .text
.global Reset_Handler
.thumb_func

Reset_Handler:
    @ int a = 0;
    LDR R4, =a
    MOV R0, #0
    STR R0, [R4]

    @ int i = 0;
    MOV R5, #0

for_loop:
    @ a++;
    LDR R0, [R4]
    ADDS R0, R0, #1
    STR R0, [R4]

    @ i++;
    ADDS R5, R5, #1

    @ i < 10
    CMP R5, #10
    BLT for_loop

    @ 반복문 종료
    LDR R2, [R4]       @ R2 = a = 10

    @ 숫자 10을 ASCII로 변환
    MOV R5, #10
    UDIV R6, R2, R5    @ 십의 자리 = 1
    MLS R7, R6, R5, R2 @ 일의 자리 = 0

    ADD R6, R6, #48    @ 1 → '1'
    ADD R7, R7, #48    @ 0 → '0'

    LDR R1, =buffer
    STRB R6, [R1]
    STRB R7, [R1, #1]

    MOV R0, #0
    STRB R0, [R1, #2]  @ NULL 종료

    @ "a = " 출력
    MOV R0, #4
    LDR R1, =message
    BKPT #0xAB

    @ a 값 출력
    MOV R0, #4
    LDR R1, =buffer
    BKPT #0xAB

    @ 줄바꿈 출력
    MOV R0, #4
    LDR R1, =newline
    BKPT #0xAB

    @ QEMU 종료
    MOV R0, #0x18
    LDR R1, =0x20026
    BKPT #0xAB

stop:
    B stop

.section .rodata
message:
    .asciz "a = "

newline:
    .asciz "\n"

.section .bss
.align 2
a:
    .space 4

buffer:
    .space 3
