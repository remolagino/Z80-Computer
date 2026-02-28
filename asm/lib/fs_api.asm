; ------------------------------------------------------
; -                  fs_api.asm                        -
; -  abstraction between filesystem and shell cmd      -
; ------------------------------------------------------

    
    IFNDEF __FS_API__
    DEFINE __FS_API__ 1

    INCLUDE "./FAT16.asm"
    INCLUDE "./FATtools.asm"


    STRUCT FS_STRUCT
DRIVE BYTE
DIR_CLUSTER WORD
CURR_CLUSTER WORD
CURR_SECTOR DWORD
CURR_SECTOR_IDX BYTE
CURR_ENTRY_IDX BYTE
    ENDS

FS_CONTEXT EQU 0x8500

FS_FILENAME_PREP EQU FS_CONTEXT + FS_STRUCT ; need 12 chars
;    BLOCK 0x100, 0x00

; Prépare la lecture d'un répertoire (initialise les pointeurs)
; * Drive Letter in A
; * HL as the root cluster of the dir
; * Return : IX is position at the begining of the FAT buffer for process
FS_OpenDir:
    CALL FAT_SELECT_MIRROR_DCB
    RET C

    PUSH BC
    PUSH DE
    PUSH HL
    LD (FS_CONTEXT + FS_STRUCT.DRIVE), A
    LD (FS_CONTEXT + FS_STRUCT.DIR_CLUSTER), HL
    LD (FS_CONTEXT + FS_STRUCT.CURR_CLUSTER), HL
; check if root dir
    LD A, H
    OR L
    JP NZ, .notRootDir
    LD A, (FAT_MIRROR_DCB + FAT_DRIVE_CONTROL.ROOT_DIR_SIZE)
    JP .setSectorIdx
.notRootDir:
    LD A, (FAT_MIRROR_DCB + FAT_DRIVE_CONTROL.SPC)
.setSectorIdx:
    LD (FS_CONTEXT + FS_STRUCT.CURR_SECTOR_IDX), A

    CALL FAT_GetLBAfromCluster
    LD A, E
    LD (FS_CONTEXT + FS_STRUCT.CURR_SECTOR), A
    LD A, D
    LD (FS_CONTEXT + FS_STRUCT.CURR_SECTOR + 1), A
    LD A, C
    LD (FS_CONTEXT + FS_STRUCT.CURR_SECTOR + 2), A
    LD A, B
    LD (FS_CONTEXT + FS_STRUCT.CURR_SECTOR + 3), A

    CALL FAT_ReadSector

    LD A, 0x00
    LD (FS_CONTEXT + FS_STRUCT.CURR_ENTRY_IDX), A
    LD IX, FAT_BUFFER

    POP HL
    POP DE
    POP BC
    RET



; Follow the provided path and return the cluster of the end of the path
; * path in (DE)
; * start from cluster HL
; * Result in BC
; * IX positioned at last element of the path
; * Carry flag set if error
FS_followPath:
    PUSH DE
    PUSH HL
    LD IX, FS_VIRTUAL_ROOT_DIR
    LD A, (DE)
    CP '/' ; if path start with / then root
    JP NZ, .followLoop
    LD HL, 0x0000
    INC DE
    LD A, (DE)
    CP 0x00
    JP NZ, .followLoop
    ; special treatment for root dir
    LD BC, 0x0000
    POP HL
    POP DE
    RET
.followLoop:
    CALL FATtools_getPathElement
    JP C, .error
    CP 0x00
    JP Z, .endPath
    PUSH DE
    LD DE, BC
    CALL FS_SearchEntry
    POP DE
    JP C, .error
    LD A, (IX + FAT_DIR_ENTRY.ATTRIBUTE)
    AND 0x10
    CP 0x10
    JP NZ, .isItLast 
    LD HL, (IX + FAT_DIR_ENTRY.START_CLUSTER)
    JP .followLoop
.endPath:
    LD BC, HL
    POP HL
    POP DE
    RET
.isItLast:
    LD (DE), A
    CP 0x00
    JP NZ, .error
    POP HL
    POP DE
    RET
.error:
    SCF
    POP HL
    POP DE
    LD DE, BC
    RET



; Search in a directory the name provided and return the dir entry
; * NOT NEEDED / Entry : Drive Letter in A
; * Entry : folder cluster in HL
; * Entry : the dir/file name in (DE), nul terminated string
; * Result : return IX pointing to the dir entry
; * Carry set if name not found
FS_SearchEntry :
    PUSH BC
    PUSH DE
    LD A, (FS_CONTEXT + FS_STRUCT.DRIVE)
    CALL FS_OpenDir
    JP C, .error
    PUSH HL
    LD HL, FS_FILENAME_PREP
    CALL FATtools_FileNamePrep
    EX DE, HL
    POP HL
    JP C, .error
