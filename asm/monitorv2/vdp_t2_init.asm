; V9938 VDP Mode Text 2 Initialisation Routines


    IFNDEF __VDP_T2_INIT__
    DEFINE __VDP_T2_INIT__ 1


  include "../lib/vdp_core.asm"


; START:
;     CALL    VDP_T2_INIT        ; Initialize V9938
;     ; LD HL, Msg_VDP_T2_Init
;     ; CALL PRINT_STRING

;     CALL init
;     LD HL, Msg_VDP_Pattern_Generator_Init
;     CALL PRINT_STRING

; ;    CALL READ_STATUS


;     CALL INIT_PATTERN_LAYOUT_TABLE
;     LD HL, Msg_VDP_Pattern_Layout_Init
;     CALL PRINT_STRING
    
;     CALL INIT_COLOR_TABLE
;     LD HL, Msg_VDP_ColorMap_Init
;     CALL PRINT_STRING

;     CALL WRITE_RAM
; ;    CALL READ_RAM
; ;    CALL SET_BLINK

;     RET                     ; or HALT


VDP_T2_Init:
    LD      C, 0        ; R#0: Mode set register
    LD      A, 0x04 ;
    CALL    Write_Reg

    LD      C, 1
    LD      A, 0x50     ; BL:screen enabled, M1: Mode Text 1 or 2
    CALL    Write_Reg

    LD      C, 8
    LD      A, 0x0A     ; VR: VRAM 64k*4b - sprite disabled
    CALL    Write_Reg

    LD      C, 9
    LD      A, 0x82     ; LN bit set (8x) - RGB output : NTSC x0, PAL x2
    CALL    Write_Reg

    LD      C, 2
    LD      A, 0x03     ; Pattern Name Table at 0x0000
    CALL    Write_Reg
    LD      C, 3
    LD      A, 0x2F     ; Color Table at 0x0A00
    CALL    Write_Reg
    LD      C, 10
    LD      A, 0x00     ; Color Table at 0x0A00
    CALL    Write_Reg

    LD      C, 4
    LD      A, 0x02     ; Pattern Generator at 0x0800
    CALL    Write_Reg

; Initialize Color Palette
    CALL Init_Color_Palette
    LD      C, 7
    LD      A, 0xF4         ; Text color: white (F) on blue (4)
    CALL    Write_Reg

; Initialize Pattern Generator Table
    CALL Init_Pattern_Generator_Table

    ; R#12: Text blink color
    LD C, 12
    LD A, 0x4F
    CALL Write_Reg

    ; R#13: Blink rate
    LD C, 13  
    LD A, 0x23
    CALL Write_Reg

    ; R#19: Interrupt line position (set to avoid issues)
    LD C, 19
    LD A, 0x00
    CALL Write_Reg

    LD C, 45
    LD A, 0x00 ; Video RAM standard
    CALL Write_Reg

    RET

Init_Color_Palette:
    PUSH AF
    PUSH BC
    PUSH HL

    LD HL, COLOR_PALETTE
    LD B, 16 ; 16 colors
.paletteLoop:
    LD C, 16
    LD A, (HL) ; palette idx 4
    CALL Write_Reg
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


Init_Pattern_Generator_Table:
    PUSH AF
    PUSH BC
    PUSH HL

    LD HL, PATTERN_GENERATOR_BASE_ADDR ; start of the pattern generator table
    LD A, VRAM_WRITE_MODE
    CALL Set_VRAM_Address

    LD HL, Pattern_Generator_Table
    LD B, 0x00 ; character index
    LD C, 0x08; number of bytes per character
.loop:
    LD A, (HL)
    OUT (VRAM_DATA), A
    NOP7
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


; WRITE_RAM: ; write at adress 0x0000
;     PUSH AF
;     PUSH BC
;     PUSH HL

;     LD HL, 0x0000
;     CALL SET_VRAM_ADDR

; ;    LD HL, Msg_RamTest
;     LD HL, Msg_VDP_T2_Init
; .loop:
;     LD A, (HL)
;     OR A
;     JP Z, .loopEnd
;     OUT (VRAM_DATA), A
;     NOP_7
;     INC HL
;     JP  .loop
; .loopEnd:
;     POP HL
;     POP BC
;     POP AF
;     RET
    
; READ_RAM:
;     PUSH AF
;     PUSH BC
;     PUSH HL
;     LD C, 14
;     LD A, 0x00 ; Set Address A16-A15-A14
;     CALL WRITE_REG
;     LD A, 0x00 ; Set Address A7..A0
;     OUT (VRAM_ADDR), A
;     LD A, 0x00 & 0xBF ; Set Address A13..A8 + data read mode
;     OUT (VRAM_ADDR), A
 
;     NOP
;     NOP
;     NOP
;     NOP

;     LD B, 0x00
; .loop:
;     IN A, (VRAM_DATA)
;     CP 0x20
;     JP C, .non_printable
; .printable:
;     CALL SENDCHAR_A
;     JP .continue
; .non_printable:
;      CALL HEX2STR
;      LD A, '-'
;      CALL SENDCHAR_A
; .continue:
;     DJNZ .loop

;     LD HL, CR_LF
;     CALL PRINT_STRING

;     POP HL
;     POP BC
;     POP AF
;     RET



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

; CR_LF:
;     DB 0x0A, 0x0D, 0x00 ; Carriage return + line feed

; Msg_VDP_T2_Init:
;     DB "V9938 - TEXT2 Mode Initialised", 0x0D, 0x0A,0x00 
; Msg_VDP_Pattern_Generator_Init:
;     DB "V9938 - Pattern Generator Initialised", 0x0D, 0x0A,0x00 
; Msg_VDP_Pattern_Layout_Init:
;     DB "V9938 - Pattern Layout Initialised", 0x0D, 0x0A,0x00 
; Msg_VDP_ColorMap_Init:
;     DB "V9938 - ColorMap Initialised", 0x0D, 0x0A,0x00 


    include "../lib/char_pattern_table.inc"
    
    ENDIF