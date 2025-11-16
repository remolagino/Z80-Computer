; Keypad Driver

    IFNDEF __KEYPAD__
    DEFINE __KEYPAD__ 1



 
KEYPAD_IO_ADDRESS EQU 0x60 ; Keypad Columns address
KEYPAD_COLUMNS EQU 0x03 ; number of columns
KEYPAD_ROWS EQU 0x05 ; number of rows
KEYPAD_MODIFIERS EQU 0x03 ; modifiers column
KEYPAD_BUFFER_LENGTH EQU 0x04 ; buffer length for keys



Keypad_Scan: ; Scan the keypad columns
    LD C, KEYPAD_IO_ADDRESS
    LD IX, DECODE_MATRIX ; Pointer to rows data
    LD DE, KEYPAD_STATE
    LD HL, KEYPAD_BUFFER ; Pointer to the buffer for keys

.scanModifiers:
    IN A, (KEYPAD_IO_ADDRESS+ KEYPAD_MODIFIERS) ; Read the modifier keys
    PUSH AF
    BIT 3, A
    JP Z, .noEnter
    PUSH AF
    LD A, (MODIFER_STATE) ; Load the current modifier keys state
    OR A ; Check if Enter key is pressed
    JP NZ, .alreadyPressed
    LD A, 0x01
    LD (MODIFER_STATE), A ; Store the current modifier keys state
    LD A, 0x0D; Carriage return
    LD (HL), A ; Store the carriage return in the Buffer
    INC HL ; Increment the buffer pointer
;    CALL SendChar_A
    LD A, 0x0A ; Line feed
    LD (HL), A ; Store the line feed in the Buffer
    INC HL ; Increment the buffer pointer
;    CALL SendChar_A
.alreadyPressed:
    POP AF
    JP .continue_modifiers
.noEnter:
    LD A, 0x00
    LD (MODIFER_STATE), A ; Clear the modifier state
.continue_modifiers:
    POP AF
    AND 0x03 ; Mask to get only the modifier keys state
    LD (MODIFERS), A ; Store the modifier keys state

.colLoop:
    IN A, (C)
    LD B, KEYPAD_ROWS ; Number of bits to scan (8 bits per column)
.rowLoop:
    BIT 0, A ; Check if the bit is Set
    JP Z, .notPressed ; If not pressed, skip to next bit
    PUSH AF
    LD A, (DE) ; Load the current key state
    OR A ; check if the state is already set
    JP NZ, .alreadyPrinted
    PUSH AF
    LD A, (MODIFERS)
    CP 0x00
    JP NZ, .elseIf1
    LD A, (IX) ; Load the character from the decode matrix
    JP .printModifiedChar
.elseIf1:
    CP 0x01
    JP NZ, .elseIf2
    LD A, (IX+0x10) ; Load the character from the decode matrix
    JP .printModifiedChar
.elseIf2:
    CP 0x02
    JP NZ, .elseIf3
    LD A, (IX+0x20) ; Load the character from the decode matrix
    JP .printModifiedChar
.elseIf3:
    LD A, (IX+0x30) ; Load the character from the decode matrix
.printModifiedChar:
;    CALL SendChar_A ; display the key if not already set
    LD (HL), A
    LD A, L
    SUB KEYPAD_BUFFER
    CP KEYPAD_BUFFER_LENGTH
    JP Z, .endPrintModifiedChar
    INC HL ; Increment the buffer pointer
.endPrintModifiedChar:
    POP AF
.alreadyPrinted:
    LD A, 0x01 ; set the key as pressed
    LD (DE), A
    POP AF
    JP .continue
.notPressed:
    PUSH AF
    LD A, 0x00 ; Load the current row data
    LD (DE), A ; Clear the current row data
    POP AF
.continue:
    SRL A ; Shift right to check next bit
    INC IX ; Move to next row data
    INC DE
    DJNZ .rowLoop ; Loop for all bits in the column
    INC C
    LD A, C
    CP KEYPAD_IO_ADDRESS + KEYPAD_COLUMNS ; Check if we have scanned all columns 
    JP NZ, .colLoop ; If not, continue scanning
    RET

Keypad_Scan2: ; Scan the keypad columns
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH IX
    LD C, KEYPAD_IO_ADDRESS
    LD IX, DECODE_MATRIX2 ; Pointer to rows data
    LD DE, KEYPAD_STATE
    LD HL, KEYPAD_BUFFER ; Pointer to the buffer for keys 
.colLoop:
    IN A, (C)
    LD B, KEYPAD_ROWS ; Number of bits to scan (5 bits per column)
.rowLoop:
    PUSH AF
    BIT 0, A ; Check if the bit is Set
    JP Z, .notPressed ; If not pressed, skip to next bit
    ;The button is pressed
.Pressed:
    LD A, (DE)
    OR A ; check if the state is already set
    ;The button was not already pressed
    JP NZ, .continue
    CALL OnKeyPressed
    LD A, 0x40 ; set the key as pressed; debounce counter
    LD (DE), A
    POP AF ; the jump to exit skip the pop AF after continue so we put it here
    JP .exit ; early exit at the the first not processed click so as the 
    ; the keypadScan only call onKeyPressed once (to be compatible with getc)

.notPressed:
    LD A, (DE) 
    OR A; check if the key was released
    JP Z, .continue 
    CP 0x01
    CALL Z, OnKeyReleased
    LD A, (DE)
    DEC A ; decrement the debounce counter
    LD (DE), A

.continue:
    POP AF
    SRL A ; Shift right to check next bit
    INC IX ; Move to next row data
    INC DE

    DJNZ .rowLoop ; Loop for all bits in the column
    INC C
    LD A, C
    CP KEYPAD_IO_ADDRESS + KEYPAD_COLUMNS +1 ; Check if we have scanned all columns 
    JP NZ, .colLoop ; If not, continue scanning
.exit:
    POP IX
    POP DE
    POP BC
    POP AF
    RET


DECODE_MATRIX: ; organised by columns
    DB 0x08, '7', '4', '1', '0'
    DB '/', '8', '5', '2', 0x00
    DB '*', '9', '6', '3', '.',0x00
    DB 'a', 'b', 'c', 'd', 'e'
    DB 'f', 'g', 'h', 'i', 'j'
    DB 'k', 'l', 'm', 'n', 'o', 0x00
    DB 'A', 'B', 'C', 'D', 'E'
    DB 'F', 'G', 'H', 'I', 'J' 
    DB 'K', 'L', 'M', 'N', 'O', 0x00
    DB 'P', 'Q', 'R', 'S', 'T'
    DB 'U', 'V', 'W', 'X', 'Y'
    DB 'Z', '$', '£', 'ù', 'µ', 0x00

DECODE_MATRIX2: ; organised by columns
    DB 'D', '7', 0x12, '1', '0'
    DB '/', 0x11, '5', 0x13, 0x00
    DB '*', '9', 0x14, '3', '.'
    DB '-', '+', 0x00, 0x0D, 0x00


    ENDIF ; __KEYPAD__