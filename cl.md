# ARM GNU Toolchain & QEMU 명령어 정리

> 환경: **macOS Apple Silicon (M1 Pro)** / **ARM Cortex-M4 (Thumb)** / **GNU Arm Embedded Toolchain** / **QEMU**  
> 목적: `src/test.s`로 ARM Assembly 작성 → 오브젝트 생성 → ELF 링크 → Mac에서 Cortex-M4 에뮬레이션 실행

## 1. Mac에서 ARM Cortex-M4 코드를 실행하는 구조

```text
Mac (ARM64 / AArch64)                      Target (ARM Cortex-M4 / Thumb)
┌───────────────────┐
│ src/test.s        │
│       ↓           │
│ arm-none-eabi-gcc │ → main.o → linker.ld 사용 → main.elf
│       ↓           │                              ↓
│ QEMU             │ ← Cortex-M4 보드를 에뮬레이션하여 실행
└───────────────────┘
```

- `arm-none-eabi-gcc`: **Mac에서 실행될 프로그램**이 아니라 **ARM bare-metal 타깃용 파일**을 생성한다.
- `qemu-system-arm`: Cortex-M4 같은 ARM 시스템을 에뮬레이션한다.
- `clang`(Mac 기본): Mac의 **AArch64** 코드를 빌드할 때 사용한다. Cortex-M4 어셈블리(`R0`, `R1`, `.thumb`)와 문법이 다르다.
- `.o`: 링킹 전 오브젝트 파일. `.elf`: 링킹된 ARM 실행 이미지. Mac에서 `./main.elf`로 직접 실행하지 않는다.

## 2. 설치 / 버전 / 지원 보드 확인

```bash
# QEMU 설치 (Homebrew)
brew install qemu

# 설치 확인
qemu-system-arm --version
arm-none-eabi-gcc --version
arm-none-eabi-as --version
arm-none-eabi-ld --version
arm-none-eabi-objdump --version

# QEMU가 지원하는 보드에서 Cortex-M4 보드 검색
qemu-system-arm -M help | grep mps2-an386
```

`mps2-an386`은 ARM Cortex-M4 기반 MPS2 보드 모델이다. **STM32F446RE 보드 그 자체를 에뮬레이션하는 것은 아니다.** 따라서 CPU 명령어 학습에는 적합하지만 STM32 전용 GPIO/UART 레지스터 주소가 그대로 작동하지는 않는다.

## 3. 프로젝트 구성

```text
Assembly/
├── src/
│   └── test.s           # Cortex-M4 Assembly 소스
├── linker.ld            # 메모리 배치 및 섹션 설정
├── main.o               # 어셈블 결과
└── main.elf             # QEMU에서 실행할 ELF
```

## 4. 핵심 빌드 / 실행 명령어

### 4.1 Assembly → Object (`.s` → `.o`)

```bash
arm-none-eabi-gcc \
    -mcpu=cortex-m4 \
    -mthumb \
    -c src/test.s -o main.o
```

### 4.2 Object → ELF (`.o` → `.elf`)

```bash
arm-none-eabi-gcc \
    -mcpu=cortex-m4 \
    -mthumb \
    -nostdlib \
    -T linker.ld \
    main.o -o main.elf
```

### 4.3 QEMU 실행

```bash
qemu-system-arm \
    -M mps2-an386 \
    -nographic \
    -semihosting \
    -kernel main.elf
```

위 실습에서는 Semihosting `BKPT #0xAB`으로 문자열을 호스트 터미널에 출력할 수 있다. **펌웨어 코드와 출력 기능이 준비되어 있어야 출력된다.**

### 4.4 한 번에 빌드하고 실행

```bash
arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb -c src/test.s -o main.o && \
arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb -nostdlib -T linker.ld main.o -o main.elf && \
qemu-system-arm -M mps2-an386 -nographic -semihosting -kernel main.elf
```

## 5. 주요 옵션

| 옵션 | 의미 |
|---|---|
| `-mcpu=cortex-m4` | 타깃 CPU를 Cortex-M4로 설정 |
| `-mthumb` | Thumb 명령어 생성 |
| `-c` | 링크하지 않고 오브젝트 파일까지만 생성 |
| `-o main.o` | 출력 파일 지정 |
| `-nostdlib` | 표준 시작 파일 및 표준 라이브러리 자동 링크 생략 |
| `-T linker.ld` | GNU LD 링커 스크립트 지정 |
| `-M mps2-an386` | 에뮬레이션할 QEMU 보드 모델 선택 |
| `-nographic` | 별도 그래픽 창 없이 터미널 사용 |
| `-semihosting` | Semihosting 호출 허용 (`BKPT #0xAB`) |
| `-kernel main.elf` | 실행 이미지 로드 |

## 6. 결과물 검사 및 디버깅 명령어

```bash
# 실행 파일의 형식 확인
file main.o
file main.elf

# ELF 헤더 및 아키텍처
arm-none-eabi-readelf -h main.elf

# 섹션 목록 / 메모리 배치
arm-none-eabi-readelf -S main.elf

# 심볼 확인
arm-none-eabi-nm -n main.elf

# 디스어셈블
arm-none-eabi-objdump -d main.elf

# 코드와 섹션을 함께 확인
arm-none-eabi-objdump -h -d main.elf

# 크기 확인
arm-none-eabi-size main.elf

# 필요할 때 ELF → BIN 변환
arm-none-eabi-objcopy -O binary main.elf main.bin

# 링커 맵 생성 (링크할 때 옵션 추가)
arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb -nostdlib \
    -T linker.ld -Wl,-Map=main.map main.o -o main.elf
```

