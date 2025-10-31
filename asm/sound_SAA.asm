; SOUND CARD DRIVER
; This file contains the sound card driver for the system.
; Based on SAA1099 IC (IORQ 0x30)
; and YM3812 IC (IORQ 0x50)


; The sound card driver is used to play sound effects and music in the system
; It uses the SAA1099 and YM3812 sound chips to generate sound
; The sound card driver is initialized in the main program and used to play sound effects and music

KEYPAD_ADDR EQU 0x60
KEYPAD_BASECOL EQU KEYPAD_ADDR
KEYPAD_COLNUM EQU 0x04

SAA1099_DATA EQU 0x30 ; I/O request for SAA1099
SAA1099_REGISTER EQU 0x31 ; I/O request for SAA1099 register
YM3812_DATA EQU 0x51; I/O request for YM3812
YM3812_REGISTER EQU 0x50 ; I/O request for YM3812 register

   include "jumpTable.inc"
 
    .ORG 0x5000

    JP main

    

; Sound card initialization
init_sound_card:
    ; Initialize the SAA1099 sound chip
    LD B, 20
    LD HL, SAA_CMD_INIT
    CALL playSound_SAA
    RET

shutdown_sound_card:
    ; Shutdown the SAA1099 sound chip
    LD A, 0x1C ; Reset SAA1099  
    OUT (SAA1099_REGISTER), A ; Send reset command
    LD A, 0x00 ; Reset SAA1099  
    OUT (SAA1099_DATA), A ; Send reset command
    ; Shutdown the YM3812 sound chip
    ; LD A, 0x00 ; Reset YM3812   
    ; OUT (YM3812_IORQ), A ; Send reset command
    RET

playSound_SAA: ; play the sequence in HL of length B
    PUSH BC
    PUSH HL
.loop:
    LD A, (HL) ; Load command byte
    OUT (SAA1099_REGISTER), A ; Send command to SAA1099
    INC HL ; Move to next command byte
    LD A, (HL) ; Load command byte
    OUT (SAA1099_DATA), A ; Send command to SAA1099
    INC HL ; Move to next command byte
    DJNZ .loop

    POP HL
    POP BC
    RET

playSound_YM: ; play the sequence in HL of length B
    PUSH BC
    PUSH HL
.loop:
    LD A, (HL) ; Load command byte
    OUT (SAA1099_REGISTER), A ; Send command to SAA1099
    INC HL ; Move to next command byte
    LD A, (HL) ; Load command byte
    OUT (SAA1099_DATA), A ; Send command to SAA1099
    INC HL ; Move to next command byte
    DJNZ .loop

    POP HL
    POP BC
    RET

putRegVal_SAA: ; put the value E in the register D
    LD A, D ; Load command byte
    OUT (SAA1099_REGISTER), A ; Send command to SAA1099
    LD A, E ; Load command byte
    OUT (SAA1099_DATA), A ; Send command to SAA1099
    RET

putRegVal_YM: ; put the value E in the register D
    LD A, D ; Load command byte
    OUT (YM3812_REGISTER), A ; Send command to SAA1099
    LD A, E ; Load command byte
    OUT (YM3812_DATA), A ; Send command to SAA1099
    RET

keypadSCan:
    PUSH BC
    PUSH HL
    LD C, KEYPAD_BASECOL
    LD B, KEYPAD_COLNUM

    LD HL, KEYPAD_BUFFER
.rowLoop:
    IN A, (C)
    LD (HL), A
    INC C
    INC HL
    DJNZ .rowLoop

    POP HL
    POP BC
    RET

main:
    ; Initialize the sound card
    CALL init_sound_card
