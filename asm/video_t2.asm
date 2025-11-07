; V9938 Blue Screen Test Program for Z80


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
    LD HL, Msg_Video
    CALL PRINT_STRING

    CALL INIT_PATTERN_GENERATOR_TABLE
;    CALL CHECK_PATTERN

    LD HL, CR_LF
    CALL PRINT_STRING
    LD HL, CR_LF
    CALL PRINT_STRING

;    LD B, 20
;status_loop:
    CALL READ_STATUS
;    CALL Delay
;    DJNZ status_loop

    CALL INIT_PATTERN_LAYOUT_TABLE
    CALL INIT_COLOR_MAP
    CALL WRITE_RAM
;    CALL READ_RAM
    CALL SET_BLINK

    LD B, 0
.colorLoop:
    CALL RECEIVE_CHAR_A
    CP 'q'
    JP Z, .endLoop

    LD      C, 7
    LD      A, 0xF0         ; Text color: white (F) on blue (4)
    OR B
    CALL    WRITE_REG
    INC B
    LD A, B
    AND 0x0F
    LD B, A
    JP .colorLoop

.endLoop:

    RET                     ; or HALT

Msg_Video:
    DB "Video Init Done", 0x0D, 0x0A,0x00 

Delay:
    PUSH BC
    LD B, 255
.loop:
    NOP
    NOP
    DJNZ .loop
    POP BC
    RET

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
    LD C, 0 ; R#0: Mode set register
    LD A, 0x04 ;
    CALL WRITE_REG

    LD C, 1
    LD A, 0x50 ; BL:screen enabled, M1: Mode Text 1 or 2
    CALL WRITE_REG

    LD C, 8
    LD A, 0x0A ; VR: VRAM 64k*4b - sprite disabled
    CALL WRITE_REG

    LD C, 9
    LD A, 0x82 ; LN bit set (8x) - RGB output : NTSC x0, PAL x2
    CALL WRITE_REG

    LD      C, 2
    LD      A, 0x03         ; Pattern Name Table at 0x0000
    CALL    WRITE_REG

    LD      C, 3
    LD      A, 0x2F         ; Color Table at 0x0000
    CALL    WRITE_REG
    LD      C, 10
    LD      A, 0x00         ; Color Table at 0x0000
    CALL    WRITE_REG

    LD      C, 4
    LD      A, 0x02         ; Pattern Generator at 0x0800
    CALL    WRITE_REG

    CALL INIT_PALETTE

    LD      C, 7
    LD      A, 0xF4         ; Text color: white (F) on blue (4)
    CALL    WRITE_REG


    ; R#12: Text blink rate and color (often needed)
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

WRITE_REG_INDIRECT: ; REG number in A (add +128 for no auto increment), Values in (HL), number of values in B
    LD C, 17 ; 17: indirect register number
    CALL WRITE_REG

    LD C, VDP_REG_INDIR        ; you can also write ld bc,#nn9B, which is faster
    OTIR
    RET

INIT_PATTERN_LAYOUT_TABLE: ; write at adress 0x0000
    PUSH AF
    PUSH BC
    PUSH HL
    LD C, 14
    LD A, 0x00 ; Set Address A16-A15-A14
    CALL WRITE_REG
    LD A, 0x00 ; Set Address A7..A0
    OUT (VRAM_ADDR), A
    LD A, 0x00 | 0x40 ; Set Address A13..A8 + data write mode
    OUT (VRAM_ADDR), A

    LD HL, 0x0B0D ; number of bytes to write (0x0B0D = 2821 bytes)
.loop:
    LD A, 0x20 ; value to write to initialize VRAM
    OUT (VRAM_DATA), A
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    DEC HL
    LD A, H
    OR L
    JP NZ, .loop
.loopEnd:
    POP HL
    POP BC
    POP AF
    RET

INIT_COLOR_MAP: ; write at adress 0x0000
    PUSH AF
    PUSH BC
    PUSH HL
    LD C, 14
    LD A, 0x00 ; Set Address A16-A15-A14
    CALL WRITE_REG
    LD A, 0x00 ; Set Address A7..A0
    OUT (VRAM_ADDR), A
    LD A, 0x0A | 0x40 ; Set Address A13..A8 + data write mode
    OUT (VRAM_ADDR), A

    LD HL, 0x0150 ; number of bytes to write (0x0150 = 336 bytes)
.loop:
    LD A, 0x00 ; value to write to initialize COLOR MAP
    OUT (VRAM_DATA), A
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    DEC HL
    LD A, H
    OR L
    JP NZ, .loop
.loopEnd:
    POP HL
    POP BC
    POP AF
    RET

SET_BLINK:
    PUSH AF
    PUSH BC
    LD C, 14
    LD A, 0x00 ; Set Address A16-A15-A14
    CALL WRITE_REG
    LD A, 0x00 + 0x14 ; Set Address A7..A0
    OUT (VRAM_ADDR), A
    LD A, 0x0A | 0x40 ; Set Address A13..A8 + data write mode
    OUT (VRAM_ADDR), A
    LD A, 0xAA ; blink state of the 8 chars at this address
    OUT (VRAM_DATA), A
    POP BC
    POP AF
    RET

INIT_PATTERN_GENERATOR_TABLE:
    PUSH AF
    PUSH BC
    PUSH HL
    LD C, 14
    LD A, 0x00 ; Set Address A16-A15-A14
    CALL WRITE_REG
    LD A, 0x00 ; Set Address A7..A0
    OUT (VRAM_ADDR), A
    LD A, 0x10 | 0x40 ; Set Address A13..A8 (A12=1) + data write mode
    OUT (VRAM_ADDR), A

    LD HL, Pattern_Generator_Table
    LD B, 0x00 ; character index
    LD C, 0x08; number of bytes per character
