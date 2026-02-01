; ------------------  I2C RT CLOCK (DS3231)   ---------------

    


; ------------- Program START -----------------
    .ORG 0x4000

    JP Main

;    INCLUDE "jumpTable.inc"
    INCLUDE "./lib/rtclock.asm"
    INCLUDE "./lib/string.asm"
    INCLUDE "./lib/stdio.asm"
    INCLUDE "./monitorv2/memoryMapv2.inc"
    INCLUDE "./lib/eeprom.asm"
; I2C_EEPROM_ADDRESS EQU 0xAE
; I2C_RAND_ADDRESS EQU 0x84



Main:
    CALL RtClock_Init
    JP NZ, .rterror1
    LD HL, DS3231_DATA
    CALL RtClock_GetDS3231Data
    JP NZ, .rterror2
    LD DE, TIMEDATA_FORMAT
    LD HL, DS3231_DATA
    CALL RtClock_GetDateTime
;    JP NZ, .rterror3

    CALL EEPROM_Init
    JP NZ, .error

    LD DE, EEPROM_SUCCESS_MSG
    LD HL, (CURSOR_IDX)
    CALL PutS_LN
    LD (CURSOR_IDX), HL
    
    LD HL, TIMEDATA_FORMAT
    LD DE, 0x0000
    CALL EEPROM_PageWrite
    JP NZ, .error
    LD DE, EEPROM_SUCCESS2_MSG
    LD HL, (CURSOR_IDX)
    CALL PutS_LN
    LD (CURSOR_IDX), HL

    ; CALL EEPROM_AckPolling
    ; LD HL, EEPROM_TEST_MSG
    ; LD DE, 0x0020
    ; LD BC, 400
    ; CALL EEPROM_BulkWrite
    ; JP NZ, .error

    ; LD DE, EEPROM_SUCCESS2_MSG
    ; LD HL, (CURSOR_IDX)
    ; CALL PutS_LN
    ; LD (CURSOR_IDX), HL

    CALL EEPROM_AckPolling
    LD BC, 60
    LD DE, 0x0000
    LD HL, EEPROM_RESULT
    CALL EEPROM_SequentialRead
    JP NZ, .error
    LD DE, EEPROM_RESULT
    LD HL, (CURSOR_IDX)
    CALL PutS_LN
    LD (CURSOR_IDX), HL
.exit:
    RET
.error:
    LD DE, EEPROM_ERROR_MSG
    LD HL, (CURSOR_IDX)
    CALL PutS
    CALL PutC
    LD DE, LF_CR
    CALL PutS
    LD (CURSOR_IDX), HL
    RET
.rterror1:
    LD DE, RT_ERROR_MSG1
    JP .rterror
.rterror2:
    LD DE, RT_ERROR_MSG2
    JP .rterror
.rterror3:
    LD DE, RT_ERROR_MSG3
.rterror:
    LD HL, (CURSOR_IDX)
    CALL PutS
    CALL PutC
    LD DE, LF_CR
    CALL PutS
    LD (CURSOR_IDX), HL
    RET

LF_CR:
    DB 0x0A, 0x0D, 0x00
RT_ERROR_MSG1:
    DB "RTC Error : Init", 0x00
RT_ERROR_MSG2:
    DB "RTC Error : Get Data", 0x00
RT_ERROR_MSG3:
    DB "RTC Error : Get Time", 0x00
EEPROM_ERROR_MSG:
    DB "EEPROM Error : ", 0x00
EEPROM_SUCCESS_MSG:
    DB "EEPROM Success Init", 0x00
EEPROM_SUCCESS2_MSG:
    DB "EEPROM Success Write", 0x00
DS3231_DATA :
    DS 19, 0x00
TIMEDATA_FORMAT:
    DB "DAY 00/00/00 00:00:00 ", 0x00
EEPROM_TEST_MSG:
    DB "EEPROM Test Write Data 1234567890ABCDEFGH"
    DB "EEPROM Test Write Data 1234567890ABCDEFGH"
    DB "EEPROM Test Write Data 1234567890ABCDEFGH"
    DB "EEPROM Test Write Data 1234567890ABCDEFGH"
    DB "EEPROM Test Write Data 1234567890ABCDEFGH"
    DB "EEPROM Test Write Data 1234567890ABCDEFGH"
    DB "EEPROM Test Write Data 1234567890ABCDEFGH"
    DB "EEPROM Test Write Data 1234567890ABCDEFGH"
    DB "EEPROM Test Write Data 1234567890ABCDEFGH"
    DB "EEPROM Test Write Data 1234567890ABCDEFGH", 0x00
EEPROM_RESULT:
    DB "TEST RESULT"
    DS 200, 0x00
