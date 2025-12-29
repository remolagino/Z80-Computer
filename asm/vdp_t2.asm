; V9938 Blue Screen Test Program for Z80

    MACRO NOP_7
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
    ENDM

        ORG     0x5000          ; Start address

; V9938 Port definitions
VRAM_DATA EQU   0x40            ; PORT #0 - VRAM data port
VRAM_ADDR EQU   0x41            ; PORT #1 - VRAM Address 
VDP_STAT_REG EQU   0x41            ; PORT #1 - Status Register 
VDP_REG_SETUP EQU   0x41            ; PORT #1 - Register Setup

VDP_PAL_REG   EQU   0x42            ; PORT #2 - Palette Register port (MODE1)
VDP_REG_INDIR EQU   0x43            ; PORT #3 - Register Indirect Addressing 

  include "jumpTable.inc"


START:
    CALL    VDP_INIT        ; Initialize V9938
    LD HL, Msg_VDP_T2_Init
    CALL PRINT_STRING

    CALL INIT_PATTERN_GENERATOR_TABLE
    LD HL, Msg_VDP_Pattern_Generator_Init
    CALL PRINT_STRING

;    CALL READ_STATUS


    CALL INIT_PATTERN_LAYOUT_TABLE
    LD HL, Msg_VDP_Pattern_Layout_Init
    CALL PRINT_STRING
    
    CALL INIT_COLOR_TABLE
    LD HL, Msg_VDP_ColorMap_Init
    CALL PRINT_STRING

    CALL WRITE_RAM
;    CALL READ_RAM
;    CALL SET_BLINK

    RET                     ; or HALT

READ_STATUS:
    PUSH AF
    PUSH BC
    LD C, 15 ; Status register
    LD A, 0 ; status register to read
    CALL WRITE_REG
    IN A, (VDP_STAT_REG)
    CALL HEX2STR
    LD A, '-'
    CALL SENDCHAR_A
    LD C, 15 ; Status register
    LD A, 1 ; status register to read
    CALL WRITE_REG
    IN A, (VDP_STAT_REG)
    CALL HEX2STR
     LD A, '-'
    CALL SENDCHAR_A
    LD C, 15 ; Status register
    LD A, 2 ; status register to read
    CALL WRITE_REG
    IN A, (VDP_STAT_REG)
    CALL HEX2STR
    LD A, '-'
    CALL SENDCHAR_A
    LD C, 15 ; Status register
    LD A, 3 ; status register to read
    CALL WRITE_REG
    IN A, (VDP_STAT_REG)
    CALL HEX2STR
    LD A, '-'
    CALL SENDCHAR_A
    LD C, 15 ; Status register
    LD A, 4 ; status register to read
    CALL WRITE_REG
    IN A, (VDP_STAT_REG)
    CALL HEX2STR
    LD A, '-'
    CALL SENDCHAR_A
    LD C, 15 ; Status register
    LD A, 5 ; status register to read
    CALL WRITE_REG
    IN A, (VDP_STAT_REG)
    CALL HEX2STR
    LD A, '-'
    CALL SENDCHAR_A
    LD C, 15 ; Status register
    LD A, 6 ; status register to read
    CALL WRITE_REG
    IN A, (VDP_STAT_REG)
    CALL HEX2STR
    LD A, '-'
    CALL SENDCHAR_A
    LD C, 15 ; Status register
    LD A, 7 ; status register to read
    CALL WRITE_REG
    IN A, (VDP_STAT_REG)
    CALL HEX2STR
    LD A, '-'
    CALL SENDCHAR_A
    LD C, 15 ; Status register
    LD A, 8 ; status register to read
    CALL WRITE_REG
    IN A, (VDP_STAT_REG)
    CALL HEX2STR
    LD A, '-'
    CALL SENDCHAR_A
    LD C, 15 ; Status register
    LD A, 9 ; status register to read
    CALL WRITE_REG
    IN A, (VDP_STAT_REG)
    CALL HEX2STR
    LD HL, CR_LF
    CALL PRINT_STRING
    POP BC
    POP AF
    RET


