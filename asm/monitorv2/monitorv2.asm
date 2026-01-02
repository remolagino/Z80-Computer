; Monitor v2
; New version of the monitor using VDP for display
; and native keyboard for input
;
; 0. Set Stack Pointer
; 1. Initialise MMU
; 2. Initialise VDP in Texte mode 2
; 3. Initialise keyboard
; 4. Display prompt
; 5. Read line from keyboard with line editing
; 6. Execute command
; 7. Loop to 4
;
; TODO :
; Allow for interruptio mode 1
; Tokenizer


MONITORV2_START_ADDRESS  EQU 0x5000
;    include "../jumpTable.inc"
    include "memoryMapv2.inc"

    ORG MONITORV2_START_ADDRESS
    DI
    JP Main
; RST Quick Call Management
    DS MONITORV2_START_ADDRESS + 0x0008 - $
    ORG MONITORV2_START_ADDRESS + 0x0008
    RET
    DS MONITORV2_START_ADDRESS + 0x0010 - $
    ORG MONITORV2_START_ADDRESS + 0x0010
    RET
    DS MONITORV2_START_ADDRESS + 0x0018 - $
    ORG MONITORV2_START_ADDRESS + 0x0018
    RET
    DS MONITORV2_START_ADDRESS + 0x0020 - $
    ORG MONITORV2_START_ADDRESS + 0x0020
    RET
    DS MONITORV2_START_ADDRESS + 0x0028 - $
    ORG MONITORV2_START_ADDRESS + 0x0028
    RET
    DS MONITORV2_START_ADDRESS + 0x0030 - $
    ORG MONITORV2_START_ADDRESS + 0x0030
    RET
; Interrupt Mode 1 Management
    DS MONITORV2_START_ADDRESS + 0x0038 - $
    ORG MONITORV2_START_ADDRESS + 0x0038
; Jump to the interruption vector in RAM
    LD HL, (INTERRUPT_VECTOR)
    JP (HL)
DEFAULT_INTERRUPT_VECTOR:
    LD HL, DEFAULT_INTERRUPT_VECTOR_MSG
    CALL PrintString
    RET
DEFAULT_INTERRUPT_VECTOR_MSG:
    DB "Default Interrupt Routine", 0x00

    DB " < MONITOR V2 > ", 0x00

    include "../lib/MMU.asm"
    include "vdp_t2_init.asm"
    include "../lib/stdio.asm"
    include "lineEdit.asm"

Main:
; MMU Init _Do Not Move
    LD A, 0x00 OR ROM_SELECT; ROM bank 0
    OUT (MMU_PAGE0_SET), A
    LD A, 0x01 OR RAM_SELECT; RAM bank 1
    OUT (MMU_PAGE1_SET), A
    LD A, 0x02 OR RAM_SELECT; RAM bank 2
    OUT (MMU_PAGE2_SET), A
    LD A, 0x03 OR RAM_SELECT; RAM bank 3
    OUT (MMU_PAGE3_SET), A  
    OUT (MMU_ACTIVATE), A
; MMU Init End

; Setup Stack pointer - Decomment when flashing in ROM
;    LD SP, STACK_TOP
; 

    LD HL, CR_LF
    CALL PrintString

;    LD A, STREAM_OUT_VDP|STREAM_OUT_SERIAL|STREAM_IN_KEYBOARD|STREAM_IN_SERIAL
    LD A, STREAM_OUT_VDP|STREAM_IN_KEYBOARD|STREAM_IN_SERIAL
    LD (STREAM_SELECT), A

    CALL VDP_T2_Init
    PUSH HL
    LD HL, VDP_T2_INIT_MSG
    CALL PrintString
    POP HL

; Initialisation of interrupt mode 1
    LD HL, DEFAULT_INTERRUPT_VECTOR
    LD (INTERRUPT_VECTOR), HL
    IM 1
    EI

; Initialisation of Keyboard
    CALL Keyboard_Init
    PUSH HL
    LD HL, KEYBOARD_INIT_MSG
    CALL PrintString
    POP HL

; Initialisation of LineEdit
    CALL LineEdit_Init
    PUSH HL
    LD HL, LINEEDIT_INIT_MSG
    CALL PrintString
    POP HL

; Clear screen (pattern layout and color table in texte mode 2)
    CALL VDP_Clear_Screen
    PUSH HL
    LD HL, VDP_T2_CLEAR_SCREEN_MSG
    CALL PrintString
    POP HL

