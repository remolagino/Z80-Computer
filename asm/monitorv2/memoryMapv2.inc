
    IFNDEF __MEMORY_MAP__
    DEFINE __MEMORY_MAP__ 1

; ====== STACK Address ======
STACK_TOP EQU 0xFF00 ; adresse de la pile (top of stack)

; ============ MONITOR RAM START Address ==============
MONITOR_RAM_START EQU 0xC000 ; Start of RAM (block 4 of MMU)- variables area 
PROGRAM_BASE_ADDRESS EQU 0x4000 ; Block 2 of the MMU

; =============== INTERRUPT ROUTINE ADDRESS ============
INTERRUPT_VECTOR EQU MONITOR_RAM_START

; =============== VARIABLES ADDRESS ================
BUFFER_FLAG EQU MONITOR_RAM_START +0x02; buffer flag (bitmap) Insert Mode
DRIVE_LETTER EQU MONITOR_RAM_START + 0x03 ; contains the letter of the drive
FILE_SYSTEM EQU MONITOR_RAM_START + 0x04 ; contains the type of the filesystem

; ======= Line Edit Variables =======
LINE_EDIT_START EQU MONITOR_RAM_START + 0x10 ; start of line edit variables
LINE_EDIT_LINESTART EQU LINE_EDIT_START + 0x00 ; start of the line on the screen (word)
LINE_EDIT_INSERT_MODE EQU LINE_EDIT_LINESTART + 0x02 ; insert mode (0 = overwrite, 1 = insert)
LINE_EDIT_BUFFER_ADDRESS EQU LINE_EDIT_INSERT_MODE + 0x01 ; buffer address
LINE_EDIT_BUFFER_SIZE EQU 75  ; buffer size (75 bytes) including leading 0x00
LINE_EDIT_BUFFER_END EQU LINE_EDIT_BUFFER_ADDRESS + LINE_EDIT_BUFFER_SIZE ; end of buffer

; ======= Keyboard Variables =======
KEYBOARD_RAM_START EQU LINE_EDIT_BUFFER_END + 0x0010 ; Start of Keyboard RAM area
    include "../lib/keyboard_memoryMap.inc"

; ======= STDIO Variables =======
STDIO_MEMORY_START EQU KEYBOARD_RAM_END ; start of stdio memory area
STDIO_MEMORY_SIZE EQU 128 ; size of stdio memory area
STDIO_MEMORY_END EQU STDIO_MEMORY_START + STDIO_MEMORY_SIZE ; end of stdio memory area

; ======= Working Memory =======
WORKING_MEMORY_START EQU STDIO_MEMORY_END ; start of working memory

    ENDIF ; __MONITOR_INC__
    