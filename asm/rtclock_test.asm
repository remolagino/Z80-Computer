; ------------------  I2C RT CLOCK (DS3231)   ---------------

    


; ------------- Program START -----------------
    .ORG 0x4000

    JP Main

;    INCLUDE "jumpTable.inc"
    INCLUDE "./lib/rtclock.asm"
    INCLUDE "./lib/string.asm"
    INCLUDE "./lib/stdio.asm"
    INCLUDE "./monitorv2/memoryMapv2.inc"

; I2C_EEPROM_ADDRESS EQU 0xAE
; I2C_RAND_ADDRESS EQU 0x84



Main:
 ;   CALL I2C_Init

    CALL RtClock_Init
    CALL NZ, .setTestFail

    LD HL, TIME_TEST
    CALL RtClock_GetDS3231Data
 ;   POP HL
    JP NZ, .getTimeFail
    
    LD DE, RTCLK_WORK_MEM
    CALL RtClock_GetDateTime
    LD HL, (CURSOR_IDX)
    CALL PutS_LN
    LD (CURSOR_IDX), HL

;    CALL PrintTime
    ; LD HL, LF_CR
    ; CALL PrintString
    RET
.getTimeFail:
    LD HL, (CURSOR_IDX)
    LD DE, TIME_GET_TEST
    CALL PutS
    CALL PutC
    LD DE, LF_CR
    CALL PutS
    LD (CURSOR_IDX), HL
    RET
.setTestFail:
    LD HL, (CURSOR_IDX)
    LD DE, TIME_SET_TEST
    CALL PutS
    CALL PutC
    LD DE, LF_CR
    CALL PutS
    LD (CURSOR_IDX), HL
    RET


PrintTime:
    LD HL, (CURSOR_IDX)
    LD A, (TIME_TEST.TIME.DOW)
    CALL RtClock_Day2Str
    CALL PutS
    LD A, ' '
    CALL PutC
    LD A, (TIME_TEST.TIME.DATE)
    LD DE, RTCLK_WORK_MEM
    CALL Bin2Hex_DE
    LD DE, RTCLK_WORK_MEM
    CALL PutS
    LD A, '/'
    CALL PutC
    LD A, (TIME_TEST.TIME.MONTH)
    LD DE, RTCLK_WORK_MEM
    CALL Bin2Hex_DE
    LD DE, RTCLK_WORK_MEM
    CALL PutS
    LD A, '/'
    CALL PutC
    LD A, '2'
    CALL PutC
    LD A, '0'
    CALL PutC
    LD A, (TIME_TEST.TIME.YEAR)
    LD DE, RTCLK_WORK_MEM
    CALL Bin2Hex_DE
    LD DE, RTCLK_WORK_MEM
    CALL PutS
    LD A, ' '
    CALL PutC
    LD A, (TIME_TEST.TIME.HOUR)
    LD DE, RTCLK_WORK_MEM
    CALL Bin2Hex_DE
    LD DE, RTCLK_WORK_MEM
    CALL PutS
    LD A, ':'
    CALL PutC
    LD A, (TIME_TEST.TIME.MINUTE)
    LD DE, RTCLK_WORK_MEM
    CALL Bin2Hex_DE
    LD DE, RTCLK_WORK_MEM
    CALL PutS
    LD A, ':'
    CALL PutC
    LD A, (TIME_TEST.TIME.SECOND)
    LD DE, RTCLK_WORK_MEM
    CALL Bin2Hex_DE
    LD DE, RTCLK_WORK_MEM
    CALL PutS_LN
    LD (CURSOR_IDX), HL
    RET

TIME_SET_TEST:
    DB "Time Set test failed : ", 0x00
TIME_GET_TEST:
    DB "Time Get test failed : ", 0x00

LF_CR:
    DB 0x0D, 0x0A, 0x00

I2C_CLK_MSG:
    DB "Call to RT Clk : ", 0x00
I2C_EEPROM_MSG:
    DB "Call to EEPROM : ", 0x00
I2C_RAND_MSG:
    DB "Call to Random Address : ", 0x00
I2C_RESULT_SUCCESS:
    DB "Success", 0x00
I2C_RESULT_FAIL:
    DB "Fail", 0x00

TIME_TEST DS3231
    DB "@"
RTCLK_WORK_MEM:
    DS 20, '.'


