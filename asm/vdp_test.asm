; V9938 Blue Screen Test Program for Z80
; RAM_START EQU 0x4000 ; Start of RAM
; ======= Keypad Variables =======

    ORG     0x5000          ; Start address
    include "../jumpTable.inc"
     include "memoryMapv2.inc"
    JP Main

    include "../lib/stdio.asm"
    include "lineEdit.asm"

SCROLL_LINE_IDX EQU 25 ; line index to start scrolling



Main:
    LD HL, CR_LF
    CALL PrintString

; STREAM_IN_KEYBOARD|
 ;   LD A, STREAM_OUT_VDP|STREAM_OUT_SERIAL|STREAM_IN_KEYBOARD|STREAM_IN_SERIAL
    LD A, STREAM_OUT_VDP|STREAM_IN_KEYBOARD|STREAM_IN_SERIAL
    LD (STREAM_SELECT), A
    LD HL, STREAM_MSG
    CALL PrintString
    LD A, (STREAM_SELECT)
    LD HL, WORKING_MEMORY_START
    CALL Hex2Str
    CALL PrintString
    LD HL, CR_LF
    CALL PrintString
    LD HL, CR_LF
    CALL PrintString

    CALL INIT_PATTERN_LAYOUT_TABLE
    CALL INIT_COLOR_TABLE

    CALL Keyboard_Init
    CALL LineEdit_Init

    LD HL, 0x0000

    LD B, 0
    LD C, 0x01
    CALL Set_Blink

.eventLoop:
    LD DE, MSG_PROMPT
    CALL PutS
;    CALL Display_HL_In_Hex
    CALL LineEdit

    LD DE, CR_LF
    CALL PutS

; command management
    LD A, (LINE_EDIT_BUFFER_ADDRESS)
    CP '²'
    JP Z, .endLoop
    CP 0x00 ; 
    JP Z, .eventLoop ; empty line, nothing to display
    CP '*'
    JP Z, .dumpMem ; dump memory
    LD DE, LINE_EDIT_BUFFER_ADDRESS
    CALL PutS_LN
    JP .eventLoop

.dumpMem:
    PUSH HL
    LD HL, LINE_EDIT_BUFFER_ADDRESS +2 ; skip the first char
    CALL Str2Digits
    JP NZ, .dumpMemError ; invalid number
    LD HL, DE
;    LD HL, 0x0000
    LD DE, WORKING_MEMORY_START
    CALL MemoryDump
    POP HL
    LD DE, WORKING_MEMORY_START
    CALL PutS_LN
    JP .eventLoop
.dumpMemError:
    POP HL
    LD DE, MEM_DUMP_ERROR
    CALL PutS_LN
    JP .eventLoop

.endLoop:
    LD HL, CR_LF
    CALL PrintString
    RET 


; Display_HL_In_Hex:
;     PUSH AF
;     PUSH BC
;     PUSH HL
;     LD BC, HL
;     LD HL, .DISPLAY_VAR+2
;     LD A, B
;     CALL Hex2Str
;     LD HL, .DISPLAY_VAR+4
;     LD A, C
;     CALL Hex2Str
;     LD HL, .DISPLAY_VAR+6
;     LD (HL), ' '
;     LD HL, .DISPLAY_VAR
;     CALL PrintString
;     POP HL
;     POP BC
;     POP AF
;     RET
; .DISPLAY_VAR : DB "0x0000 ", 0x00



INIT_PATTERN_LAYOUT_TABLE: ; write at adress 0x0000
    PUSH AF
    PUSH BC
    PUSH HL

    LD HL, PATTERN_LAYOUT_TABLE_BASE_ADDR
    LD A, VRAM_WRITE_MODE
    CALL Set_VRAM_Address
    LD HL, 80*27 ; number of bytes to write (0x0B0D = 2821 bytes)
.loop:
    LD A, ' ' ; value to write to initialize VRAM
    OUT (VRAM_DATA), A
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    DEC HL
    LD A, H
    OR L
    JP NZ, .loop
.loopEnd:
    POP HL
    POP BC
    POP AF
    RET

INIT_COLOR_TABLE: ; write at adress 0x0000
    PUSH AF
    PUSH BC
    PUSH HL
    LD HL, COLOR_TABLE_BASE_ADDR
    LD A, VRAM_WRITE_MODE
    CALL Set_VRAM_Address

    LD HL, 270 ; number of bytes to write (0x0B0D = 2821 bytes)
.loop:
    LD A, 0x00 ; value to write to initialize VRAM
    OUT (VRAM_DATA), A
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    DEC HL
    LD A, H
    OR L
    JP NZ, .loop
.loopEnd:
    POP HL
    POP BC
    POP AF
    RET


CR_LF:
    DB CR_KEY_CODE, LF_KEY_CODE, 0x00 ; Carriage return + line feed
STREAM_MSG:
    DB "Stream Selected : ", 0x00
MSG_PROMPT:
    DB "A:\\>", 0x00
DEBUG:
    DB "DEBUG", CR_KEY_CODE, LF_KEY_CODE, 0x00
MEM_DUMP_ERROR:
    DB "Memory Dump Error : Invalid Address",0x00
    END