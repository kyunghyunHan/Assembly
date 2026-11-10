# Exam 01 — Assembly → ELF / MAP / BIN 생성 및 QEMU 실행 분석

## 1. 실습 목적

Assembly 소스 한 개에서 다음 세 파일이 어떻게 생성되고 무엇이 들어 있는지 직접 확인한다.

| 파일 | 역할 | 확인하는 내용 |
|---|---|---|
| `firmware.elf` | 실행 가능한 ELF 파일 | 섹션, 심볼, 주소, 실제 데이터 |
| `firmware.map` | 링커의 메모리 배치 보고서 | 섹션의 실행 주소(VMA), 로드 주소(LMA), 크기 |
| `firmware.bin` | 평탄한 바이너리 이미지 | 플래시에 기록할 원시 바이트(자체 심볼/주소 정보 없음) |



사용 도구:

- `arm-none-eabi-gcc`: Assembly를 오브젝트로 만들고 링킹
- `arm-none-eabi-objcopy`: ELF의 로드 이미지를 BIN으로 추출
- `arm-none-eabi-readelf`: ELF 섹션 정보 확인
- `arm-none-eabi-nm`: 심볼(함수·변수)의 주소 확인
- `arm-none-eabi-objdump`: ELF 안의 데이터 바이트 덤프
- `grep`: MAP 텍스트에서 필요한 항목 검색
- `xxd`: BIN 파일을 16진수로 출력
- `qemu-system-arm`: ARM 보드 에뮬레이션 및 프로그램 실행

## 3. 사용한 Assembly 코드의 핵심

```asm
/* Reset 시 초기 스택과 실행 시작 주소 */
.section .isr_vector,"a",%progbits
.word _estack
.word Reset_Handler

/* 초기화 후 demo 실행 */
.section .text.Reset_Handler,"ax",%progbits
Reset_Handler:
    bl init_data_bss
    bl demo
    b exit_ok

/* 초기값이 있는 변수 */
.section .data
.align 2
counter: .word 7

/* 실행 중 0으로 초기화할 변수 */
.section .bss,"aw",%nobits
.align 2
svc_count: .space 4

/* 메시지 출력에 쓰는 읽기 전용 문자열 */
.section .rodata
message: .asciz "exam01: image and sections OK\n"
```

전체 소스에서는 `init_data_bss`가 `.data` 초기값을 Flash 로드 주소에서 RAM으로 복사하고 `.bss`를 0으로 채운다. `demo`는 Semihosting으로 문자열을 출력한 후 `counter`를 1 증가시키도록 작성돼 있다.


### 4.1 Assembly → Object (`main.o`)

```bash
arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb \
  -c src/01-elf-map-bin.s -o main.o
```

- `-mcpu=cortex-m4`: 대상 코어를 Cortex-M4로 선택
- `-mthumb`: Thumb 명령어 사용
- `-c`: 링크하지 않고 `.o`만 생성
- `-o main.o`: 출력 파일명 지정

**실제 결과:** 오류 메시지 없이 명령이 종료되었으므로 오브젝트 생성 성공.

### 4.2 Object → ELF + MAP

```bash
arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb \
  -nostdlib -T linker.ld \
  -Wl,-Map=firmware.map \
  main.o -o firmware.elf
```

- `-nostdlib`: 기본 표준 라이브러리 및 일반적인 시작 파일 자동 링크 방지
- `-T linker.ld`: 메모리 배치 규칙을 링커 스크립트에서 읽음
- `-Wl,-Map=firmware.map`: 링커에 MAP 파일 생성 옵션 전달
- `main.o`: 링크할 오브젝트
- `-o firmware.elf`: 최종 ELF 파일명

**실제 결과:** 오류 메시지 없이 `firmware.elf`, `firmware.map` 생성 성공.

### 4.3 ELF → BIN

```bash
arm-none-eabi-objcopy -O binary firmware.elf firmware.bin
```

- `-O binary`: ELF에서 평탄한 바이너리 로드 이미지 추출
- ELF를 **다시 컴파일하는 명령이 아님**

**실제 결과:** 오류 메시지 없이 `firmware.bin` 생성 성공.

## 5. ELF 확인 — 섹션, 변수, 초기값

### 5.1 섹션 확인: `readelf -S`

