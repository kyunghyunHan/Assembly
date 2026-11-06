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
    MOV r1,#3
    mov r4,#1
    mov r5,#2
    add r6,r4,r5 @r6 = r4+r5
    mov r2,#0x1234     @0x12345부터 안댐
    ldr r3,=0x12345678 @Pseudo-instruction(의사 명령어)
    MOV R0, #4          @ SYS_WRITE0
    LDR R1, =message    @ 문자열 주소
    BKPT #0xAB          @ Semihosting 출력

    @ ===== R6 출력 추가 =====
    ADD R7, R6, #48     @ 숫자 3을 ASCII '3'으로 변환
    LDR R1, =buffer     @ 출력 버퍼 주소
    STRB R7, [R1]       @ ASCII 문자 저장
    MOV R7, #0
    STRB R7, [R1, #1]   @ 문자열 끝 NULL 저장

    MOV R0, #4          @ SYS_WRITE0
    BKPT #0xAB          @ R6 값 출력

    MOV R0, #4
    LDR R1, =newline
    BKPT #0xAB          @ 줄바꿈 출력
    @ ========================

    MOV R0, #0x18       @ SYS_EXIT
    LDR R1, =0x20026    @ 정상 종료
    BKPT #0xAB

stop:
    B stop

.section .rodata
message:
    .asciz "Hello World!\n"

newline:
    .asciz "\n"

.section .bss
.align 2
buffer:
    .space 2