.entryLoop:
; routine processing the name verification in a record
    PUSH DE
    PUSH IX ; put IX in HL
    POP HL
    LD A, (IX)
    CP 0xE5
    JP Z, .nextEntry
    LD A, (IX + FAT_DIR_ENTRY.ATTRIBUTE)
    CP 0x0F
    JP Z, .nextEntry
    LD B, 11
.nameLoop:
    LD A, (DE)
    CP (HL)
    JP NZ, .nextEntry
    INC HL
    INC DE
    DJNZ .nameLoop
; name Match
    POP DE
    LD A, (IX + FAT_DIR_ENTRY.ATTRIBUTE)
    OR A
    POP DE
    POP BC
    RET
.nextEntry:
    POP DE
    CALL FS_GetNextEntry
    JP C, .error
    JP NZ, .entryLoop
    SCF
    LD A, 0xAA
    POP DE
    POP BC
    RET
.error:
    POP DE
    POP BC
    RET



; next directory entry in IX
; * Set Carry if error
; * Z flag if no more entry end of chain
FS_GetNextEntry:
    PUSH HL
    LD A, (FS_CONTEXT + FS_STRUCT.CURR_ENTRY_IDX)
    INC A
    CP 16
    JP Z, .nextSector
    LD (FS_CONTEXT + FS_STRUCT.CURR_ENTRY_IDX), A
    ; IX = Idx*32 + fat_buffer
    ADD A ; *2
    ADD A ; *4
    ADD A ; *8
    ADD A ; *16
    ADD A ; *32
    LD L, A
    LD A, 0x00
    ADC A, A
    LD H, A
    LD BC, FAT_BUFFER
    ADD HL, BC
    PUSH HL
    POP IX
    POP HL
    LD A, (IX) ; set Z flag if no more entry
    OR A
    RET
.nextSector:
    LD A, 0x00
    LD (FS_CONTEXT + FS_STRUCT.CURR_ENTRY_IDX), A
    LD IX, FAT_BUFFER
    CALL FS_ReadNextSector
    JP C, .exit
    CP 0xFF
    JP Z, .exit
    LD A, (FAT_BUFFER)
;    CALL SendChar_A
    OR A ; set the Z flag if no more entry
.exit:
    POP HL
    RET


;Load the next sector in a chain of cluster
; * new sector loaded in FAT_buffer
; * Return : set Carry if error
; * Return : A=0xFF  if end of chain reached
FS_ReadNextSector:
    PUSH BC
    PUSH DE
    PUSH HL
    LD A, (FS_CONTEXT + FS_STRUCT.CURR_SECTOR_IDX)
    DEC A
    JP Z, .nextCluster
    LD (FS_CONTEXT + FS_STRUCT.CURR_SECTOR_IDX),A
    ; next lba
    LD DE, (FS_CONTEXT + FS_STRUCT.CURR_SECTOR)
    LD BC, (FS_CONTEXT + FS_STRUCT.CURR_SECTOR + 2)
    LD HL, 0x0001
    ADD HL, DE
    LD (FS_CONTEXT + FS_STRUCT.CURR_SECTOR), HL
    LD HL, 0x0000
    ADC HL, BC
    LD (FS_CONTEXT + FS_STRUCT.CURR_SECTOR + 2), HL
    LD BC, HL
    LD DE, (FS_CONTEXT + FS_STRUCT.CURR_SECTOR)
    JP .getSectorData
.nextCluster:
    LD BC, (FS_CONTEXT + FS_STRUCT.CURR_CLUSTER)
    CALL FAT_GetNextCluster
    CP 0xFF
    JP Z, .endOfChain
    LD (FS_CONTEXT + FS_STRUCT.CURR_CLUSTER), DE
    EX DE, HL
    CALL FAT_GetLBAfromCluster
    LD (FS_CONTEXT + FS_STRUCT.CURR_SECTOR), DE
    LD (FS_CONTEXT + FS_STRUCT.CURR_SECTOR + 2), BC
    LD A, (FAT_MIRROR_DCB + FAT_DRIVE_CONTROL.SPC)
    LD (FS_CONTEXT + FS_STRUCT.CURR_SECTOR_IDX), A
.getSectorData:
    CALL FAT_ReadSector
    POP HL
    POP DE
    POP BC
    RET
.endOfChain: ; set Z flag for end of chain
    OR A 
    POP HL
    POP DE
    POP BC
    RET




FS_VIRTUAL_ROOT_DIR:
    DB "VIRTUALROOT"
    BYTE 0x10
    BYTE 0x00
    BYTE 0x00
    WORD 0x0000
    WORD 0x0000
    WORD 0x0000
    WORD 0x0000
    WORD 0x0000
    WORD 0x0000
    WORD 0x0000
    DWORD 0x00000000
    


    ENDIF