```bash
arm-none-eabi-readelf -S firmware.elf
```

**실제 출력 중 주요 부분:**

```text
[Nr] Name             Type       Addr      Off     Size    Flg
[ 1] .isr_vector      PROGBITS   00000000  001000  000040  A
[ 2] .text            PROGBITS   00000040  001040  0000f4  AX
[ 3] .data            PROGBITS   20000000  002000  000004  WA
[ 4] .bss             NOBITS     20000004  002004  000004  WA
[ 5] .noinit          NOBITS     20000008  000000  000000  WA
```

| 섹션 | 실행 주소 (`Addr`) | 크기 (`Size`) | 의미 |
|---|---:|---:|---|
| `.isr_vector` | `0x00000000` | `0x40` = 64 B | 초기 MSP와 예외 벡터 |
| `.text` | `0x00000040` | `0xF4` = 244 B | 실행 명령어와 이 링크 구성에서 합쳐진 읽기 전용 데이터 |
| `.data` | `0x20000000` | `0x4` = 4 B | 초기값 있는 RAM 데이터 (`counter`) |
| `.bss` | `0x20000004` | `0x4` = 4 B | 시작 시 0으로 초기화할 RAM 공간 |
| `.noinit` | `0x20000008` | 0 B | 이 빌드에서 데이터가 없는 섹션 |

**중요:** `.text` 내부에 문자열이 보이는 것은 링커 스크립트가 입력 `.rodata`를 출력 `.text`에 포함한 구성으로 해석할 수 있다. 이 결과에는 별도 출력 `.rodata` 섹션이 표시되지 않는다. `Addr`와 `Off`도 다르다. 예컨대 `.data`의 **실행 시 주소**는 `0x20000000`, ELF 파일 내부 오프셋은 `0x2000`이다.

### 5.2 심볼 주소 확인: `nm`

```bash
arm-none-eabi-nm -n firmware.elf | grep counter
```

**실제 출력:**

```text
20000000 d counter
```

- `20000000`: `counter`의 실행 시 RAM 주소 = `0x20000000`
- `d`: 초기화된 데이터 영역에 있는 **로컬** 심볼 (`.data`)
- `counter`: Assembly에서 정의한 변수 이름

즉 ELF 심볼 테이블에서 `counter`의 위치를 확인했다.

### 5.3 ELF 안에 초기값 7이 있는지: `objdump`

```bash
arm-none-eabi-objdump -s -j .data firmware.elf
```

**실제 출력:**

```text
firmware.elf:     file format elf32-littlearm

Contents of section .data:
 20000000 07000000                             ....
```

`counter: .word 7`은 **32비트 정수 7**이다. ARM 리틀 엔디언에서는 다음 순서로 저장된다.

```text
값          : 0x00000007
메모리 바이트: 07 00 00 00
```

**확인 결과:** ELF `.data`에 초기값 `7`이 실제로 들어 있다.

## 6. MAP 확인 — RAM 주소와 Flash 로드 주소

```bash
grep -E '\.data|counter|_sidata' firmware.map
```

**실제 출력:**

```text
.data           0x20000000        0x4 load address 0x00000134
 *(.data*)
 .data          0x20000000        0x4 main.o
                0x00000134                        _sidata = LOADADDR (.data)
```

- `.data` **실행 주소(VMA)**: `0x20000000` → `counter`가 실행 중 놓이는 RAM 주소
- `.data` **로드 주소(LMA)**: `0x00000134` → 초기값 7이 이미지 안에 저장된 주소
- `.data` 크기: `0x4` → 4바이트
- `_sidata`: 링커가 정의한 `.data` 초기값의 로드 주소 `0x00000134`

```text
이미지의 로드 주소 0x00000134 : 07 00 00 00
                │
                │ Reset_Handler → init_data_bss에서 복사
                ▼
RAM 주소 0x20000000            : counter = 7
                │
                │ demo에서 1 증가
                ▼
RAM 주소 0x20000000            : counter = 8 (코드상 예상)
```

