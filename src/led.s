Reset_Handler:
    movw r1, #0x3800    @ 하위 16비트
    movt r1, #0x4002    @ 상위 16비트