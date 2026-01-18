    IFNDEF __MONITOR_INC__
    DEFINE __MONITOR_INC__ 1

; Management of the File System Command
; For the Serial File System (through SERIAL B)
;
; cwd, cd, ls, run, cat, 

    include "memoryMapv2.inc"
    include "../lib/stdio.asm"
    include "../lib/serial.asm"
    include "../lib/string.asm"

EOT EQU 0x04
ENQ EQU 0x05
ACK EQU 0x06

SerFS_Init:
    PUSH HL
    LD A, 'A'
    LD (DRIVE_LETTER), A
    LD A, FS_SERIAL
    LD (FILE_SYSTEM), A
    LD HL, SerFS_Cmd_ls
    LD (FS_CMD_LS), HL
    LD HL, SerFS_Cmd_cd
    LD (FS_CMD_CD), HL
    LD HL, SerFS_Cmd_cwd
    LD (FS_CMD_CWD), HL
    LD HL, SerFS_Cmd_run
    LD (FS_CMD_RUN), HL
    LD HL, SerFS_Cmd_cat
    LD (FS_CMD_CAT), HL
    POP HL
    RET

SerFS_Cmd_ls:
    LD A, (FILE_SYSTEM)
    CP FS_SERIAL
    JP NZ, Wrong_File_System
    LD HL, LINE_EDIT_BUFFER_ADDRESS
    CALL SerFS_TxtCmd
    RET

SerFS_Cmd_cwd:
    LD A, (FILE_SYSTEM)
    CP FS_SERIAL
    JP NZ, Wrong_File_System
    LD HL, LINE_EDIT_BUFFER_ADDRESS
    CALL SerFS_TxtCmd
    RET

SerFS_Cmd_cd:
    LD A, (FILE_SYSTEM)
    CP FS_SERIAL
    JP NZ, Wrong_File_System
    LD HL, LINE_EDIT_BUFFER_ADDRESS
    CALL SerFS_TxtCmd
    RET

SerFS_Cmd_cat:
    LD A, (FILE_SYSTEM)
    CP FS_SERIAL
    JP NZ, Wrong_File_System
    LD HL, LINE_EDIT_BUFFER_ADDRESS
    CALL SerFS_TxtCmd
    RET

SerFS_Cmd_run:
    LD A, (FILE_SYSTEM)
    CP FS_SERIAL
    JP NZ, Wrong_File_System
    LD HL, LINE_EDIT_BUFFER_ADDRESS
.send_loop:
    CALL SendCharB_HL
    INC HL
    LD A, (HL)
    OR A
    JP NZ, .send_loop
    ;LD A, 0x0D
    ;CALL SendChar_A
    CALL ReceiveChar_B ; get Ack or Nack
    CP ACK ; Check for ACK
    JP NZ, .errorMsg
    CALL ReceiveChar_B ; get the two bytes for the size
    LD B, A
    CALL Hex2Str
    CALL ReceiveChar_B
    LD C, A
    CALL Hex2Str
    LD HL, CR_LF
    CALL PrintString
    LD HL, PROGRAM_BASE_ADDRESS
.receive_loop:
    CALL ReceiveChar_B
    LD (HL), A
;    CALL Hex2Str
    DEC BC
    INC HL
    LD A, C
    OR B
    JP Z, .end_loop
    ; LD A, B
    ; CALL Hex2Str
    ; LD A, C
    ; CALL Hex2Str
    LD A, '.'
    CALL SendChar_A
    JP .receive_loop
.end_loop:
    LD A, '/'
    CALL SendChar_A
    CALL ReceiveChar_B
    CALL Hex2Str
    LD HL, CR_LF
    CALL PrintString
    CALL PROGRAM_BASE_ADDRESS
    RET
.errorMsg:
    CALL ReceiveChar_B
    CP ACK
    JP Z, .error_loop
    CALL SendChar_A
    JP .errorMsg
.error_loop:
    RET

SerFS_TxtCmd: ; send command in HL and display response
.send_loop:
    CALL SendCharB_HL
    INC HL
    LD A, (HL)
    OR A
    JP NZ, .send_loop
;    LD A, 0x0D
;    CALL SendChar_A

    LD HL, 0xD000 ;WORKING_MEMORY_START + 0x400
.receive_Data_loop:
    CALL ReceiveChar_B
    LD (HL), A
    CP EOT
    JP Z, .endOfTransmission
    INC HL
    JP .receive_Data_loop
.endOfTransmission:
    LD A, 0x00
    LD (HL), A
    LD DE, 0xD000; WORKING_MEMORY_START . 0x400
    LD HL, (CURSOR_IDX)
;    LD B, LINE_LENGTH
.printLoop:
    CALL PutS_LN
    ; CALL PutS_Length
    ; PUSH AF
    ; PUSH HL
    ; LD HL, LINE_LENGTH
    ; ADD HL, DE
    ; EX DE, HL
    ; POP HL
    ; POP AF
    ; JP NZ, .printLoop
    LD (CURSOR_IDX), HL
    RET
SCROLL_LINE_NUMBER EQU 20
LINE_LENGTH EQU 80

Wrong_File_System:
    LD DE, SERFS_WRONGFS_MSG
    LD HL, (CURSOR_IDX)
    CALL PutS_LN
    LD (CURSOR_IDX), HL
    RET

SERFS_WRONGFS_MSG:
    DB "Wrong File System", 0x00


    ENDIF