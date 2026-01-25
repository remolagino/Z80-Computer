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
    DB "list", 0x00 ; Dump
    DW Cmd_List
    DB "load", 0x00 ; Load
    DW Cmd_Load
    DB "ldtx", 0x00 ; Load
    DW Cmd_LoadTxt
    DB "write", 0x00 ; Write
    DW Cmd_Write
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

Cmd_Help:
    LD DE, CMD_HELP_MSG
    LD HL, (CURSOR_IDX)
    CALL PutS_LN
    LD (CURSOR_IDX), HL
    LD A, 0x00
    OR 0x00
    RET

CMD_HELP_MSG:
    DB "Commands : cat, cd, clrscr, cwd, dump, echo, ls, peek, poke, run, help, ?", 0x00 
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