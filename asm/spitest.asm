; -------------------------------------
; SPI test program
; -------------------------------------

    .ORG 0x4000

    JP main

    INCLUDE "./lib/spi.asm"
    INCLUDE "./lib/stdio.asm"
    INCLUDE "./lib/string.asm"
    INCLUDE "sdcard.asm"

main:
    LD HL, (CURSOR_IDX)
    LD DE, SPITEST_MSG
    CALL PutS_LN
    LD (CURSOR_IDX), HL

   ; CALL SPI_Init
.loop:
    LD HL, SDCARD_CMD0 ; Prepare CMD0 command
    CALL SDCARD_SendCmd ; Send CMD0 to SD card
    CALL SDCARD_Wait_R1 ; Wait for response from SD card

    LD A, (SDCARD_R1)
    LD DE, SPITEST_WORK
    CALL Bin2Hex_DE
    LD A, 0x00
    LD (DE), A
    LD DE, SPITEST_WORK
    LD HL, (CURSOR_IDX)
    CALL PutS_LN
    LD (CURSOR_IDX), HL
        
 
    LD HL, (CURSOR_IDX)
    LD DE, SPITEST_END_MSG
    CALL PutS_LN
    LD (CURSOR_IDX), HL
    RET

SpiTest_ErrorMsgPrint: ; print and error message for error code in A
    LD DE, SPITEST_ERROR_MSG
    LD HL, (CURSOR_IDX)
    CALL PutS

    LD DE, SPITEST_WORK
    ; LD A, (SDCARD_R1)
    CALL Bin2Hex_DE ; Convert response to string for display
    LD A, 0x00
    LD (DE), A
    LD DE, SPITEST_WORK
    LD HL, (CURSOR_IDX)
    CALL PutS_LN
    LD (CURSOR_IDX), HL
    RET

SPITEST_MSG: 
    DB "SPI Test Program - Press any key to send data to SD card", 0
SPITEST_END_MSG:
    DB "Program Exit", 0
SPITEST_ERROR_MSG:
    DB "SD Card Error : ", 0x00
SPITEST_WORK:
    DS 0x20