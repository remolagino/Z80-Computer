
    IFNDEF __MEMORY_MAP__
    DEFINE __MEMORY_MAP__ 1

    MACRO CALL_HL 
        RST 0x10
    ENDM

; ====== STACK Address ======
STACK_TOP EQU 0xFF00 ; adresse de la pile (top of stack)

; ============ MONITOR RAM START Address ==============
MONITOR_RAM_START EQU 0xC000 ; Start of RAM (block 4 of MMU)- variables area 
PROGRAM_BASE_ADDRESS EQU 0x4000 ; Block 2 of the MMU

; =============== INTERRUPT ROUTINE ADDRESS ============
INTERRUPT_VECTOR EQU MONITOR_RAM_START

; ============== File System Type ================
FS_SERIAL EQU 0x00
FS_SDCARD EQU 0x01
FS_EEPROM EQU 0x02
FS_START EQU MONITOR_RAM_START + 2
DRIVE_LETTER EQU FS_START  ; contains the letter of the drive
FILE_SYSTEM EQU DRIVE_LETTER + 0x01 ; contains the type of the filesystem
FS_CMD_CWD EQU FILE_SYSTEM + 0x01 ; address to the cwd command
FS_CMD_CD EQU FS_CMD_CWD + 0x02
FS_CMD_LS EQU FS_CMD_CD + 0x02
FS_CMD_RUN EQU FS_CMD_LS + 0x02
FS_CMD_CAT EQU FS_CMD_RUN + 0x02
FS_END EQU FS_CMD_CAT + 0x02

; ======= Line Edit Variables =======
LINE_EDIT_START EQU FS_END  ; start of line edit variables
LINE_EDIT_LINESTART EQU LINE_EDIT_START + 0x00 ; start of the line on the screen (word)
LINE_EDIT_INSERT_MODE EQU LINE_EDIT_LINESTART + 0x02 ; insert mode (0 = overwrite, 1 = insert)
LINE_EDIT_BUFFER_ADDRESS EQU LINE_EDIT_INSERT_MODE + 0x01 ; buffer address
LINE_EDIT_BUFFER_SIZE EQU 75  ; buffer size (75 bytes) including leading 0x00
LINE_EDIT_BUFFER_END EQU LINE_EDIT_BUFFER_ADDRESS + LINE_EDIT_BUFFER_SIZE ; end of buffer

; ======= Keyboard Variables =======
KEYBOARD_RAM_START EQU LINE_EDIT_BUFFER_END + 0x0010 ; Start of Keyboard RAM area
    include "../lib/keyboard_memoryMap.inc"

; ======= STDIO Variables =======
STDIO_MEMORY_START EQU KEYBOARD_RAM_END + 10; start of stdio memory area
STDIO_STREAM_SELECT EQU STDIO_MEMORY_START
STDIO_DEAD_KEY EQU STDIO_STREAM_SELECT + 1
CURSOR_IDX EQU STDIO_DEAD_KEY +1 ; word
STDIO_SCROLL_MEMORY EQU CURSOR_IDX + 2
STDIO_SCROLL_MEMORY_SIZE EQU 128 ; size of stdio memory area
STDIO_MEMORY_END EQU STDIO_SCROLL_MEMORY + STDIO_SCROLL_MEMORY_SIZE ; end of stdio memory area

; ======== I2C - RTCLOCK Variables =========
I2C_PIO_STATUS EQU STDIO_MEMORY_END
I2C_MEMORY_END EQU I2C_PIO_STATUS + 1

; ======= Working Memory =======
WORKING_MEMORY_START EQU STDIO_MEMORY_END ; start of working memory

    ENDIF ; __MONITOR_INC__
    