; Monitor v2
; New version of the monitor using VDP for display
; and native keyboard for input
;
; 1. Initialise VDP in Texte mode 2
;       - 
; 2. Initialise keyboard
; 3. Display prompt
; 4. Read line from keyboard with line editing
; 5. Execute command
; 6. Loop to 3
;

MONITORV2_START_ADDRESS  EQU 0x5000

    ORG MONITORV2_START_ADDRESS

;    include "../jumpTable.inc"
    JP Main

    include "memoryMapv2.inc"
    include "vdp_t2_init.asm"
    include "../lib/stdio.asm"
    include "lineEdit.asm"

Main:
    LD HL, CR_LF
    CALL PrintString

    LD A, STREAM_OUT_VDP|STREAM_OUT_SERIAL|STREAM_IN_KEYBOARD|STREAM_IN_SERIAL
    LD (STREAM_SELECT), A

    CALL VDP_T2_Init
    PUSH HL
    LD HL, VDP_T2_INIT_MSG
    CALL PrintString
    POP HL

    CALL Keyboard_Init
    PUSH HL
    LD HL, KEYBOARD_INIT_MSG
    CALL PrintString
    POP HL

    CALL LineEdit_Init
    PUSH HL
    LD HL, LINEEDIT_INIT_MSG
    CALL PrintString
    POP HL

    CALL Clear_Screen
    PUSH HL
    LD HL, VDP_T2_CLEAR_SCREEN_MSG
    CALL PrintString
    POP HL

;    LD HL, 0x0000

 ;   LD B, 0
    LD C, 0x01
    CALL Set_Blink


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
    LD DE, LINE_EDIT_BUFFER_ADDRESS
    CALL PutS_LN
    JP .eventLoop

.clearScreen:
    CALL Clear_Screen
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

CR_LF:
    DB CR_KEY_CODE, LF_KEY_CODE, 0x00 ; Carriage return + line feed
STREAM_MSG:
    DB "Stream Selected : ", 0x00
MSG_PROMPT:
    DB "A:\\>", 0x00
MEM_DUMP_ERROR:
    DB "Memory Dump Error : Invalid Address",0x00

VDP_T2_INIT_MSG:
    DB "VDP T2 Initialized", CR_KEY_CODE, LF_KEY_CODE, 0x00
VDP_T2_CLEAR_SCREEN_MSG:
    DB "VDP T2 Screen Cleared", CR_KEY_CODE, LF_KEY_CODE, 0x00
KEYBOARD_INIT_MSG:
    DB "Keyboard Initialized", CR_KEY_CODE, LF_KEY_CODE, 0x00
LINEEDIT_INIT_MSG:
    DB "Line Editor Initialized", CR_KEY_CODE, LF_KEY_CODE, 0x00

; DEBUG1_MSG:
;     DB "DEBUG1", CR_KEY_CODE, LF_KEY_CODE, 0x00
; DEBUG2_MSG:
;     DB "DEBUG2", CR_KEY_CODE, LF_KEY_CODE, 0x00

    END 
