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
;


; MONITORV2_START_ADDRESS  EQU 0x5000
MONITORV2_START_ADDRESS  EQU 0x0000

    ORG MONITORV2_START_ADDRESS
    DI
    JP Main
; RST Quick Call Management
    DS MONITORV2_START_ADDRESS + 0x0008 - $
    ORG MONITORV2_START_ADDRESS + 0x0008
    LD A, 'A'
    CALL SendChar_A
    RET
    DS MONITORV2_START_ADDRESS + 0x0010 - $
    ORG MONITORV2_START_ADDRESS + 0x0010
    JP (HL)
    DS MONITORV2_START_ADDRESS + 0x0018 - $
    ORG MONITORV2_START_ADDRESS + 0x0018
    LD A, 'C'
    CALL SendChar_A
    RET
    DS MONITORV2_START_ADDRESS + 0x0020 - $
    ORG MONITORV2_START_ADDRESS + 0x0020
    LD A, 'D'
    CALL SendChar_A
    RET
    DS MONITORV2_START_ADDRESS + 0x0028 - $
    ORG MONITORV2_START_ADDRESS + 0x0028
    LD A, 'E'
    CALL SendChar_A
    RET
    DS MONITORV2_START_ADDRESS + 0x0030 - $
    ORG MONITORV2_START_ADDRESS + 0x0030
    LD A, 'F'
    CALL SendChar_A
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
    RETI
DEFAULT_INTERRUPT_VECTOR_MSG:
    DB "Default Interrupt Routine ", 0x00

    DB " < MONITOR V2 > ", 0x00
;    include "../jumpTable.inc"
    include "memoryMapv2.inc"

    include "../lib/MMU.asm"
    include "vdp_t2_init.asm"
    include "../lib/rtclock.asm"
    include "../lib/eeprom.asm"
    include "../lib/stdio.asm"
    include "lineEdit.asm"
    include "parseCmdLine.asm"
    include "commandList.asm"



Main:
; MMU Init _Do Not Move
    LD A, 0x00 OR MMU_ROM_SELECT; ROM bank 0
    OUT (MMU_PAGE0_SET), A
    LD A, 0x01 OR MMU_RAM_SELECT; RAM bank 1
    OUT (MMU_PAGE1_SET), A
    LD A, 0x02 OR MMU_RAM_SELECT; RAM bank 2
    OUT (MMU_PAGE2_SET), A
    LD A, 0x03 OR MMU_RAM_SELECT; RAM bank 3
    OUT (MMU_PAGE3_SET), A  
    OUT (MMU_ACTIVATE), A
; MMU Init End

; Setup Stack pointer - Decomment when flashing in ROM
    LD SP, STACK_TOP
; 
; initialisation of SIO Channel A (Terminal)
    CALL InitSerial_A
; initialisation of SIO Channel B
    CALL InitSerial_B  
; initialise downcounter in CTC3
    CALL Init_CTC3

    LD HL, CR_LF
    CALL PrintString

    LD A, STREAM_OUT_VDP|STREAM_IN_KEYBOARD
;    LD A, STREAM_OUT_VDP|STREAM_OUT_SERIAL|STREAM_IN_KEYBOARD|STREAM_IN_SERIAL
;    LD A, STREAM_OUT_VDP|STREAM_IN_KEYBOARD|STREAM_IN_SERIAL
    LD (STDIO_STREAM_SELECT), A
    LD A, 0x00
    LD (STDIO_DEAD_KEY), A

    CALL VDP_T2_Init
    PUSH HL
    LD HL, VDP_T2_INIT_MSG
    CALL PrintString
    POP HL

; Initialisation of interrupt mode 1
    LD HL, DEFAULT_INTERRUPT_VECTOR
    LD (INTERRUPT_VECTOR), HL
    IM 1
    DI ; interrupt disable by default
;    EI

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
    LD (CURSOR_IDX), HL
    PUSH HL
    LD HL, VDP_T2_CLEAR_SCREEN_MSG
    CALL PrintString
    POP HL

