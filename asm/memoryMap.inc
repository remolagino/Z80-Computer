
    IFNDEF __MEMORY_MAP__
    DEFINE __MEMORY_MAP__ 1


; ============ RAM START Address ==============
RAM_START EQU 0x4000 ; Start of RAM

; =============== VARIABLES ADDRESS ================
BUFFER_FLAG EQU RAM_START ; buffer flag (bitmap) Insert Mode
DRIVE_LETTER EQU RAM_START + 0x01 ; contains the letter of the drive
FILE_SYSTEM EQU RAM_START + 0x02 ; contains the type of the filesystem
PROGRAM_BASE_ADDRESS EQU 0x5000

; ======= Command characters buffer =======
BUFFER_ADDRESS EQU RAM_START + 0x10 ; buffer address
BUFFER_SIZE EQU 0x41 ; buffer size (65 bytes) including leading 0x00
BUFFER_END EQU BUFFER_ADDRESS + BUFFER_SIZE ; end of buffer
BUFFER_START EQU BUFFER_ADDRESS ; start of buffer

; ======= Keypad Variables =======
MODIFER_STATE EQU RAM_START + 0x0100 ; 1 byte
MODIFERS EQU RAM_START + 0x0101 ; 1 byte
KEYPAD_BUFFER EQU RAM_START + 0x0102 ; 4 characters buffer
KEYPAD_STATE EQU RAM_START + 0x0110 ; Keypad state - ROWs * COLS bytes
KEYBOARD_STATE EQU KEYPAD_STATE

    ENDIF ; __MONITOR_INC__
    