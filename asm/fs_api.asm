; ------------------------------------------------------
; -                  fs_api.asm                        -
; -  abstraction between filesystem and shell cmd      -
; ------------------------------------------------------

    
    IFNDEF __FS_API__
    DEFINE __FS_API__ 1

    INCLUDE "./FAT16.asm"

CUR_DIR_CLUSTER:
    WORD 0x0000
PATH_STRING:
    BLOCK 0x100, 0x00



; Prépare la lecture d'un répertoire (initialise les pointeurs)
FS_OpenDir:

    RET

;Renvoie l'entrée suivante d'un répertoire, en gérant de manière 
; transparente le passage d'un secteur à l'autre et d'un cluster à l'autre. 
; C'est elle qui appelle FAT_GetNextCluster.
FS_ReadNextEntry:

    RET

; Prend un chemin relatif (ex: ../TOTO) et met à jour le PATH_STRING.
FS_CanonicalizePath:
    
    RET

    ENDIF