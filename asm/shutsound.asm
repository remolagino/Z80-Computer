; SOUND CARD DRIVER
; This file contains the sound card driver for the system.
; Based on SAA1099 IC (IORQ 0x30)
; and YM3812 IC (IORQ 0x50)


; The sound card driver is used to play sound effects and music in the system
; It uses the SAA1099 and YM3812 sound chips to generate sound
; The sound card driver is initialized in the main program and used to play sound effects and music


SAA1099_DATA EQU 0x30 ; I/O request for SAA1099
SAA1099_REGISTER EQU 0x31 ; I/O request for SAA1099 register
YM3812_DATA EQU 0x51; I/O request for YM3812
YM3812_REGISTER EQU 0x50 ; I/O request for YM3812 register

    .ORG 0x5000

main:
    ; Initialize the sound card
    ; Shutdown the SAA1099 sound chip
    LD A, 0x1C ; Reset SAA1099  
    OUT (SAA1099_REGISTER), A ; Send reset command
    LD A, 0x00 ; Reset SAA1099  
    OUT (SAA1099_DATA), A ; Send reset command

    RET
