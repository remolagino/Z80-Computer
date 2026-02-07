; SOUND CARD DRIVER
; This file contains the sound card driver for the system.
; Based on SAA1099 IC (IORQ 0x30)
; and YM3812 IC (IORQ 0x50)


; The sound card driver is used to play sound effects and music in the system
; It uses the SAA1099 and YM3812 sound chips to generate sound
; The sound card driver is initialized in the main program and used to play sound effects and music

; KEYPAD_ADDR EQU 0x60
; KEYPAD_BASECOL EQU KEYPAD_ADDR
; KEYPAD_COLNUM EQU 0x04

SAA1099_DATA EQU 0x30 ; I/O request for SAA1099
SAA1099_REGISTER EQU 0x31 ; I/O request for SAA1099 register
YM3812_DATA EQU 0x51; I/O request for YM3812
YM3812_REGISTER EQU 0x50 ; I/O request for YM3812 register

;   include "jumpTable.inc"
    .ORG 0x4000
    JP main

    include "./lib/stdio.asm"
    include "./monitorv2/memoryMapv2.inc"



    

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

putRegVal_SAA: ; put the value E in the register D
    LD A, D ; Load command byte
    OUT (SAA1099_REGISTER), A ; Send command to SAA1099
    LD A, E ; Load command byte
    OUT (SAA1099_DATA), A ; Send command to SAA1099
    RET

main:
    LD HL, (CURSOR_IDX)
    LD DE, START_MSG
    CALL PutS_LN
    LD (CURSOR_IDX), HL

; Initialize the sound card
    CALL init_sound_card

;    CALL playSound
.mainLoop:
    CALL GetC
    CP 0x00
    JP Z, .mainLoop
    CP '²' 
    JP Z, prog_end
    
    CP 'a'
    JP Z, .endNote

    LD HL, SAA_SOUND_1
    LD B, 8
    CALL playSound_SAA
    JP .mainLoop

.endNote:
    LD HL,  SAA_SOUND_2
    LD B, 8
    CALL playSound_SAA
    JP .mainLoop

prog_end:
    ; LD DE, 0x1104 ; stop all sound
    ; CALL putRegVal_SAA
    ; LD DE, 0x1884 ; stop all sound
    ; CALL putRegVal_SAA

    LD HL, (CURSOR_IDX)
    LD DE, END_MSG
    CALL PutS_LN
    LD (CURSOR_IDX), HL

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

START_MSG DB "SAA1099 Test Program", 0
END_MSG DB "Program ended", 0
