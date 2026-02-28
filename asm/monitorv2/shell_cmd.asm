; ------------------------------------------------------
; -                  shell_cmd.asm                     -
; -       shell command : ls, cd, cat ....             -
; ------------------------------------------------------

    
    IFNDEF __SHELL_CMD__
    DEFINE __SHELL_CMD__ 1

    INCLUDE "../lib/fs_api.asm"
    INCLUDE "../lib/doubleDabble.asm"


; TODO : Put that in MemoryMap
; IMPLEMENT CURRENT_DIR AND PATH for C: and B:
SHELL_DRIVE_LETTER:
    DB 0x00
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
    
; Initialise the shell with drive C at the root
SHELL_INIT_DRIVE_C:
    PUSH AF
    PUSH HL
    LD A, 'C'
    LD (SHELL_DRIVE_LETTER), A
    LD HL, 0x0000
    LD (SHELL_CURRENT_DIR), HL
    LD A, '/'
    LD HL, SHELL_CANONICAL_PATH
    LD (HL), A
    POP HL
    POP AF
    RET

; Cmd LS. Parse cmd line in (DE)
; * Result (printable text) in (HL)
; * success A=0x00, Carry flag reset
; * failure : A= error code, Carry flag set
SHELL_LS:
    PUSH BC
    PUSH DE
    PUSH HL
    LD (SHELL_OUT_ADDR), HL
    INC DE
    LD A, (DE)
    CP ':'
    JP NZ, .useCurrentDrive
    DEC DE
    LD A, (DE); get the drive letter
    INC DE
    INC DE
    JP .setMirrorDCB
.useCurrentDrive:
    DEC DE ; put DE back at begining of buffer
    LD A, (SHELL_DRIVE_LETTER)
.setMirrorDCB:
    CALL FAT_SELECT_MIRROR_DCB
    JP C, .driveError
    LD A, (FAT_MIRROR_DCB + FAT_DRIVE_CONTROL.MOUNTED)
    CP 0x00
    JP Z, .driveError

    LD (SHELL_CMD_PARAM_ADDR), DE
    LD HL, SHELL_TMP_STRING
    CALL CopyStringDE2HL ; copy line edit buffer to workspace

    LD HL, (SHELL_CURRENT_DIR)
    LD DE, SHELL_TMP_STRING
    CALL FS_followPath
    JP C, .notFound

    LD A, (IX + FAT_DIR_ENTRY.ATTRIBUTE)
    AND 0x10
    CP 0x10
    JP NZ, .file

    LD DE, SHELL_CANONICAL_PATH
    LD HL, SHELL_TMP_STRING
    CALL CopyStringDE2HL ; copy canonical path to tmp

    LD HL, SHELL_TMP_STRING
    LD DE, (SHELL_CMD_PARAM_ADDR) 
    CALL FATtools_CanonicalizePath

    LD DE, (SHELL_OUT_ADDR)
; Put the name of the volume:
    LD HL, SHELL_LS_VolLabel
    CALL CopyStringHL2DE
    LD HL, FAT_MIRROR_DCB + FAT_DRIVE_CONTROL.VOL_LABEL
    CALL CopyStringHL2DE
    LD A, 0x0A
    LD (DE), A
    INC DE
    LD A, 0x0D
    LD (DE), A
    INC DE
; Put the canonical path:
    LD HL, SHELL_LS_DirOf
    CALL CopyStringHL2DE
    LD A, (FAT_MIRROR_DCB + FAT_DRIVE_CONTROL.DRIVE_LETTER)
    LD (DE), A
    INC DE
    LD A, ':'
    LD (DE), A
    INC DE
    LD HL, SHELL_TMP_STRING
    CALL CopyStringHL2DE
    LD A, 0x0A
    LD (DE), A
    INC DE
    LD A, 0x0D
    LD (DE), A
    INC DE
    CALL SHELL_ListDir
    POP HL
    POP DE
    POP BC
    RET
.file:
    LD DE, (SHELL_OUT_ADDR)
    LD HL, SHELL_LS_File
    CALL CopyStringHL2DE
    LD HL, BC ; BC contains the address on the token not found
    CALL CopyStringHL2DE
    POP HL
    POP DE
    POP BC
    RET