## 7. QEMU 종료 방법

QEMU를 `-nographic`으로 실행했다면:

- **`Ctrl+A`를 누른 뒤 손을 떼고 `X`**: QEMU 모니터 단축키로 종료
- **`Ctrl+C`**: 터미널에서 인터럽트 요청 (환경에 따라 처리 방식이 다를 수 있음)
- 종료되지 않으면 **다른 터미널**에서 `pkill -f qemu-system-arm` 실행 (실행 중인 다른 QEMU ARM 프로세스까지 종료할 수 있으므로 주의)

### Assembly 코드에서 종료 요청 (Semihosting)

```asm
    MOV R0, #0x18       @ SYS_EXIT
    LDR R1, =0x20026    @ ADP_Stopped_ApplicationExit
    BKPT #0xAB          @ QEMU에 종료 요청

hang:
    B hang              @ 종료되지 않는 경우 대비
```

## 8. 최소 Assembly 예제 (`src/test.s`)

Cortex-M4 MPS2용으로 **메모리에 123을 저장하고, 다시 읽어 확인한 뒤, 결과 문자열을 출력**한다.

```asm
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
    LDR R1, =data        @ data의 RAM 주소
    MOV R0, #123         @ R0 = 123
    STR R0, [R1]         @ RAM에 123 저장
    MOV R0, #0           @ R0 = 0
    LDR R2, [R1]         @ R2 = RAM에서 읽은 값

    CMP R2, #123
    BNE error

    LDR R1, =message
    B print

error:
    LDR R1, =error_msg

print:
    MOV R0, #4           @ SYS_WRITE0
    BKPT #0xAB

    MOV R0, #0x18        @ SYS_EXIT
    LDR R1, =0x20026
    BKPT #0xAB

hang:
    B hang

.section .rodata
message:
    .asciz "Value = 123\n"
error_msg:
    .asciz "Error\n"

.section .bss
.align 2
data:
    .space 4
```

출력 예시:

```text
Value = 123
```

## 9. 링커 스크립트 예제 (`linker.ld`)

> QEMU MPS2 연습용 주소 배치다. 실제 STM32에서 사용하려면 **해당 STM32의 Flash/RAM 주소 및 크기에 맞게 교체**해야 한다.

```ld
ENTRY(Reset_Handler)

MEMORY
{
    FLASH (rx)  : ORIGIN = 0x00000000, LENGTH = 4M
    RAM   (rwx) : ORIGIN = 0x20000000, LENGTH = 4M
}

_stack_top = ORIGIN(RAM) + LENGTH(RAM);

SECTIONS
{
    .isr_vector :
    {
        KEEP(*(.isr_vector))
    } > FLASH

    .text :
    {
        *(.text*)
        *(.rodata*)
    } > FLASH

    .bss (NOLOAD) :
    {
        *(.bss*)
        *(COMMON)
    } > RAM
}
```

## 10. 자주 발생하는 오류

| 오류 | 원인 / 해결 |
|---|---|
| `ARM register expected: mov w0, #0` | `w0`, `x1`, `ret`, `adrp`는 AArch64 문법. Cortex-M4에서는 `r0`, `r1`, `bx lr` 등 사용 |
| `linker.ld:1: syntax error` | `linker.ld` 첫 줄에 마크다운 코드 펜스(```), 설명문, 잘못된 내용이 들어갔는지 확인. `head -n 10 linker.ld` |
| `cannot open linker script file` | 파일 경로·유형·권한 확인. `pwd`, `ls -ld linker.ld`, `file linker.ld` |
| `undefined reference to printf` | `-nostdlib`로 C 라이브러리를 연결하지 않음. 이 최소 예제에서는 `printf` 대신 Semihosting 사용 |
| QEMU에서 출력 없음 | `-semihosting` 옵션, `BKPT #0xAB`, Vector Table, 링커 배치를 확인 |
| QEMU가 종료되지 않음 | 코드의 `B hang` 무한 루프 혹은 종료 요청 미처리. `Ctrl+A`, `X` 순서로 종료 |

## 11. 학습 포인트

- `MOV R0, #123`: 숫자 123을 레지스터에 저장
- `LDR R1, =data`: `data`의 주소를 레지스터로 가져옴 (어셈블러 의사 명령어)
- `STR R0, [R1]`: 레지스터 값을 지정 주소의 메모리에 기록
- `LDR R2, [R1]`: 지정 주소의 메모리 값을 레지스터로 읽음
- `CMP` / `BNE`: 비교 후 조건부 분기
- `BKPT #0xAB`: Semihosting 서비스 요청
- `Reset_Handler`: 리셋 후 실행되는 진입 코드
- `.isr_vector`: 초기 SP와 Reset Vector가 들어가는 벡터 테이블
- `linker.ld`: Flash/RAM에 코드와 데이터를 배치하는 규칙

**한 줄 요약:** `arm-none-eabi-gcc`는 ARM용 `.o`/`.elf`를 **만들고**, `qemu-system-arm`은 그 ARM 프로그램을 Mac에서 **에뮬레이션하여 실행**한다.
