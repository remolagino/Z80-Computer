; ------------------------------------------------------
; -                  shell_cmd.asm                     -
; -       shell command : ls, cd, cat ....             -
; ------------------------------------------------------

    
    IFNDEF __SHELL_CMD__
    DEFINE __SHELL_CMD__ 1

    INCLUDE "./fs_api.asm"


; FAT_LS : list the files and directory in a directory
; * Params : Drive letter in A, cluster number in BC
; * Result in (DE)
; * success A=0x00, Carry flag reset
; * failure : A= error code, Carry flag set
SHELL_LS:
    PUSH HL
; store the current drive and sector
    PUSH DE
    LD (SHELL_CURR_DRIVE), A
    LD (SHELL_CURR_CLUSTER), BC
    LD HL, BC
    CALL FAT_GetLBAfromCluster
    LD (SHELL_CURR_SECTOR), DE
    LD (SHELL_CURR_SECTOR + 2), BC
    POP DE

; Put the name of the volume:
    LD HL, SHELL_MSG_VolLabel
    CALL SHELL_CopyString
    LD HL, FAT_VOL_LABEL
    CALL SHELL_CopyString
    LD A, 0x0A
    LD (DE), A
    INC DE
    LD A, 0x0D
    LD (DE), A
    INC DE

.sectorLoop:
    PUSH DE
    LD HL, FAT_BUFFER
    LD A, (SHELL_CURR_DRIVE)
    LD DE, (SHELL_CURR_SECTOR)
    LD BC, (SHELL_CURR_SECTOR + 2)
    CALL DISK_READ
    POP DE
    JP C, .error

; iterate on the directory entries  in the sector
    LD IX, FAT_BUFFER
    LD B, 16 ; max number dir entries in a sector
.dirLoop:
    LD A, (IX)
    CP 0x00
    JP Z, .exit
    CP 0xE5
    JP Z, .nextEntry
    LD A, (IX + DIR_ENTRY.ATTRIBUTE)
    AND 0x0F
;    CP 0x0F
    JP NZ, .nextEntry
    ; do the stuff on the dir entry
    CALL SHELL_DirEntryProcess
    LD A, 0x0A
    LD (DE), A
    INC DE
    LD A, 0x0D
    LD (DE), A
    INC DE
    ; end of stuff on the dir entry, now we loop
.nextEntry:
    PUSH BC
    LD BC, 32
    ADD IX, BC
    POP BC
    DJNZ .dirLoop
;  Increment to the next sector
    LD B, 0x01
    LD A, (SHELL_CURR_SECTOR)
    ADD B
    LD (SHELL_CURR_SECTOR), A
    LD B, 0x00
    LD A, (SHELL_CURR_SECTOR + 1)
    ADC B
    LD (SHELL_CURR_SECTOR + 1), A
    LD A, (SHELL_CURR_SECTOR + 2)
    ADC B
    LD (SHELL_CURR_SECTOR + 2), A
    LD A, (SHELL_CURR_SECTOR + 3)
    ADC B
    LD (SHELL_CURR_SECTOR + 3), A
    JP .sectorLoop
.exit:
    LD A, 0x00
    LD (DE), A
    OR A
    POP HL
    RET
.error:
    SCF
    POP HL
    RET


; copy the null_terminated string in (HL) to (DE)
; * DE at the end of the string for next add
SHELL_CopyString:
    PUSH HL
.loop:
    LD A, (HL)
    CP 0x00
    JR Z, .exit
    LD (DE), A
    INC HL
    INC DE
    JP .loop
.exit:
    POP HL
    RET
    

; Create a formated string (\n terminated) of the dir entry
; * Dir entry in IX
; * result string in (DE)
; * HL at the end of the string for next iteration
SHELL_DirEntryProcess:
    PUSH BC
    PUSH HL
    LD A, (IX + DIR_ENTRY.LAST_MODIF_DATE)
    LD C, A
    LD A, (IX + DIR_ENTRY.LAST_MODIF_DATE + 1)
    LD B, A
    CALL SHELL_WordToDate
    LD A, ' '
    LD (DE), A
    INC DE
    LD A, (IX + DIR_ENTRY.LAST_MODIF_TIME)
    LD C, A
    LD A, (IX + DIR_ENTRY.LAST_MODIF_TIME + 1)
    LD B, A
    CALL SHELL_WordToTime
    LD A, ' '
    LD (DE), A
    INC DE
    LD A, ' '
    LD (DE), A
    INC DE
    LD A, (IX + DIR_ENTRY.ATTRIBUTE)
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
    LD A, (IX + DIR_ENTRY.START_CLUSTER + 1)
    CALL Bin2Hex_DE
    LD A, (IX + DIR_ENTRY.START_CLUSTER)
    CALL Bin2Hex_DE
 
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

SHELL_CURR_CLUSTER:
    WORD 0x0000
SHELL_CURR_SECTOR:
    DWORD 0x00000000
SHELL_CURR_DRIVE:
    DB 0x00

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