; ------------------  I2C RT CLOCK (DS3231)   ---------------

    IFNDEF __RTCLOCK__
    DEFINE __RTCLOCK__ 1


;    INCLUDE "jumpTable.inc"
    INCLUDE "string.asm"
    INCLUDE "I2C.asm"

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
    
CLOCK EQU 0x4010


RTCLOCK_I2C_ADDRESS EQU 0xD0

RT_CLOCK_INIT_MSG:
    DB "Init RT Clock : ", 0x00
RT_CLOCK_INIT_SUCCESS:
    DB 0x1B,"[32m", "Success",0x1B,"[0m", 0x00
RT_CLOCK_INIT_FAIL:
    DB 0x1B,"[31m", "Failed",0x1B,"[0m", 0x00
RT_CLOCK_RESULT_CODE:
    DB 0x00

DAYS_TABLE:
    DB "Mon", 0x00, "Tue", 0x00, "Wed", 0x00, "Thu", 0x00
    DB "Fri", 0x00, "Sat", 0x00, "Sun", 0x00

RtClock_InitCheck:
;    CALL I2C_Init
    LD HL, RT_CLOCK_INIT_MSG
    CALL PrintString
    LD A, 0x00
    LD (RT_CLOCK_RESULT_CODE), A
    CALL I2C_Stop_condition
    CALL I2C_Start_condition
    LD C, RTCLOCK_I2C_ADDRESS ; RT Clk Address, Write
    CALL I2C_SendByte
    JP Z, .rtclk_initCheck_success
    LD HL, RT_CLOCK_INIT_FAIL
    CALL PrintString
    CALL I2C_Stop_condition
    LD A, 0x01
    LD (RT_CLOCK_RESULT_CODE), A
    LD A, 0x01
    OR A
    RET
.rtclk_initCheck_success:
    LD HL, RT_CLOCK_INIT_SUCCESS
    CALL PrintString
    CALL I2C_Stop_condition
    LD A, 0x00
    OR A
    RET

RtClock_GetTime: ; Get time in (HL) - HL to be reset after by user
    LD A, 0x00
    LD (RT_CLOCK_RESULT_CODE), A
    CALL I2C_Start_condition
    LD C, RTCLOCK_I2C_ADDRESS ; RT Clk Address, Write
    CALL I2C_SendByte
    JP NZ, .getTimeError
.setAddress:
    LD C, 0x00 ; Send Start Address
    CALL I2C_SendByte
    JP NZ, .getTimeError
.restart:
    CALL I2C_Restart_condition
    LD C, RTCLOCK_I2C_ADDRESS+1 ; RT Clk address, Read
    CALL I2C_SendByte
    JP NZ, .getTimeError
.readRegisters:
    CALL I2C_ReceiveByte
    LD (HL),C
    INC HL
    CALL I2C_Send_Ack
    CALL I2C_ReceiveByte
    LD (HL),C
    INC HL
    CALL I2C_Send_Ack
    CALL I2C_ReceiveByte
    LD (HL),C
    INC HL
    CALL I2C_Send_Ack
    CALL I2C_ReceiveByte
    LD (HL),C
    INC HL
    CALL I2C_Send_Ack
    CALL I2C_ReceiveByte
    LD (HL),C
    INC HL
    CALL I2C_Send_Ack
    CALL I2C_ReceiveByte
    LD (HL),C
    INC HL
    CALL I2C_Send_Ack
    CALL I2C_ReceiveByte
    LD (HL),C
    INC HL
    CALL I2C_Send_NAck
    CALL I2C_Stop_condition
    LD A, 0x00
    OR A
    RET
.getTimeError:
    LD A, 0x01
    LD (RT_CLOCK_RESULT_CODE), A
    CALL I2C_Stop_condition
    LD A, 0x01
    OR A
    RET

RtClock_SetTime: ; set time from (HL) - HL to be reset after by user
    LD A, 0x00
    LD (RT_CLOCK_RESULT_CODE), A

    CALL I2C_Start_condition
    LD C, RTCLOCK_I2C_ADDRESS ; RT Clk Address, Write
    CALL I2C_SendByte
    JP NZ, .setTimeError
.gt1:
    LD C, 0x00 ; Send Start Address - no update of sec
    CALL I2C_SendByte
    JP NZ, .setTimeError
.gt2:
    LD C, (HL) 
    CALL I2C_SendByte
    JP NZ, .setTimeError
.gt3:
    INC HL
    LD C, (HL) 
    CALL I2C_SendByte
    JP NZ, .setTimeError
.gt4:
    INC HL
    LD C, (HL) 
    CALL I2C_SendByte
    JP NZ, .setTimeError
.gt5:
    INC HL
    LD C, (HL) 
    CALL I2C_SendByte
    JP NZ, .setTimeError
.gt6:
    INC HL
    LD C, (HL) 
    CALL I2C_SendByte
    JP NZ, .setTimeError
.gt7:
    INC HL
    LD C, (HL) 
    CALL I2C_SendByte
    JP NZ, .setTimeError
.gt8:
    INC HL
    LD C, (HL) 
    CALL I2C_SendByte
    JP NZ, .setTimeError
.stopCondition:
    CALL I2C_Stop_condition
    LD A, 0x00
    OR A ; Put the Z Flag at Z to indicate success
    RET
.setTimeError:
    LD A, 0x02
    LD (RT_CLOCK_RESULT_CODE), A
    CALL I2C_Stop_condition
    LD A, 0x01
    OR A
    RET

RtClock_Day2Str: ; in : HL point to DAYS_TABLE - out : HL point to day
    LD A, (CLOCK + TIME.DOW)
    DEC A
    JP Z, .end
    LD B, A
    LD DE, 0x0004
.loop:
    ADD HL, DE
    DJNZ .loop
.end:
    RET

RtClock_PrintTime:
    LD HL, DAYS_TABLE
    CALL RtClock_Day2Str
    CALL PrintString
    LD A, ' '
    CALL SendChar_A
    LD A, (CLOCK + TIME.DATE)
    CALL Hex2Str
    LD A, '/'
    CALL SendChar_A
    LD A, (CLOCK + TIME.MONTH)
    CALL Hex2Str
    LD A, '/'
    CALL SendChar_A
    LD A, '2'
    CALL SendChar_A
    LD A, '0'
    CALL SendChar_A
    LD A, (CLOCK + TIME.YEAR)
    CALL Hex2Str
    LD A, ' '
    CALL SendChar_A
    LD A, (CLOCK + TIME.HOUR)
    CALL Hex2Str
    LD A, ':'
    CALL SendChar_A
    LD A, (CLOCK + TIME.MINUTE)
    CALL Hex2Str
    LD A, ':'
    CALL SendChar_A
    LD A, (CLOCK + TIME.SECOND)
    CALL Hex2Str
    RET



    ENDIF