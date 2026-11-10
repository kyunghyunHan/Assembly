# Exam-02. AIRCR 소프트웨어 Reset 실습 결과

**환경:** Cortex-M4 / QEMU (`mps2-an386`) / GDB  
**소스:** `src/02-reset-reason.s`  
**결과:** Reset 재진입 및 RAM 재초기화 확인

## 1. 실습 목표

- AIRCR의 `SYSRESETREQ`로 시스템 Reset 요청
- Reset 후 `Reset_Handler` 재실행 확인
- MSP와 PC의 Reset 초기 상태 확인
- `.data` / `.bss`가 다시 초기화되는지 확인

## 2. 주요 실행 명령어

```bash
# Assembly → Object
arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb -c src/02-reset-reason.s -o main.o

# Object → ELF + MAP
arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb -nostdlib -T linker.ld \
  -Wl,-Map=firmware.map main.o -o firmware.elf

# ELF → BIN
arm-none-eabi-objcopy -O binary firmware.elf firmware.bin

# 터미널 1: QEMU 실행 (GDB 대기)
qemu-system-arm -M mps2-an386 -nographic -semihosting \
  -S -gdb tcp::1234 -kernel firmware.elf

# 터미널 2: GDB 실행
arm-none-eabi-gdb firmware.elf
```

GDB에서 한 줄씩 입력:

```gdb
target remote localhost:1234
break Reset_Handler
break after_init
continue
info registers sp pc
x/3wx 0x20000000
break wait_here
continue
set {unsigned int}0x20000000 = 99
set {unsigned int}0x20000004 = 55
x/3wx 0x20000000
set {unsigned int}0x20000008 = 1
clear wait_here
continue
info registers sp pc
set {unsigned int}0x20000000 = 99
set {unsigned int}0x20000004 = 55
x/3wx 0x20000000
continue
x/3wx 0x20000000
```

## 3. 실제 확인한 결과

| 검사 시점 | SP | PC | `counter` (.data) | `svc_count` (.bss) | `reset_request` (.bss) |
|---|---|---|---:|---:|---:|
| 첫 부팅, 초기화 완료 | `0x20400000` | `0x44` (`after_init`) | 7 | 0 | 0 |
| 첫 부팅, GDB로 값 변경 | — | `wait_here` | 99 | 55 | 0 |
| Reset 후, `Reset_Handler` 진입 | `0x20400000` | `0x40` (`Reset_Handler`) | — | — | — |
| 두 번째 부팅, GDB로 값 재설정 | — | `Reset_Handler` | 99 | 55 | 1 |
| 두 번째 부팅, 초기화 완료 | — | `0x44` (`after_init`) | **7** | **0** | **0** |

**실제 GDB 핵심 로그:**

```text
Breakpoint 1, 0x00000040 in Reset_Handler ()
sp  0x20400000
pc  0x40 <Reset_Handler>

# Reset_Handler에서 RAM 값 재설정
0x20000000:  0x00000063  0x00000037  0x00000001

# Startup 초기화 후
Breakpoint 2, 0x00000044 in after_init ()
0x20000000:  0x00000007  0x00000000  0x00000000
```

- `0x63 = 99`, `0x37 = 55` (16진수)
- `AIRCR = 0xE000ED0C`, 요청값 `0x05FA0004` (`VECTKEY` + `SYSRESETREQ`)
- Reset 직후 RAM 값은 GDB에서 다시 설정한 후 Startup 초기화 결과를 비교했음

## 4. 결론

**4가지 목표 확인 완료.** `AIRCR.SYSRESETREQ` 요청 뒤 `Reset_Handler`에 재진입했고, 초기 MSP (`0x20400000`)와 PC (`0x40`)를 확인했다. Startup 코드 실행 후에는 `.data`의 `counter`가 **99 → 7**, `.bss`의 `svc_count`가 **55 → 0**으로 복원됐다.