VDP_INIT:
    LD      C, 0        ; R#0: Mode set register
    LD      A, 0x04 ;
    CALL    WRITE_REG

    LD      C, 1
    LD      A, 0x50     ; BL:screen enabled, M1: Mode Text 1 or 2
    CALL    WRITE_REG

    LD      C, 8
    LD      A, 0x0A     ; VR: VRAM 64k*4b - sprite disabled
    CALL    WRITE_REG

    LD      C, 9
    LD      A, 0x82     ; LN bit set (8x) - RGB output : NTSC x0, PAL x2
    CALL    WRITE_REG

    LD      C, 2
    LD      A, 0x03     ; Pattern Name Table at 0x0000
    CALL    WRITE_REG

    LD      C, 3
    LD      A, 0x2F     ; Color Table at 0x0A00
    CALL    WRITE_REG
    LD      C, 10
    LD      A, 0x00     ; Color Table at 0x0A00
    CALL    WRITE_REG

    LD      C, 4
    LD      A, 0x02     ; Pattern Generator at 0x0800
    CALL    WRITE_REG

    CALL INIT_PALETTE

    LD      C, 7
    LD      A, 0xF4         ; Text color: white (F) on blue (4)
    CALL    WRITE_REG

    ; R#12: Text blink rate and color
    LD C, 12
    LD A, 0x4F
    CALL WRITE_REG

    ; R#13: Blink period
    LD C, 13  
    LD A, 0x23
    CALL WRITE_REG

    ; R#19: Interrupt line position (set to avoid issues)
    LD C, 19
    LD A, 0x00
    CALL WRITE_REG

    LD C, 45
    LD A, 0x00 ; Video RAM standard
    CALL WRITE_REG

    RET

INIT_PALETTE:
    PUSH AF
    PUSH BC
    PUSH HL

    LD HL, COLOR_PALETTE
    LD B, 16 ; 16 colors
.paletteLoop:
    LD C, 16
    LD A, (HL) ; palette idx 4
    CALL WRITE_REG
    INC HL
    LD A, (HL)
    OUT (VDP_PAL_REG), A
    INC HL
    LD A, (HL)
    OUT (VDP_PAL_REG), A
    INC HL
    DJNZ .paletteLoop
    POP HL
    POP BC
    POP AF
    RET

WRITE_REG: ; REG number in C, Value in A
    PUSH AF
    ;DI
    OUT (VDP_REG_SETUP), A
    LD A, C
    OR 0x80
    ;EI
    OUT (VDP_REG_SETUP), A
    POP AF
    RET

WRITE_REG_INDIRECT: ; REG number in A (add +128 for no auto increment), Values in (HL), number of values in B
    LD C, 17 ; 17: indirect register number
    CALL WRITE_REG
    LD C, VDP_REG_INDIR        ; you can also write ld bc,#nn9B, which is faster
    OTIR
    RET

SET_VRAM_ADDR: ; Set VRAM address from HL - WRITE MODE
    PUSH AF
    PUSH BC
    PUSH HL
    LD A, H
    RLCA
    RLCA
    AND 0x03 ; keep only A14 et A15 in the 2 rightmost positions

    LD C, 14
;    LD A, 0x00 ; Set Address A16-A15-A14
    CALL WRITE_REG
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

INIT_PATTERN_LAYOUT_TABLE: ; write at adress 0x0000
    PUSH AF
    PUSH BC
    PUSH HL

    LD HL, 0x0000
    CALL SET_VRAM_ADDR

    LD HL, 0x0B0D ; number of bytes to write (0x0B0D = 2821 bytes)
.loop:
    LD A, 0x20 ; value to write to initialize VRAM
    OUT (VRAM_DATA), A
    NOP_7
    DEC HL
    LD A, H
    OR L
    JP NZ, .loop
.loopEnd:
    POP HL
    POP BC
    POP AF
    RET

INIT_COLOR_TABLE: ; write at adress 0x0000
    PUSH AF
    PUSH BC
    PUSH HL
    
    LD HL, 0x0A00
    CALL SET_VRAM_ADDR

    LD HL, 0x0150 ; number of bytes to write (0x0150 = 336 bytes)
.loop:
    LD A, 0x00 ; value to write to initialize COLOR MAP
    OUT (VRAM_DATA), A
    NOP_7
    DEC HL
    LD A, H
    OR L
    JP NZ, .loop
.loopEnd:
    POP HL
    POP BC
    POP AF
    RET

