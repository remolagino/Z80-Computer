; ------------------  I2C RT CLOCK (DS3231)   ---------------

    IFNDEF __RTCLOCK__
    DEFINE __RTCLOCK__ 1


    include "./lib/serial.asm"
    INCLUDE "./lib/I2C_2.asm"

    STRUCT TIME
SECOND  BYTE
MINUTE  BYTE
HOUR    BYTE
DOW     BYTE
DATE    BYTE
MONTH   BYTE
YEAR    BYTE
    ENDS
    STRUCT A1
SECOND  BYTE
MINUTE  BYTE
HOUR    BYTE
DATE    BYTE
    ENDS
    STRUCT A2
MINUTE  BYTE
HOUR    BYTE
DATE    BYTE
    ENDS
    STRUCT REG
CTRL    BYTE
STATUS  BYTE
AGING   BYTE
    ALIGN 2
TEMP    WORD
    ENDS
    STRUCT DS3231
TIME    TIME
A1  A1
A2 A2
REG REG
    ENDS
    
CLOCK EQU 0x6010


RTCLOCK_I2C_ADDRESS EQU 0xD0



RT_CLOCK_INIT_MSG:
    DB "Init RT Clock : ", 0x00
RT_CLOCK_INIT_SUCCESS:
    DB 0x1B,"[32m", "Success",0x1B,"[0m", 0x00
RT_CLOCK_INIT_FAIL:
    DB 0x1B,"[31m", "Failed",0x1B,"[0m", 0x00
; RT_CLOCK_RESULT_CODE:
;     DB 0x00

DAYS_TABLE:
    DB "Mon", 0x00, "Tue", 0x00, "Wed", 0x00, "Thu", 0x00
    DB "Fri", 0x00, "Sat", 0x00, "Sun", 0x00

RtClock_InitCheck: ; Z Flag set if success, error code in A
    CALL I2C_Stop_condition
    CALL I2C_Start_condition
    LD A, RTCLOCK_I2C_ADDRESS ; RT Clk Address, Write
    CALL I2C_SendByte
    JP Z, .rtclk_initCheck_success
    CALL I2C_Stop_condition
    LD A, '0'
;    LD (RT_CLOCK_RESULT_CODE), A
    OR A
    RET
.rtclk_initCheck_success:
    CALL I2C_Stop_condition
    LD A, 0x00
    OR A
    RET

RtClock_GetTime: ; Get time in (HL) - HL to be reset after by user
;    LD A, 0x00
;    LD (RT_CLOCK_RESULT_CODE), A
    CALL I2C_Start_condition
    LD A, RTCLOCK_I2C_ADDRESS ; RT Clk Address, Write
    CALL I2C_SendByte
    LD A, '1'
    JP NZ, .getTimeError
.setAddress:
    LD A, 0x00 ; Send Start Address
    CALL I2C_SendByte
    LD A, '2'
    JP NZ, .getTimeError
.restart:
    CALL I2C_Restart_condition
    LD A, RTCLOCK_I2C_ADDRESS+1 ; RT Clk address, Read
    CALL I2C_SendByte
    LD A, '3'
    JP NZ, .getTimeError
.readRegisters:
    CALL I2C_ReceiveByte
    LD (HL),A
    INC HL
    CALL I2C_Send_Ack
    CALL I2C_ReceiveByte
    LD (HL),A
    INC HL
    CALL I2C_Send_Ack
    CALL I2C_ReceiveByte
    LD (HL),A
    INC HL
    CALL I2C_Send_Ack
    CALL I2C_ReceiveByte
    LD (HL),A
    INC HL
    CALL I2C_Send_Ack
    CALL I2C_ReceiveByte
    LD (HL),A
    INC HL
    CALL I2C_Send_Ack
    CALL I2C_ReceiveByte
    LD (HL),A
    INC HL
    CALL I2C_Send_Ack
    CALL I2C_ReceiveByte
    LD (HL),A
    INC HL
    CALL I2C_Send_NAck
    CALL I2C_Stop_condition
    LD A, 0x00
    OR A
    RET
.getTimeError:
    CALL I2C_Stop_condition
    OR A
    RET

RtClock_SetTime: ; set time from (HL) - HL to be reset after by user
    ; LD A, 0x00
    ; LD (RT_CLOCK_RESULT_CODE), A

    CALL I2C_Start_condition
    LD A, RTCLOCK_I2C_ADDRESS ; RT Clk Address, Write
    CALL I2C_SendByte
    LD A, '4'
    JP NZ, .setTimeError

    LD A, 0x00 ; Send Start Address - no update of sec
    CALL I2C_SendByte
    LD A, '5'
    JP NZ, .setTimeError

    LD A, (HL) 
    CALL I2C_SendByte
    LD A, '6'
    JP NZ, .setTimeError

    INC HL
    LD A, (HL) 
    CALL I2C_SendByte
    LD A, '7'
    JP NZ, .setTimeError

    INC HL
    LD A, (HL) 
    CALL I2C_SendByte
    LD A, '8'
    JP NZ, .setTimeError

    INC HL
    LD A, (HL) 
    CALL I2C_SendByte
    LD A, '9'
    JP NZ, .setTimeError

    INC HL
    LD A, (HL) 
    CALL I2C_SendByte
    LD A, 'A'
    JP NZ, .setTimeError

    INC HL
    LD A, (HL) 
    CALL I2C_SendByte
    LD A, 'B'
    JP NZ, .setTimeError

    INC HL
    LD A, (HL) 
    CALL I2C_SendByte
    LD A, 'C'
    JP NZ, .setTimeError
.stopCondition:
    CALL I2C_Stop_condition
    LD A, 0x00
    OR A ; Put the Z Flag at Z to indicate success
    RET
.setTimeError:
    CALL I2C_Stop_condition
    OR A
    RET

; RtClock_Day2Str: ; in : HL point to DAYS_TABLE - out : HL point to day
;     PUSH AF
;     PUSH BC
;     PUSH DE
;     LD A, (CLOCK + TIME.DOW)
;     DEC A
;     JP Z, .end
;     LD B, A
;     LD DE, 0x0004
; .loop:
;     ADD HL, DE
;     DJNZ .loop
; .end:
;     POP DE
;     POP BC
;     POP AF
;     RET

; RtClock_PrintTime:
;     LD HL, DAYS_TABLE
;     CALL RtClock_Day2Str
;     CALL PrintString
;     LD A, ' '
;     CALL SendChar_A
;     LD A, (CLOCK + TIME.DATE)
;     CALL Hex2Str
;     LD A, '/'
;     CALL SendChar_A
;     LD A, (CLOCK + TIME.MONTH)
;     CALL Hex2Str
;     LD A, '/'
;     CALL SendChar_A
;     LD A, '2'
;     CALL SendChar_A
;     LD A, '0'
;     CALL SendChar_A
;     LD A, (CLOCK + TIME.YEAR)
;     CALL Hex2Str
;     LD A, ' '
;     CALL SendChar_A
;     LD A, (CLOCK + TIME.HOUR)
;     CALL Hex2Str
;     LD A, ':'
;     CALL SendChar_A
;     LD A, (CLOCK + TIME.MINUTE)
;     CALL Hex2Str
;     LD A, ':'
;     CALL SendChar_A
;     LD A, (CLOCK + TIME.SECOND)
;     CALL Hex2Str
;     RET



    ENDIF