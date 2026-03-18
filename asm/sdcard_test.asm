; --------------------------------------------
; -------- test program for SDCARD -------------
; --------------------------------------------
    .ORG 0x4000

    JP Main

 ;   INCLUDE "./lib/diskio.asm"
    INCLUDE "./monitorv2/memoryMapv2.inc"
    INCLUDE "./monitorv2/lineEdit.asm"
    INCLUDE "./monitorv2/FAT_cmd.asm"
    INCLUDE "./lib/stdio.asm"
    INCLUDE "./lib/string.asm"

SDCARD_BUFFER  EQU 0x7000

SDCARD_WORKSPACE:
    BLOCK 0x100, 0x00

Main:
    LD A, 0x33
    LD (0xc0c5), A
    
    CALL FAT_BOOT_INIT_DCBs
    CALL FAT_CMD_INIT_DRIVES

    LD DE, SDCARD_Init1_MSG
    CALL SDCARD_MsgPrint

    LD A, (SHELL_DRIVE_LETTER)
    CALL FAT_MOUNT
    JP C, .initError
    CALL SDCARD_CodePrint

    LD A, 'B'
    CALL FAT_MOUNT
    JP C, .initError
    CALL SDCARD_CodePrint


.loop:
    LD HL, (CURSOR_IDX)
    LD A, '>'
    CALL PutC
    CALL LineEdit_Init
    ; LD HL, (CURSOR_IDX)
    CALL LineEdit
    LD DE, LF_CR
    CALL PutS
    LD (CURSOR_IDX), HL

    LD DE, LINE_EDIT_BUFFER_ADDRESS
    LD A, (DE)
    CP '~'
    JP Z, .exit
    CP 'l'
    JP Z, .ls
    CP 'c'
    JP Z, .cd
    JP .loop
.ls:
    INC DE
    LD HL, SDCARD_BUFFER
    CALL FAT_CMD_LS
    JP .print_result
.cd:
    INC DE
    LD HL, SDCARD_BUFFER
    CALL FAT_CMD_CD
    JP .print_result
.print_result
    LD DE, SDCARD_BUFFER
    CALL SDCARD_MsgPrintLN
    
    JP .loop
.exit
    LD A, 0x11
    LD (0xc0c5), A
    RET
.error:
    CALL SDCARD_ErrorMsgPrint
    JP .loop
;    RET
.initError:
    PUSH DE
    LD DE, SDCARD_Init1_MSG
    CALL SDCARD_MsgPrint
    POP DE

    CALL SDCARD_ErrorMsgPrint
    RET

SDCARD_MsgPrint: ; print message in DE
    PUSH HL
    LD HL, (CURSOR_IDX)
    CALL PutS
    LD (CURSOR_IDX), HL
    POP HL
    RET

SDCARD_MsgPrintLengthLN: ; print message in DE, length B
    PUSH HL
    LD HL, (CURSOR_IDX)
    CALL PutS_Length
    LD DE, LF_CR
    CALL PutS
    LD (CURSOR_IDX), HL
    POP HL
    RET

SDCARD_MsgPrintLN: ; print message in DE
    PUSH HL
    LD HL, (CURSOR_IDX)
    CALL PutS_LN
    LD (CURSOR_IDX), HL
    POP HL
    RET

SDCARD_CodePrint: ; print code in A as hex
    PUSH AF
    PUSH DE
    PUSH HL
    LD DE, SDCARD_WORKSPACE
    CALL Bin2Hex_DE ; Convert response to string for display
    LD A, 0x00
    LD (DE), A
    LD DE, SDCARD_WORKSPACE
    LD HL, (CURSOR_IDX)
    CALL PutS_LN ; Print 
    LD (CURSOR_IDX), HL
    POP HL
    POP DE
    POP AF
    RET

SDCARD_ErrorMsgPrint: ; print and error message for error code in A
    PUSH AF
    PUSH DE
    PUSH HL

    LD DE, SDCARD_ERRROR_MSG
    LD HL, (CURSOR_IDX)
    CALL PutS
    LD DE, SDCARD_WORKSPACE
    CALL Bin2Hex_DE ; Convert response to string for display
    LD A, 0x00
    LD (DE), A
    LD DE, SDCARD_WORKSPACE
    CALL PutS_LN
    LD (CURSOR_IDX), HL

    POP HL
    POP DE
    POP AF
    RET

; Text Constants
LF_CR:
    DB 0x0D, 0x0A, 0x00
SDCARD_Init1_MSG:
    DB "Starting Initialisation 1 : ", 0x00
SDCARD_Init2_MSG:
    DB "Starting Initialisation 2 : ", 0x00
SDCARD_INIT_SUCCESS_MSG:
    DB "SD Card initialized successfully.", 0x00
SDCARD_ERRROR_MSG:
    DB "Error: ", 0x00
SDCARD_SPACE:
    DB " - ", 0x00



