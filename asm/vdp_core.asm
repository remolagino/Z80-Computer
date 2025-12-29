; V9938 Core functions


    IFNDEF __VDP_CORE__
    DEFINE __VDP_CORE__ 1

; V9938 Port definitions
VRAM_DATA EQU   0x40            ; PORT #0 - VRAM data port
VRAM_ADDR EQU   0x41            ; PORT #1 - VRAM Address 
VDP_STAT_REG EQU   0x41            ; PORT #1 - Status Register 
VDP_REG_SETUP EQU   0x41            ; PORT #1 - Register Setup

VDP_PAL_REG   EQU   0x42            ; PORT #2 - Palette Register port
VDP_REG_INDIR EQU   0x43            ; PORT #3 - Register Indirect Addressing 

COLOR_TABLE_BASE_ADDR EQU 0x0A00 ; Base address of color table in VRAM
PATTERN_LAYOUT_TABLE_BASE_ADDR EQU 0x0000 ; Base address of pattern name table in VRAM



Write_Reg: ; REG number in C, Value in A
    PUSH AF
    ;PUSH BC
    ;DI
    OUT (VDP_REG_SETUP), A
    LD A, C
    OR 0x80
    ;EI
    OUT (VDP_REG_SETUP), A
    ;POP BC
    POP AF
    RET

Writereg_Indirect: ; REG number in A (add +128 for no auto increment), Values in (HL), number of values in B
    LD C, 17 ; 17: indirect register number
    CALL Write_Reg
    LD C, VDP_REG_INDIR        ; you can also write ld bc,#nn9B, which is faster
    OTIR
    RET

Set_VRAM_Address: ; Set VRAM address from HL
    PUSH AF
    PUSH BC
    PUSH HL
    LD A, H
    RLCA
    RLCA
    AND 0x03 ; keep only A14 et A15 in the 2 rightmost positions

    LD C, 14
;    LD A, 0x00 ; Set Address A16-A15-A14
    CALL Write_Reg
    LD A, L
;    LD A, 0x00 ; Set Address A7..A0

    OUT (VRAM_ADDR), A

    LD A, H
    AND 0x3F ; keep only A13..A8
    OR 0x40 ; data write mode
    OUT (VRAM_ADDR), A
    POP HL
    POP BC
    POP AF
    RET

Set_Blink: ; set or unset blink at address HL (in pattern layout) based on C value (0: unset, 1: set)
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL

    LD A, L
    AND 0x07 ; get the 3 lowest bits to shift the blink to the right position
    ADD A, 1; make sure there is only one shift when offset is 0
    LD B, A ; save shift count in B

    SRL H ; divide HL by 8 to get the index 
    RR L  ; in the color table of the byte 
    SRL H ; containing the char to blink
    RR L
    SRL H
    RR L 

    LD DE, COLOR_TABLE_BASE_ADDR
    ADD HL, DE ; compute the address in VRAM of the color byte
    CALL Set_VRAM_Address

    LD A, C
.shift_loop:  ; Shift the blink  to the right position
    RRCA
    DJNZ .shift_loop
    OUT (VRAM_DATA), A

    POP HL
    POP DE
    POP BC
    POP AF
    RET


putC_VRAM: ; write at adress HL in Pattern layout table the character in reg A
    PUSH AF
    PUSH DE
    PUSH HL

    LD DE, PATTERN_LAYOUT_TABLE_BASE_ADDR
    ADD HL, DE ; compute the address in VRAM of the pattern layout position
    CALL Set_VRAM_Address

    OUT (VRAM_DATA), A

    POP HL
    POP DE
    POP AF
    RET
    
    ENDIF