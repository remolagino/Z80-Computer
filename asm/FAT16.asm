; ------------------------------------------------------
; -                  FAT16.asm                         -
; -       Filesystem management for FAT 16             -
; ------------------------------------------------------

    
    IFNDEF __FAT16__
    DEFINE __FAT16__ 1


FAT_BUFFER EQU 0x8000

    INCLUDE "FAT16.inc"
    INCLUDE "./lib/math.asm"
    INCLUDE "./lib/diskio.asm"

; FAT_MOUNT : Initialise the SD CARD. Compute the FAT values
; * Parameters : Drive letter (B or C) in A
; * Return : set the Carry flag if failure
FAT_MOUNT:
    PUSH BC
    PUSH DE
    PUSH HL

    LD (FAT_DRIVE_LETTER), A
    CALL DISK_INIT
    LD A, 0x90 ; error code Disk not ready
    RET C
    LD BC, 0x0000
    LD DE, 0x0000
    LD HL, FAT_BUFFER
    LD A, (FAT_DRIVE_LETTER)
    CALL DISK_READ
    LD A, 0x91
    RET C
; check filesystem type
    LD A, (FAT_BUFFER + MBR.PARTITION1.TYPE)
    CP 0x06 ; check if partition type is FAT16
    LD A, 0x92 ; error code for wrong file system
    JP NZ, .error
; get LBA Start
    LD DE, (FAT_BUFFER + MBR.PARTITION1.BEGINING_LBA)
    LD BC, (FAT_BUFFER + MBR.PARTITION1.BEGINING_LBA + 2)
    LD (FAT_LBA_START), DE
    LD (FAT_LBA_START+2), BC
; get Boot Record from LBA
    LD HL, FAT_BUFFER
    LD A, (FAT_DRIVE_LETTER)
    CALL DISK_READ
; get Sectors per Cluster
    LD A, (FAT_BUFFER + BOOT_RECORD.SECTORS_PER_CLUSTER)
    LD (FAT_SPC), A
; get FAT1 Sector Address
    LD BC, FAT_LBA_START
    LD HL, (FAT_BUFFER + BOOT_RECORD.RESERVED_SECTORS)
    LD DE, FAT_LBA_FAT1
    CALL MATH_ADD_WORD_TO_DWORD
; get FAT2 Sector Address
    LD BC, FAT_LBA_FAT1
    LD HL, (FAT_BUFFER + BOOT_RECORD.FAT_SIZE)
    LD DE, FAT_LBA_FAT2
    CALL MATH_ADD_WORD_TO_DWORD
; get ROOT Sector Address
    LD BC, FAT_LBA_FAT2
    LD HL, (FAT_BUFFER + BOOT_RECORD.FAT_SIZE)
    LD DE, FAT_LBA_ROOT
    CALL MATH_ADD_WORD_TO_DWORD
; get Root Dir Size 
    LD HL, (FAT_BUFFER + BOOT_RECORD.MAX_ROOT_DIR_ENTRIES)
    SRL H
    RR L  ; /2
    SRL H
    RR L  ; /4
    SRL H
    RR L  ; /8
    SRL H
    RR L  ; /16
    LD (FAT_ROOT_DIR_SIZE), HL
; get DATA Start Sector address
    LD BC, FAT_LBA_ROOT
    LD HL, (FAT_ROOT_DIR_SIZE)
    LD DE, FAT_LBA_DATA_START
    CALL MATH_ADD_WORD_TO_DWORD
; create the 


    LD A, 0x00
    OR A ; reset carry flag
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

; FAT_LS : list the files and directory in a directory
; * Params : Drive letter in A, cluster number in BC
; * Result in (DE)
; * success A=0x00, Carry flag reset
; * failure : A= error code, Carry flag set
FAT_LS:
    PUSH DE
    PUSH HL
    LD HL, BC
    CALL FAT_GetLBAfromCluster
    LD HL, FAT_BUFFER
    CALL DISK_READ
    POP HL
    POP DE
    RET C
; iterate on the directory entries  in the sector
    LD IX, FAT_BUFFER
    LD B, 16 ; max number dir entries in a sector
.dirLoop:
    LD A, (IX)
    CP 0x00
    JP Z, .exit
    ; CP 0xE5
    ; JP Z, .nextEntry
    LD A, (IX + DIR_ENTRY.ATTRIBUTE)
    CP 0x0F
    JP Z, .nextEntry
    ; do the stuff on the dir entry
    CALL FAT_DirEntryProcess
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
.exit:
    LD A, 0x00
    LD (DE), A
    OR A
    RET



