; ------------------------------------------------------
; -                  shell_cmd.asm                     -
; -       shell command : ls, cd, cat ....             -
; -        Direct Shell cmd to proper drive            -
; ------------------------------------------------------

    
    IFNDEF __SHELL_CMD__
    DEFINE __SHELL_CMD__ 1

    include "./memoryMapv2.inc"
    INCLUDE "./FAT_cmd.asm"
    INCLUDE "./FS_Serial.asm"


; TODO : Put that in MemoryMap
; IMPLEMENT CURRENT_DIR AND PATH for C: and B:
SHELL_CURRENT_DIR :
    WORD 0x0000
SHELL_START_PATH: ; stop condition for the path canonisation
; a bit fragile, to be updated
    DB 0x00
SHELL_CANONICAL_PATH:
    BLOCK 0x100, 0x00
SHELL_CMD_PARAM_ADDR:
    WORD 0x0000
SHELL_OUT_ADDR:
    WORD 0x0000
SHELL_TMPBCD:
    BLOCK 0x05, 0x00
SHELL_TMP_STRING:
    BLOCK 0x100, 0x00
    

; select fqs type and st the adjusted parameters address
; the parameters in (DE)
; results parameters address in (SHELL_CMD_PARAM_ADDR)
SHELL_CMD_SELECT_FS:
    INC DE
    LD A, (DE)
    CP ':'
    JP NZ, .useCurrentDrive
    DEC DE
    LD A, (DE); get the drive letter
    INC DE
    INC DE
    JP .exit
.useCurrentDrive:
    DEC DE ; put DE back at begining of buffer
    LD A, (SHELL_DRIVE_LETTER)
.exit:

    RET



; Ls command with the direction to FAT or Serial based on the drive 
SHELL_CMD_LS:
    RET


; cd command
SHELL_CMD_CD:
    RET

; run command
SHELL_CMD_RUN:
    RET

; cat command
SHELL_CMD_CAT:
    RET