;    LD HL, 0x0000

 ;   LD B, 0
    ; LD C, 0x01
    ; CALL VDP_Set_Blink


.eventLoop:
    LD DE, MSG_PROMPT
    CALL PutS
    CALL LineEdit
    LD DE, CR_LF; after line edit, start new line
    CALL PutS

; command management
    LD A, (LINE_EDIT_BUFFER_ADDRESS)
    CP '²'
    JP Z, .endLoop
    CP 0x00 ; 
    JP Z, .eventLoop ; empty line, nothing to display
    CP '*'
    JP Z, .dumpMem ; dump memory
    CP '$'
    JP Z, .clearScreen
    CP '%'
    JP Z, .stackPointerRead
    CP '}'
    JP Z, .charDisplay
    CP ']'
    JP Z, .crissCross
    LD DE, LINE_EDIT_BUFFER_ADDRESS
    CALL PutS_LN
    JP .eventLoop

.crissCross:
    PUSH BC
    PUSH DE
    LD BC, 80*7
.crissCrossLoop:
    LD A, R
    AND 0x02
    JP Z, .crisscrossChar2
    LD A, 0x8B
    JP .crisscrossNextStep
.crisscrossChar2:
    LD A, 0x8C
.crisscrossNextStep:
    CALL PutC
    DEC BC
    LD A, B
    OR C
    JP NZ, .crissCrossLoop
    LD DE, .CRISSCROSS_MSG
    CALL PutS_LN
    POP DE
    POP BC
    JP .eventLoop
.CRISSCROSS_MSG: DB 0x00

.clearScreen:
    CALL VDP_Clear_Screen
    PUSH HL
    LD HL, SERIAL_CLRSCR
    CALL PrintString
    POP HL
    JP .eventLoop

.charDisplay:
    PUSH HL
    LD HL, LINE_EDIT_BUFFER_ADDRESS + 2
    CALL StrB2Digits
    JP NZ, .charDisplayError
 ;   LD A, E
    LD DE, .CHAR_DISP_STRING + 13
    CALL Byte2HexStr
    LD DE, .CHAR_DISP_STRING + 19
    LD (DE), A
    LD DE, .CHAR_DISP_STRING
    POP HL
    CALL PutS_LN
    JP .eventLoop
.charDisplayError:
    POP HL
    LD DE, CHAR_DISP_ERROR
    CALL PutS_LN
    JP .eventLoop
.CHAR_DISP_STRING: DB "Character (0x00) : _", 0x00

.stackPointerRead:
    PUSH HL
    LD HL, 0xFF00
    SBC HL, SP
    LD DE, .SP_STRING+18
    LD A, H
    CALL Byte2HexStr
    LD DE, .SP_STRING+20
    LD A, L
    CALL Byte2HexStr
    POP HL
    LD DE, .SP_STRING
    CALL PutS_LN
    JP .eventLoop
.SP_STRING: DB "Stack Pointer : 0x0000", 0x00

.dumpMem:
    PUSH HL
    LD HL, LINE_EDIT_BUFFER_ADDRESS +2 ; skip the first char
    CALL StrW2Digits
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

CR_LF:
    DB CR_KEY_CODE, LF_KEY_CODE, 0x00 ; Carriage return + line feed
STREAM_MSG:
    DB "Stream Selected : ", 0x00
MSG_PROMPT:
    DB "Z:\\>", 0x00
MEM_DUMP_ERROR:
    DB "Memory Dump Error : Invalid Address",0x00
CHAR_DISP_ERROR:
    DB "Char Display : invalid number", 0x00
VDP_T2_INIT_MSG:
    DB "VDP T2 Initialized", CR_KEY_CODE, LF_KEY_CODE, 0x00
VDP_T2_CLEAR_SCREEN_MSG:
    DB "VDP T2 Screen Cleared", CR_KEY_CODE, LF_KEY_CODE, 0x00
KEYBOARD_INIT_MSG:
    DB "Keyboard Initialized", CR_KEY_CODE, LF_KEY_CODE, 0x00
LINEEDIT_INIT_MSG:
    DB "Line Editor Initialized", CR_KEY_CODE, LF_KEY_CODE, 0x00

SERIAL_CLRSCR:
    DB 0x1B, "[2J", 0x1B, "[H", 0x00 ; Clear screen and home cursor


    END 
