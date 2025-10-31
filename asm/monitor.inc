
    IFNDEF __MONITOR_INC__
    DEFINE __MONITOR_INC__ 1


; ====== STACK Address ======
STACK_TOP EQU 0xFF00 ; adresse de la pile (top of stack)

; ============ RAM START Address ==============
RAM_START EQU 0x4000 ; Start of RAM

; ======== CURSOR LOOK ====================
CURSOR_INSERT EQU '5'
CURSOR_OVERWRITE EQU '1'

; ============== File System Type ================
FS_SERIAL EQU 0x00
FS_SDCARD EQU 0x01
FS_EEPROM EQU 0x02

; =============== VARIABLES ADDRESS ================
BUFFER_FLAG EQU RAM_START ; buffer flag (bitmap) Insert Mode
DRIVE_LETTER EQU RAM_START + 0x01 ; contains the letter of the drive
FILE_SYSTEM EQU RAM_START + 0x02 ; contains the type of the filesystem
PROGRAM_BASE_ADDRESS EQU 0x5000

; ======= Command characters buffer =======
BUFFER_ADDRESS EQU RAM_START + 0x10 ; buffer address
BUFFER_SIZE EQU 0x41 ; buffer size (65 bytes) including leading 0x00
BUFFER_END EQU BUFFER_ADDRESS + BUFFER_SIZE ; end of buffer
BUFFER_START EQU BUFFER_ADDRESS ; start of buffer

; ======= Keypad Variables =======
MODIFER_STATE EQU RAM_START + 0x0100 ; 1 byte
MODIFERS EQU RAM_START + 0x0101 ; 1 byte
KEYPAD_BUFFER EQU RAM_START + 0x0102 ; 4 characters buffer
KEYPAD_STATE EQU RAM_START + 0x0110 ; Keypad state - ROWs * COLS bytes


; ==================== Monitor Messages =====================
WelcomeMsg:
    DB "Welcome to the Z80 Monitor", 0x0D, 0x0A,0x00

INFO_MSG:
    DB 0x0A, 0x0D,"You typed : ", 0x00 ; Newline and prompt
PROMPT:
    DB ':\>', 0x00 ; Prompt character
CLRSCR:
    DB 0x1B, "[2J", 0x1B, "[H", 0x00 ; Clear screen and home cursor

UNKNOWN_CMD_MSG:
    DB "Unknown command", 0x00 
CMD_ECHO_MSG:
    DB "Echo command", 0x00 
CMD_EXEC_MSG:
    DB "Exec program at 0x", 0x00 
CMD_EXEC_ERROR_MSG:
    DB "Syntax error - Format : exec AAAA", 0x00 
CMD_DUMP_MSG:
    DB "Dump command", 0x00 
CMD_DUMP_ERROR_MSG:
    DB "Syntax error - Format : dump AAAA", 0x00 
CMD_LIST_MSG:
    DB "List text at 0x", 0x00 
CMD_LIST_ERROR_MSG:
    DB "Syntax error - Format : list AAAA", 0x00 
CMD_LOAD_MSG1:
    DB "Load program (0x", 0x00
CMD_LOAD_MSG2:
    DB " bytes) to 0x", 0x00  
CMD_LOAD_MSG_WAITING:
    DB 0x0D, "Waiting for data", 0x00
CMD_LOAD_MSG_END:
    DB 0x0D, "Bytes received : ", 0x00
CMD_LOAD_ERROR_MSG:
    DB "Syntax error - Format : load AAAA SSSS", 0x00
CMD_LOADTXT_MSG:
    DB "Load text file to 0x", 0x00  
CMD_LOADTXT_MSG_WAITNG:
    DB 0x0D, "Waiting for Data", 0x00  
CMD_LOADTXT_MSG_END:
    DB "Characters received : Ox", 0x00  
CMD_LOADTXT_ERROR_MSG:
    DB "Syntax error - Format : ldtx AAAA", 0x00
CMD_WRITE_MSG:
    DB "Write command", 0x00 
CMD_HELP_MSG:
    DB "Commands : echo, exec, dump, list, load, ldtx, write, clrscr, help, ?", 0x00 

WRONG_FILE_SYSTEM_MSG:
    DB "Wrong File System", 0x00
; List of Commands
COMMANDS_LIST:
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

    ENDIF ; __MONITOR_INC__
    