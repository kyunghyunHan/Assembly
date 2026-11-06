# Assembly (어셈블리어)

> **대상:** ARM Cortex-M4 / STM32F429ZI
>
> **학습 목표:** 어셈블리 명령어(Instruction), 어셈블러 지시어(Directive), 레이블(Label)을 구분하고 Startup 코드를 해석한다.

## 1. Assembly란?

**어셈블리어(Assembly Language)**는 CPU의 기계어 명령과 밀접하게 대응하는 저수준 프로그래밍 언어이다.

```text
C / Rust 코드
      ↓ Compiler
Assembly (.s)
      ↓ Assembler
Object File (.o)
      ↓ Linker
ELF 실행 이미지
      ↓
MCU에서 기계어 실행
```

- **Assembly:** CPU 명령을 사람이 읽을 수 있는 형태로 표현
- **Assembler:** Assembly를 기계어로 변환하는 프로그램
- **Instruction:** CPU가 실제로 실행하는 명령
- **Directive:** 어셈블러가 코드 생성 시 처리하는 지시문
- **Label:** 코드나 데이터의 위치를 나타내는 이름

※ C/Rust 컴파일러가 항상 `.s` 파일을 생성하는 것은 아니며, 직접 오브젝트 파일을 생성할 수도 있다.

---

## 2. Instruction vs Directive vs Label

```asm
.syntax unified
.cpu cortex-m4
.thumb

.section .text
.global example

example:
    movs r0, #10
    adds r0, r0, #5
    bx lr
```

| 구분 | 예시 | 역할 |
|---|---|---|
| Directive | `.thumb`, `.section` | 어셈블러에 설정 전달 |
| Instruction | `MOVS`, `ADDS`, `BX` | CPU가 실제 실행 |
| Label | `example:` | 코드 시작 위치에 이름 지정 |
| Register | `R0`, `LR` | CPU 내부 데이터 저장 공간 |
| Immediate | `#10`, `#5` | 명령어에 직접 지정한 상수 |

**핵심:** Directive는 빌드할 때 처리하고, Instruction은 MCU가 실행할 때 동작한다.

---

## 3. 주요 어셈블러 지시어 (Assembly Directives)

Startup의 `startup_stm32f429zitx.s` 파일에서 사용하는 대표적인 지시어이다.

| 지시어 | 의미 | 역할 |
|---|---|---|
| `.syntax unified` | 통합 어셈블리 문법 | ARM Unified Assembly 문법 사용 |
| `.cpu cortex-m4` | CPU 지정 | Cortex-M4 명령어 사용 |
| `.fpu fpv4-sp-d16` | FPU 지정 | 단정밀도 FPU 명령어 허용 |
| `.thumb` | Thumb 모드 | Thumb/Thumb-2 명령어 생성 |
| `.section` | 영역 지정 | 코드·데이터 Section 선택 |
| `.global` | 전역 심볼 | 다른 파일에서도 심볼 참조 가능 |
| `.type` | 심볼 타입 | 함수 또는 데이터 심볼 구분 |
| `.word` | 32비트 데이터 | 4바이트 값 배치 |
| `.weak` | 약한 심볼 | 사용자 정의 심볼로 대체 가능 |
| `.thumb_set` | Thumb 별칭 | Thumb 함수 심볼의 별칭 설정 |
| `.thumb_func` | Thumb 함수 표시 | 심볼이 Thumb 함수임을 지정 |
| `.size` | 심볼 크기 | 함수·객체 크기 지정 |
| `.align` | 메모리 정렬 | 지정된 경계로 정렬 |

### 3.1 CPU 및 Thumb 설정

```asm
.syntax unified
.cpu cortex-m4
.fpu fpv4-sp-d16
.thumb
```

- `.cpu`: 대상 CPU 지정
- `.fpu`: 사용 가능한 FPU 명령어 지정
- `.thumb`: Thumb 명령어 인코딩 사용

**Thumb:** ARM Cortex-M4가 사용하는 명령어 형식으로, 16비트와 32비트 길이의 명령어를 지원한다. CPU 자체는 32비트이다.

### 3.2 Section 설정

```asm
.section .isr_vector,"a",%progbits
```

- `.section`: 현재 데이터를 배치할 Section 지정
- `.isr_vector`: 벡터 테이블 Section 이름
- `"a"`: 메모리에 배치할 Section임을 표시
- `%progbits`: 실제 데이터가 들어 있는 Section

