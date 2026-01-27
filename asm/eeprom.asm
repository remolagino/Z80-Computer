; ------------------  I2C RT CLOCK (DS3231)   ---------------

    IFNDEF __EEPROM__
    DEFINE __EEPROM__ 1


;    INCLUDE "jumpTable.inc"
    INCLUDE "./lib/I2C.asm"


EEPROM_I2C_ADDRESS EQU 0xAE

EEPROM_INIT_MSG:
    DB "Init EEPROM : ", 0x00
EEPROM_INIT_SUCCESS:
    DB "Success", 0x00
EEPROM_INIT_FAIL:
    DB "Failed", 0x00
EEPROM_RESULT_CODE:
    DB 0x00


EEPROM_InitCheck:
;    CALL I2C_Init
    LD HL, EEPROM_INIT_MSG
    CALL PRINT_STRING
    LD A, 0x00
    LD (EEPROM_RESULT_CODE), A
    CALL I2C_Stop_condition
    LD C, EEPROM_I2C_ADDRESS ; RT Clk Address, Write
    ; CALL I2C_Start_condition
    ; CALL I2C_SendByte
    CALL EEPROM_SendAddress ; ack polling
    JP Z, .eeprom_initCheck_success
    LD HL, EEPROM_INIT_FAIL
    CALL PRINT_STRING
    CALL I2C_Stop_condition
    LD A, 0x01
    LD (EEPROM_RESULT_CODE), A
    LD A, 0x01
    OR A
    RET
.eeprom_initCheck_success:
    LD HL, EEPROM_INIT_SUCCESS
    CALL PRINT_STRING
    CALL I2C_Stop_condition
    LD A, 0x00
    OR A
    RET

EEPROM_SendAddress:    ; first message with device address and Ack Polling - byte to send in C - Ack result in Flag Z (Ack=Z) - use A, B
    CALL I2C_Start_condition
    CALL I2C_SendByte
    JP NZ, EEPROM_SendAddress
    RET

EEPROM_Read_Page: ; Get result in (HL) - HL to be reset after by user
    LD A, 0x00
    LD (EEPROM_RESULT_CODE), A

    LD C, EEPROM_I2C_ADDRESS ; RT Clk Address, Write
    ; CALL I2C_Start_condition
    ; CALL I2C_SendByte
    CALL EEPROM_SendAddress
    JP Z, .gt1
    LD A, 0x02
    LD (EEPROM_RESULT_CODE), A
    CALL I2C_Stop_condition
    LD A, 0x01
    OR A
    RET
.gt1:
    LD C, 0x00 ; Send Start Address MSB
    CALL I2C_SendByte
    JP Z, .gt1_1
    LD A, 0x03
    LD (EEPROM_RESULT_CODE), A
    CALL I2C_Stop_condition
    LD A, 0x01
    OR A
    RET
.gt1_1:
    LD C, 0x00 ; Send Start Address LSB
    CALL I2C_SendByte
    JP Z, .gt2
    LD A, 0x03
    LD (EEPROM_RESULT_CODE), A
    CALL I2C_Stop_condition
    LD A, 0x01
    OR A
    RET
.gt2:
    CALL I2C_Restart_condition
    LD C, EEPROM_I2C_ADDRESS+1 ; RT Clk address, Read
    CALL I2C_SendByte
    JP Z, .gt3
    LD A, 0x04
    LD (EEPROM_RESULT_CODE), A
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
    CALL I2C_Send_Ack
    CALL I2C_ReceiveByte
    LD (HL),C
    CALL I2C_Send_NAck
    CALL I2C_Stop_condition

    CALL I2C_Stop_condition
    LD A, 0x00
    OR A

    RET

EEPROM_Write: ; write data from (HL) to address (DE) - HL to be reset after by user
    LD A, 0x00
    LD (EEPROM_RESULT_CODE), A

    LD C, EEPROM_I2C_ADDRESS ; RT Clk Address, Write
    CALL I2C_Start_condition
    CALL I2C_SendByte
   ; CALL EEPROM_SendAddress
    JP Z, .gt1
    LD A, 0x10
    LD (EEPROM_RESULT_CODE), A
    CALL I2C_Stop_condition
    LD A, 0x01
    OR A
    RET
.gt1:
    LD C, D ; Send Start Address MSB
    CALL I2C_SendByte
    JP Z, .gt1_1
    LD A, 0x11
    LD (EEPROM_RESULT_CODE), A
    CALL I2C_Stop_condition
    LD A, 0x01
    OR A
    RET
.gt1_1:
    LD C, E ; Send Start Address LSB
    CALL I2C_SendByte
    JP Z, .gt2
    LD A, 0x12
    LD (EEPROM_RESULT_CODE), A
    CALL I2C_Stop_condition
    LD A, 0x01
    OR A
    RET
.gt2:
    CALL I2C_Delay
    LD C, (HL) 
    CALL I2C_SendByte
    JP Z, .gt3
    LD A, 0x13
    LD (EEPROM_RESULT_CODE), A
    CALL I2C_Stop_condition
    LD A, 0x01
    OR A
    RET
.gt3:
    CALL I2C_Stop_condition
    LD A, 0x00
    OR A ; Put the Z Flag at Z to indicate success
    RET

EEPROM_Write_Page: ; write data from (HL) - HL to be reset after by user
    LD A, 0x00
    LD (EEPROM_RESULT_CODE), A

    LD C, EEPROM_I2C_ADDRESS ; RT Clk Address, Write
    ; CALL I2C_Start_condition
    ; CALL I2C_SendByte
    CALL EEPROM_SendAddress
    JP Z, .gt1
    LD A, 0x05
    LD (EEPROM_RESULT_CODE), A
    CALL I2C_Stop_condition
    LD A, 0x01
    OR A
    RET
.gt1:
    LD C, 0x00 ; Send Start Address MSB
    CALL I2C_SendByte
    JP Z, .gt1_1
    LD A, 0x06
    LD (EEPROM_RESULT_CODE), A
    CALL I2C_Stop_condition
    LD A, 0x01
    OR A
    RET
.gt1_1:
    LD C, 0x00 ; Send Start Address LSB
    CALL I2C_SendByte
    JP Z, .gt2
    LD A, 0x06
    LD (EEPROM_RESULT_CODE), A
    CALL I2C_Stop_condition
    LD A, 0x01
    OR A
    RET
.gt2:
    LD C, (HL) 
    CALL I2C_SendByte
    JP Z, .gt3
    LD A, 0x07
    LD (EEPROM_RESULT_CODE), A
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
    LD (EEPROM_RESULT_CODE), A
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
    LD (EEPROM_RESULT_CODE), A
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
    LD (EEPROM_RESULT_CODE), A
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
    LD (EEPROM_RESULT_CODE), A
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
    LD (EEPROM_RESULT_CODE), A
    CALL I2C_Stop_condition
    LD A, 0x01
    OR A
    RET
.gt8:
    INC HL
    LD C, (HL) 
    CALL I2C_SendByte
    JP Z, .gt9
    LD A, 0x0D
    LD (EEPROM_RESULT_CODE), A
    CALL I2C_Stop_condition
    LD A, 0x01
    OR A
    RET
.gt9:
    INC HL
    LD C, (HL) 
    CALL I2C_SendByte
    JP Z, .gt10
    LD A, 0x0E
    LD (EEPROM_RESULT_CODE), A
    CALL I2C_Stop_condition
    LD A, 0x01
    OR A
    RET
.gt10:
    CALL I2C_Stop_condition

    LD A, 0x00
    OR A ; Put the Z Flag at Z to indicate success
 
    RET

    ENDIF