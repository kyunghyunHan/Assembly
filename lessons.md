# ARM Cortex-M4 Startup 실습 16개

각 실습은 독립된 `.s` 파일 하나로 구성됩니다. 파일은 `src/`에 모아 두고, 모든 실습이 루트의 `linker.ld`를 공유합니다.

```bash
./run.sh 01-elf-map-bin.s
```

스크립트는 해당 파일을 빌드한 뒤 QEMU에서 실행합니다. ELF, MAP, BIN 파일은 `build/<실습이름>/` 아래에 생성됩니다.

## 실습 목록

| 실습 | 소스 파일 | 주제 | 예상 출력 / 학습 포인트 |
|---|---|---|---|
| 01 | `src/01-elf-map-bin.s` | ELF / MAP / BIN 비교 | `exam01: image and sections OK` — `readelf`, `nm`, `objdump`, `objcopy`로 `.data`의 LMA/VMA 비교 |
| 02 | `src/02-reset-reason.s` | Reset / AIRCR | `exam02: AIRCR address/read; reset write disabled` — 무한 재부팅 방지를 위해 SYSRESETREQ 쓰기는 비활성화; F429 reset 원인은 보드에서 `RCC_CSR` 확인 |
| 03 | `src/03-boot-alias.s` | Boot Alias와 QEMU 한계 | `exam03: read QEMU vectors at 0x0; NO STM32 BOOT alias test` — STM32 BOOT 핀과 Flash alias 검증은 실제 보드 필요 |
| 04 | `src/04-vector-table.s` | 첫 8바이트 벡터 테이블 | `exam04: vector[0]/vector[1] captured in RAM` — `objdump -s -j .isr_vector`, GDB `x/2wx 0x0` |
| 05 | `src/05-msp-stack.s` | MSP / PUSH / BL / LR | `exam05: MSP before/push/pop saved in RAM` — push는 SP를 8바이트 감소시키고 8바이트 정렬을 유지 |
| 06 | `src/06-thumb-pc.s` | Reset Vector Thumb bit | `vector[1] & 1 == 1` 확인 및 실제 명령 주소와 disassembly 비교 |
| 07 | `src/07-reset-handler-step.s` | Reset_Handler single-step | GDB에서 `break Reset_Handler`, `si`, `info registers`, `x/i $pc` |
| 08 | `src/08-assembly-instructions.s` | LDR / STR / CMP / BCC / BL | `exam08: CMP/BCC result in RAM (expected 0x11)` — BCC는 unsigned lower 조건 |
| 09 | `src/09-c-variable-sections.s` | `.data` / `.bss` / `.rodata` | `exam09: .data=7 and .bss=0 observed` — `nm`, `objdump -h`, `.data` 덤프와 RAM 확인 |
| 10 | `src/10-linker-vma-lma.s` | Linker VMA / LMA / symbols | `exam10: LMA / VMA symbols saved` — `objdump -h`에서 `.data`의 LMA와 VMA 비교 |
| 11 | `src/11-data-bss-trace.s` | Flash→RAM 복사 / zero-fill | `exam11: set breakpoint at init_data_bss and step LDR/STR` — 초기화 루프를 단계별로 추적 |
| 12 | `src/12-runtime-order.s` | SystemInit / C runtime 구분 | `exam12: simulated hooks, NOT libc/SystemInit implementation` — QEMU 예제는 순서 개념만 시연 |
| 13 | `src/13-isr-vtor.s` | SVC exception / VTOR | `exam13: SVC invoked, svc_count should be 1` — SVC는 CPU exception이며 F429 USART IRQ가 아님 |
| 14 | `src/14-ccm-dma-limit.s` | F429 CCM과 DMA 제한 | `exam14: address constants only; DMA test requires F429ZI` — 실제 CCM/DMA 동작은 보드와 peripheral driver 필요 |
| 15 | `src/15-openocd-gdb.s` | QEMU GDB 원격 디버깅 | `exam15: remote GDB step target` — QEMU `-S -gdb tcp::1234`; OpenOCD는 F429 하드웨어에서 별도 설정 |
| 16 | `src/16-fault-investigation.s` | UsageFault / DIV_0_TRP | `UsageFault handler reached` — GDB에서 SCB CFSR (`0xE000ED28`)과 stacked PC 관찰; QEMU 구현에 따라 차이가 있을 수 있음 |

## 준비 및 디버깅

macOS에서 `arm-none-eabi-gcc`, `arm-none-eabi-objcopy`, `qemu-system-arm`이 PATH에 있어야 합니다. 특정 실습은 파일명만 지정해 빌드·실행합니다.

```bash
./run.sh 16-fault-investigation.s
```

15번을 GDB로 실행하려면 먼저 ELF를 빌드하고 QEMU를 GDB 대기 상태로 시작합니다.

터미널 A:

```bash
arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb -c src/15-openocd-gdb.s -o build/15-openocd-gdb/main.o
arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb -nostdlib -T linker.ld \
  -Wl,-Map=build/15-openocd-gdb/main.map build/15-openocd-gdb/main.o \
  -o build/15-openocd-gdb/main.elf
qemu-system-arm -M mps2-an386 -nographic -semihosting -S -gdb tcp::1234 \
  -kernel build/15-openocd-gdb/main.elf
```

터미널 B:

```text
arm-none-eabi-gdb build/15-openocd-gdb/main.elf
(gdb) target remote :1234
(gdb) break Reset_Handler
(gdb) continue
(gdb) info registers
(gdb) x/2wx 0x0
(gdb) x/8i $pc
(gdb) stepi
```

## 제한 및 주의

- `qemu-system-arm -M mps2-an386`은 Arm MPS2 AN386을 에뮬레이션하며 STM32F429ZI 에뮬레이터가 아닙니다. 공통 linker의 Flash `0x0`, RAM `0x20000000`은 QEMU용 주소 배치입니다.
- F429ZI에서 실행할 때는 보드 전용 Flash/RAM 배치와 startup을 사용해야 합니다. 실제 보드에서 OpenOCD를 사용하려면 ST-Link 연결 설정도 필요합니다.
- 02번은 AIRCR을 읽는 실습이며 SYSRESETREQ 쓰기를 수행하지 않습니다. 03번은 QEMU 벡터를 읽으며 STM32 BOOT 핀이나 alias를 시험하지 않습니다.
- 12번은 init hook 순서의 교육용 모형이며 실제 `__libc_init_array()`나 ST `SystemInit()`을 호출하지 않습니다.
- 14번은 주소 상수만 확인합니다. CCM RAM 접근이나 DMA 동작을 재현하지 않습니다.
- 16번은 의도적으로 Fault를 발생시킵니다. 예상 출력은 검증 전 예시이며 에뮬레이터 구현에 따라 달라질 수 있습니다.
- 모든 소스에는 독립 실행을 위한 공통 startup이 포함되어 있습니다. 실제 ST CMSIS startup과 다르며, 이 실습은 실제 보드에서 검증되지 않았습니다.
