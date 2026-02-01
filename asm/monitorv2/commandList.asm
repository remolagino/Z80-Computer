    IFNDEF __COMMAND_LIST__
    DEFINE __COMMAND_LIST__ 1

    include "../lib/string.asm"
    include "memoryMapv2.inc"
    include "FS_Serial.asm"

; List of commands for Monitor v2
; Format : - command as null-terminated string
;          - adress of the command routine as a WORD
; HL Contains the address
; DE contains the parameter

COMMAND_LIST:
    DB "a:", 0x00   ; A Drive
    DW Cmd_DriveA
    DB "A:", 0x00   ; A Drive
    DW Cmd_DriveA
    DB "b:", 0x00   ; B drive
    DW Cmd_DriveB
    DB "B:", 0x00   ; B drive
    DW Cmd_DriveB
    DB "c:", 0x00   ; C Drive
    DW Cmd_DriveC
    DB "C:", 0x00   ; C Drive
    DW Cmd_DriveC
    DB "d:", 0x00   ; C Drive
    DW Cmd_DriveD
    DB "D:", 0x00   ; C Drive
    DW Cmd_DriveD
    DB "echo", 0x00 ; Echo
    DW Cmd_Echo
    DB "exec", 0x00 ; Exec
    DW Cmd_Exec
    DB "dump", 0x00 ; Dump
    DW Cmd_Dump
    DB "list", 0x00 ; List
    DW Cmd_List
    DB "load", 0x00 ; Load
    DW Cmd_Load
    DB "ldtx", 0x00 ; Load
    DW Cmd_LoadTxt
    DB "write", 0x00 ; Write
    DW Cmd_Write
    DB "clk", 0x00 ; print time
    DW Cmd_Clk
    DB "clrscr", 0x00 ; clear screen
    DW Cmd_clrscr
    DB "ls", 0x00 ; clear screen
    DW Cmd_ls
    DB "cd", 0x00 ; clear screen
    DW Cmd_cd
    DB "cwd", 0x00 ; clear screen
    DW Cmd_cwd
    DB "cat", 0x00 ; clear screen
    DW Cmd_cat
    DB "peek", 0x00 ; clear screen
    DW Cmd_peek
    DB "poke", 0x00 ; clear screen
    DW Cmd_poke    
    DB "run", 0x00 ; clear screen
    DW Cmd_run
    DB "setclk", 0x00 ; set time
    DW Cmd_setClk
    DB "help", 0x00 ; Help
    DW Cmd_Help
    DB "?", 0x00 ; Help
    DW Cmd_Help
    DB 0xFF ; End of commands list

Cmd_DriveA:
    CALL SerFS_Init
    XOR A ; set Z flag as true = success
    RET
Cmd_DriveB:
    LD A, 'B'
    LD (DRIVE_LETTER), A
    LD A, FS_EEPROM
    LD (FILE_SYSTEM), A
;    CALL SerFS_Init
    XOR A ; set Z flag as true = success
    RET
Cmd_DriveC:
    LD A, 'C'
    LD (DRIVE_LETTER), A
    LD A, FS_SDCARD
    LD (FILE_SYSTEM), A
;    CALL SerFS_Init
    XOR A ; set Z flag as true = success
    RET

Cmd_DriveD:
    LD A, 'D'
    LD (DRIVE_LETTER), A
    LD A, FS_SDCARD
    LD (FILE_SYSTEM), A
;    CALL SerFS_Init
    XOR A ; set Z flag as true = success
    RET

Cmd_Echo:
;    PUSH HL
    LD HL, (CURSOR_IDX)
    CALL PutS_LN
    LD (CURSOR_IDX), HL
;    POP HL
    XOR A
    RET

Cmd_Exec:
    LD A, 0x01
    OR A
    RET

Cmd_Clk:
    PUSH DE
    PUSH HL
    CALL RtClock_Init
    CALL NZ, .rtClockFail

    LD HL, WORKING_MEMORY_START
    CALL RtClock_GetDS3231Data
 ;   POP HL
    JP NZ, .rtClockFail
    
    LD DE, WORKING_MEMORY_START + 20
    CALL RtClock_GetDateTime
    LD HL, (CURSOR_IDX)
    CALL PutS_LN
    LD (CURSOR_IDX), HL
    JP .rtClockExit