### 3.3 심볼 정의

```asm
.global Reset_Handler
.type Reset_Handler, %function
.thumb_func

Reset_Handler:
```

- `.global`: 다른 파일에서도 참조할 수 있게 공개
- `.type`: 함수 심볼로 지정
- `.thumb_func`: Thumb 함수임을 표시
- `Reset_Handler:`: 함수 시작 위치를 나타내는 레이블

### 3.4 32비트 데이터 배치

```asm
.word _estack
.word Reset_Handler
```

`.word`는 현재 Section에 32비트 데이터를 배치한다.

- `_estack`: 초기 Stack Pointer 값
- `Reset_Handler`: Reset Handler의 함수 주소

**주의:** `.word Reset_Handler`는 함수를 실행하는 것이 아니라 해당 함수의 주소값을 저장한다.

### 3.5 Weak Handler

```asm
.weak USART3_IRQHandler
.thumb_set USART3_IRQHandler, Default_Handler
```

- `.weak`: 동일한 이름의 강한 정의가 있으면 대체 가능
- `.thumb_set`: 기본적으로 Default_Handler를 가리키도록 별칭 설정

---

## 4. 주요 어셈블리 명령어 (Assembly Instructions)

Instruction은 **CPU가 직접 실행하는 명령어**이다.

### 4.1 데이터 이동 및 메모리 접근

| 명령어 | 영어 원문 | 역할 |
|---|---|---|
| `MOV` | Move | 레지스터 간 값 이동 |
| `MOVS` | Move and update flags | 값 이동 및 조건 플래그 갱신 |
| `LDR` | Load Register | 메모리 값 읽기 |
| `STR` | Store Register | 메모리에 값 저장 |
| `LDRB` | Load Register Byte | 1바이트 읽기 |
| `STRB` | Store Register Byte | 1바이트 저장 |
| `PUSH` | Push | 레지스터 값을 Stack에 저장 |
| `POP` | Pop | Stack에서 레지스터 값 복원 |

**예시**

```asm
movs r0, #10
ldr  r1, =0x20000000
str  r0, [r1]
ldr  r2, [r1]
```

동작:

1. R0에 10 저장
2. R1에 RAM 주소 저장
3. R0의 값 10을 RAM에 기록
4. RAM의 값을 읽어 R2에 저장

`ldr r1, =주소`는 주소값을 로드하는 의사 명령어이고, `ldr r2, [r1]`은 해당 주소의 메모리를 실제로 읽는 명령어이다.

### 4.2 산술 및 비트 연산

| 명령어 | 역할 |
|---|---|
| `ADD` / `ADDS` | 덧셈 |
| `SUB` / `SUBS` | 뺄셈 |
| `MUL` | 곱셈 |
| `AND` | 비트 AND |
| `ORR` | 비트 OR |
| `EOR` | 비트 XOR |
| `BIC` | 특정 비트 클리어 |
| `LSL` | 왼쪽 시프트 |
| `LSR` | 논리적 오른쪽 시프트 |

```asm
movs r0, #10
movs r1, #20
adds r2, r0, r1
```

**결과:** R2 = 30

### 4.3 비교 및 분기

| 명령어 | 의미 |
|---|---|
| `CMP` | 두 값을 비교하고 조건 플래그 설정 |
| `B` | 무조건 분기 |
| `BEQ` | 같으면 분기 (Z=1) |
| `BNE` | 다르면 분기 (Z=0) |
| `BCS` | Carry Set이면 분기 |
| `BCC` | Carry Clear이면 분기 |
| `BL` | 함수 호출 및 복귀 주소 저장 |
| `BX LR` | 일반적인 함수 복귀 |

```asm
movs r0, #5
movs r1, #5

cmp r0, r1
beq Equal

Equal:
    movs r2, #1
```

`CMP`는 두 값을 비교하고, `BEQ`는 두 값이 같으면 지정된 레이블로 분기한다.

---

## 5. Startup에서 실제로 사용하는 어셈블리

### 5.1 Vector Table

```asm
.section .isr_vector,"a",%progbits

.word _estack
.word Reset_Handler
.word NMI_Handler
.word HardFault_Handler
```

**역할:** Reset 및 Exception 발생 시 사용할 주소를 Flash에 저장한다.

