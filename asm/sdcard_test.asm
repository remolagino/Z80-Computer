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

    ; LD A ,'C'
    ; CALL FAT_SELECT_MIRROR_DCB

    ; LD BC, 0x0100
    ; CALL FAT_GetNextCluster
    ; LD B, D
    ; LD C, E
    ; LD DE, SDCARD_WORKSPACE
    ; CALL MATH_WORD_TO_STRING
    ; CALL SDCARD_MsgPrintLN

    

;     LD DE, SDCARD_Init2_MSG
;     CALL SDCARD_MsgPrint
;     LD A, SPI_CS1_BIT
;     LD HL, SDCARD_BUFFER
;     LD BC, (FAT_MIRROR_LBA_FAT1 + 2)
;     LD DE, (FAT_MIRROR_LBA_FAT1)
;  ;    CALL DISK_WRITE
;     CALL DISK_READ
;     JP C, .initError
;     CALL SDCARD_CodePrint

;     LD BC, FAT_MIRROR_MAX_CLUSTER_NUMBER
;     LD DE, SDCARD_WORKSPACE
;     CALL MATH_DWORD_TO_STRING
;     CALL SDCARD_MsgPrintLN
;     RET
.loop:
    CALL LineEdit_Init
    LD HL, (CURSOR_IDX)
    CALL LineEdit
    LD DE, LF_CR
    CALL PutS
     LD (CURSOR_IDX), HL

    LD HL, LINE_EDIT_BUFFER_ADDRESS
    LD A, (HL)
    CP '²'
    JP Z, .exit
    LD (SD_DRIVE_LETTER), A
    INC HL
    CALL HexWord2Bin
    JP NZ, .error
    LD B, D ; cluster number needs to be in BC
    LD C, E

    ; LD DE, SDCARD_LS_MSG
    ; CALL SDCARD_MsgPrint
    LD A, (SD_DRIVE_LETTER)

    LD DE, SDCARD_BUFFER2
    CALL SHELL_LS
    JP C, .error
    CALL SDCARD_CodePrint

    LD HL, (CURSOR_IDX)
    LD DE, SDCARD_BUFFER2
    CALL PutS_LN
    LD (CURSOR_IDX), HL
    
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
; SDCARD_STATUS_MSG:
;     DB "Get Status Result : ", 0x00
; SDCARD_GetBlock_MSG :
;     DB "Block Received : ", 0x00
; SDCARD_WriteBlock_MSG:
;     DB "Write back the block : ", 0x00
; SDCARD_LS_MSG:
;     DB "LS test : ", 0x00
; SDCARD_Time_MSG:
;     DB "Time test : ", 0x00

SD_DRIVE_LETTER:
    DB 0x00
SDCARD_WORKSPACE:
    BLOCK 0x10, 0x00



