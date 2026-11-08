.syntax unified
.cpu cortex-m4
.thumb
/* Cortex-M4 reset vectors. GNU as .thumb_func makes vector entry Thumb-aware. */
.section .isr_vector,"a",%progbits
.word _estack
.word Reset_Handler
.word 0 /* NMI */
.word HardFault_Handler
.word 0 /* MemManage */
.word 0 /* BusFault */
.word UsageFault_Handler
.word 0,0,0,0
.word SVC_Handler
.word 0,0,0,0 /* DebugMon, reserved, PendSV, SysTick */
.section .text.Reset_Handler,"ax",%progbits
.global Reset_Handler
.thumb_func
Reset_Handler:
    /* The core already loaded MSP from vector[0]. */
    bl init_data_bss
    bl demo
    b exit_ok

/* Generic startup for all labs: copy .data and zero .bss. */
.thumb_func
init_data_bss:
    ldr r0, =_sidata
    ldr r1, =_sdata
    ldr r2, =_edata
1:  cmp r1, r2
    bcs 2f
    ldr r3, [r0]
    str r3, [r1]
    adds r0, #4
    adds r1, #4
    b 1b
2:  ldr r1, =_sbss
    ldr r2, =_ebss
    movs r3, #0
3:  cmp r1, r2
    bcs 4f
    str r3, [r1]
    adds r1, #4
    b 3b
4:  bx lr

/* ARM semihosting SYS_WRITE0: r1 -> NUL-terminated string. */
.thumb_func
print_string:
    push {r0, lr}
    movs r0, #4
    bkpt #0xab
    pop {r0, pc}
.thumb_func
exit_ok:
    movs r0, #0x18      /* SYS_EXIT */
    ldr r1, =0x20026    /* ADP_Stopped_ApplicationExit */
    bkpt #0xab
    b .
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
.section .rodata,"a",%progbits
msg_hardfault: .asciz "HardFault handler reached\n"
msg_usagefault: .asciz "UsageFault handler reached\n"
.section .bss,"aw",%nobits
.align 2
svc_count: .space 4

.section .text.demo,"ax",%progbits
.global demo
.thumb_func
demo:
    push {r7, lr}
    ldr r0, =0x00000000
    ldr r2, [r0]    /* 0x0: boot image initial MSP */
    ldr r0, =seen_msp
    str r2, [r0]
    ldr r0, =0x00000004
    ldr r2, [r0]    /* 0x4: reset handler vector */
    ldr r0, =seen_reset
    str r2, [r0]
    ldr r1, =message
    bl print_string
    pop {r7, pc}
.section .rodata
message: .asciz "exam03: read QEMU vectors at 0x0; NO STM32 BOOT alias test\n"
.section .bss
.align 2
seen_msp: .space 4
seen_reset: .space 4
