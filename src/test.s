.syntax unified
.cpu cortex-m4
.thumb

@ Vector Table
.section .isr_vector, "a", %progbits
.word _stack_top
.word Reset_Handler

@ ARM Assembly
.section .text
.global Reset_Handler
.thumb_func

Reset_Handler:
    LDR R1, =data        @ RAM 주소 가져오기
    MOV R0, #123         @ R0 = 123
    STR R0, [R1]         @ 메모리에 123 저장

    MOV R0, #0           @ R0 초기화
    LDR R2, [R1]         @ 메모리에서 읽기

    CMP R2, #123         @ 값 비교
    BNE error            @ 다르면 error 이동

    @ 정상 메시지 출력
    LDR R1, =message
    B print

error:
    LDR R1, =error_msg

print:
    MOV R0, #4           @ Semihosting SYS_WRITE0
    BKPT #0xAB           @ QEMU 터미널 출력

stop:
    B stop               @ 무한 루프

@ 문자열
.section .rodata
message:
    .asciz "Value = 123\n"

error_msg:
    .asciz "Error\n"

@ RAM 데이터
.section .bss
.align 2
data:
    .space 4
