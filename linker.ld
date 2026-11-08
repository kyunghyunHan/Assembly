
/* QEMU MPS2-AN386 memory map, NOT STM32F429ZI memory map. */
ENTRY(Reset_Handler)

MEMORY {
  FLASH (rx)  : ORIGIN = 0x00000000, LENGTH = 4M
  RAM (rwx)   : ORIGIN = 0x20000000, LENGTH = 4M
}

_estack = ORIGIN(RAM) + LENGTH(RAM);

SECTIONS {
  .isr_vector ORIGIN(FLASH) : {
    . = ALIGN(4);
    KEEP(*(.isr_vector))
    . = ALIGN(4);
  } > FLASH

  .text : {
    *(.text*)
    *(.rodata*)
    . = ALIGN(4);
  } > FLASH

  .ARM.exidx : { *(.ARM.exidx*) } > FLASH

  .data : {
    . = ALIGN(4);
    _sdata = .;
    *(.data*)
    . = ALIGN(4);
    _edata = .;
  } > RAM AT> FLASH
  _sidata = LOADADDR(.data);

  .bss (NOLOAD) : {
    . = ALIGN(4);
    _sbss = .;
    *(.bss*)
    *(COMMON)
    . = ALIGN(4);
    _ebss = .;
  } > RAM

  .noinit (NOLOAD) : {
    . = ALIGN(4);
    *(.noinit*)
    . = ALIGN(4);
  } > RAM

  . = ALIGN(8);
  ASSERT(_ebss <= _estack - 1024, "Not enough stack space")
}
