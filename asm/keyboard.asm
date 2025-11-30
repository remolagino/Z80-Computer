; Keyboard Driver

    IFNDEF __KEYBOARD__
    DEFINE __KEYBOARD__ 1



 
KEYBOARD_IO_ADDRESS EQU 0x60 ; Keypad Columns address
; KEYBOARD_COLUMNS EQU 0x03 ; number of columns
; KEYBOARD_ROWS EQU 0x05 ; number of rows
; KEYBOARD_MODIFIERS EQU 0x03 ; modifiers column

KEYBOARD_BUFFER_SIZE EQU 0x09 ; buffer length for keys

; SHIFT EQU 0x01
; CTRL EQU 0x02
; ALT EQU 0x08

    include "memoryMapv2.inc"
    include "ringBuffer.asm"
    include "keyboard.inc"
 ;   include "keypad.inc"

Keyboard_Scan: ; Scan the keypad columns
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH IX
; Read modifiers keys (shift, ctrl, alt)
    IN A, (KEYBOARD_IO_ADDRESS + KEYBOARD_MODIFIERS_COL)
    LD (KEYBOARD_MODIFIERS),A
; Keyboard scan
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
    LD A, 0x20 ; set the key as pressed; debounce counter
    LD (DE), A
    JP .continue
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
    CP KEYBOARD_IO_ADDRESS + KEYBOARD_COLUMNS ; Check if we have scanned all columns 
    JP NZ, .colLoop ; If not, continue scanning

; Read the Control Key column
    LD IX, CTRL_KEYS_MATRIX ; Pointer to control keys Columns data
    IN A, (KEYBOARD_IO_ADDRESS + KEYBOARD_CONTROL_COL)
    LD B, 8 ; Number of modifier keys to scan (8 bits)
.controlRowLoop:
    PUSH AF
    BIT 0, A ; Check if the bit is Set
    JP Z, .ctrlNotPressed ; If not pressed, skip to next bit
    ;The button is pressed
.ctrlPressed:
    LD A, (DE)
    OR A ; check if the state is already set
    ;The button was not already pressed
    JP NZ, .ctrlContinue
    PUSH IY
    LD  IY, KBD_RING_BUFFER
    LD A, (IX)
    CALL RING_PUT
    POP IY
    LD A, 0x40 ; set the key as pressed; debounce counter
    LD (DE), A
    JP .ctrlContinue
.ctrlNotPressed:
    LD A, (DE) 
    OR A; check if the key was released
    JP Z, .ctrlContinue 
;    CP 0x01
;    CALL Z, OnKeyReleased
    LD A, (DE)
    DEC A ; decrement the debounce counter
    LD (DE), A
.ctrlContinue:
    POP AF
    SRL A ; Shift right to check next bit
    INC IX ; Move to next row data
    INC DE
    DJNZ .controlRowLoop ; Loop for all bits in the column

.exit:
    POP IX
    POP DE
    POP BC
    POP AF
    RET


OnKeyPressed:
    PUSH AF
    PUSH BC
    PUSH IY
    LD IY, KBD_RING_BUFFER
    LD A, (KEYBOARD_MODIFIERS)
    LD B, A
    AND SHIFT ; test for shift
    JP NZ, .shiftMatrix
    LD A, B
    AND CTRL ; test for CTRL
    JP NZ, .ctrlMatrix
    LD A, B
    AND ALT ; test for ALT
    JP NZ, .altMatrix
; no modifier key
    LD A, (IX)
    JP .exit
.shiftMatrix:
    LD A, (IX + SHIFT_MATRIX -DECODE_MATRIX )
    JP .exit
.ctrlMatrix:
    LD A, (IX + CTRL_MATRIX - DECODE_MATRIX)
    JP .exit
.altMatrix:
    LD A, (IX + ALT_MATRIX - DECODE_MATRIX)
    JP .exit
.exit:   
    CALL RING_PUT
    POP IY
    POP BC
    POP AF
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

KBD_RING_BUFFER RING_BUFFER 0x0000, 0x0000, KEYBOARD_BUFFER_SIZE, KBD_BUFFER_DATA

KBD_BUFFER_DATA:
    BLOCK KEYBOARD_BUFFER_SIZE, 0x00

    ENDIF ; __KEYBOARD__