.loop:
    LD A, (HL)
    OUT (VRAM_DATA), A
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
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
    LD C, 14
    LD A, 0x00 ; Set Address A16-A15-A14
    CALL WRITE_REG
    LD A, 0x00 ; Set Address A7..A0
    OUT (VRAM_ADDR), A
    LD A, 0x00 | 0x40 ; Set Address A13..A8 + data write mode
    OUT (VRAM_ADDR), A

    LD HL, Msg_RamTest
.loop:
    LD A, (HL)
    OR A
    JP Z, .loopEnd
    OUT (VRAM_DATA), A
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
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

CHECK_PATTERN:
    PUSH AF
    PUSH BC
    PUSH HL
    LD C, 14
    LD A, 0x00 ; Set Address A16-A15-A14
    CALL WRITE_REG
    LD A, 0x00 ; Set Address A7..A0
    OUT (VRAM_ADDR), A
    LD A, 0x08 & 0xBF ; Set Address A13..A8 + data read mode
    OUT (VRAM_ADDR), A
 
    NOP
    NOP
    IN A, (VRAM_DATA) ; Dummy Read to clear buffer or whatever
    NOP
    NOP

    LD B, 0x00
    ; add a 8 loop here using C inside the B loop to read each char bytes
.loop:
    LD C, 0x08
.small_loop:
    IN A, (VRAM_DATA)

    CALL HEX2STR
    LD A, '-'
    CALL SENDCHAR_A
    DEC C
    JP NZ, .small_loop
;    CALL Delay
    LD HL, CR_LF
    CALL PRINT_STRING
    LD A, B
    AND 0x0F
    CP 0x01
    JP NZ, .continue
    LD HL, CR_LF
    CALL PRINT_STRING   
.continue:
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
;    DB 0x0B, 0x64, 0x06 ; Color 11: Light Yellow
    DB 0x0C, 0x11, 0x04 ; Color 12: Dark Green  
    DB 0x0D, 0x65, 0x02 ; Color 13: Magenta
    DB 0x0E, 0x55, 0x05 ; Color 14: Grey
    DB 0x0F, 0x77, 0x07 ; Color 15: White

CR_LF:
    DB 0x0A, 0x0D, 0x00 ; Carriage return + line feed

Msg_RamTest:
    DB 0x82
    DB 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80,  0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80
    DB 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80,  0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80
    DB 0x80, 0x80, 0x80, 0x80, 0x80, 0x80
    DB 0x83
    DB 0x81, " C'est un succès !!                   ", 0x81
    DB 0x81, " Contenu de la pattern table :        ", 0x81
    DB 0x81, "                                      ", 0x81
    DB 0x81, " ", 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B, 0x2C, 0x2D, 0x2E, 0x2F
    DB 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E, 0x3F
    DB "     ", 0x81
    DB 0x81, "                                      ", 0x81
    DB 0x81, " ", 0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x4B, 0x4C, 0x4D, 0x4E, 0x4F
    DB 0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5A, 0x5B, 0x5C, 0x5D, 0x5E, 0x5F
    DB "     ", 0x81
    DB 0x81, "                                      ", 0x81
    DB 0x81, " ", 0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6A, 0x6B, 0x6C, 0x6D, 0x6E, 0x6F
    DB 0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7A, 0x7B, 0x7C, 0x7D, 0x7E, 0x7F
    DB "     ", 0x81
    DB 0x81, "                                      ", 0x81
    DB 0x81, " ", 0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x8A, 0x8B, 0x8C, 0x8D, 0x8E, 0x8F
    DB 0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9A, 0x9B, 0x9C, 0x9D, 0x9E, 0x9F
    DB "     ", 0x81
    DB 0x81, "                                      ", 0x81
    DB 0x81, " ", 0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6, 0xA7, 0xA8, 0xA9, 0xAA, 0xAB, 0xAC, 0xAD, 0xAE, 0xAF
    DB 0xB0, 0xB1, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6, 0xB7, 0xB8, 0xB9, 0xBA, 0xBB, 0xBC, 0xBD, 0xBE, 0xBF
    DB "     ", 0x81
    DB 0x81, "                                      ", 0x81
    DB 0x81, " ", 0xC0, 0xC1, 0xC2, 0xC3, 0xC4, 0xC5, 0xC6, 0xC7, 0xC8, 0xC9, 0xCA, 0xCB, 0xCC, 0xCD, 0xCE, 0xCF
    DB 0xD0, 0xD1, 0xD2, 0xD3, 0xD4, 0xD5, 0xD6, 0xD7, 0xD8, 0xD9, 0xDA, 0xDB, 0xDC, 0xDD, 0xDE, 0xDF
    DB "     ", 0x81
    DB 0x81, "                                      ", 0x81
    DB 0x81, " ", 0xE0, 0xE1, 0xE2, 0xE3, 0xE4, 0xE5, 0xE6, 0xE7, 0xE8, 0xE9, 0xEA, 0xEB, 0xEC, 0xED, 0xEE, 0xEF
    DB 0xF0, 0xF1, 0xF2, 0xF3, 0xF4, 0xF5, 0xF6, 0xF7, 0xF8, 0xF9, 0xFA, 0xFB, 0xFC, 0xFD, 0xFE, 0xFF
    DB "     ", 0x81
    DB 0x81, "                                      ", 0x81
    DB 0x81, " => Fin du test !!   ", 0x9C, "                ", 0x81
    DB 0x84
    DB 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80,  0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80
    DB 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80,  0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80
    DB 0x80, 0x80, 0x80, 0x80, 0x80, 0x80
    DB 0x85
    DB 0x00

    include "../Video Card/char_pattern_table.asm"
    
    END