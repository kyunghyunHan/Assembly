
.syntax unified
.cpu cortex-m4
.thumb

.section .isr_vector, "a", %progbits
.word _stack_top
.word Reset_Handler @지시어 (Directive)

.section .text
.global Reset_Handler @global:다음파일에서도 
.thumb_func @thumb_func → 다음 심볼이 Thumb 함수라는 것을 표시
@nzcvq  neg,zero, carry,Q
Reset_Handler: @레이블
    MOV r1,#3 @명령어
    mov r4,#1
    mov r5,#2
    add r6,r4,r5 @r6 = r4+r5
    mov r2,#0x1234     @0x12345부터 안댐
    ldr r3,=0x12345678 @Pseudo-instruction(의사 명령어)
    MOV R0, #4          @ SYS_WRITE0
    LDR R1, =message    @ 문자열 주소 문자열이 저장된 메모리 주소를 R1에 삽입
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


    @ ===== 추가 실습 1: CMP / BNE =====
    MOV R4, #10
    MOV R5, #20

    CMP R4, R5          @ R4 - R5 비교, NZCV 플래그 갱신
    BNE not_equal       @ Z=0이면 not_equal로 이동

    MOV R6, #0          @ 같으면 R6=0
    B compare_end       @ 비교 종료 위치로 이동

not_equal:
    MOV R6, #1          @ 다르면 R6=1

compare_end:
    @ 현재 R4=10, R5=20이므로 R6=1


    @ ===== 추가 실습 2: STR / LDR =====
    LDR R1, =number     @ number의 RAM 주소를 R1에 저장

    MOV R0, #100        @ R0=100
    STR R0, [R1]        @ R1 주소에 R0의 32비트 값 저장

    MOV R0, #0          @ R0=0으로 초기화
    LDR R2, [R1]        @ R1 주소에서 32비트 읽기, R2=100

    @ STR = Store Register (메모리에 저장)
    @ LDR = Load Register (메모리에서 읽기)
    @ [R1] = R1에 저장된 주소가 가리키는 메모리
    @ [R1, #0] = R1+0 주소, 즉 [R1]과 동일


    @ ===== 추가 실습 3: 주소 Offset =====
    LDR R1, =numbers    @ 배열의 시작 주소

    MOV R0, #10
    STR R0, [R1, #0]    @ 첫 번째 32비트 공간에 10 저장

    MOV R0, #20
    STR R0, [R1, #4]    @ 두 번째 32비트 공간에 20 저장

    MOV R0, #30
    STR R0, [R1, #8]    @ 세 번째 32비트 공간에 30 저장

    LDR R4, [R1, #0]    @ R4=10
    LDR R5, [R1, #4]    @ R5=20
    LDR R6, [R1, #8]    @ R6=30

    @ Offset은 바이트 단위
    @ 32비트 데이터 하나 = 4바이트
    @ [R1,#0] 첫 번째
    @ [R1,#4] 두 번째
    @ [R1,#8] 세 번째


    @ ===== 추가 실습 4: STRB / LDRB =====
    LDR R1, =byte_data  @ 1바이트 공간 주소

    MOV R0, #65         @ ASCII 'A'
    STRB R0, [R1]       @ 하위 8비트만 메모리에 저장
    LDRB R2, [R1]       @ 1바이트 읽기, R2=65

    @ STR  = 32비트 저장
    @ LDR  = 32비트 읽기
    @ STRB = 8비트 저장
    @ LDRB = 8비트 읽기
    @ ========================


    MOV R0, #0x18       @ SYS_EXIT
    LDR R1, =0x20026    @ 정상 종료
    BKPT #0xAB

stop: @B : 이동? 
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

@ ===== 추가 실습용 RAM 공간 =====
.align 2
number:
    .space 4            @ 32비트 1개

.align 2
numbers:
    .space 12           @ 32비트 3개

byte_data:
    .space 1            @ 8비트 1개
