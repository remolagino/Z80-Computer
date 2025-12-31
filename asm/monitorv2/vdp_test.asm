; V9938 Blue Screen Test Program for Z80
; RAM_START EQU 0x4000 ; Start of RAM
; ======= Keypad Variables =======

    ORG     0x5000          ; Start address
    include "../jumpTable.inc"
     include "memoryMapv2.inc"
    JP Main

    include "../lib/stdio.asm"
    include "lineEdit.asm"

; CURSOR_IDX:
;     DW 0 ; row 0, col 0

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
;    LD (CURSOR_IDX), HL ; put the cursor at 0
    LD C, 0x01
    CALL Set_Blink


.eventLoop:
    LD DE, MSG_PROMPT
    CALL PutS

    CALL LineEdit
    LD A, CR_KEY_CODE
    CALL PutC
    LD A, LF_KEY_CODE
    CALL PutC

    LD A, (LINE_EDIT_BUFFER_ADDRESS)
    CP 0x00
    JP Z, .scrollManagement ; empty line, continue loop
    CP '²'
    JP Z, .endLoop
    ; CP '*'
    ; CALL Z, ScrollTest
    LD DE, LINE_EDIT_BUFFER_ADDRESS
    CALL PutS_LN
.scrollManagement:
    PUSH BC
    LD BC, 80*15
    SBC HL, BC
    POP BC
    CALL P, ScrollTest
    JP .eventLoop

.endLoop:
    ; LD HL, CR_LF
    ; CALL PrintString
    RET                     ; or HALT

ScrollTest:
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL

    LD HL, 80
    LD C, 20 ; number of lines to read/write
.screenLoop:
; read line from vram
;    LD HL, 80
    LD A, VRAM_READ_MODE
    CALL Set_VRAM_Address
    LD DE, WORKING_MEMORY_START
    LD B, 80 ; number of bytes to read
.readLoop:
    IN A, (VRAM_DATA)
    LD (DE), A
    INC DE
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    DJNZ .readLoop
; write line to vram   
    ; LD A, 0x00
    ; LD (DE), A
    ; PUSH HL
    ; LD HL, WORKING_MEMORY_START   
    ; CALL PrintString
    ; LD HL, CR_LF
    ; CALL PrintString
    ; POP HL
    PUSH BC
    LD BC, 80 
    SBC HL, BC
    POP BC
    LD A, VRAM_WRITE_MODE
    CALL Set_VRAM_Address
    LD DE, WORKING_MEMORY_START
    LD B, 80 ; number of bytes to write
.writeLoop:
    LD A, (DE)
    OUT (VRAM_DATA), A
    INC DE
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    DJNZ .writeLoop
    PUSH BC
    LD BC, 160
    ADD HL, BC
    POP BC
    DEC C
    JP NZ, .screenLoop
    POP HL
    LD BC, 80 ; we position back HL to the start of the line
    SBC HL, BC
    POP DE
    POP BC
    POP AF

    RET

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

    END