; Keyboard Driver

    IFNDEF __MKEYBOARD__
    DEFINE __MKEYBOARD__ 1



 
M_KEYBOARD_IO_ADDRESS EQU 0x60 ; Keypad Columns address

    include "mkeyboard_memoryMap.inc"
    include "../lib/keyboard.inc"


mKeyboard_Init:

    PUSH BC
    PUSH HL
    LD HL, M_KEYBOARD_STATE
    LD B, M_KEYBOARD_ROWS * M_KEYBOARD_COLUMNS + 8 ; +1 for control keys column
    LD A, 0x00
.initStateLoop:
    LD (HL), A
    INC HL
    DJNZ .initStateLoop
    ; Set default handlers (can be overridden by user)
    LD HL, DefaultKeyPressedHandler
    LD (M_KEYBOARD_ONKEYPRESSED_HANDLER), HL
    LD HL, DefaultKeyReleasedHandler
    LD (M_KEYBOARD_ONKEYRELEASED_HANDLER), HL
    POP HL
    POP BC
    
    RET



mKeyboard_Scan: ; Scan the keypad columns
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH IX
; Read modifiers keys (shift, ctrl, alt)
    IN A, (M_KEYBOARD_IO_ADDRESS + KEYBOARD_MODIFIERS_COL)
    LD (M_KEYBOARD_MODIFIERS),A
; Keyboard scan
    LD C, M_KEYBOARD_IO_ADDRESS
    LD IX, DECODE_MATRIX ; Pointer to rows data
    LD DE, M_KEYBOARD_STATE
.colLoop:
    IN A, (C)
    LD B, M_KEYBOARD_ROWS ; Number of bits to scan (5 bits per column)
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
    CALL mOnKeyPressed
    LD A, 0x20 ; set the key as pressed; debounce counter
    LD (DE), A
    JP C, .earlyExit ; If the callback set Carry Flag, exit early without scanning further keys
    JP .continue
.notPressed:
    LD A, (DE) 
    OR A; check if the key was released
    JP Z, .continue 
    CP 0x01
    CALL Z, mOnKeyReleased
    JP C, .earlyExit ; If the callback set Carry Flag, exit early without scanning further keys
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
    CP M_KEYBOARD_IO_ADDRESS + M_KEYBOARD_COLUMNS ; Check if we have scanned all columns 
    JP NZ, .colLoop ; If not, continue scanning

; Read the Control Key column
; Why the specific process for them : because there are 8 keys in this column 
; but only 5 keys in the other columns. So either we handle them separately
; or we add 3 dummy rows in the other columns (wasting 3x15 process loop)
    LD IX, CTRL_KEYS_MATRIX ; Pointer to control keys Columns data
    IN A, (M_KEYBOARD_IO_ADDRESS + KEYBOARD_CONTROL_COL)
    LD B, 8 ; Number of modifier keys to scan (8 bits)
.controlRowLoop:
    PUSH AF
    BIT 0, A ; Check if the bit is Set
    JP Z, .ctrlRowNotPressed ; If not pressed, skip to next bit
    ;The button is pressed
.ctrlRowPressed:
    LD A, (DE)
    OR A ; check if the state is already set
    ;The button was not already pressed
    JP NZ, .ctrlRowContinue
    CALL mOnKeyPressed
    LD A, 0x20 ; set the key as pressed; debounce counter
    LD (DE), A
    JP C, .earlyExit ; If the callback set Carry Flag, exit early without scanning further keys
    JP .ctrlRowContinue
.ctrlRowNotPressed:
    LD A, (DE) 
    OR A; check if the key was released
    JP Z, .ctrlRowContinue 
    CP 0x01
    CALL Z, mOnKeyReleased
    JP C, .earlyExit ; If the callback set Carry Flag, exit early without scanning further keys
    LD A, (DE)
    DEC A ; decrement the debounce counter
    LD (DE), A

.ctrlRowContinue:
    POP AF
    SRL A ; Shift right to check next bit
    INC IX ; Move to next row data
    INC DE
    DJNZ .controlRowLoop ; Loop for all bits in the column

.Exit: 
    POP IX
    POP DE
    POP BC
    POP AF
    RET
.earlyExit: ; exit early because a callback returned Carry Flag Set
    POP AF
    POP IX
    POP DE
    POP BC
    POP AF
    SCF
    RET

DefaultKeyPressedHandler:
    RET

DefaultKeyReleasedHandler:
    RET

mOnKeyPressed:
    PUSH BC
    PUSH DE
    PUSH HL
    LD A, (IX)
    LD HL, (M_KEYBOARD_ONKEYPRESSED_HANDLER)
    RST 0x10
    POP HL
    POP DE
    POP BC
    RET

mOnKeyReleased:
    PUSH BC
    PUSH DE
    PUSH HL
    LD A, (IX)
    LD HL, (M_KEYBOARD_ONKEYRELEASED_HANDLER)
    RST 0x10
    POP HL
    POP DE
    POP BC
    RET

    ENDIF ; __KEYBOARD__