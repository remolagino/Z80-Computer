; ------------------  I2C RT CLOCK (DS3231)   ---------------

    


; ------------- Program START -----------------
    .ORG 0x5000

    JP Main

    INCLUDE "jumpTable.inc"
    INCLUDE "rtclock.asm"
;    INCLUDE "I2C.asm"

; I2C_EEPROM_ADDRESS EQU 0xAE
; I2C_RAND_ADDRESS EQU 0x84



Main:
    CALL I2C_Init

    CALL RtClock_InitCheck
    LD HL, LF_CR
    CALL PrintString

    LD HL, TIME_TEST
    CALL RtClock_GetTime

    CALL NZ, setTestFail
    
    CALL PrintTime
    LD HL, LF_CR
    CALL PrintString
    RET

setTestFail:
    LD HL, TIME_SET_TEST
    CALL PrintString
    LD A, (RT_CLOCK_RESULT_CODE)
    CALL Hex2Str
    LD A, 0x0D
    CALL SendChar_A

    RET

Day2Str: ; in : HL point to DAYS_TABLE - out : HL point to day
    LD A, (TIME_TEST.DOW)
    DEC A
    JP Z, .end
    LD B, A
    LD DE, 0x0004
.loop:
    ADD HL, DE
    DJNZ .loop
.end:
    RET

PrintTime:
    LD HL, DAYS_TABLE
    CALL Day2Str
    CALL PrintString
    LD A, ' '
    CALL SendChar_A
    LD A, (TIME_TEST.DATE)
    CALL Hex2Str
    LD A, '/'
    CALL SendChar_A
    LD A, (TIME_TEST.MONTH)
    CALL Hex2Str
    LD A, '/'
    CALL SendChar_A
    LD A, '2'
    CALL SendChar_A
    LD A, '0'
    CALL SendChar_A
    LD A, (TIME_TEST.YEAR)
    CALL Hex2Str
    LD A, ' '
    CALL SendChar_A
    LD A, (TIME_TEST.HOUR)
    CALL Hex2Str
    LD A, ':'
    CALL SendChar_A
    LD A, (TIME_TEST.MINUTE)
    CALL Hex2Str
    LD A, ':'
    CALL SendChar_A
    LD A, (TIME_TEST.SECOND)
    CALL Hex2Str
    RET

TIME_TEST TIME

TIME_SET_TEST:
    DB "Time set test failed : ", 0x00

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


RT_CLOCK_RESULT TIME

