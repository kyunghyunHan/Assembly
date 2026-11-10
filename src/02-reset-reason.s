
.syntax unified
.cpu cortex-m4
.thumb

/* 1. Vector Table */
.section .isr_vector,"a",%progbits
.word _estack
.word Reset_Handler
.word 0                    /* NMI */
.word HardFault_Handler
.word 0                    /* MemManage */
.word 0                    /* BusFault */
.word 0                    /* UsageFault */
.word 0,0,0,0              /* Reserved */
.word 0                    /* SVCall */
.word 0                    /* DebugMon */
.word 0                    /* Reserved */
.word 0                    /* PendSV */
.word 0                    /* SysTick */

/* 2. Reset Handler */
.section .text.Reset_Handler,"ax",%progbits
.global Reset_Handler
.thumb_func
Reset_Handler:
    bl init_data_bss       /* RAM 초기화 */

.global after_init
after_init:
    bl demo                /* 부팅 메시지 출력 */
    b wait_here

/* 3. .data / .bss 초기화 */
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

/* 4. Semihosting 출력 */
.thumb_func
print_string:
    push {r0, lr}
    movs r0, #4
    bkpt #0xab
    pop {r0, pc}

/* 5. 부팅 메시지 */
.thumb_func
demo:
    push {r7, lr}
    ldr r1, =message
    bl print_string
    pop {r7, pc}

/* 6. GDB에서 Reset 요청을 활성화할 때까지 대기 */
.global wait_here
.thumb_func
wait_here:
    ldr r0, =reset_request
    ldr r1, [r0]
    cmp r1, #1
    bne wait_here

/* 7. AIRCR를 통한 시스템 Reset */
.global request_reset
.thumb_func
request_reset:
    ldr r0, =0xE000ED0C  /* AIRCR 주소 */
    ldr r1, =0x05FA0004  /* VECTKEY + SYSRESETREQ */
    dsb
    str r1, [r0]         /* 실제 Reset 요청 */
    dsb

reset_pending:
    b reset_pending

/* 8. HardFault */
.thumb_func
HardFault_Handler:
    b .

/* 9. 문자열 */
.section .rodata,"a",%progbits
message:
    .asciz "exam02: Reset_Handler executed\n"

/* 10. .data: Reset 후 7로 복원 */
.section .data,"aw",%progbits
.align 2
.global counter
counter:
    .word 7

/* 11. .bss: Reset 후 0으로 초기화 */
.section .bss,"aw",%nobits
.align 2

.global svc_count
svc_count:
    .space 4

.global reset_request
reset_request:
    .space 4
