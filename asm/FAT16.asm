; ------------------------------------------------------
; -                  FAT16.asm                         -
; -       Filesystem management for FAT 16             -
; ------------------------------------------------------

    
    IFNDEF __FAT16__
    DEFINE __FAT16__ 1

FAT_RAM_START EQU 0x8000
FAT_DCB_B EQU FAT_RAM_START
FAT_DCB_C EQU FAT_DCB_B + FAT_DRIVE_CONTROL
FAT_TMP_DWORD EQU FAT_DCB_C + FAT_DRIVE_CONTROL
FAT_BUFFER EQU FAT_RAM_START+0x100

    INCLUDE "FAT16.inc"
    INCLUDE "./lib/math.asm"
    INCLUDE "./lib/diskio.asm"

; Initialise the DCB at system start
; set the B: and C: as unmounted
; put 0x00 in volume name to avoid weird chars
FAT_INIT_DCBs:
    LD A, 0x00
    LD (FAT_DCB_B + FAT_DRIVE_CONTROL.MOUNTED), A
    LD (FAT_DCB_C + FAT_DRIVE_CONTROL.MOUNTED), A
    LD (FAT_DCB_B + FAT_DRIVE_CONTROL.VOL_LABEL), A
    LD (FAT_DCB_C + FAT_DRIVE_CONTROL.VOL_LABEL), A
    LD A, 'B'
    LD (FAT_DCB_B + FAT_DRIVE_CONTROL.DRIVE_LETTER), A
    LD A, SPI_CS2_BIT
    LD (FAT_DCB_B + FAT_DRIVE_CONTROL.SDCARD_CS), A
    LD A, 'C'
    LD (FAT_DCB_C + FAT_DRIVE_CONTROL.DRIVE_LETTER), A
    LD A, SPI_CS1_BIT
    LD (FAT_DCB_C + FAT_DRIVE_CONTROL.SDCARD_CS), A

    RET

; Select the correct Drive Control Block based on the drive letter
; * Drive letter in A
; * return DCB in IY
FAT_SELECT_DCB:
    CP 'B'
    JP Z, .select_DCB_B
    CP 'C'
    JP Z, .select_DCB_C
    LD A, 0x94
    SCF
    RET
.select_DCB_B:
    LD IY, FAT_DCB_B
    OR A
    RET
.select_DCB_C:
    LD IY, FAT_DCB_C
    OR A
    RET


