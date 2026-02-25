; ------------------------------------------------------
; -                  shell_cmd.asm                     -
; -       shell command : ls, cd, cat ....             -
; ------------------------------------------------------

    
    IFNDEF __SHELL_CMD__
    DEFINE __SHELL_CMD__ 1

    INCLUDE "./fs_api.asm"


; SHELL_LS : list the files and directory in a directory
; * Params : Drive letter in A, cluster number in BC
; * Result in (DE)
; * success A=0x00, Carry flag reset
; * failure : A= error code, Carry flag set
SHELL_LS:
    PUSH BC
    PUSH DE
    PUSH HL
; init var and read first sector
    LD HL, BC
    CALL FS_OpenDir
    JP C, .error
; Put the name of the volume:
    LD HL, SHELL_MSG_VolLabel
    CALL CopyString
    LD HL, FAT_MIRROR_DCB + FAT_DRIVE_CONTROL.VOL_LABEL
    CALL CopyString
    LD A, 0x0A
    LD (DE), A
    INC DE
    LD A, 0x0D
    LD (DE), A
    INC DE

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
    ; do the stuff on the dir entry
    CALL SHELL_DirEntryProcess
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
SHELL_DirEntryProcess:
    PUSH BC
    PUSH HL
    LD A, (IX + FAT_DIR_ENTRY.LAST_MODIF_DATE)
    LD C, A
    LD A, (IX + FAT_DIR_ENTRY.LAST_MODIF_DATE + 1)
    LD B, A
    CALL SHELL_WordToDate
    LD A, ' '
    LD (DE), A
    INC DE
    LD A, (IX + FAT_DIR_ENTRY.LAST_MODIF_TIME)
    LD C, A
    LD A, (IX + FAT_DIR_ENTRY.LAST_MODIF_TIME + 1)
    LD B, A
    CALL SHELL_WordToTime
    LD A, ' '
    LD (DE), A
    INC DE
    LD A, ' '
    LD (DE), A
    INC DE
    LD A, (IX + FAT_DIR_ENTRY.ATTRIBUTE)
    CALL Bin2Hex_DE
    LD A, ' '
    LD (DE), A
    INC DE
    LD A, ' '
    LD (DE), A
    INC DE
; init filename loop
    PUSH IX
    POP HL
    LD B, 11
.fileNameLoop:
    LD A, (HL)
    LD (DE), A
    INC HL
    INC DE
    DJNZ .fileNameLoop
    LD A, ' '
    LD (DE), A
    INC DE
    LD A, ' '
    LD (DE), A
    INC DE
    LD A, (IX + FAT_DIR_ENTRY.START_CLUSTER + 1)
    CALL Bin2Hex_DE
    LD A, (IX + FAT_DIR_ENTRY.START_CLUSTER)
    CALL Bin2Hex_DE

    LD A, 0x0A
    LD (DE), A
    INC DE
    LD A, 0x0D
    LD (DE), A
    INC DE

    POP HL
    POP BC
    RET

; convert a date word to its string représentation
; * params : date word in BC YYYYYYYM MMMDDDDD
; * string représentation in (DE)
SHELL_WordToDate:
    PUSH HL
; day
    LD A, C
    AND 0x1F ; day in 5 LSb
    CALL Bin2BCD
    LD A, L
    CALL Bin2Hex_DE
    LD A, '/'
    LD (DE), A
    INC DE
; month
    LD A, B
    RRA
    LD A, C
    RLA
    RLA
    RLA
    RLA
    AND 0x0F
    CALL Bin2BCD
    LD A, L
    CALL Bin2Hex_DE
    LD A, '/'
    LD (DE), A
    INC DE
; year
    LD A, '2'
    LD (DE), A
    INC DE
    LD A, '0'
    LD (DE), A
    INC DE
    LD A, B
    OR A
    RRA
    SUB 20 ; a bit hacky, we suppose there won't be files too old
    CALL Bin2BCD
    LD A, L
    CALL Bin2Hex_DE
    POP HL
    RET


; convert a time word to its string représentation
; * params : time word in BC hhhhhmmm mmmsssss 
; * string représentation in (DE)
SHELL_WordToTime:
    PUSH BC
    PUSH HL
; hours
    LD A, B
    AND 0xF8 ; hours in 5 MSb of B
    RRA
    RRA
    RRA
    CALL Bin2BCD
    LD A, L
    CALL Bin2Hex_DE
    LD A, ':'
    LD (DE), A
    INC DE
; minutes
    LD A, B
    AND 0x07
    RL C
    RLA
    RL C
    RLA
    RL C
    RLA
    CALL Bin2BCD
    LD A, L
    CALL Bin2Hex_DE
    POP HL
    POP BC
    RET


SHELL_MSG_FatAddr DB 'FAT Address : ', 0x00
SHELL_MSG_PartStart DB 'Partition Start Address : ', 0x00
SHELL_MSG_DirRoot DB 'Dir Root : ', 0x00
SHELL_MSG_DataArea DB 'Data Area : ', 0x00
SHELL_MSG_MediaExt DB 'Media - Extended Sig : ', 0x00
SHELL_MSG_FatName DB 'FAT Name : ', 0x00
SHELL_MSG_OemName DB 'OEM Name : ', 0x00
SHELL_MSG_VolLabel DB 'Volume Label : ', 0x00
SHELL_MSG_ReservedSec DB 'Reserved sectors : ', 0x00
SHELL_MSG_sectorPerCluster DB 'Sectors per cluster : ', 0x00
SHELL_MSG_bytesPerSector DB 'Bytes per Sector : ', 0x00
SHELL_MSG_FatCount DB 'Fat Count : ', 0x00
SHELL_MSG_MaxRootDirEntry DB 'Max Root Dir Entry : ', 0x00
SHELL_TotalSectors DB 'Total Sctors : ', 0x00
SHELL_MSG_FatSize DB 'Fat Size : ', 0x00
SHELL_MSG_HiddenSector DB 'Hidden Sector(s) : ', 0x00
SHELL_MSG_TotalSector DB 'Total Sectors : ' , 0x00
SHELL_MSG_LogicalNum DB 'Logical Num : ', 0x00
SHELL_MSG_VolId DB 'Volume ID : ', 0x00
SHELL_MSG_SearchFileNotFound DB 'File not found', 0x00 ; Message to display if no match found
SHELL_MSG_SearchFileFound DB 'File found -> Cluster : ', 0x00 ; Message to display if match found


    ENDIF