; Create a formated string (\n terminated) of the dir entry
; * Dir entry in IX
; * result string in (DE)
; * HL at the end of the string for next iteration
FAT_DirEntryProcess:
    PUSH BC
    PUSH HL
    LD A, (IX + DIR_ENTRY.LAST_MODIF_DATE)
    LD C, A
    LD A, (IX + DIR_ENTRY.LAST_MODIF_DATE + 1)
    LD B, A
    CALL FAT_WordToDate
    LD A, ' '
    LD (DE), A
    INC DE
    LD A, (IX + DIR_ENTRY.LAST_MODIF_TIME)
    LD C, A
    LD A, (IX + DIR_ENTRY.LAST_MODIF_TIME + 1)
    LD B, A
    CALL FAT_WordToTime
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
FAT_WordToDate:
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
FAT_WordToTime:
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


; take the cluster in HL
; Return the LBA in BCDE
FAT_GetLBAfromCluster:
    PUSH AF
    PUSH HL
;cluster 0 or 1 are Root directory
    LD A, L
    AND 0xFE
    OR H
    JP Z, .isRoot
; Calcul LBA = Data + (Cluster-2) x SPC
    DEC HL
    DEC HL
    LD BC, FAT_TMP_DWORD
    LD A, (FAT_SPC)
    CALL MATH_MULT_WORD_BYTE
    LD HL, FAT_LBA_DATA_START
    LD DE, FAT_TMP_DWORD
    CALL MATH_ADD_DWORD_TO_DWORD
    LD HL, (FAT_TMP_DWORD)
    LD D, H
    LD E, L
    LD HL, (FAT_TMP_DWORD + 2)
    LD B, H
    LD C, L

    POP HL
    POP AF
    RET
.isRoot:
    LD HL, (FAT_LBA_ROOT)
    LD D, H
    LD E, L
    LD HL, (FAT_LBA_ROOT + 2)
    LD B, H
    LD C, L
    POP HL
    POP AF
    RET


FAT_DRIVE_LETTER:
    DB 0x00
FAT_MOUNTED:
    DB 0x00
FAT_LBA_START:
    DWORD 0x00000000
FAT_LBA_FAT1: ; = LBA_Start + Reserved_Sectors
    DWORD 0x00000000
FAT_LBA_FAT2: ; = LBA_FAT1 + Sectors_Per_FAT
    DWORD 0x00000000
FAT_LBA_ROOT: ; = LBA_FAT2 + Sectors_Per_FAT
    DWORD 0x00000000
FAT_LBA_DATA_START: ; = LBA_Root + Taille_du_Root_Dir
    DWORD 0x00000000
FAT_ROOT_DIR_SIZE: ; = (max root entries * 32)/512
    WORD 0x0000
FAT_SPC: ; Sectors per Cluster
    DB 0x00
FAT_TMP_DWORD:
    DWORD 0x00000000

FAT16_MSG_FatAddr DB 'FAT Address : ', 0x00
FAT16_MSG_PartStart DB 'Partition Start Address : ', 0x00
FAT16_MSG_DirRoot DB 'Dir Root : ', 0x00
FAT16_MSG_DataArea DB 'Data Area : ', 0x00
FAT16_MSG_MediaExt DB 'Media - Extended Sig : ', 0x00
FAT16_MSG_FatName DB 'FAT Name : ', 0x00
FAT16_MSG_OemName DB 'OEM Name : ', 0x00
FAT16_MSG_VolLabel DB 'Volume Label : ', 0x00
FAT16_MSG_ReservedSec DB 'Reserved sectors : ', 0x00
FAT16_MSG_sectorPerCluster DB 'Sectors per cluster : ', 0x00
FAT16_MSG_bytesPerSector DB 'Bytes per Sector : ', 0x00
FAT16_MSG_FatCount DB 'Fat Count : ', 0x00
FAT16_MSG_MaxRootDirEntry DB 'Max Root Dir Entry : ', 0x00
FAT16_TotalSectors DB 'Total Sctors : ', 0x00
FAT16_MSG_FatSize DB 'Fat Size : ', 0x00
FAT16_MSG_HiddenSector DB 'Hidden Sector(s) : ', 0x00
FAT16_MSG_TotalSector DB 'Total Sectors : ' , 0x00
FAT16_MSG_LogicalNum DB 'Logical Num : ', 0x00
FAT16_MSG_VolId DB 'Volume ID : ', 0x00
FAT16_MSG_SearchFileNotFound DB 'File not found', 0x00 ; Message to display if no match found
FAT16_MSG_SearchFileFound DB 'File found -> Cluster : ', 0x00 ; Message to display if match found


    ENDIF