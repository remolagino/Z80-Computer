
    IFNDEF __MEMORY_MAP__
    DEFINE __MEMORY_MAP__ 1


; ============ RAM START Address ==============
RAM_START EQU 0x4200 ; Start of RAM

; =============== VARIABLES ADDRESS ================
BUFFER_FLAG EQU RAM_START ; buffer flag (bitmap) Insert Mode
DRIVE_LETTER EQU RAM_START + 0x01 ; contains the letter of the drive
FILE_SYSTEM EQU RAM_START + 0x02 ; contains the type of the filesystem
PROGRAM_BASE_ADDRESS EQU 0x5000

; ======= Command characters buffer =======
EDIT_BUFFER_ADDRESS EQU RAM_START + 0x10 ; buffer address
EDIT_BUFFER_SIZE EQU 0x41 ; buffer size (65 bytes) including leading 0x00
EDIT_BUFFER_END EQU EDIT_BUFFER_ADDRESS + EDIT_BUFFER_SIZE ; end of buffer
EDIT_BUFFER_START EQU EDIT_BUFFER_ADDRESS ; start of buffer

; ======= Keypad Variables =======
;MODIFER_STATE EQU RAM_START + 0x0100 ; 1 byte
KEYBOARD_MODIFIERS EQU RAM_START + 0x0101 ; 1 byte
;KEYPAD_BUFFER EQU RAM_START + 0x0102 ; 4 characters buffer
KEYPAD_STATE EQU RAM_START + 0x0110 ; Keypad state - ROWs * COLS bytes
KEYBOARD_STATE EQU KEYPAD_STATE

    ENDIF ; __MONITOR_INC__
    