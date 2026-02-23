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

SD_CURRENT_DIR :
    WORD 0x0000

Main:

    LD A, '|'
    LD (FAT_MIRROR_DCB + FAT_DRIVE_CONTROL), A
    LD (FAT_TMP_DWORD + 4), A
    LD (FAT_TMP_DWORD + 5), A
    LD (FAT_TMP_DWORD + 6), A
    LD (FAT_TMP_DWORD + 7), A
    LD (FAT_TMP_DWORD + 8), A
    LD (FAT_TMP_DWORD + 9), A
    LD (FAT_TMP_DWORD + 10), A
    LD (FAT_TMP_DWORD + 11), A

    CALL FAT_BOOT_INIT_DCBs

    LD DE, SDCARD_Init1_MSG
    CALL SDCARD_MsgPrint

    LD A, 'C'
    CALL FAT_MOUNT
    JP C, .initError
    CALL SDCARD_CodePrint

    LD DE, SDCARD_BUFFER2
    LD A, 'C'
    LD BC, (SD_CURRENT_DIR)
    CALL SHELL_LS
    JP C, .initError
    CALL SDCARD_MsgPrintLN

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
 
    ; LD HL, 0x5D00
    ; CALL FS_FileNamePrep
    ; JP C, .error
    ; EX DE, HL
    ; CALL SDCARD_MsgPrintLN

    LD A, 'C'
    LD HL, (SD_CURRENT_DIR)
    CALL FS_followPath
;    CALL FS_SearchEntry
    JP C, .notFound
    
    CALL MATH_WORD_TO_STRING
    CALL SDCARD_MsgPrintLN

    LD C, (IX + FAT_DIR_ENTRY.START_CLUSTER)
    LD B, (IX + FAT_DIR_ENTRY.START_CLUSTER + 1)
    LD (SD_CURRENT_DIR), BC

    LD A, 'C'
    LD DE, SDCARD_BUFFER2
    CALL SHELL_LS
    JP C, .error
    CALL SDCARD_CodePrint

    LD DE, SDCARD_BUFFER2
    CALL SDCARD_MsgPrintLN
    
    JP .loop
.notFound:
    LD DE, SD_NotFound
    CALL SDCARD_MsgPrint
    LD DE, LINE_EDIT_BUFFER_ADDRESS
    CALL SDCARD_MsgPrintLN
    JP .loop
.exit
    RET
.error:
    CALL SDCARD_ErrorMsgPrint
    JP .loop
;    RET
.initError:
    CALL SDCARD_ErrorMsgPrint
    RET


SDCARD_print_FS_Struct:
    PUSH BC
    PUSH DE
    PUSH HL
    LD DE, SD_FsStructClust
    CALL SDCARD_MsgPrint
    LD DE, SDCARD_WORKSPACE
    LD BC, (FS_VAR + FS_STRUCT.CURR_CLUSTER)
    CALL MATH_WORD_TO_STRING
    CALL SDCARD_MsgPrint

    LD DE, SD_FsStructSect
    CALL SDCARD_MsgPrint
    LD DE, SDCARD_WORKSPACE
    LD BC, FS_VAR + FS_STRUCT.CURR_SECTOR
    CALL MATH_DWORD_TO_STRING
    CALL SDCARD_MsgPrint

    LD DE, SD_FsStructIdx
    CALL SDCARD_MsgPrint
    LD DE, SDCARD_WORKSPACE
    LD A, (FS_VAR + FS_STRUCT.CURR_SECTOR_IDX)
    CALL Bin2BCD
;    LD A, H
;    CALL Bin2Hex_DE
    LD A, L
    CALL Bin2Hex_DE
    LD A, 0x00
    LD (DE), A
    LD DE, SDCARD_WORKSPACE
    CALL SDCARD_MsgPrintLN
    POP HL
    POP DE
    POP BC
    RET
SD_FsStructClust :
    DB "Cluster : ",0x00
SD_FsStructSect :
    DB " - Sector : ",0x00
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


SD_DRIVE_LETTER:
    DB 'C'
SDCARD_WORKSPACE:
    BLOCK 0x10, 0x00



