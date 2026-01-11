    IFNDEF __COMMAND_LIST__
    DEFINE __COMMAND_LIST__ 1

; List of commands for Monitor v2
; Format : - command as null-terminated string
;          - adress of the command routine as a WORD

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
    DB "Cmd_DriveA", 0x00
Cmd_DriveB:
    DB "Cmd_DriveB", 0x00
Cmd_DriveC:
    DB "Cmd_DriveC", 0x00
Cmd_Echo:
    DB "Cmd_Echo", 0x00
Cmd_Exec:
    DB "Cmd_Exec", 0x00
Cmd_Dump:
    DB "Cmd_Dump", 0x00
Cmd_List:
    DB "Cmd_List", 0x00
Cmd_Load:
    DB "Cmd_Load", 0x00
Cmd_LoadTxt:
    DB "Cmd_LoadTxt", 0x00
Cmd_Write:
    DB "Cmd_Write", 0x00
Cmd_clrscr:
    DB "Cmd_clrscr", 0x00
Cmd_ls:
    DB "Cmd_ls", 0x00
Cmd_cd:
    DB "Cmd_cd", 0x00
Cmd_cwd:
    DB "Cmd_cwd", 0x00
Cmd_cat:
    DB "Cmd_cat", 0x00
Cmd_run:
    DB "Cmd_run", 0x00
Cmd_Help:
    DB "Cmd_Help", 0x00



    ENDIF