; ------------------  I2C RT CLOCK (DS3231)   ---------------

    IFNDEF __RTCLOCK__
    DEFINE __RTCLOCK__ 1


    INCLUDE "jumpTable.inc"
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
    


RTCLOCK_I2C_ADDRESS EQU 0xD0
;I2C_EEPROM_ADDRESS EQU 0xAE
;I2C_RAND_ADDRESS EQU 0x84

RT_CLOCK_INIT_MSG:
    DB "Init RT Clock : ", 0x00
RT_CLOCK_INIT_SUCCESS:
    DB 0x1B,"[32m", "Success",0x1B,"[0m", 0x00
RT_CLOCK_INIT_FAIL:
    DB 0x1B,"[31m", "Failed",0x1B,"[0m", 0x00
RT_CLOCK_RESULT_CODE:
    DB 0x00


RtClock_InitCheck:
;    CALL I2C_Init
    LD HL, RT_CLOCK_INIT_MSG
    CALL PRINT_STRING
    LD A, 0x00
    LD (RT_CLOCK_RESULT_CODE), A
    CALL I2C_Stop_condition
    CALL I2C_Start_condition
    LD C, RTCLOCK_I2C_ADDRESS ; RT Clk Address, Write
    CALL I2C_SendByte
    JP Z, .rtclk_initCheck_success
    LD HL, RT_CLOCK_INIT_FAIL
    CALL PRINT_STRING
    CALL I2C_Stop_condition
    LD A, 0x01
    LD (RT_CLOCK_RESULT_CODE), A
    LD A, 0x01
    OR A
    RET
.rtclk_initCheck_success:
    LD HL, RT_CLOCK_INIT_SUCCESS
    CALL PRINT_STRING
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
    JP Z, .gt1
    LD A, 0x02
    LD (RT_CLOCK_RESULT_CODE), A
    CALL I2C_Stop_condition
    LD A, 0x01
    OR A
    RET
.gt1:
    LD C, 0x00 ; Send Start Address
    CALL I2C_SendByte
    JP Z, .gt2
    LD A, 0x03
    LD (RT_CLOCK_RESULT_CODE), A
    CALL I2C_Stop_condition
    LD A, 0x01
    OR A
    RET
.gt2:
    CALL I2C_Restart_condition
    LD C, RTCLOCK_I2C_ADDRESS+1 ; RT Clk address, Read
    CALL I2C_SendByte
    JP Z, .gt3
    LD A, 0x04
    LD (RT_CLOCK_RESULT_CODE), A
    CALL I2C_Stop_condition
    LD A, 0x01
    OR A
    RET
.gt3:
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

    CALL I2C_Stop_condition
    LD A, 0x00
    OR A

    RET

RtClock_SetTime: ; set time from (HL) - HL to be reset after by user
    LD A, 0x00
    LD (RT_CLOCK_RESULT_CODE), A

    CALL I2C_Start_condition
    LD C, RTCLOCK_I2C_ADDRESS ; RT Clk Address, Write
    CALL I2C_SendByte
    JP Z, .gt1
    LD A, 0x05
    LD (RT_CLOCK_RESULT_CODE), A
    CALL I2C_Stop_condition
    LD A, 0x01
    OR A
    RET
.gt1:
    LD C, 0x00 ; Send Start Address - no update of sec
    CALL I2C_SendByte
    JP Z, .gt2
    LD A, 0x06
    LD (RT_CLOCK_RESULT_CODE), A
    CALL I2C_Stop_condition
    LD A, 0x01
    OR A
    RET
.gt2:
    LD C, (HL) 
    CALL I2C_SendByte
    JP Z, .gt3
    LD A, 0x07
    LD (RT_CLOCK_RESULT_CODE), A
    CALL I2C_Stop_condition
    LD A, 0x01
    OR A
    RET
.gt3:
    INC HL
    LD C, (HL) 
    CALL I2C_SendByte
    JP Z, .gt4
    LD A, 0x08
    LD (RT_CLOCK_RESULT_CODE), A
    CALL I2C_Stop_condition
    LD A, 0x01
    OR A
    RET
.gt4:
    INC HL
    LD C, (HL) 
    CALL I2C_SendByte
    JP Z, .gt5
    LD A, 0x09
    LD (RT_CLOCK_RESULT_CODE), A
    CALL I2C_Stop_condition
    LD A, 0x01
    OR A
    RET
.gt5:
    INC HL
    LD C, (HL) 
    CALL I2C_SendByte
    JP Z, .gt6
    LD A, 0x0A
    LD (RT_CLOCK_RESULT_CODE), A
    CALL I2C_Stop_condition
    LD A, 0x01
    OR A
    RET
.gt6:
    INC HL
    LD C, (HL) 
    CALL I2C_SendByte
    JP Z, .gt7
    LD A, 0x0B
    LD (RT_CLOCK_RESULT_CODE), A
    CALL I2C_Stop_condition
    LD A, 0x01
    OR A
    RET
.gt7:
    INC HL
    LD C, (HL) 
    CALL I2C_SendByte
    JP Z, .gt8
    LD A, 0x0C
    LD (RT_CLOCK_RESULT_CODE), A
    CALL I2C_Stop_condition
    LD A, 0x01
    OR A
    RET
.gt8:
    INC HL
    LD C, (HL) 
    CALL I2C_SendByte
    JP Z, .gt9
    LD A, 0x0C
    LD (RT_CLOCK_RESULT_CODE), A
    CALL I2C_Stop_condition
    LD A, 0x01
    OR A
    RET
.gt9:
    CALL I2C_Stop_condition

    LD A, 0x00
    OR A ; Put the Z Flag at Z to indicate success
 
    RET

    ENDIF