; FAT_MOUNT : Initialise the SD CARD. Compute the FAT values
; * Parameters : Drive letter (B or C) in A
; * Return : set the Carry flag if failure
FAT_MOUNT:
    PUSH BC
    PUSH DE
    PUSH HL

    CALL FAT_SELECT_DCB
    JP C, .error
    LD A, (IY + FAT_DRIVE_CONTROL.SDCARD_CS)
    CALL DISK_INIT
    LD A, 0x90 ; error code Disk not ready
    JP C, .error
    LD BC, 0x0000
    LD DE, 0x0000
    LD HL, FAT_BUFFER
    LD A, (IY + FAT_DRIVE_CONTROL.SDCARD_CS)
    CALL DISK_READ
    LD A, 0x91
    JP C, .error
    ; check filesystem type
    LD A, (FAT_BUFFER + FAT_MBR.PARTITION1.TYPE)
    CP 0x06 ; check if partition type is FAT16
    LD A, 0x92 ; error code for wrong file system
    JP NZ, .error
    ; get LBA Start
    LD DE, (FAT_BUFFER + FAT_MBR.PARTITION1.BEGINING_LBA)
    LD BC, (FAT_BUFFER + FAT_MBR.PARTITION1.BEGINING_LBA + 2)
    LD (IY + FAT_DRIVE_CONTROL.LBA_START), E
    LD (IY + FAT_DRIVE_CONTROL.LBA_START + 1), D
    LD (IY + FAT_DRIVE_CONTROL.LBA_START + 2), C
    LD (IY + FAT_DRIVE_CONTROL.LBA_START + 3), B
    ; get Boot Record from LBA
    LD HL, FAT_BUFFER
    LD A, (IY + FAT_DRIVE_CONTROL.SDCARD_CS)
    CALL DISK_READ
    ; get Sectors per Cluster
    LD A, (FAT_BUFFER + FAT_BOOT_RECORD.SECTORS_PER_CLUSTER)
    LD (IY + FAT_DRIVE_CONTROL.SPC), A
    ; get FAT1 Sector Address
    LD (FAT_TMP_DWORD), DE ; BCDE at LBA_START since last step
    LD (FAT_TMP_DWORD + 2), BC
    LD BC, FAT_TMP_DWORD
    LD HL, (FAT_BUFFER + FAT_BOOT_RECORD.RESERVED_SECTORS)
    LD DE, FAT_TMP_DWORD
    CALL MATH_ADD_WORD_TO_DWORD
    LD A, (FAT_TMP_DWORD)
    LD (IY + FAT_DRIVE_CONTROL.LBA_FAT1), A
    LD A, (FAT_TMP_DWORD + 1)
    LD (IY + FAT_DRIVE_CONTROL.LBA_FAT1 + 1), A
    LD A, (FAT_TMP_DWORD + 2)
    LD (IY + FAT_DRIVE_CONTROL.LBA_FAT1 + 2), A
    LD A, (FAT_TMP_DWORD + 3)
    LD (IY + FAT_DRIVE_CONTROL.LBA_FAT1 + 3), A
    ; get FAT2 Sector Address
    LD BC, FAT_TMP_DWORD
    LD HL, (FAT_BUFFER + FAT_BOOT_RECORD.FAT_SIZE)
    LD DE, FAT_TMP_DWORD
    CALL MATH_ADD_WORD_TO_DWORD
    LD A, (FAT_TMP_DWORD)
    LD (IY + FAT_DRIVE_CONTROL.LBA_FAT2), A
    LD A, (FAT_TMP_DWORD + 1)
    LD (IY + FAT_DRIVE_CONTROL.LBA_FAT2 + 1), A
    LD A, (FAT_TMP_DWORD + 2)
    LD (IY + FAT_DRIVE_CONTROL.LBA_FAT2 + 2), A
    LD A, (FAT_TMP_DWORD + 3)
    LD (IY + FAT_DRIVE_CONTROL.LBA_FAT2 + 3), A
    ; get ROOT Sector Address
    LD BC, FAT_TMP_DWORD
    LD HL, (FAT_BUFFER + FAT_BOOT_RECORD.FAT_SIZE)
    LD DE, FAT_TMP_DWORD
    CALL MATH_ADD_WORD_TO_DWORD
    LD A, (FAT_TMP_DWORD)
    LD (IY + FAT_DRIVE_CONTROL.LBA_ROOT), A
    LD A, (FAT_TMP_DWORD + 1)
    LD (IY + FAT_DRIVE_CONTROL.LBA_ROOT + 1), A
    LD A, (FAT_TMP_DWORD + 2)
    LD (IY + FAT_DRIVE_CONTROL.LBA_ROOT + 2), A
    LD A, (FAT_TMP_DWORD + 3)
    LD (IY + FAT_DRIVE_CONTROL.LBA_ROOT + 3), A
    ; get Root Dir Size 
    LD HL, (FAT_BUFFER + FAT_BOOT_RECORD.MAX_ROOT_DIR_ENTRIES)
    SRL H
    RR L  ; /2
    SRL H
    RR L  ; /4
    SRL H
    RR L  ; /8
    SRL H
    RR L  ; /16
    LD (IY + FAT_DRIVE_CONTROL.ROOT_DIR_SIZE), L
    LD (IY + FAT_DRIVE_CONTROL.ROOT_DIR_SIZE + 1), H
    ; get DATA Start Sector address
    LD BC, FAT_TMP_DWORD
    ; LD HL, (FAT_ROOT_DIR_SIZE) root dir size already in hl
    LD DE, FAT_TMP_DWORD
    CALL MATH_ADD_WORD_TO_DWORD
    LD A, (FAT_TMP_DWORD)
    LD (IY + FAT_DRIVE_CONTROL.LBA_DATA_START), A
    LD A, (FAT_TMP_DWORD + 1)
    LD (IY + FAT_DRIVE_CONTROL.LBA_DATA_START + 1), A
    LD A, (FAT_TMP_DWORD + 2)
    LD (IY + FAT_DRIVE_CONTROL.LBA_DATA_START + 2), A
    LD A, (FAT_TMP_DWORD + 3)
    LD (IY + FAT_DRIVE_CONTROL.LBA_DATA_START + 3), A

    ; get Volmue Name
    LD E, (IY + FAT_DRIVE_CONTROL.LBA_ROOT)
    LD D, (IY + FAT_DRIVE_CONTROL.LBA_ROOT)
    LD C, (IY + FAT_DRIVE_CONTROL.LBA_ROOT)
    LD B, (IY + FAT_DRIVE_CONTROL.LBA_ROOT)
    LD HL, FAT_BUFFER
    LD A, (IY + FAT_DRIVE_CONTROL.SDCARD_CS)
    CALL DISK_READ
    LD A, (FAT_BUFFER + FAT_DIR_ENTRY.ATTRIBUTE)
    CP 0x08 ; record is Volume Label
    JP NZ, .continue
    LD HL, FAT_BUFFER + FAT_DIR_ENTRY.FILENAME
    ;LD DE, FAT_VOL_LABEL
    PUSH IY
    LD B, 11
.nameLoop:
    LD A, (HL)
    LD (IY + FAT_DRIVE_CONTROL.VOL_LABEL), A
    INC HL
    INC IY
    DJNZ .nameLoop
    LD A, 0x00
    LD (IY + FAT_DRIVE_CONTROL.VOL_LABEL), A
    POP IY    
.continue:
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

; Lit la table FAT et renvoie le numéro du cluster suivant (ou 0xFFFF).
FAT_GetNextCluster : 

    RET

; Remplit un buffer avec un secteur de répertoire.
FAT_ReadDirSector :

    RET

; Prend un nom de fichier en entrée, parcourt un cluster, et renvoie le DIRECTORY_ENTRY complet ou son cluster de départ.
FAT_SearchEntry :

    RET

; FAT_DRIVE_LETTER:
;     DB 0x00
; FAT_MOUNTED:
;     DB 0x00
; FAT_VOL_LABEL:
;     DB "@@@@@@@@@@@", 0x00
; FAT_LBA_START:
;     DWORD 0x00000000
; FAT_LBA_FAT1: ; = LBA_Start + Reserved_Sectors
;     DWORD 0x00000000
; FAT_LBA_FAT2: ; = LBA_FAT1 + Sectors_Per_FAT
;     DWORD 0x00000000
; FAT_LBA_ROOT: ; = LBA_FAT2 + Sectors_Per_FAT
;     DWORD 0x00000000
; FAT_LBA_DATA_START: ; = LBA_Root + Taille_du_Root_Dir
;     DWORD 0x00000000
; FAT_ROOT_DIR_SIZE: ; = (max root entries * 32)/512
;     WORD 0x0000
; FAT_SPC: ; Sectors per Cluster
;     DB 0x00
; FAT_TMP_DWORD:
;     DWORD 0x00000000



    ENDIF