.rtClockFail:
    LD HL, (CURSOR_IDX)
    LD DE, RTCLOCK_FAIL
    CALL PutS
    CALL PutC
    LD DE, CR_LF
    CALL PutS
    LD (CURSOR_IDX), HL
.rtClockExit:
    POP HL
    POP DE
    LD A, 0x00
    OR A
    RET

Cmd_peek:
    PUSH BC
    PUSH DE
    PUSH HL
    EX DE, HL ; put the param in (HL)
    CALL HexWord2Bin
    JP NZ, .peekError ; invalid number
    LD B, D ; store DE in BC
    LD C, E
    LD DE, WORKING_MEMORY_START
    LD A, '('
    LD (DE), A
    INC DE
    LD A, '0'
    LD (DE), A
    INC DE
    LD A, 'x'
    LD (DE), A
    INC DE
    LD A, (HL) ; copy the 4 char of the number to (DE)
    LD (DE), A
    INC DE
    INC HL
    LD A, (HL)
    LD (DE), A
    INC DE
    INC HL
    LD A, (HL)
    LD (DE), A
    INC DE
    INC HL
    LD A, (HL)
    LD (DE), A
    INC DE
    INC HL
    LD A, ')'
    LD (DE), A
    INC DE
    LD A, '='
    LD (DE), A
    INC DE
    LD A, '0'
    LD (DE), A
    INC DE
    LD A, 'x'
    LD (DE), A
    INC DE
    EX DE, HL
    LD A, (BC)
    CALL Bin2Hex_HL
    LD DE, WORKING_MEMORY_START
    JP .exit
.peekError:
    LD DE, PEEK_CMD_MEM_ERROR
.exit:
    LD HL, (CURSOR_IDX)
    CALL PutS_LN
    LD (CURSOR_IDX), HL
    LD A, 0x00
    OR 0x00
    POP HL
    POP DE
    POP BC
    RET

Cmd_poke:
    PUSH BC
    PUSH DE
    PUSH HL
    EX DE, HL ; put the param in (HL)
    CALL HexWord2Bin
    JP NZ, .pokeError ; invalid number
    INC HL
    INC HL
    INC HL
    INC HL
    CALL HexByte2Bin
    JP NZ, .pokeError ; invalid number
    LD (DE), A
    POP HL
    POP DE
    POP BC
    CALL Cmd_peek
    RET
.pokeError:
    LD DE, POKE_CMD_MEM_ERROR
    LD HL, (CURSOR_IDX)
    CALL PutS_LN
    LD (CURSOR_IDX), HL
    LD A, 0x00
    OR 0x00
    POP HL
    POP DE
    POP BC
    RET


Cmd_Dump:
;    LD HL, LINE_EDIT_BUFFER_ADDRESS +2 ; skip the first char
    EX DE, HL
    CALL HexWord2Bin
    JP NZ, .dumpMemError ; invalid number
    ; LD HL, DE
    LD HL, WORKING_MEMORY_START
    EX DE, HL
    CALL MemoryDump
;    LD DE, WORKING_MEMORY_START
    JP .exit
.dumpMemError:
    LD DE, DUMP_CMD_MEM_ERROR
.exit:
    LD HL, (CURSOR_IDX)
    CALL PutS_LN
    LD (CURSOR_IDX), HL
    LD A, 0x00
    OR 0x00
    RET

Cmd_List:
    LD A, 0x00
    OR 0x01
    RET
Cmd_Load:
    LD A, 0x00
    OR 0x01
    RET
Cmd_LoadTxt:
    LD A, 0x00
    OR 0x01
    RET
Cmd_Write:
    LD A, 0x00
    OR 0x01
    RET

Cmd_clrscr:
    CALL VDP_Clear_Screen
    LD HL, 0x0000
    LD (CURSOR_IDX), HL
    LD A, 0x00 ; set Z flag
    OR A
    RET

Cmd_ls:
    LD HL, (FS_CMD_LS)
    CALL_HL
    LD A, 0x00
    OR 0x00
    RET

