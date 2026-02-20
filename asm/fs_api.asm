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
PATH_STRING BLOCK 0x100
    ENDS

FS_VAR FS_STRUCT

; Prépare la lecture d'un répertoire (initialise les pointeurs)
; * Drive Letter in A
; * HL as the root of the dir
FS_OpenDir:
    CALL FAT_SELECT_MIRROR_DCB
    RET C
    LD (FS_VAR + FS_STRUCT.CURR_DRIVE), A
    LD A, (FAT_MIRROR_DCB + FAT_DRIVE_CONTROL.SPC)
    LD (FS_VAR + FS_STRUCT.CURR_SECTOR_IDX), A
    LD (FS_VAR + FS_STRUCT.DIR_CLUSTER), HL
    LD (FS_VAR + FS_STRUCT.CURR_CLUSTER), HL

    CALL FAT_GetLBAfromCluster
    LD A, E
    LD (FS_VAR + FS_STRUCT.CURR_SECTOR), A
    LD A, D
    LD (FS_VAR + FS_STRUCT.CURR_SECTOR + 1), A
    LD A, C
    LD (FS_VAR + FS_STRUCT.CURR_SECTOR + 2), A
    LD A, B
    LD (FS_VAR + FS_STRUCT.CURR_SECTOR + 3), A

    RET


;Renvoie l'entrée suivante d'un répertoire, en gérant de manière 
; transparente le passage d'un secteur à l'autre et d'un cluster à l'autre. 
; C'est elle qui appelle FAT_GetNextCluster.
FS_ReadNextEntry:
    LD A, (FS_VAR + FS_STRUCT.CURR_SECTOR_IDX)
    OR A
    JP Z, .nextCluster

.nextCluster:
    LD BC, (FS_VAR + FS_STRUCT.CURR_CLUSTER)
    CALL FAT_GetNextCluster
    JP NZ, .endOfChain
    LD (FS_VAR + FS_STRUCT.CURR_CLUSTER), DE
    EX DE, HL
    CALL FAT_GetLBAfromCluster
    LD (FS_VAR + FS_STRUCT.CURR_SECTOR), DE
    LD (FS_VAR + FS_STRUCT.CURR_SECTOR + 2), BC
    LD A, (FAT_MIRROR_DCB + FAT_DRIVE_CONTROL.SPC)
    LD (FS_VAR + FS_STRUCT.CURR_SECTOR_IDX), A
    RET
.endOfChain: ; set NZ end of chain
    LD A, 0x01
    OR A 
    RET

; Prend un chemin relatif (ex: ../TOTO) et met à jour le PATH_STRING.
FS_CanonicalizePath:
    
    RET

    ENDIF