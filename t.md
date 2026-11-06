# ARM Cortex-M4 레지스터와 Assembly 메모리 접근

대상 MCU: STM32F429ZI (ARM Cortex-M4)

## 1. CPU 레지스터(Register)란?

레지스터는 CPU 내부에 존재하는 작은 고속 저장 공간으로, 연산에 필요한 데이터, 메모리 주소, 계산 결과 등을 임시로 저장한다.

C언어의 변수와 비슷하게 값을 저장할 수 있지만, `R0`, `R1` 등은 CPU 하드웨어에 미리 정의된 이름이다.

### ARM Cortex-M4 주요 레지스터

| 레지스터 | 이름 | 역할 |
|---|---|---|
| R0~R3 | 범용 레지스터 | 데이터 저장, 함수 인자 전달, 반환값 |
| R4~R11 | 범용 레지스터 | 데이터 저장, 연산, 함수 호출 중 값 유지 |
| R12 | 범용 레지스터 | 임시 데이터 저장 |
| R13 | SP (Stack Pointer) | 스택 주소 관리 |
| R14 | LR (Link Register) | 함수 복귀 주소 저장 |
| R15 | PC (Program Counter) | 실행 중인 명령어 위치 관리 |

- R0~R12: 일반 목적 레지스터 13개
- R13~R15: 특수한 역할을 가진 레지스터 3개
- 총 16개의 기본 CPU 레지스터
- 각 레지스터 크기: 32비트

그 외 `xPSR`, `CONTROL`, `PRIMASK`, `BASEPRI`, `FAULTMASK` 등 특수 레지스터가 존재한다.

### CPU 레지스터와 주변장치 레지스터의 차이

| 구분 | CPU 레지스터 | 주변장치 레지스터 |
|---|---|---|
| 위치 | CPU 내부 | MCU 주변장치 |
| 예시 | R0, R1, R2, SP, PC | RCC_AHB1ENR, GPIOA_MODER |
| 역할 | 계산, 주소 및 데이터 저장 | 클럭, GPIO, UART 등 하드웨어 제어 |
| 접근 | MOV, ADD 등 | 주소를 통한 LDR, STR |

**핵심:** `R1`은 CPU 내부 레지스터이고, `RCC_AHB1ENR`은 메모리 맵에 배치된 하드웨어 제어 레지스터이다.

---

## 2. ARM Assembly 기본 명령어

| 명령어 | 의미 | 예시 |
|---|---|---|
| MOV | 값 복사 | `mov r1, #10` |
| MOVW | 하위 16비트 설정 | `movw r1, #0x3800` |
| MOVT | 상위 16비트 설정 | `movt r1, #0x4002` |
| LDR | 메모리 데이터 읽기 | `ldr r2, [r1]` |
| STR | 메모리에 데이터 쓰기 | `str r2, [r1]` |
| ADD | 덧셈 | `add r3, r1, r2` |
| SUB | 뺄셈 | `sub r3, r1, r2` |
| ORR | 비트 OR 연산 | `orr r2, r2, #1` |
| BIC | 지정한 비트 클리어 | `bic r2, r2, #1` |
| B | 분기 | `b loop` |
| BL | 함수 호출 | `bl function` |
| BX | 레지스터 주소로 분기 | `bx lr` |

### Assembly 문법

```asm
mov r1, #10
```

- `mov`: 명령어
- `r1`: 목적지 레지스터
- `#10`: 즉시값(Immediate Value)

```asm
ldr r2, [r1, #0x30]
```

- `ldr`: 메모리 읽기
- `r2`: 읽은 데이터를 저장할 CPU 레지스터
- `r1`: 기준 주소를 가진 CPU 레지스터
- `#0x30`: 기준 주소에 더할 오프셋
- `[]`: 계산한 주소에 있는 메모리 데이터에 접근

---

## 3. RCC 레지스터 주소 이해

STM32F429ZI의 RCC 시작 주소는 다음과 같다.

```c
#define RCC_BASE 0x40023800UL
```

RCC 내부에는 여러 하드웨어 레지스터가 존재한다.

| 레지스터 | Offset | 실제 주소 |
|---|---|---|
| RCC_CR | 0x00 | 0x40023800 |
| RCC_PLLCFGR | 0x04 | 0x40023804 |
| RCC_CFGR | 0x08 | 0x40023808 |
| RCC_AHB1ENR | 0x30 | 0x40023830 |
| RCC_APB1ENR | 0x40 | 0x40023840 |

**실제 주소 = Base Address + Offset**

예시:

```text
RCC_BASE      = 0x40023800
Offset        = 0x00000030
--------------------------------
RCC_AHB1ENR   = 0x40023830
```

---

## 4. LDR 명령어 이해

### 4.1 주소값을 CPU 레지스터에 저장

```asm
ldr r1, =0x40023800
```

실행 결과:

```text
R1 = 0x40023800
```

`=값`은 상수를 로드하도록 요청하는 어셈블러 의사 명령어다.

아직 RCC 하드웨어 레지스터를 읽은 것은 아니다.

### 4.2 실제 하드웨어 레지스터 읽기

```asm
ldr r2, [r1, #0x30]
```

