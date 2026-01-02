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

VRAM_READ_MODE EQU 0x00
VRAM_WRITE_MODE EQU 0x40

PATTERN_LAYOUT_TABLE_BASE_ADDR EQU 0x0000 ; Base address of pattern name table in VRAM
COLOR_TABLE_BASE_ADDR EQU 0x0A00 ; Base address of color table in VRAM
PATTERN_GENERATOR_BASE_ADDR EQU 0x1000 ; Base address of pattern generator table in VRAM


    MACRO NOP7
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    ENDM

VDP_Write_Reg: ; REG number in C, Value in A
    PUSH AF
    ;DI
    OUT (VDP_REG_SETUP), A
    LD A, C
    OR 0x80
    ;EI
    OUT (VDP_REG_SETUP), A
    POP AF
    RET

VDP_Write_Reg_Indirect: ; REG number in A (add +128 for no auto increment), Values in (HL), number of values in B
    LD C, 17 ; 17: indirect register number
    CALL VDP_Write_Reg
    LD C, VDP_REG_INDIR        ; you can also write ld bc,#nn9B, which is faster
    OTIR
    RET

VDP_Set_VRAM_Address: ; Set VRAM address from HL, READ or WRITE mode in A
    PUSH AF
    PUSH BC
    PUSH HL
    LD B, A ; save read/writemode in B
    LD A, H
    RLCA
    RLCA
    AND 0x03 ; keep only A14 et A15 in the 2 rightmost positions

    LD C, 14
    CALL VDP_Write_Reg
    LD A, L
    OUT (VRAM_ADDR), A

    LD A, H
    AND 0x3F ; keep only A13..A8
    OR B     ; set read or write mode
;    OR 0x40 ; data write mode
    OUT (VRAM_ADDR), A
    POP HL
    POP BC
    POP AF
    RET

VDP_Set_Blink: ; set or unset blink at address HL (in pattern layout) based on C value (0: unset, 1: set)
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
    LD A, VRAM_WRITE_MODE
    CALL VDP_Set_VRAM_Address

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


VDP_putC_VRAM: ; write at adress HL in Pattern layout table the character in reg A
    PUSH AF
    PUSH DE
    PUSH HL

    LD DE, PATTERN_LAYOUT_TABLE_BASE_ADDR
    ADD HL, DE ; compute the address in VRAM of the pattern layout position

    PUSH AF
    LD A, VRAM_WRITE_MODE
    CALL VDP_Set_VRAM_Address
    POP AF

    OUT (VRAM_DATA), A

    POP HL
    POP DE
    POP AF
    RET

; Empty the screen by initializing pattern layout and color tables
; Position the cursor at top-left corner
VDP_Clear_Screen:
    CALL Init_Pattern_Layout_Table
    CALL Init_Color_Table
    LD HL, 0x0000
    RET

Init_Pattern_Layout_Table: ; write at adress 0x0000
    PUSH AF
    PUSH BC
    PUSH HL

    LD HL, PATTERN_LAYOUT_TABLE_BASE_ADDR
    LD A, VRAM_WRITE_MODE
    CALL VDP_Set_VRAM_Address
    LD HL, 80*27 ; number of bytes to write (0x0B0D = 2821 bytes)
.loop:
    LD A, ' ' ; value to write to initialize VRAM
    OUT (VRAM_DATA), A
    NOP7
    DEC HL
    LD A, H
    OR L
    JP NZ, .loop
.loopEnd:
    POP HL
    POP BC
    POP AF
    RET


Init_Color_Table: ;
    PUSH AF
    PUSH BC
    PUSH HL
    LD HL, COLOR_TABLE_BASE_ADDR
    LD A, VRAM_WRITE_MODE
    CALL VDP_Set_VRAM_Address

    LD HL, 270 ; number of bytes to write (0x0B0D = 2821 bytes)
.loop:
    LD A, 0x00 ; value to write to initialize VRAM
    OUT (VRAM_DATA), A
    NOP7
    DEC HL
    LD A, H
    OR L
    JP NZ, .loop
.loopEnd:
    POP HL
    POP BC
    POP AF
    RET

    
    ENDIF