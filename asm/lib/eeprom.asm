; ------------------  I2C RT CLOCK (DS3231)   ---------------

    IFNDEF __EEPROM__
    DEFINE __EEPROM__ 1


;    INCLUDE "jumpTable.inc"
    INCLUDE "I2C.asm"


EEPROM_I2C_ADDRESS EQU 0xAE

EEPROM_INIT_MSG:
    DB "Init EEPROM : ", 0x00
EEPROM_INIT_SUCCESS:
    DB "Success", 0x00
EEPROM_INIT_FAIL:
    DB "Failed", 0x00
;EEPROM_RESULT_CODE:
 ;   DB 0x00



EEPROM_Init: ; Z Flag set if success, error code in A
    CALL I2C_Init
    CALL I2C_Stop_condition
    CALL I2C_Start_condition
    LD A, EEPROM_I2C_ADDRESS + I2C_WRITE; RT Clk Address, Write
    CALL I2C_SendByte
    LD A, 'A'
    JR NZ, .exit
    LD A, 0x00 ; set Z flag if success
    OR A
.exit:
    CALL I2C_Stop_condition
    RET



EEPROM_SendAddress: ; send Address to read or write - Address in DE
    LD A, D
    CALL I2C_SendByte
    LD A, 'C'
    JR NZ, .exit
    LD A, E
    CALL I2C_SendByte
    LD A, 'D'
    JR NZ, .exit
    LD A, 0x00
.exit:
    OR A ; Put the Z Flag at Z to indicate success
    RET

EEPROM_ByteWrite: ; write data in B to address in DE
    CALL I2C_Start_condition
    LD A, EEPROM_I2C_ADDRESS + I2C_WRITE; EEPROM Address, Write
    CALL I2C_SendByte ; send device address
    LD A, 'A'
    JR NZ, .exit
    CALL EEPROM_SendAddress ; send memory address
    JR NZ, .exit
    LD A, B ; put data to send in A
    CALL I2C_SendByte ; send data bytes
    LD A, 'B'
    JR NZ, .exit
    LD A, 0x00
.exit:
    OR A
    CALL I2C_Stop_condition
    RET

; write data from (HL) to address in DE - 32 bytes page. 
; * HL at end of page to allow for chaining calls for next page
EEPROM_PageWrite:
    PUSH BC
    PUSH DE
    CALL I2C_Start_condition
    LD A, EEPROM_I2C_ADDRESS + I2C_WRITE; EEPROM Address, Write
    CALL I2C_SendByte ; send device address
    LD A, 'A'
    JR NZ, .exit
    LD A, E
    AND 0x1F ; align to 32 bytes page boundary
    LD E,A
    CALL EEPROM_SendAddress ; send memory address
    JR NZ, .exit
    LD B, 32
.pageWriteLoop:
    LD A, (HL) ; put data to send in A
    CALL I2C_SendByte ; send data bytes
    LD A, 'E'
    JR NZ, .exit
    INC HL
    DJNZ .pageWriteLoop
    LD A, 0x00
.exit:
    OR A
    CALL I2C_Stop_condition
    POP DE
    POP BC
    RET

; write BC bytes of data from (HL) to address in DE (page boundary). 
EEPROM_BulkWrite:
    PUSH BC
    PUSH DE
    PUSH HL

    LD A, E
    AND 0x1F ; align to 32 bytes page boundary
    LD E,A
; divide BC by 32 to get number of full pages and remaining bytes
    PUSH BC ; keep orignial for the ramainer
    SRL B
    RR C
    SRL B
    RR C
    SRL B
    RR C
    SRL B
    RR C
.setupPage:
    CALL I2C_Start_condition
    LD A, EEPROM_I2C_ADDRESS + I2C_WRITE; EEPROM Address, Write
    CALL I2C_SendByte ; send device address
    JR NZ, .setupPage
    CALL EEPROM_SendAddress ; send memory address
    JR NZ, .errorPop
    LD A, B
    or C
    JR Z, .last32;  
    PUSH BC
    LD B, 32