;    CALL playSound
.mainLoop:
    CALL keypadSCan
    LD A, (KEYPAD_BUFFER+3)
    AND 0x08 ; mask for the Enter key
    JP NZ, prog_end
    
    LD A, (KEYPAD_BUFFER)
    AND 0x01 ; mask for the first row
    JP Z, .noPress
    LD A,(KEYPAD_STATE)
    CP 0x01
    JP Z,.mainLoop
    LD A, 0x01
    LD (KEYPAD_STATE), A
    LD HL, SAA_SOUND_1
    LD B, 8
    CALL playSound_SAA

    JP .mainLoop
.noPress:
    LD A, (KEYPAD_STATE)
    CP 0x01
    JP NZ, .endNoPress
    LD HL,  SAA_SOUND_2
    LD B, 8
    CALL playSound_SAA
.endNoPress:
    LD A, 0x00
    LD (KEYPAD_STATE), A
    JP .mainLoop

prog_end:
    ; LD HL, SAA_SOUND_2
    ; LD B, 8
    ; CALL playSound

    LD DE, 0x1104
    CALL putRegVal_SAA
    LD DE, 0x1884
    CALL putRegVal_SAA
    ; LD A, 0x11
    ; OUT (SAA1099_REGISTER), A ; Send command to SAA1099
    ; LD A, 0x04 ; Load command byte
    ; OUT (SAA1099_DATA), A ; Send command to SAA1099
    ; LD A, 0x18
    ; OUT (SAA1099_REGISTER), A ; Send command to SAA1099
    ; LD A, 0x88 ; Load command byte
    ; OUT (SAA1099_DATA), A ; Send command to SAA1099
    RET

   ; JP main
    ; Shutdown the sound card
 ;   CALL shutdown_sound_card

    RET

SAA_CMD_INIT 
        DB 0x00, 0x00, 0x01, 0x00, 0x02, 0x00, 0x03, 0x00, 0x04, 0x00, 0x05, 0x00 ; amplitude
        DB 0x08, 0x80, 0x09, 0x00, 0x0A, 0x80, 0x0B, 0x80, 0x0C, 0x80, 0x0D, 0x80 ; freq
        DB 0x10, 0x00, 0x11, 0x02, 0x12, 0x00 ; octave
        DB 0x14, 0x00, 0x15, 0x00; freq & noise enable
        DB 0x18, 0x00, 0x19, 0x00 ; envelope generator
        DB 0x1C, 0x01
SAA_SOUND_1 DB 0x01, 0x00, 0x02, 0xFF ; amplitude
        DB 0x09, 0x01, 0x0A, 0xF0 ; freq
        DB 0x10, 0x00, 0x11, 0x03 ; octave
        DB 0x14, 0x06; freq  enable
        DB 0x18, 0x8A ; envelope generator
SAA_SOUND_2 DB 0x01, 0x00, 0x02, 0xFF ; amplitude
        DB 0x09, 0x01, 0x0A, 0xF0 ; freq
        DB 0x10, 0x00, 0x11, 0x04 ; octave
        DB 0x14, 0x06; freq  enable
        DB 0x18, 0x88 ; envelope generator

YM_CMD_INIT DB 0x01, 0x00, 0x20, 0x22, 0x23, 0x21, 0x40, 0x0F, 0x43, 0x01, 0x63, 0xFF 
       DB 0x83, 0xFF, 0xA0, 0x80, 0xB0, 0x14   

KEYPAD_BUFFER
    DB 0x00, 0x00, 0x00, 0x00, 0x00

KEYPAD_STATE 
    DB 0x00, 0x00, 0x00, 0x00, 0x00
    DB 0x00, 0x00, 0x00, 0x00, 0x00
    DB 0x00, 0x00, 0x00, 0x00, 0x00
    DB 0x00, 0x00, 0x00, 0x00, 0x00

KEYPAD_DECODE_MATRIX
    DB 0x10, 0x30, 0x50, 0x70, 0x80
    DB 0x90, 0xA0, 0xB0, 0xC0, 0xD0
    DB 0x10, 0x30, 0x50, 0x70, 0x80
    DB 0x90, 0xA0, 0xB0, 0xC0, 0xD0