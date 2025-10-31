; Label pointing to subroutines in the ROM
    IFNDEF __JUMP_TABLE__
    DEFINE __JUMP_TABLE__ 1

JUMP_TABLE EQU 0x1900 ; Start of the jump table
SENDCHAR_HL EQU JUMP_TABLE ; SendChar in HL Register
SENDCHAR_IX EQU JUMP_TABLE + 3 ; SendChar in HL Register
SENDCHAR_A EQU JUMP_TABLE + 6 ; SendChar in A Register
PRINT_STRING EQU JUMP_TABLE + 9 ; Print a message (0 terminated string, address in HL)
RECEIVE_CHAR_A EQU JUMP_TABLE + 12 ;  Wait for a character to be received from port A (stored in A)
RECEIVE_CHAR_B EQU JUMP_TABLE + 15 ; Wait for a character to be received from port B (stored in A)
PRINT_HEX EQU JUMP_TABLE + 18 ; Print memory in hex format (address in HL, always 16 x16 bytes)
HEX2STR EQU JUMP_TABLE + 21 ; display a number in hex format (number in A)
CHAR2DIGIT EQU JUMP_TABLE + 24; convert one 0-9-A-F character (in A) to a number (in A)
STR2DIGITS EQU JUMP_TABLE + 27; Convert a string (in HL) to a number (in DE) Zero flag Z is success
STRING_LENGTH EQU JUMP_TABLE + 30 ; Calculate the length of the string in HL, return in A
SPACE_REMOVAL EQU JUMP_TABLE +33 ; Remove leading spaces from the string (from HL)
GET_BASE_ADDRESS_HL EQU JUMP_TABLE + 36 ; return the return address of the CALL in HL
GET_BASE_ADDRESS_BC EQU JUMP_TABLE + 39 ; return the return address of the CALL in BC
GET_BASE_ADDRESS_DE EQU JUMP_TABLE + 42 ; return the return address of the CALL in DE
GET_BASE_ADDRESS_IX EQU JUMP_TABLE + 45 ; return the return address of the CALL in IX
GET_BASE_ADDRESS_IY EQU JUMP_TABLE + 48 ; return the return address of the CALL in IY
KEYPAD_SCAN EQU JUMP_TABLE + 51 ; Read the keypad and return the keys in KEYPAD_BUFFER
HEX2BCD EQU JUMP_TABLE + 54 ; Convert a hex number in E to BCD in HL
    
    
    ENDIF
