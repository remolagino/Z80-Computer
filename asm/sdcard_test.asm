; --------------------------------------------
; -------- test program for SDCARD -------------
; --------------------------------------------
    .ORG 0x4000

    JP Main

 ;   INCLUDE "./lib/diskio.asm"
    INCLUDE "./monitorv2/memoryMapv2.inc"
    INCLUDE "./monitorv2/lineEdit.asm"
    INCLUDE "shell_cmd.asm"
    INCLUDE "./lib/stdio.asm"
    INCLUDE "./lib/string.asm"

SDCARD_BUFFER  EQU 0x7000
SDCARD_BUFFER2 EQU SDCARD_BUFFER + 0x0200



Main:

    CALL FAT_BOOT_INIT_DCBs

    LD DE, SDCARD_Init1_MSG
    CALL SDCARD_MsgPrint

    LD A, 'C'
    CALL FAT_MOUNT
    JP C, .initError
    CALL SDCARD_CodePrint

    LD DE, SDCARD_BUFFER2
    LD A, 'C'
    LD BC, 0x0000
    LD (SD_CURRENT_DIR), BC
    CALL SHELL_LS
    JP C, .initError
    CALL SDCARD_MsgPrintLN

; DEBUG TEST TO BE REMOVED
    LD A, '/'
    LD HL, SD_CURRENT_PATH
    LD (HL), A
; ------------------

.loop:
    CALL LineEdit_Init
    LD HL, (CURSOR_IDX)
    CALL LineEdit
    LD DE, LF_CR
    CALL PutS
    LD (CURSOR_IDX), HL

    LD DE, LINE_EDIT_BUFFER_ADDRESS
    LD A, (DE)
    CP '~'
    JP Z, .exit
 
    EX DE, HL
    LD DE, SDCARD_WORKSPACE
    CALL CopyString
    LD A, 0x00
    LD (DE), A
    EX DE, HL

    LD A, 'C'
    LD HL, (SD_CURRENT_DIR)
    CALL FS_OpenDir
    JP C, .error

    CALL FS_followPath
    JP C, .notFound
    
    LD DE, SDCARD_WORKSPACE
    LD HL, SD_CURRENT_PATH
    CALL FS_CanonicalizePath

    EX DE, HL
    CALL SDCARD_MsgPrintLN

    LD A, (IX + FAT_DIR_ENTRY.ATTRIBUTE)
    AND 0x10
    CP 0x10
    JP NZ, .file

    LD (SD_CURRENT_DIR), BC

    LD A, 'C'
    LD DE, SDCARD_BUFFER2
    CALL SHELL_LS
    JP C, .error
;    CALL SDCARD_CodePrint

    LD DE, SDCARD_BUFFER2
    CALL SDCARD_MsgPrintLN
    
    JP .loop
.file:
    PUSH BC
    PUSH DE
    LD DE, SD_File
    CALL SDCARD_MsgPrint
    LD B, (IX + FAT_DIR_ENTRY.START_CLUSTER + 1)
    LD C, (IX + FAT_DIR_ENTRY.START_CLUSTER )
    LD DE, SDCARD_WORKSPACE
    CALL MATH_WORD_TO_STRING
    CALL SDCARD_MsgPrint
    LD DE, SDCARD_SPACE
    CALL SDCARD_MsgPrint
    LD DE, IX
    LD B, 11
    CALL SDCARD_MsgPrintLengthLN
    POP DE
    POP BC
    JP .loop
.notFound:
    PUSH DE
    LD DE, SD_NotFound
    CALL SDCARD_MsgPrint
    POP DE
;    LD DE, LINE_EDIT_BUFFER_ADDRESS
    CALL SDCARD_MsgPrintLN
    JP .loop
.exit
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



SD_Dir :
    DB "Directory : ",0x00
SD_File :
    DB "File : ",0x00
SD_FsStructIdx :
    DB " - Idx : ",0x00
SD_FsEnd :
    DB "End Of Chain :", 0x00
SD_NotFound :
    DB "Not Found : ", 0x00

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

; TO BE MOVED TO SHELL COMMAND
SD_DRIVE_LETTER:
    DB 'C'
SD_CURRENT_DIR :
    WORD 0x0000
SD_START_PATH: ; stop condition for the path canonisation
; a bit fragile, to be updated
    DB 0x00
SD_CURRENT_PATH:
    BLOCK 0x100, 0x00

SDCARD_WORKSPACE:
    BLOCK 0x10, 0x00