실행 과정:

```text
R1 = 0x40023800
         +
       0x30
         |
         v
주소 = 0x40023830
         |
         v
RCC_AHB1ENR의 현재 값 읽기
         |
         v
R2에 저장
```

예를 들어 RCC_AHB1ENR의 현재 값이 `0x00000004`라면:

```text
R1 = 0x40023800
R2 = 0x00000004
```

R2에는 주소가 아닌 해당 주소의 데이터가 저장된다.

### 4.3 LDR과 STR 차이

| 명령어 | 역할 |
|---|---|
| `ldr r1, =0x40023800` | 주소값을 R1에 저장 |
| `ldr r2, [r1]` | R1이 가리키는 주소의 데이터 읽기 |
| `ldr r2, [r1, #0x30]` | R1+0x30 주소의 데이터 읽기 |
| `str r2, [r1, #0x30]` | R2 데이터를 R1+0x30 주소에 쓰기 |

---

## 5. 실습: GPIOA 클럭 활성화

목표: STM32F429ZI의 RCC_AHB1ENR 레지스터 bit 0(GPIOAEN)을 1로 설정한다.

### ARM Assembly

```asm
.syntax unified
.cpu cortex-m4
.thumb

.equ RCC_BASE, 0x40023800

.global gpio_clock_enable
.type gpio_clock_enable, %function
.thumb_func

gpio_clock_enable:
    ldr r1, =RCC_BASE     @ 1. RCC_BASE 주소 로드

    ldr r2, [r1, #0x30]  @ 2. RCC_AHB1ENR 값 읽기

    orr r2, r2, #1       @ 3. bit 0을 1로 설정

    str r2, [r1, #0x30]  @ 4. 변경값 저장

    bx lr                @ 5. 호출한 함수로 복귀
```

### 실행 과정

**① RCC 주소 준비**

```asm
ldr r1, =0x40023800
```

결과:

```text
R1 = 0x40023800
```

**② RCC_AHB1ENR 읽기**

```asm
ldr r2, [r1, #0x30]
```

예를 들어 초기값이 0이라고 가정하면:

```text
R2 = 0x00000000
```

**③ GPIOAEN 비트 설정**

```asm
orr r2, r2, #1
```

OR 연산:

```text
  00000000
| 00000001
----------
  00000001
```

결과:

```text
R2 = 0x00000001
```

이때 변경된 값은 아직 CPU 내부 R2에만 존재한다.

**④ 하드웨어 레지스터에 기록**

```asm
str r2, [r1, #0x30]
```

결과:

```text
RCC_AHB1ENR bit 0 = 1
         |
         v
GPIOA Clock Enable
```

### C언어와 비교

```c
#include <stdint.h>

#define RCC_BASE 0x40023800UL

#define RCC_AHB1ENR \
    (*(volatile uint32_t *)(RCC_BASE + 0x30UL))

void gpio_clock_enable(void)
{
    RCC_AHB1ENR |= (1U << 0);
}
```

두 코드는 동일하게 GPIOA의 클럭을 활성화한다.

**주의:** 실제로 C에서 Assembly 함수를 호출할 경우에는 레지스터 사용 규약을 고려해야 한다. 위 함수는 R1, R2만 사용하며, 이들은 호출자가 보존을 기대하지 않는 레지스터다.

---

## 6. MOVW / MOVT를 이용한 32비트 주소 저장

다음 두 명령어로 32비트 주소를 직접 구성할 수도 있다.

```asm
movw r1, #0x3800
movt r1, #0x4002
```

```text
R1 = 0x40023800

상위 16비트 | 하위 16비트
  0x4002    |   0x3800
    MOVT    |    MOVW
```

다음 코드와 최종 R1 값이 같다.

```asm
ldr r1, =0x40023800
```

차이는 `MOVW/MOVT`가 실제 ARM 명령어인 반면, `LDR =상수`는 어셈블러가 적절한 명령어나 리터럴 풀로 변환하는 의사 명령어라는 것이다.

---

## 7. 핵심 암기

1. `R0~R15`는 CPU 내부 레지스터이다.
2. `RCC_AHB1ENR`은 MCU의 주변장치 레지스터이다.
3. `RCC_BASE`는 RCC의 시작 주소이다.
4. `Offset`을 더하면 특정 주변장치 레지스터의 주소를 얻는다.
5. `LDR =값`은 상수값을 CPU 레지스터에 로드한다.
6. `LDR [주소]`는 해당 주소의 데이터를 읽는다.
7. `ORR`는 비트 OR 연산을 수행한다.
8. `STR`은 데이터를 메모리 또는 주변장치 레지스터에 기록한다.

**가장 중요한 실행 흐름**

```text
주소 준비
   ↓
LDR (하드웨어 레지스터 읽기)
   ↓
ORR / BIC (비트 수정)
   ↓
STR (하드웨어 레지스터 쓰기)
   ↓
주변장치 동작 변경
```

이 과정을 Read-Modify-Write(RMW)라고 한다. 일부 하드웨어 레지스터에는 별도의 쓰기 규칙이나 부작용이 있으므로, 항상 같은 RMW 방식을 사용할 수 있는 것은 아니다.