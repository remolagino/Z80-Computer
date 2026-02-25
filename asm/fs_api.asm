; ------------------------------------------------------
; -                  fs_api.asm                        -
; -  abstraction between filesystem and shell cmd      -
; ------------------------------------------------------

    
    IFNDEF __FS_API__
    DEFINE __FS_API__ 1

    INCLUDE "./FAT16.asm"



    STRUCT FS_STRUCT
CURR_DRIVE BYTE
DIR_CLUSTER WORD
CURR_CLUSTER WORD
CURR_SECTOR DWORD
CURR_SECTOR_IDX BYTE
CURR_ENTRY_IDX BYTE
    ENDS

FS_CONTEXT EQU 0x8500

FS_WORKSPACE EQU 0x8600;:
;    BLOCK 0x100, 0x00

; Prépare la lecture d'un répertoire (initialise les pointeurs)
; * Drive Letter in A
; * HL as the root of the dir
; * Return : IX is position at the begining of the FAT buffer for process
FS_OpenDir:
    CALL FAT_SELECT_MIRROR_DCB
    RET C

    PUSH BC
    PUSH DE
    PUSH HL
    LD (FS_CONTEXT + FS_STRUCT.CURR_DRIVE), A
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
; * Return : A=FF  if end of chain reached
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


; Search in a directory the name provided and return the dir entry
; * NOT NEEDED / Entry : Drive Letter in A
; * Entry : folder cluster in HL
; * Entry : the dir/file name in (DE), nul terminated string
; * Result : return IX pointing to the dir entry
; * Carry set if name not found
FS_SearchEntry :
    PUSH BC
    PUSH DE
    LD A, (FS_CONTEXT + FS_STRUCT.CURR_DRIVE)
    CALL FS_OpenDir
    JP C, .error
    PUSH HL
    LD HL, FS_WORKSPACE
    CALL FS_FileNamePrep
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


; Validate the filename in (DE) and prepare a normalised string
; in (HL)
; * Return : Carry flag if name not conform
FS_FileNamePrep:
    PUSH BC
    PUSH DE
    PUSH HL

    LD A, (DE)
    CP 0x00
    JP Z, .error
    CP '.'
    JP NZ, .nameLoopProcess
    INC DE
    LD A, (DE)
    CP 0x00
    JP Z, .sameDir
    CP '.'
    JP NZ, .error
    INC DE
    LD A, (DE)
    CP 0x00
    JP Z, .parentDir
    JP .error
.nameLoopProcess:
    LD B, 8
.nameLoop:
    LD A,(DE)
    CP 0x00
    JP Z, .nameLoopAddSpace
    CP '.'
    JP Z, .nameLoopAddSpace
    CALL FS_CheckChar
    JP C, .error
    INC DE
    JP .nameLoopNoDot
.nameLoopAddSpace:
    LD A, ' '
.nameLoopNoDot:
    LD (HL), A
    INC HL
    DJNZ .nameLoop
    LD A, (DE)
    CP 0x00
    JP Z, .extProcess
    CP '.'
    JP NZ, .error
    INC DE
    LD A, (DE)
    CP 0x00 ; no extension after dot : error
    JP Z, .error
.extProcess:
    LD B, 3
.extLoop:
     LD A,(DE)
    CP 0x00
    JP Z, .extLoopAddSpace
    CP '.'
    JP Z, .extLoopAddSpace
    CALL FS_CheckChar
    JP C, .error
    INC DE
    JP .extLoopNoDot
.extLoopAddSpace:
    LD A, ' '
.extLoopNoDot:
    LD (HL), A
    INC HL
    DJNZ .extLoop
    LD A, (DE)
    CP 0x00
    JP NZ, .error
    LD A, 0x00
    LD (HL), A
    POP HL
    POP DE
    POP BC
    RET
.sameDir:
    LD DE, FS_SAME_DIR
    LD B, 12
.sameDirLoop:
    LD A, (DE)
    LD (HL), A
    INC DE
    INC HL
    DJNZ .sameDirLoop
    OR A ; reset carry
    POP HL
    POP DE
    POP BC
    RET
.parentDir:
    LD DE, FS_PARENT_DIR
    LD B, 12
.parentDirLoop:
    LD A, (DE)
    LD (HL), A
    INC DE
    INC HL
    DJNZ .parentDirLoop
    OR A ; reset carry
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

; check if char in A is acceptable
; * transform lower case to upper case
; * if not good, SCF
FS_CheckChar:
    PUSH BC
    PUSH HL
    CP 0x21
    JP C, .error
    CP 0x7F
    JP NC, .error
    LD B, 15
    LD HL, FS_FORBIDDEN_CHARS
.forbidCharLoop:
    CP (HL) 
    JP Z, .error
    INC HL
    DJNZ .forbidCharLoop
    CP 'a'
    JP C, .notLower
    CP '{'
    JP NC, .notLower
    AND 0xDF
