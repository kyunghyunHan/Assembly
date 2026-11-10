
.syntax unified
.cpu cortex-m4
.thumb

/* 1. Vector Table: 초기 SP 및 예외 핸들러 주소 */
.section .isr_vector,"a",%progbits
.word _estack               /* 초기 MSP */
.word Reset_Handler         /* Reset 시작 주소 */
.word 0                     /* NMI */
.word HardFault_Handler
.word 0                     /* MemManage */
.word 0                     /* BusFault */
.word UsageFault_Handler
.word 0,0,0,0               /* Reserved */
.word SVC_Handler
.word 0,0,0,0               /* DebugMon, Reserved, PendSV, SysTick */

/* 2. Reset_Handler: 메모리 초기화 → demo 실행 */
.section .text.Reset_Handler,"ax",%progbits
.global Reset_Handler
.thumb_func
Reset_Handler:
    bl init_data_bss        /* .data / .bss 초기화 */
    bl demo                 /* 실습 코드 실행 */
    b exit_ok               /* 프로그램 종료 */

/* 3. .data: Flash → RAM / .bss: 0 초기화 */
.thumb_func
init_data_bss:
    ldr r0, =_sidata        /* Flash .data 시작 */
    ldr r1, =_sdata         /* RAM .data 시작 */
    ldr r2, =_edata         /* RAM .data 끝 */
1:
    cmp r1, r2
    bcs 2f
    ldr r3, [r0]            /* Flash 값 읽기 */
    str r3, [r1]            /* RAM에 복사 */
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
    str r3, [r1]            /* RAM을 0으로 초기화 */
    adds r1, #4
    b 3b
4:
    bx lr                   /* 호출한 위치로 복귀 */

/* 4. Semihosting: 문자열 출력 */
.thumb_func
print_string:
    push {r0, lr}
    movs r0, #4             /* SYS_WRITE0 */
    bkpt #0xab              /* QEMU/디버거 출력 */
    pop {r0, pc}

/* 5. Semihosting: 종료 */
.thumb_func
exit_ok:
    movs r0, #0x18          /* SYS_EXIT */
    ldr r1, =0x20026
    bkpt #0xab
    b .

/* 6. 예외 핸들러 */
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
    adds r1, #1             /* svc_count++ */
    str r1, [r0]
    bx lr

/* 7. .rodata: 읽기 전용 문자열 */
.section .rodata,"a",%progbits
msg_hardfault: .asciz "HardFault handler reached\n"
msg_usagefault: .asciz "UsageFault handler reached\n"

/* 8. .bss: 초기값 없는 변수 */
.section .bss,"aw",%nobits
.align 2
svc_count: .space 4

/* 9. demo: 문자열 출력 + counter 증가 */
.section .text.demo,"ax",%progbits
.global demo
.thumb_func
demo:
    push {r7, lr}
    ldr r1, =message
    bl print_string
    ldr r0, =counter
    ldr r2, [r0]
    adds r2, #1             /* counter: 7 → 8 */
    str r2, [r0]
    pop {r7, pc}

/* 10. 읽기 전용 데이터 */
.section .rodata
message: .asciz "exam01: image and sections OK\n"

/* 11. 초기값 있는 변수 */
.section .data
.align 2
counter: .word 7