.notFound:
;    LD BC, DE ; put the unfound token in BC
    LD DE, (SHELL_OUT_ADDR)
    LD HL, SHELL_LS_NotFound
    CALL CopyStringHL2DE
    LD HL, BC ; BC contains the address on the token not found
    CALL CopyStringHL2DE
    POP HL
    POP DE
    POP BC
    RET
.driveError:
    LD DE, (SHELL_OUT_ADDR)
    LD HL, SHELL_LS_Error
    CALL CopyStringHL2DE
    POP HL
    POP DE
    POP BC
    RET


; Cmd CD. Parse cmd line in (DE)
; * Result: currrent dir set to cluster
; * result message in (HL)
; * success A=0x00, Carry flag reset
; * failure : A= error code, Carry flag set
SHELL_CD:
    PUSH BC
    PUSH DE
    PUSH HL
    LD (SHELL_OUT_ADDR), HL
    INC DE
    LD A, (DE)
    CP ':'
    JP NZ, .useCurrentDrive
    DEC DE
    LD A, (DE); get the drive letter
    INC DE
    INC DE
    JP .setMirrorDCB
.useCurrentDrive:
    DEC DE ; put DE back at begining of buffer
    LD A, (SHELL_DRIVE_LETTER)
.setMirrorDCB:
    CALL FAT_SELECT_MIRROR_DCB
    JP C, .driveError
    LD A, (FAT_MIRROR_DCB + FAT_DRIVE_CONTROL.MOUNTED)
    CP 0x00
    JP Z, .driveError

    LD (SHELL_CMD_PARAM_ADDR), DE
    LD HL, SHELL_TMP_STRING
    CALL CopyStringDE2HL ; copy line edit buffer to workspace

    LD HL, (SHELL_CURRENT_DIR)
    LD DE, SHELL_TMP_STRING
    CALL FS_followPath
    JP C, .notFound

    LD A, (IX + FAT_DIR_ENTRY.ATTRIBUTE)
    AND 0x10
    CP 0x10
    JP NZ, .file

    LD (SHELL_CURRENT_DIR), BC

    LD HL, SHELL_CANONICAL_PATH
    LD DE, (SHELL_CMD_PARAM_ADDR) 
    CALL FATtools_CanonicalizePath

    LD DE, (SHELL_OUT_ADDR)
; Put the canonical path:
    LD A, (FAT_MIRROR_DCB + FAT_DRIVE_CONTROL.DRIVE_LETTER)
    LD (DE), A
    INC DE
    LD A, ':'
    LD (DE), A
    INC DE
    LD HL, SHELL_CANONICAL_PATH
    CALL CopyStringHL2DE
    LD A, 0x0A
    LD (DE), A
    INC DE
    LD A, 0x0D
    LD (DE), A
    INC DE
    LD A, 0x00
    LD (DE), A
    POP HL
    POP DE
    POP BC
    RET
.file:
    LD DE, (SHELL_OUT_ADDR)
    LD HL, SHELL_LS_File
    CALL CopyStringHL2DE
    LD HL, BC ; BC contains the address on the token not found
    CALL CopyStringHL2DE
    POP HL
    POP DE
    POP BC
    RET
.notFound:
;    LD BC, DE ; put the unfound token in BC
    LD DE, (SHELL_OUT_ADDR)
    LD HL, SHELL_LS_NotFound
    CALL CopyStringHL2DE
    LD HL, BC ; BC contains the address on the token not found
    CALL CopyStringHL2DE
    POP HL
    POP DE
    POP BC
    RET
.driveError:
    LD DE, (SHELL_OUT_ADDR)
    LD HL, SHELL_LS_Error
    CALL CopyStringHL2DE
    POP HL
    POP DE
    POP BC
    RET




; SHELL_ListDir : list the files and directory in a directory
; * Params : cluster number in BC
; * Result in (DE)
; * success A=0x00, Carry flag reset
; * failure : A= error code, Carry flag set
SHELL_ListDir:
    PUSH BC
    PUSH DE
    PUSH HL
; init var and read first sector
    LD HL, BC
    LD A, (FAT_MIRROR_DCB + FAT_DRIVE_CONTROL.DRIVE_LETTER)
    CALL FS_OpenDir
    JP C, .error
; iterate on the directory entries  in the sector
.entryLoop:
    LD A, (IX)
    CP 0x00
    JP Z, .exit
    CP 0xE5
    JP Z, .nextEntry
    LD A, (IX + FAT_DIR_ENTRY.ATTRIBUTE)
