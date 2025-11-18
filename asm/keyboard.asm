; Keyboard Driver

    IFNDEF __KEYBOARD__
    DEFINE __KEYBOARD__ 1



 
KEYBOARD_IO_ADDRESS EQU 0x60 ; Keypad Columns address
KEYBOARD_COLUMNS EQU 0x03 ; number of columns
KEYBOARD_ROWS EQU 0x05 ; number of rows
KEYBOARD_MODIFIERS EQU 0x03 ; modifiers column

KEYBOARD_BUFFER_SIZE EQU 0x09 ; buffer length for keys

    include "memoryMap.inc"
    include "ringBuffer.asm"


Keyboard_Scan: ; Scan the keypad columns

    PUSH AF
    PUSH BC
    PUSH DE
    PUSH IX
    LD C, KEYBOARD_IO_ADDRESS
    LD IX, DECODE_MATRIX ; Pointer to rows data
    LD DE, KEYBOARD_STATE
;    LD HL, KEYPAD_BUFFER ; Pointer to the buffer for keys 
.colLoop:
    IN A, (C)
    LD B, KEYBOARD_ROWS ; Number of bits to scan (5 bits per column)
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
    CP KEYBOARD_IO_ADDRESS + KEYBOARD_COLUMNS +1 ; Check if we have scanned all columns 
    JP NZ, .colLoop ; If not, continue scanning
.exit:
    POP IX
    POP DE
    POP BC
    POP AF
    RET

OnKeyPressed:
    PUSH IY
    LD IY, KBD_RING_BUFFER
    LD A, (IX)
    CALL RING_PUT
    POP IY
    RET

OnKeyReleased:
    RET

Keyboard_GetKey: ; return char in A, 0x00 if none
    PUSH IY
    LD IY, KBD_RING_BUFFER
    CALL RING_IS_EMPTY
    CALL C, Keyboard_Scan
    CALL RING_GET
    POP IY
    RET 

Keyboard_UngetKey: ; put char in A back in the ring buffer
    PUSH IY
    LD IY, KBD_RING_BUFFER
    CALL RING_UNGET
    POP IY
    RET 

TREMA EQU 0xA8

DECODE_MATRIX: ; organised by columns
    DB '^', 'e', 0x12, 'a', ' '
    DB TREMA, 0x11, '5', 0x13, 0x00
    DB '~', '9', 0x14, '3', '.'
    DB '-', 'p', 0x00, 0x0D, 0x00

KBD_RING_BUFFER RING_BUFFER 0x0000, 0x0000, KEYBOARD_BUFFER_SIZE, KBD_BUFFER_DATA

KBD_BUFFER_DATA:
    BLOCK KEYBOARD_BUFFER_SIZE, 0x00

    ENDIF ; __KEYBOARD__