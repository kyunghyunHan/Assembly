
.syntax unified
.cpu cortex-m4
.thumb

/* 1. Vector Table
 * ELF: .isr_vector 섹션
 * MAP: 벡터 테이블의 Flash 주소
 * BIN: MSP와 Handler 주소의 실제 바이트
 */
.section .isr_vector,"a",%progbits
.word _estack
.word Reset_Handler
.word 0
.word HardFault_Handler
.word 0
.word 0
.word UsageFault_Handler
.word 0,0,0,0
.word SVC_Handler
.word 0,0,0,0

/* 2. Reset_Handler
 * ELF: .text 섹션의 실행 코드
 * MAP: Reset_Handler의 배치 주소
 * BIN: 실제 ARM Thumb 기계어
 */
.section .text.Reset_Handler,"ax",%progbits
.global Reset_Handler
.thumb_func
Reset_Handler:
    bl init_data_bss       /* RAM 초기화 */
    bl demo                /* 실습 함수 실행 */
    b exit_ok              /* 종료 */

/* 3. RAM 초기화
 * .data: Flash 초기값 → RAM
 * .bss : RAM을 0으로 초기화
 *
 * ELF: 초기화 코드와 섹션 정보
 * MAP: .data/.bss의 RAM 주소 및 크기
 * BIN: 초기화 기계어와 .data 초기값
 *      (.bss 공간 자체는 일반적으로 제외)
 */
.thumb_func
init_data_bss:
    ldr r0, =_sidata
    ldr r1, =_sdata
    ldr r2, =_edata
1:
    cmp r1, r2
    bcs 2f
    ldr r3, [r0]
    str r3, [r1]
    adds r0, #4
    adds r1, #4
    b 1b
2:
    ldr r1, =_sbss
    ldr r2, =_ebss
    movs r3, #0
3:
    cmp r1, r2
    bcs 4f
    str r3, [r1]
    adds r1, #4
    b 3b
4:
    bx lr

/* 4. Semihosting 문자열 출력
 * ELF: print_string 함수와 기계어
 * MAP: 함수 주소
 * BIN: BKPT 등을 포함한 기계어
 */
.thumb_func
print_string:
    push {r0, lr}
    movs r0, #4            /* SYS_WRITE0 */
    bkpt #0xab
    pop {r0, pc}

/* 5. Semihosting 종료 */
.thumb_func
exit_ok:
    movs r0, #0x18
    ldr r1, =0x20026
    bkpt #0xab
    b .

/* 6. 예외 핸들러
 * ELF: Handler 심볼 및 기계어
 * MAP: Handler 주소
 * BIN: Handler 기계어
 */
.thumb_func
HardFault_Handler:
    ldr r1, =msg_hardfault
    bl print_string
    b exit_ok

.thumb_func
UsageFault_Handler:
    ldr r1, =msg_usagefault
    bl print_string
    b exit_ok

.thumb_func
SVC_Handler:
    ldr r0, =svc_count
    ldr r1, [r0]
    adds r1, #1
    str r1, [r0]
    bx lr

/* 7. 읽기 전용 문자열
 * ELF: .rodata 섹션
 * MAP: .rodata 주소 및 크기
 * BIN: 문자열의 ASCII 바이트
 */
.section .rodata,"a",%progbits
msg_hardfault: .asciz "HardFault handler reached\n"
msg_usagefault: .asciz "UsageFault handler reached\n"

/* 8. 초기값 없는 변수
 * ELF: .bss 섹션, 심볼 및 크기
 * MAP: svc_count의 RAM 주소
 * BIN: 초기화 공간은 일반적으로 없음
 */
.section .bss,"aw",%nobits
.align 2
svc_count: .space 4

/* 9. demo 함수
 * ELF: .text.demo 및 demo 심볼
 * MAP: demo 함수 주소
 * BIN: demo 함수의 기계어
 */
.section .text.demo,"ax",%progbits
.global demo
.thumb_func
demo:
    push {r7, lr}
    ldr r1, =message
    bl print_string
    ldr r0, =counter
    ldr r2, [r0]
    adds r2, #1            /* 7 → 8 */
    str r2, [r0]
    pop {r7, pc}

/* 10. 출력 문자열
 * ELF: .rodata 섹션
 * MAP: 문자열의 배치 주소
 * BIN: ASCII 원시 바이트
 */
.section .rodata
message: .asciz "exam01: image and sections OK\n"

/* 11. 초기값 있는 변수
 * ELF: .data 섹션과 counter 심볼
 * MAP: RAM 주소 + Flash 로드 주소
 * BIN: 초기값 7 → 07 00 00 00
 */
.section .data
.align 2
counter: .word 7