;     AND 0x0F
    CP 0x0F
    JP Z, .nextEntry
    CP 0x08
    JP Z, .nextEntry
    ; do the stuff on the dir entry
    CALL SHELL_DirEntryFormat
    ; end of stuff on the dir entry, now we loop
.nextEntry:
    CALL FS_GetNextEntry
    JP C, .error
    JP NZ, .entryLoop
.exit:
    LD A, 0x00
    LD (DE), A
    OR A
    POP HL
    POP DE
    POP BC
    RET
.error:
    SCF
    POP HL
    POP DE
    POP BC
    RET
   

; Create a formated string (\n terminated) of the dir entry
; * Dir entry in IX
; * result string in (DE)
; * HL at the end of the string for next iteration
SHELL_DirEntryFormat:
    PUSH BC
    PUSH HL
    LD A, (IX + FAT_DIR_ENTRY.LAST_MODIF_DATE)
    LD C, A
    LD A, (IX + FAT_DIR_ENTRY.LAST_MODIF_DATE + 1)
    LD B, A
    CALL FATtools_WordToDate
    LD A, ' '
    LD (DE), A
    INC DE
    LD A, (IX + FAT_DIR_ENTRY.LAST_MODIF_TIME)
    LD C, A
    LD A, (IX + FAT_DIR_ENTRY.LAST_MODIF_TIME + 1)
    LD B, A
    CALL FATtools_WordToTime
    LD A, ' '
    LD (DE), A
    INC DE
    LD A, ' '
    LD (DE), A
    INC DE
    LD A, ' '
    LD (DE), A
    INC DE

    LD A, (IX + FAT_DIR_ENTRY.ATTRIBUTE)
    AND 0x20
    CP 0x20
    JP Z, .displaySize
    LD A, ' '
    LD (DE), A
    INC DE
    LD A, ' '
    LD (DE), A
    INC DE
    LD A, ' '
    LD (DE), A
    INC DE
    LD A, '<'
    LD (DE), A
    INC DE
    LD A, 'D'
    LD (DE), A
    INC DE
    LD A, 'I'
    LD (DE), A
    INC DE
    LD A, 'R'
    LD (DE), A
    INC DE
    LD A, '>'
    LD (DE), A
    INC DE
    JP .displayName
.displaySize:
    PUSH DE
    LD B, (IX + FAT_DIR_ENTRY.SIZE + 3)
    LD C, (IX + FAT_DIR_ENTRY.SIZE + 2)
    LD D, (IX + FAT_DIR_ENTRY.SIZE + 1)
    LD E, (IX + FAT_DIR_ENTRY.SIZE)
    LD HL, SHELL_TMPBCD
    CALL DBDAB_bin2dec_dword
    POP DE
    LD A, 4 ; no file of size 100MB or more
    CALL Dbdab_printable
.displayName:
    LD A, 0x09 ; tab
    LD (DE), A
    INC DE
; init filename loop
    PUSH IX ; put IX in HL
    POP HL
    LD B, 8
.fileNameLoop:
    LD A, (HL)
    CP ' '
    JP Z, .skipSpaceInName
    LD (DE), A
    INC DE
.skipSpaceInName:
    INC HL
    DJNZ .fileNameLoop
    LD A, '.'
    LD (DE), A
    INC DE
    LD B, 3
.extLoop:
    LD A, (HL)
    CP ' '
    JP Z, .skipSpaceInExt
    LD (DE), A
    INC DE
.skipSpaceInExt:
    INC HL
    DJNZ .extLoop
    DEC DE
    LD A, (DE)
    CP '.'
    JP NZ, .eol
    LD A, ' '
    LD (DE), A
.eol:
    INC DE
    LD A, 0x0A
    LD (DE), A
    INC DE
    LD A, 0x0D
    LD (DE), A
    INC DE

    POP HL
    POP BC
    RET


SHELL_LS_VolLabel:
    DB 'Volume Label : ', 0x00
SHELL_LS_DirOf:
    DB "Directory of ", 0x00
SHELL_LS_File:
    DB "File : ", 0x00
SHELL_LS_NotFound:
    DB "Not Found : ", 0x00
SHELL_LS_Error:
    DB "Error Disk : ", 0x00



    ENDIF