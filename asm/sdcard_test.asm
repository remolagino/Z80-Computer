; --------------------------------------------
; -------- test program for SDCARD -------------
; --------------------------------------------
    .ORG 0x4000

    JP Main

 ;   INCLUDE "./lib/diskio.asm"
    INCLUDE "./monitorv2/memoryMapv2.inc"
    INCLUDE "./monitorv2/lineEdit.asm"
    INCLUDE "FAT16.asm"
    INCLUDE "./lib/stdio.asm"
    INCLUDE "./lib/string.asm"

SDCARD_BUFFER  EQU 0x7000
SDCARD_BUFFER2 EQU SDCARD_BUFFER + 0x0200


Main:
    LD DE, SDCARD_Init_MSG
    CALL SDCARD_MsgPrint
    LD A, 'C'
    CALL FAT_MOUNT
    JP C, .error
    CALL SDCARD_CodePrint

    LD A, 'C'
    LD HL, SDCARD_BUFFER
    LD BC, (FAT_LBA_FAT1 + 2)
    LD DE, (FAT_LBA_FAT1)
    CALL DISK_READ
.loop:
    CALL LineEdit_Init
    LD HL, (CURSOR_IDX)
    CALL LineEdit
    LD DE, LF_CR
    CALL PutS
    ; LD DE, LINE_EDIT_BUFFER_ADDRESS
    ; CALL PutS_LN
    LD (CURSOR_IDX), HL

    LD HL, LINE_EDIT_BUFFER_ADDRESS
    LD A, (HL)
    CP '²'
    JP Z, .exit

    CALL HexWord2Bin
    JP NZ, .error
    LD B, D
    LD C, E

    ; LD DE, SDCARD_LS_MSG
    ; CALL SDCARD_MsgPrint
    LD A, 'C'
 ;   LD BC, 0x0000
    LD DE, SDCARD_BUFFER2
    CALL FAT_LS
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
    LD A, 0x00
    JP .loop


SDCARD_MsgPrint: ; print message in DE
    PUSH HL
    LD HL, (CURSOR_IDX)
    CALL PutS
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
SDCARD_Init_MSG:
    DB "Starting Initialisation : ", 0x00
SDCARD_INIT_SUCCESS_MSG:
    DB "SD Card initialized successfully.", 0x00
SDCARD_ERRROR_MSG:
    DB "Error: ", 0x00
SDCARD_STATUS_MSG:
    DB "Get Status Result : ", 0x00
SDCARD_GetBlock_MSG :
    DB "Block Received : ", 0x00
SDCARD_WriteBlock_MSG:
    DB "Write back the block : ", 0x00
SDCARD_LS_MSG:
    DB "LS test : ", 0x00
SDCARD_Time_MSG:
    DB "Time test : ", 0x00

SDCARD_LOREM:
    DB "Lorem ipsum dolor sit amet, consectetur adipiscing elit. "
    DB "Integer placerat felis est, quis tempus ligula mollis nec. "
    DB "Aliquam ac nunc eget velit dictum tincidunt sed sit amet "
    DB "massa. Sed rutrum nec augue at auctor. Donec at hendrerit"
    DB " nunc, pretium rhoncus turpis. Praesent quis ante porta, "
    DB "aliquam quam ut, varius neque. Etiam eget finibus purus, vitae"
    DB " convallis magna. Integer rutrum vel risus ut tincidunt. "
    DB "Integer a hendrerit turpis. Nam accumsan urna in nulla "
    DB "ullamcorper ultricies. Cras convallis mauris proin."
    DB " Curabitur placerat commodo libero, in elementum velit "
    DB "tempus vitae. In pharetra sit amet eros non blandit. Sed "
    DB "at mi ut elit consequat tristique. Ut imperdiet quam at enim "
    DB "malesuada fringilla. Cras luctus ante nec urna rutrum elementum. "
    DB "Aliquam dapibus, dui non egestas suscipit, sem neque dictum arcu, "
    DB "eget condimentum libero dui volutpat tortor. Aliquam elementum "
    DB "posuere sollicitudin. Ut in pellentesque nulla. Aenean vitae velit "
    DB "nisl. Vivamus viverra, justo id aliquet accumsan, est risus "
    DB "vehicula est, tempus aliquet arcu lorem at nisi. Duis tellus."

SDCARD_WORKSPACE:
    BLOCK 0x10, 0x00