### 5.2 SystemInit 호출

```asm
Reset_Handler:
    bl SystemInit
```

**역할:** Reset_Handler에서 C로 구현된 `SystemInit()` 함수를 호출한다.

### 5.3 .data 복사

```asm
ldr r0, =_sdata
ldr r1, =_edata
ldr r2, =_sidata

CopyData:
    cmp r0, r1
    bcs ZeroBSS

    ldr r3, [r2]
    str r3, [r0]

    adds r0, r0, #4
    adds r2, r2, #4
    b CopyData
```

**역할:** Flash에 있는 초기값을 RAM의 `.data` 영역으로 복사한다.

| 명령어 | 동작 |
|---|---|
| `LDR` | 주소 및 데이터 읽기 |
| `STR` | RAM에 기록 |
| `ADDS` | 다음 주소로 이동 |
| `CMP / BCS` | 복사 종료 확인 |
| `B` | 반복 |

### 5.4 .bss 초기화

```asm
ZeroBSS:
    ldr r0, =_sbss
    ldr r1, =_ebss
    movs r2, #0

BSSLoop:
    cmp r0, r1
    bcs InitRuntime

    str r2, [r0]
    adds r0, r0, #4
    b BSSLoop
```

**역할:** `.bss` 메모리 영역을 0으로 초기화한다.

### 5.5 main() 호출

```asm
InitRuntime:
    bl __libc_init_array
    bl main
```

**역할:** C/C++ 런타임 초기화 후 `main()` 함수를 실행한다.

※ 위 `.data`, `.bss` 코드는 4바이트 정렬을 가정한 학습용 예시이며 실제 Startup 파일과 구현이 다를 수 있다.

---

## 6. 레지스터와 기호 이해

### 주요 ARM 레지스터

| 레지스터 | 역할 |
|---|---|
| `R0~R3` | 함수 인자, 반환값, 임시 데이터 |
| `R4~R11` | 범용 레지스터 |
| `R12` | 임시 레지스터 |
| `SP (R13)` | Stack Pointer |
| `LR (R14)` | Link Register |
| `PC (R15)` | Program Counter |

### 어셈블리 문법 기호

| 표현 | 의미 |
|---|---|
| `#10` | 즉시값 10 |
| `r0` | CPU 레지스터 R0 |
| `[r0]` | R0가 가리키는 메모리 주소 |
| `= _sbss` | 심볼 주소를 로드하는 의사 명령어 문법 (`=_sbss`) |
| `Loop:` | 코드 위치를 나타내는 레이블 |
| `.word` | 4바이트 데이터 배치 |

**예시**

```asm
ldr r0, =_sbss
```

→ `.bss` 시작 주소를 R0에 로드

```asm
ldr r1, [r0]
```

→ R0가 가리키는 메모리에서 값을 읽어 R1에 저장

```asm
str r2, [r0]
```

→ R2의 값을 R0가 가리키는 메모리 주소에 저장

---

## 7. 핵심 요약

| 구분 | 대표 코드 | 역할 |
|---|---|---|
| Directive | `.section`, `.word`, `.global` | 어셈블러에 지시 |
| Instruction | `LDR`, `STR`, `MOVS`, `BL` | CPU가 실행 |
| Label | `Reset_Handler:`, `CopyData:` | 코드 위치 식별 |
| Register | `R0`, `SP`, `LR`, `PC` | CPU 내부 데이터 저장 |
| Linker Symbol | `_estack`, `_sdata`, `_sbss` | 메모리 주소 표현 |

**핵심:** Assembly 코드는 지시어, 명령어, 레이블, 심볼을 조합하여 작성한다.

- **Directive:** 코드를 어떻게 만들고 배치할 것인가?
- **Instruction:** CPU가 어떤 연산을 수행할 것인가?
- **Label:** 코드의 어느 위치인가?
- **Linker Symbol:** 메모리의 어느 주소인가?

STM32 Startup은 이러한 요소를 이용해 Vector Table을 정의하고, RAM을 초기화한 뒤 `main()`을 호출한다.



```
arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb \
    -c src/hello.s -o main.o && \
arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb \
    -nostdlib -T linker.ld main.o -o main.elf && \
qemu-system-arm -M mps2-an386 \
    -nographic -semihosting -kernel main.elf
```