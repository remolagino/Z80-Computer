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

;    LD B, 20
;status_loop:
    CALL READ_STATUS
;    CALL Delay
;    DJNZ status_loop

    CALL INIT_VRAM
    CALL WRITE_RAM
    CALL READ_RAM
    CALL WRITE_PATTERN
 ;   CALL CHECK_PATTERN

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
    LD C, 0
    LD A, 0x00
    CALL WRITE_REG

    LD C, 1
    LD A, 0x50 ; BL:screen enabled, M1: Mode Text 1
    CALL WRITE_REG

    LD      C, 2
    LD      A, 0x00         ; Pattern Name Table at 0x0000
    CALL    WRITE_REG
        
    LD      C, 4
    LD      A, 0x01         ; Pattern Generator at 0x0800
    CALL    WRITE_REG

    CALL DEFINE_PALETTE

    LD      C, 7
    LD      A, 0xF4         ; Text color: white (F) on blue (4)
    CALL    WRITE_REG

    LD C, 8
    LD A, 0x08 ; VR: VRAM 64k*4b
    CALL WRITE_REG

    LD C, 9
    LD A, 0x00 ; RGB output : NTSC 00, PAL 02
    CALL WRITE_REG

    ; R#12: Text blink rate and color (often needed)
    LD C, 12
    LD A, 0x00
    CALL WRITE_REG

    ; R#13: Blink period
    LD C, 13  
    LD A, 0x00
    CALL WRITE_REG

    ; R#19: Interrupt line position (set to avoid issues)
    LD C, 19
    LD A, 0x00
    CALL WRITE_REG

    LD C, 45
    LD A, 0x00 ; Video RAM standard
    CALL WRITE_REG

    RET

DEFINE_PALETTE:
    ; BLue in 4
    LD C, 16
    LD A, 0x04 ; palette idx 4
    CALL WRITE_REG
    LD A, 0x01
    OUT (VDP_PAL_REG), A
    LD A, 0x70
    OUT (VDP_PAL_REG), A
    ; White in F
    LD C, 16
    LD A, 0x0F ; palette idx 15
    CALL WRITE_REG
    LD A, 0x77
    OUT (VDP_PAL_REG), A
    LD A, 0x07
    OUT (VDP_PAL_REG), A
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

INIT_VRAM: ; write at adress 0x0000
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

    LD HL, 0x2000
.loop:
    LD A, 0xAF ; value to write to initialize VRAM
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

WRITE_PATTERN:
    PUSH AF
    PUSH BC
    PUSH HL
    LD C, 14
    LD A, 0x00 ; Set Address A16-A15-A14
    CALL WRITE_REG
    LD A, 0x00 ; Set Address A7..A0
    OUT (VRAM_ADDR), A
    LD A, 0x08 | 0x40 ; Set Address A13..A8 (A11=1) + data write mode
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
    LD A, 0x10 ; Set Address A7..A0
    OUT (VRAM_ADDR), A
    LD A, 0x00 | 0x40 ; Set Address A13..A8 + data write mode
    OUT (VRAM_ADDR), A

    LD HL, Msg_RamTest
.loop:
    LD A, (HL)
    OUT (VRAM_DATA), A
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
;    NOP
;    NOP
;    CALL Delay
    INC HL
    OR A
    JP NZ, .loop
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

CR_LF:
    DB 0x0A, 0x0D, 0x00 ; Carriage return + line feed

Msg_RamTest:
    DB "Ceci est un test de message écrit dans la mémoire", 0x0A, 0x0D
    DB "Et ça c'est la suite :"
;    DB 0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6, 0xA7, 0xA8, 0xA9, 0xAA, 0xAB, 0xAC, 0xAD, 0xAE, 0xAF
;    DB 0xB0, 0xB1, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6, 0xB7, 0xB8, 0xB9, 0xBA, 0xBB, 0xBC, 0xBD, 0xBE, 0xBF
;    DB 0xC0, 0xC1, 0xC2, 0xC3, 0xC4, 0xC5, 0xC6, 0xC7, 0xC8, 0xC9, 0xCA, 0xCB, 0xCC, 0xCD, 0xCE, 0xCF
;    DB 0xD0, 0xD1, 0xD2, 0xD3, 0xD4, 0xD5, 0xD6, 0xD7, 0xD8, 0xD9, 0xDA, 0xDB, 0xDC, 0xDD, 0xDE, 0xDF
;    DB 0xE0, 0xE1, 0xE2, 0xE3, 0xE4, 0xE5, 0xE6, 0xE7, 0xE8, 0xE9, 0xEA, 0xEB, 0xEC, 0xED, 0xEE, 0xEF
;    DB 0xF0, 0xF1, 0xF2, 0xF3, 0xF4, 0xF5, 0xF6, 0xF7, 0xF8, 0xF9, 0xFA, 0xFB, 0xFC, 0xFD, 0xFE, 0xFF
    DB " Fin du test", 0x00

    include "../Video Card/char_pattern_table.asm"
    
    END