.notLower:
    OR A
    POP HL
    POP BC
    RET
.error:
    POP HL
    POP BC
    SCF
;    LD A, 0xFF
    RET


; Take a relative path in (DE) and update the PATH_STRING in (HL).
FS_CanonicalizePath:
    PUSH BC
    PUSH DE
    PUSH HL
    LD A, (DE)
    CP 0x00
    JP Z, .exit
    CP '/'
    JP NZ, .gotoEndOfCurrPathLoop
    LD (HL), A ; make sure (hl) starts with '/',0x00
    INC HL
    LD A, 0x00
    LD (HL), A
.gotoEndOfCurrPathLoop:
    LD A, (HL)
    CP 0x00
    JP Z, .copyRelativePath
    INC HL
    JP .gotoEndOfCurrPathLoop
.copyRelativePath:
    DEC HL
    LD A, (HL)
    CP '/'
    JP Z, .removeDESlash
    INC HL
.removeDESlash:
    LD A, (DE)
    CP '/'
    JP NZ, .addHLSlash
    INC DE
.addHLSlash:
    LD A, '/'
    LD (HL), A
    INC HL
.copyRelativePathLoop:
    LD A, (DE)
    LD (HL), A
    CP 0x00
    JP Z, .normalizePath
    INC HL
    INC DE
    JP .copyRelativePathLoop
.normalizePath:
    LD B, 0
.normalizePathLoop:
    DEC HL
    LD A, (HL)
    CP 0x00 ; start of path string reached
    JP Z, .compactPath ; change with better method
    CP '.'
    JP Z, .firstDot
    JP .normalizePathLoop
.firstDot:
    DEC HL
    LD A, (HL)
    CP '.'
    JP Z, .twoDots
    CP '/'
    JP NZ, .normalizePathLoop
    INC HL ; replace the dot with a +
    LD A, '+'
    LD (HL), A
    DEC HL ; replace the dash with a +
    LD (HL), A
    DEC HL
    LD A, (HL)
    CP '.'
    JP Z, .firstDot
    LD A, B
    CP 0x00
    JP NZ,.twoDotsTokenRemoval
    JP .normalizePathLoop    
.twoDots:
    INC B
    INC HL ; replace the dot with a +
    LD A, '+'
    LD (HL), A
    DEC HL ; replace the dot with a +
    LD (HL), A
    DEC HL ; replace the dash with a +
    LD (HL), A
    DEC HL
    LD A, (HL)
    CP '.'
    JP NZ, .twoDotsTokenRemoval
    JP .firstDot
.twoDotsTokenRemoval:
.twoDotsOuterLoop:
.twoDotsLoop:
    LD A, (HL)
    CP 0x00
    JP Z, .compactPath
    CP '/'
    JP Z, .twoDotsLoopEnd
    LD A, '+'
    LD (HL), A
    DEC HL
    JP .twoDotsLoop
.twoDotsLoopEnd:
    LD A, '+'
    LD (HL), A
    DEC HL
    DJNZ .twoDotsOuterLoop
    LD A, (HL)
    CP 0x00
    JP Z, .compactPath
    JP .normalizePath
.compactPath:
    INC HL
    LD A, '/'
    LD (HL), A
    INC HL
    LD DE, HL
.compactLoop:
    LD A, (HL)
    CP 0x00
    JP Z, .endCompact
    CP '+'
    JP Z, .remove
    ; CP '/'
    ; JP Z, .removeExtraSlash
    LD (DE), A
    INC DE
.removeExtraSlash:
; TODO : ADD SUPPRESSION OF CONSECUTIVE SLASH
.remove:
    INC HL
    JP .compactLoop
.endCompact:
    LD (DE), A
.exit:
    POP HL
    POP DE
    POP BC
    RET



; Follow the provided path and return the cluster of the end of the path
; * path in (DE)
; * start from HL
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
    CALL FS_getPathElement
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

; Parse the path in (DE), send the token in (BC)
; * NZ means a token has been processed
; * Z means no more token
FS_getPathElement:
    LD BC, DE
    LD A, (DE)
    CP 0x00
    RET Z
.parseLoop:
    LD A, (DE)
    CP 0x00
    JP Z, .endPath
    CP '/'
    JP Z, .endToken
    INC DE
    JP .parseLoop
.endToken:
    LD A, 0x00
    LD (DE), A
    INC DE
.endPath:
    LD A, 0x01
    OR A
    RET
.error:
    SCF
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
    
FS_SAME_DIR:
    DB ".          ", 0x00
FS_PARENT_DIR:
    DB "..         ", 0x00
FS_FORBIDDEN_CHARS:
    DB 0x22, 0x2A, 0x2B, 0x2C, 0x2F, 0x3A, 0x3B, 0x3C, 0x3D
    DB 0x3E, 0x3F, 0x5B, 0x5C, 0x5D, 0x7C, 0x2E




    ENDIF