Cmd_cd:
    LD HL, (FS_CMD_CD)
    CALL_HL
    LD A, 0x00
    OR 0x00
    RET

Cmd_cwd:
    LD HL, (FS_CMD_CWD)
    CALL_HL
    LD A, 0x00
    OR 0x00
    RET

Cmd_cat:
    LD HL, (FS_CMD_CAT)
    CALL_HL
    LD A, 0x00
    OR 0x00
    RET

Cmd_run:
    LD HL, (FS_CMD_RUN)
    CALL_HL
    LD A, 0x00
    OR 0x00
    RET

Cmd_setClk:
    LD HL, LINE_EDIT_BUFFER_ADDRESS
.send_loop:
    CALL SendCharB_HL
    INC HL
    LD A, (HL)
    OR A
    JP NZ, .send_loop

    CALL ReceiveChar_B ; get Ack or Nack
    ; CALL ReceiveChar_B_TO ; get Ack or Nack
    ; JP NZ, CmdTimeout
    CP ACK ; Check for ACK
    LD A, '1'
    JP NZ, .errorMsg
    LD HL, WORKING_MEMORY_START
    LD B, 7
.setclk_loop:
    CALL ReceiveChar_B ; get Time Data
    ; CALL ReceiveChar_B_TO ; get next byte
    ; JP NZ, SerFS_TimeOut
    LD (HL), A
    INC HL
    DJNZ .setclk_loop
    CALL ReceiveChar_B ; get EOT
    ; CALL ReceiveChar_B_TO ; get EOT
    ; JP NZ, CmdTimeout
    CP EOT ; Check for ACK
    LD A, '2'
    JP NZ, .errorMsg

    LD B, 7
    LD HL, WORKING_MEMORY_START
    LD DE, WORKING_MEMORY_START +10
.setclk_loop2:
    LD A, (HL)
    CALL Bin2Hex_DE
    LD A, ' '
    LD (DE), A
    INC DE
    INC HL
    DJNZ .setclk_loop2
    LD A, 0x00
    LD (DE), A
    LD DE, WORKING_MEMORY_START +10
    LD HL, (CURSOR_IDX)
    CALL PutS_LN
    LD (CURSOR_IDX), HL

    LD HL, WORKING_MEMORY_START
    CALL RtClock_SetTime
    JP NZ, .errorMsg
    CALL Cmd_Clk
    LD A, 0x00
    OR A
    RET
.errorMsg:
    LD DE, CMD_SETCLK_ERROR_MSG
    LD HL, (CURSOR_IDX)
    CALL PutS
    CALL PutC
    LD DE, CR_LF
    CALL PutS
    LD (CURSOR_IDX), HL
    LD A, 0x00
    OR 0x00
    RET
CMD_SETCLK_ERROR_MSG:
    DB "Set Clock - Error : ", 0x00

CmdTimeout:
    LD HL, (CURSOR_IDX)
    LD DE, CMD_SETCLK_TIMEOUT_MSG
    CALL PutS_LN
    LD (CURSOR_IDX), HL
    LD A, 0x00
    OR 0x00
    RET
CMD_SETCLK_TIMEOUT_MSG:
    DB "Set Clock - Timeout Error", 0x00

Cmd_Help:
    LD DE, CMD_HELP_MSG
    LD HL, (CURSOR_IDX)
    CALL PutS_LN
    LD (CURSOR_IDX), HL
    LD A, 0x00
    OR 0x00
    RET

CMD_HELP_MSG:
    DB "Commands : cat, cd, clk, clrscr, cwd, dump, echo, ls, peek, poke, run, help, ?", 0x00 
DUMP_CMD_MEM_ERROR:
    DB "Memory Dump Error : Invalid Address",0x00
PEEK_CMD_MEM_ERROR:
    DB "Peek Error : Invalid Address", 0x00
POKE_CMD_MEM_ERROR:
    DB "Poke Error - format : poke AAAA NN", 0x00
POKE_CMD_SUCCESS:
    DB "Done", 0x00
RUN_CMD_FS_ERROR:
    DB "Run Cmd Error : Unsupported FS",0x00

    ENDIF