.pageWriteLoop:
    LD A, (HL) ; put data to send in A
    CALL I2C_SendByte ; send data bytes
    LD A, 'E'
    JR NZ, .error2Pop
    INC HL
    INC DE
    DJNZ .pageWriteLoop
    CALL I2C_Stop_condition
    POP BC
    DEC BC
    LD A, B
    OR C
    JR NZ, .setupPage
.last32:
    POP BC ; restore original BC
    LD A, C
    AND 0x1F
    JP Z, .exit
.setupRemainerPage:
    CALL I2C_Start_condition
    LD A, EEPROM_I2C_ADDRESS + I2C_WRITE; EEPROM Address, Write
    CALL I2C_SendByte ; send device address
    JR NZ, .setupRemainerPage
    CALL EEPROM_SendAddress ; send memory address
    JR NZ, .errorPop
    LD B, C
.remainerWriteLoop:
    LD A, (HL) ; put data to send in A
    CALL I2C_SendByte ; send data bytes
    LD A, 'E'
    JR NZ, .errorPop
    INC HL
    INC DE
    DJNZ .remainerWriteLoop
    CALL I2C_Stop_condition
.exit:
    POP HL
    POP DE
    POP BC
    XOR A ; set Z flag
    RET
.error2Pop:
    POP BC ; pop of the 32 loop
.errorPop:
    POP BC ; pop of the remainer save
.error:
    OR A
    CALL I2C_Stop_condition
    POP HL
    POP DE
    POP BC
    RET



EEPROM_AckPolling:
    CALL I2C_Start_condition
    LD A, EEPROM_I2C_ADDRESS + I2C_WRITE; EEPROM Address, Write
    CALL I2C_SendByte ; send device address
    JR NZ, EEPROM_AckPolling
    CALL I2C_Stop_condition
    RET

EEPROM_RandomRead: ; read data from address in DE to A
    CALL I2C_Start_condition
    LD A, EEPROM_I2C_ADDRESS + I2C_WRITE; EEPROM Address, Write
    CALL I2C_SendByte ; send device address
    LD A, 'A'
    JR NZ, .exit
    CALL EEPROM_SendAddress ; send memory address
    JR NZ, .exit
    CALL I2C_Start_condition
    LD A, EEPROM_I2C_ADDRESS + I2C_READ; EEPROM Address, Read
    CALL I2C_SendByte ; send device address
    LD A, 'A'
    JR NZ, .exit
    CALL I2C_ReceiveByte ; receive data bytes
    CALL I2C_Stop_condition
    RET
.exit:
    OR A
    CALL I2C_Stop_condition
    RET


EEPROM_CurrentRead: ; read data from current address to A
    CALL I2C_Start_condition
    LD A, EEPROM_I2C_ADDRESS + I2C_READ; EEPROM Address, Read
    CALL I2C_SendByte ; send device address
    LD A, 'A'
    JR NZ, .exit
    CALL I2C_ReceiveByte ; receive data bytes
    CALL I2C_Stop_condition
    RET
.exit:
    OR A
    CALL I2C_Stop_condition
    RET


EEPROM_SequentialRead: ; read BC bytes from address DE to (HL)
    PUSH BC
    PUSH HL
    CALL I2C_Start_condition
    LD A, EEPROM_I2C_ADDRESS + I2C_WRITE; EEPROM Address, Write
    CALL I2C_SendByte ; send device address
    LD A, 'A'
    JR NZ, .exit
    CALL EEPROM_SendAddress ; send memory address
    JR NZ, .exit
    CALL I2C_Start_condition
    LD A, EEPROM_I2C_ADDRESS + I2C_READ; EEPROM Address, Read
    CALL I2C_SendByte ; send device address
    LD A, 'A'
    JR NZ, .exit
.readLoop:
    CALL I2C_ReceiveByte ; receive data bytes
    LD (HL), A
    INC HL
    DEC BC
    LD A, B
    OR C
    JR Z, .loopEnd
    CALL I2C_Send_Ack
    JP .readLoop
.loopEnd:
    LD A, 0x00
    LD (HL), A ; dummy write to HL to indicate end of read
    ; CALL I2C_Stop_condition
    ; POP HL
    ; POP BC
    ; RET
.exit:
    OR A
    CALL I2C_Stop_condition
    POP HL
    POP BC
    RET



    ENDIF