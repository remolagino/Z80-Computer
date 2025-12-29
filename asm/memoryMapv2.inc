
    IFNDEF __MEMORY_MAP__
    DEFINE __MEMORY_MAP__ 1


; ============ RAM START Address ==============
RAM_START EQU 0xC000 ; Start of RAM (block 4 of MMU)- variables area 

; =============== VARIABLES ADDRESS ================
BUFFER_FLAG EQU RAM_START ; buffer flag (bitmap) Insert Mode
DRIVE_LETTER EQU RAM_START + 0x01 ; contains the letter of the drive
FILE_SYSTEM EQU RAM_START + 0x02 ; contains the type of the filesystem
PROGRAM_BASE_ADDRESS EQU 0x4000 ; Block 2 of the MMU

; ======= Command characters buffer =======
LINE_EDIT_LINESTART EQU RAM_START + 0x0C ; start of the line on the screen (word)
LINE_EDIT_INSERT_MODE EQU RAM_START + 0x0E ; insert mode (0 = overwrite, 1 = insert)
LINE_EDIT_BUFFER_ADDRESS EQU RAM_START + 0x10 ; buffer address
LINE_EDIT_BUFFER_SIZE EQU 80 ; buffer size (80 bytes) including leading 0x00
LINE_EDIT_BUFFER_END EQU LINE_EDIT_BUFFER_ADDRESS + LINE_EDIT_BUFFER_SIZE ; end of buffer
LINE_EDIT_BUFFER_START EQU LINE_EDIT_BUFFER_ADDRESS ; start of buffer

; ======= Keypad Variables =======
;MODIFER_STATE EQU RAM_START + 0x0100 ; 1 byte
KEYBOARD_MODIFIERS EQU RAM_START + 0x0101 ; 1 byte
KEYBOARD_CAPSLOCK_STATUS EQU RAM_START + 0x0102 ; 1 byte
;KEYPAD_BUFFER EQU RAM_START + 0x0102 ; 4 characters buffer
;KEYPAD_STATE EQU RAM_START + 0x0110 ; Keypad state - ROWs * COLS bytes
KEYBOARD_STATE EQU RAM_START + 0x0110 ; Keyboard state - ROWs * COLS bytes

    ENDIF ; __MONITOR_INC__
    