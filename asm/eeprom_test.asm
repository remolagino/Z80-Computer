; ------------------  I2C EEPROM (24C32)   ---------------

    


; ------------- Program START -----------------
    .ORG 0x6000

    JP Main

    INCLUDE "jumpTable.inc"
    INCLUDE "eeprom.asm"
;    INCLUDE "I2C.asm"


Main:
    CALL I2C_Init

    CALL EEPROM_InitCheck
    LD A, 0x0D
    CALL SENDCHAR_A

    LD HL, EEPROM_TEST_WRITE_MSG
    CALL PRINT_STRING
    LD HL, EEPROM_WRITE_TEST
    CALL PRINT_STRING

    LD HL, EEPROM_WRITE_TEST
    LD DE, 0x0000
    CALL EEPROM_Write_Page
    CALL NZ, setTestFail

    LD A, 0x0D
    CALL SENDCHAR_A

    LD HL, EEPROM_READ_TEST
    CALL EEPROM_Read_Page
    CALL NZ, setTestFail

    LD HL, EEPROM_TEST_READ_MSG
    CALL PRINT_STRING
    LD HL, EEPROM_READ_TEST
    CALL PRINT_STRING

    RET
setTestFail:
    LD HL, EEPROM_TEST_MSG
    CALL PRINT_STRING
    LD A, (EEPROM_RESULT_CODE)
    CALL HEX2STR
    LD A, 0x0D
    CALL SENDCHAR_A

    RET

EEPROM_TEST_MSG:
    DB "test failed : ", 0x00
EEPROM_TEST_WRITE_MSG:
    DB "Written : ", 0x00
EEPROM_TEST_READ_MSG:
    DB "Read : ", 0x00
EEPROM_WRITE_TEST:
    DB "Coucou les loulous", 0x00
EEPROM_READ_TEST:
    DB "__________________", 0x00

    NOP
    NOP
    NOP
    NOP
 