INIT_PATTERN_GENERATOR_TABLE:
    PUSH AF
    PUSH BC
    PUSH HL

    LD HL, 0x1000 ; start of the pattern generator table
    CALL SET_VRAM_ADDR

    LD HL, Pattern_Generator_Table
    LD B, 0x00 ; character index
    LD C, 0x08; number of bytes per character
.loop:
    LD A, (HL)
    OUT (VRAM_DATA), A
    NOP_7
    INC HL
    DJNZ .loop
    DEC C
    LD A, C
    OR A
    JP NZ, .loop
.loopEnd:
    POP HL
    POP BC
    POP AF
    RET


WRITE_RAM: ; write at adress 0x0000
    PUSH AF
    PUSH BC
    PUSH HL

    LD HL, 0x0000
    CALL SET_VRAM_ADDR

;    LD HL, Msg_RamTest
    LD HL, Msg_VDP_T2_Init
.loop:
    LD A, (HL)
    OR A
    JP Z, .loopEnd
    OUT (VRAM_DATA), A
    NOP_7
    INC HL
    JP  .loop
.loopEnd:
    POP HL
    POP BC
    POP AF
    RET
    
READ_RAM:
    PUSH AF
    PUSH BC
    PUSH HL
    LD C, 14
    LD A, 0x00 ; Set Address A16-A15-A14
    CALL WRITE_REG
    LD A, 0x00 ; Set Address A7..A0
    OUT (VRAM_ADDR), A
    LD A, 0x00 & 0xBF ; Set Address A13..A8 + data read mode
    OUT (VRAM_ADDR), A
 
    NOP
    NOP
    ; IN A, (VRAM_DATA) ; Dummy Read to clear buffer or whatever
    ; NOP
    ; CALL HEX2STR
    ; LD HL, CR_LF
    ; CALL PRINT_STRING
    NOP
    NOP

    LD B, 0x00
.loop:
    IN A, (VRAM_DATA)
    CP 0x20
    JP C, .non_printable
.printable:
    CALL SENDCHAR_A
    JP .continue
.non_printable:
;    LD A, 0xA4
;    CALL SENDCHAR_A
     CALL HEX2STR
     LD A, '-'
     CALL SENDCHAR_A
.continue:
 ;   CALL HEX2STR
 ;   LD A, '-'
 ;   CALL SENDCHAR_A
;    CALL Delay
    DJNZ .loop

    LD HL, CR_LF
    CALL PRINT_STRING

    POP HL
    POP BC
    POP AF
    RET



COLOR_PALETTE:
    DB 0x00, 0x00, 0x00 ; Color 0: Transparent
    DB 0x01, 0x00, 0x00 ; Color 1: Black
    DB 0x02, 0x11, 0x06 ; Color 2: Green
    DB 0x03, 0x44, 0x07 ; Color 3: Light Green
    DB 0x04, 0x17, 0x01 ; Color 4: Dark Blue
    DB 0x05, 0x27, 0x03 ; Color 5: Light Blue   
    DB 0x06, 0x51, 0x01 ; Color 6: Dark Red 
    DB 0x07, 0x27, 0x06 ; Color 7: Cyan
    DB 0x08, 0x71, 0x01 ; Color 8: Red
    DB 0x09, 0x73, 0x03 ; Color 9: Light Red
    DB 0x0A, 0x61, 0x06 ; Color 10: Dark Yellow
    DB 0x0B, 0x70, 0x03 ; Color 11: Orange
    DB 0x0C, 0x11, 0x04 ; Color 12: Dark Green  
    DB 0x0D, 0x65, 0x02 ; Color 13: Magenta
    DB 0x0E, 0x55, 0x05 ; Color 14: Grey
    DB 0x0F, 0x77, 0x07 ; Color 15: White

CR_LF:
    DB 0x0A, 0x0D, 0x00 ; Carriage return + line feed

Msg_VDP_T2_Init:
    DB "V9938 - TEXT2 Mode Initialised", 0x0D, 0x0A,0x00 
Msg_VDP_Pattern_Generator_Init:
    DB "V9938 - Pattern Generator Initialised", 0x0D, 0x0A,0x00 
Msg_VDP_Pattern_Layout_Init:
    DB "V9938 - ColorMap Initialised", 0x0D, 0x0A,0x00 
Msg_VDP_ColorMap_Init:
    DB "V9938 - ColorMap Initialised", 0x0D, 0x0A,0x00 


    include "../Video Card/char_pattern_table.inc"
    
    END