**주의:** 이 프로젝트의 실제 MAP에서 이미지 로드 주소는 `0x00000134`다. STM32 내부 Flash의 전형적인 주소 `0x08000000`으로 해석하거나 치환하면 안 된다. 실제 주소는 **현재 `linker.ld`**에 의해 결정된다. 또한 제시된 MAP 검색 결과에는 `counter` 심볼 행 자체가 보이지 않았고, `counter`의 주소는 위 `nm` 결과로 확인했다.

## 7. BIN 확인 — 실제 바이트와 ELF/MAP 대조

```bash
xxd firmware.bin
```

**실제 출력 중 시작 부분:**

```text
00000000: 0000 4020 4100 0000 0000 0000 8100 0000  ..@ A...........
00000010: 0000 0000 0000 0000 8900 0000 0000 0000  ................
```

바이트를 4개씩 리틀 엔디언으로 해석하면:

- 오프셋 `0x00000000`: `00 00 40 20` → 초기 MSP 값 `0x20400000`
- 오프셋 `0x00000004`: `41 00 00 00` → Reset Vector `0x00000041`; bit 0은 Thumb 상태 정보, 명령어 시작 주소는 `0x00000040`
- `.isr_vector` 크기 64바이트이므로 `.text`는 `0x40`부터 시작한다는 ELF 결과와 대응

**실제 출력 중 마지막 부분:**

```text
00000110: 640a 0065 7861 6d30 313a 2069 6d61 6765  d..exam01: image
00000120: 2061 6e64 2073 6563 7469 6f6e 7320 4f4b   and sections OK
00000130: 0a00 0000 0700 0000                      ........
```

문자열 `exam01: image and sections OK`의 ASCII 바이트 뒤에 초기값 `07 00 00 00`이 이어진다.

정확하게 **MAP에서 본 로드 주소 `0x134`**만 읽으려면:

```bash
xxd -s 0x134 -l 4 firmware.bin
```

예상 결과(사용자가 이미 제공한 전체 `xxd` 출력으로 검증 가능한 내용):

```text
00000134: 0700 0000
```

검증 연결:

```text
Assembly: counter: .word 7
               │
ELF: .data 0x20000000 → 07 00 00 00
               │
MAP: 실행 RAM 0x20000000 / 로드 주소 0x00000134
               │
BIN: 오프셋 0x134 → 07 00 00 00
```

**핵심:** BIN 자체에는 `counter`, `.data`, `0x20000000` 같은 설명이 없다. ELF와 MAP으로 의미와 주소를 찾은 다음 그 위치의 바이트를 확인한 것이다. 이번 경우 BIN 이미지가 `0x00000000`부터 시작해 **로드 주소 `0x134`와 파일 오프셋 `0x134`가 일치**한다.

## 8. QEMU 실행 결과

```bash
qemu-system-arm -M mps2-an386 \
  -nographic -semihosting \
  -kernel firmware.elf
```

- `-M mps2-an386`: Cortex-M4 기반 MPS2 보드 모델
- `-nographic`: 그래픽 창 대신 터미널 입출력
- `-semihosting`: `bkpt #0xab`을 통한 호스트 출력·종료 활성화
- `-kernel firmware.elf`: ELF 실행

**실제 터미널 출력:**

```text
exam01: image and sections OK
```



## 명령어


```bash
# 1) Assembly → Object
arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb \
  -c src/01-elf-map-bin.s -o main.o

# 2) Object → ELF + MAP
arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb \
  -nostdlib -T linker.ld \
  -Wl,-Map=firmware.map \
  main.o -o firmware.elf

# 3) ELF → BIN
arm-none-eabi-objcopy -O binary firmware.elf firmware.bin

# 4) ELF의 섹션 확인
arm-none-eabi-readelf -S firmware.elf

# 5) ELF의 변수 심볼 확인
arm-none-eabi-nm -n firmware.elf | grep counter

# 6) ELF의 .data 바이트 확인
arm-none-eabi-objdump -s -j .data firmware.elf

# 7) MAP에서 .data의 주소 확인
grep -E '\.data|counter|_sidata' firmware.map

# 8) BIN 전체 덤프
xxd firmware.bin

# 9) BIN에서 counter 초기값의 위치만 확인 (이 실습의 실제 LMA)
xxd -s 0x134 -l 4 firmware.bin

# 10) QEMU로 실행
qemu-system-arm -M mps2-an386 \
  -nographic -semihosting \
  -kernel firmware.elf
```

