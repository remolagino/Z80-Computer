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

Cmd_Dump:
;    LD HL, LINE_EDIT_BUFFER_ADDRESS +2 ; skip the first char
    EX DE, HL
    CALL StrW2Digits
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
    DB "Commands : echo, exec, dump, list, load, ldtx, write, clrscr, help, ?", 0x00 
DUMP_CMD_MEM_ERROR:
    DB "Memory Dump Error : Invalid Address",0x00
RUN_CMD_FS_ERROR:
    DB "Run Cmd Error : Unsupported FS",0x00

    ENDIF