; Previous boot time
    CALL EEPROM_Init
    LD DE, 0x0000
    LD HL, WORKING_MEMORY_START
    LD BC, 24
    CALL EEPROM_SequentialRead

    LD HL, (CURSOR_IDX)
    LD DE, RT_PREV_BOOT_TIME_MSG
    CALL PutS
    LD DE, WORKING_MEMORY_START
    CALL PutS_LN
    LD (CURSOR_IDX), HL

; Initialise RTClock
    CALL RtClock_Init
    CALL NZ, .rtClockFail

    LD HL, WORKING_MEMORY_START
    CALL RtClock_GetDS3231Data
;   POP HL
    JP NZ, .rtClockFail
    
    LD DE, WORKING_MEMORY_START + 20
    CALL RtClock_GetDateTime
    LD HL, (CURSOR_IDX)
    LD DE, RT_CURRENT_TIME_MSG
    CALL PutS
    LD DE, WORKING_MEMORY_START + 20
    CALL PutS_LN
    LD (CURSOR_IDX), HL

    LD HL, WORKING_MEMORY_START + 20
    LD DE, 0x0000
    LD BC, 24
    CALL EEPROM_BulkWrite
    JP NZ, .eepromFail
    JP .fsInit
.rtClockFail:
    LD HL, (CURSOR_IDX)
    LD DE, RTCLOCK_FAIL
    CALL PutS
    CALL PutC
    LD DE, CR_LF
    CALL PutS
    LD (CURSOR_IDX), HL
    JP .fsInit
.eepromFail:
    LD HL, (CURSOR_IDX)
    LD DE, EEPROM_FAIL
    CALL PutS
    CALL PutC
    LD DE, CR_LF
    CALL PutS
    LD (CURSOR_IDX), HL

.fsInit:
    CALL SerFS_Init ; TODO Make it more modular

.eventLoop:
    LD HL, (CURSOR_IDX)
    LD A, (DRIVE_LETTER)
    CALL PutC
    LD DE, MSG_PROMPT
    CALL PutS
    
    CALL LineEdit
    LD DE, CR_LF; after line edit, start new line
    CALL PutS

    LD (CURSOR_IDX), HL ; to get back cursor index in the command

    LD BC, COMMAND_LIST
    LD HL, LINE_EDIT_BUFFER_ADDRESS
    CALL SpaceRemoval
    LD A, (HL)
    CP 0x00 ; 
    JP Z, .eventLoop ; empty line, nothing to display

    CALL ParseAndExecCommand
    LD HL, (CURSOR_IDX)

    JP NZ, .parseError
    JP .eventLoop
.parseError:
    LD DE, PARSE_ERROR_MSG
    CALL PutS
    LD DE, LINE_EDIT_BUFFER_ADDRESS
    CALL PutS_LN
    JP .eventLoop


; .crissCross:
;     PUSH BC
;     PUSH DE
;     LD BC, 80*22
; .crissCrossLoop:
;     CALL CTC3_GetCounter
;     AND 0x01
;     JP Z, .crisscrossChar2
;     LD A, 0x8B
;     JP .crisscrossNextStep
; .crisscrossChar2:
;     LD A, 0x8C
; .crisscrossNextStep:
;     CALL PutC
;     DEC BC
;     LD A, B
;     OR C
;     JP NZ, .crissCrossLoop
;     LD DE, .CRISSCROSS_MSG
;     CALL PutS_LN
;     POP DE
;     POP BC
;     JP .eventLoop
; .CRISSCROSS_MSG: DB 0x00



CR_LF:
    DB CR_KEY_CODE, LF_KEY_CODE, 0x00 ; Carriage return + line feed
STREAM_MSG:
    DB "Stream Selected : ", 0x00
MSG_PROMPT:
    DB ":\\>", 0x00
PARSE_ERROR_MSG:
    DB "Unknown Command : ", 0x00
CHAR_DISP_ERROR:
    DB "Char Display : invalid number", 0x00
RT_PREV_BOOT_TIME_MSG:
    DB "Previous Boot  : ", 0x00
RT_CURRENT_TIME_MSG:
    DB "Current Time   : ", 0x00
RTCLOCK_FAIL:
    DB "RTClock Error : ", 0x00
EEPROM_FAIL:
    DB "EEPROM Error : ", 0x00
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
    DB "END OF THE MONITOR", 0x00

    DS MONITORV2_START_ADDRESS + 0x3000 - $


    END 
