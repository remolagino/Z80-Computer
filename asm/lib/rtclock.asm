; ------------------  I2C RT CLOCK (DS3231)   ---------------

    IFNDEF __RTCLOCK__
    DEFINE __RTCLOCK__ 1


    INCLUDE "serial.asm"
    INCLUDE "I2C.asm"
    INCLUDE "rtclock.inc"
    INCLUDE "string.asm"

;RTCLOCK_I2C_ADDRESS EQU 0xD0
RTCLOCK_I2C_ADDRESS EQU 0xD0


DAYS_TABLE:
    DB "Mon", 0x00, "Tue", 0x00, "Wed", 0x00, "Thu", 0x00
    DB "Fri", 0x00, "Sat", 0x00, "Sun", 0x00

RtClock_Init: ; Z Flag set if success, error code in A
    CALL I2C_Init
    CALL I2C_Stop_condition
    CALL I2C_Start_condition
    LD A, RTCLOCK_I2C_ADDRESS ; RT Clk Address, Write
    CALL I2C_SendByte
    JP Z, .rtclk_initCheck_success
    CALL I2C_Stop_condition
    LD A, '0'
    OR A
    RET
.rtclk_initCheck_success:
    CALL I2C_Stop_condition
    LD A, 0x00
    OR A
    RET

RtClock_GetDS3231Data: ; Get DS3231 data (19 bytes) in (HL)
    PUSH BC
    PUSH HL
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
    LD B, 18
.readRegisters:
    CALL I2C_ReceiveByte
    LD (HL),A
    INC HL
    CALL I2C_Send_Ack
    DJNZ .readRegisters

    CALL I2C_ReceiveByte
    LD (HL),A
    CALL I2C_Send_NAck
    CALL I2C_Stop_condition
    LD A, 0x00
    OR A
    POP HL
    POP BC
    RET
.getTimeError:
    CALL I2C_Stop_condition
    OR A
    POP HL
    POP BC
    RET

RtClock_GetDateTime: ; Create a printable DateTime String in (DE) from DS3231 Data in (HL)
    PUSH DE
    PUSH HL
    PUSH IX

    PUSH HL ; load HL in IX
    POP IX
    LD A, (IX + DS3231.TIME.DOW)
    EX DE, HL ; switch the result string pointer in HL
    CALL RtClock_Day2Str ; DE overwritten to DaysTable
    LD A, (DE)
    LD (HL), A
    INC DE
    INC HL
    LD A, (DE)
    LD (HL), A
    INC DE
    INC HL
    LD A, (DE)
    LD (HL), A
    EX DE, HL ; switch the result string pointer back to DE
    INC DE
    LD A, ' '
    LD (DE), A
    INC DE
    LD A, (IX + DS3231.TIME.DATE)
    CALL Bin2Hex_DE
    LD A, '/'
    LD (DE), A
    INC DE
    LD A, (IX + DS3231.TIME.MONTH)
    CALL Bin2Hex_DE
    LD A, '/'
    LD (DE), A
    INC DE
    LD A, '2'
    LD (DE), A
    INC DE
    LD A, '0'
    LD (DE), A
    INC DE
    LD A, (IX + DS3231.TIME.YEAR)
    CALL Bin2Hex_DE
    LD A, ' '
    LD (DE), A
    INC DE
    LD A, (IX + DS3231.TIME.HOUR)
    CALL Bin2Hex_DE
    LD A, ':'
    LD (DE), A
    INC DE
    LD A, (IX + DS3231.TIME.MINUTE)
    CALL Bin2Hex_DE
    LD A, ':'
    LD (DE), A
    INC DE
    LD A, (IX + DS3231.TIME.SECOND)
    CALL Bin2Hex_DE
    LD A, 0x00
    LD (DE), A

    POP IX
    POP HL
    POP DE
    RET


RtClock_SetTime: ; set time from (HL) - Z flag set if success
    PUSH HL
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
    LD A, 0x00
 ;   OR A ; Put the Z Flag at Z to indicate success
.setTimeError:
    CALL I2C_Stop_condition
    OR A
    POP HL
    RET


RtClock_Day2Str: ; in : A is day number - out : (DE) point to day
    PUSH BC
    LD DE, DAYS_TABLE
    DEC A
    JP Z, .end
    LD B, A
.loop:
    INC DE
    INC DE
    INC DE
    INC DE
    DJNZ .loop
.end:
    POP BC
    RET


    ENDIF