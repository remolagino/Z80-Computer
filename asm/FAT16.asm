; ------------------------------------------------------
; -                  FAT16.asm                         -
; -       Filesystem management for FAT 16             -
; ------------------------------------------------------

    
    IFNDEF __FAT16__
    DEFINE __FAT16__ 1

FAT_RAM_START EQU 0x8000
FAT_DCB_B EQU FAT_RAM_START
FAT_DCB_C EQU FAT_DCB_B + FAT_DRIVE_CONTROL
FAT_MIRROR_DCB EQU FAT_DCB_C + FAT_DRIVE_CONTROL

FAT_TMP_DWORD EQU FAT_MIRROR_DCB + FAT_DRIVE_CONTROL+1
FAT_BUFFER EQU FAT_RAM_START+0x100

    INCLUDE "FAT16.inc"
    INCLUDE "./lib/math.asm"
    INCLUDE "./lib/diskio.asm"

; Initialise the DCB at system start
; set the B: and C: as unmounted
; put 0x00 in volume name to avoid weird chars
FAT_BOOT_INIT_DCBs:
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

    LD A, ' ' ; reset drive letter in mirror to avoid false positive
    LD (FAT_MIRROR_DCB + FAT_DRIVE_CONTROL.DRIVE_LETTER), A
    
    RET

; Select the correct Drive Control Block based on the drive letter
; and copy it into the mirror DCB for easy access
; * Drive letter in A
; * DCB value copied in mirror variables FAT_MIRROR_DCB
; * Return : carry set if Drive Letter incorrect
FAT_SELECT_MIRROR_DCB:
    PUSH BC
    PUSH DE
    PUSH HL
    CP 'B'
    JP Z, .select_DCB_B
    CP 'C'
    JP Z, .select_DCB_C
    LD A, 0x94
    SCF
    JP .exit
.select_DCB_B:
    LD A, (FAT_MIRROR_DCB + FAT_DRIVE_CONTROL.DRIVE_LETTER)
    CP 'B'
    JP Z, .exit
    LD HL, FAT_DCB_B
    JP .mirrorLoop
.select_DCB_C:
    LD A, (FAT_MIRROR_DCB + FAT_DRIVE_CONTROL.DRIVE_LETTER)
    CP 'C'
    JP Z, .exit
    LD HL, FAT_DCB_C
.mirrorLoop:
    LD BC, FAT_DRIVE_CONTROL
    LD DE, FAT_MIRROR_DCB
    LDIR
    LD A, (FAT_MIRROR_DCB + FAT_DRIVE_CONTROL.DRIVE_LETTER)
    OR A ; reset the carry
.exit:
    POP HL
    POP DE
    POP BC
    RET


; FAT_MOUNT : Initialise the SD CARD. Compute the FAT values
; * Parameters : Drive letter (B or C) in A
; * Return : set the Carry flag if failure
FAT_MOUNT:
    PUSH BC
    PUSH DE
    PUSH HL

    CP 'B'
    JP Z, .select_DCB_B
    CP 'C'
    JP Z, .select_DCB_C
    LD A, 0x94
    JP .selectError
.select_DCB_B:
    LD IY, FAT_DCB_B
    OR A
    JP .startMount
.select_DCB_C:
    LD IY, FAT_DCB_C
    OR A
.startMount:
    LD A, (IY + FAT_DRIVE_CONTROL.SDCARD_CS)
    CALL DISK_INIT
;    LD A, 0x90 ; error code Disk not ready
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
    LD A, 0x92
    JP C, .error
    ; get Sectors per Cluster
    LD A, (FAT_BUFFER + FAT_BOOT_RECORD.SECTORS_PER_CLUSTER)
    LD (IY + FAT_DRIVE_CONTROL.SPC), A
    CALL FAT_GetSPCShift
    LD (IY + FAT_DRIVE_CONTROL.SPC_SHIFT), A
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
    ; get max number of clusters
    LD BC, (FAT_BUFFER + FAT_BOOT_RECORD.TOTAL_SECTORS)
    LD A, B
    OR C
    JP Z, .maxNumber32
    LD A, (FAT_BUFFER + FAT_BOOT_RECORD.TOTAL_SECTORS)
    LD (FAT_TMP_DWORD), A
    LD A, (FAT_BUFFER + FAT_BOOT_RECORD.TOTAL_SECTORS+1)
    LD (FAT_TMP_DWORD + 1), A
    LD A, 0x00
    LD (FAT_TMP_DWORD + 2), A
    LD (FAT_TMP_DWORD + 3), A
    JP .continueMaxClusters
.maxNumber32:
    LD A, (FAT_BUFFER + FAT_BOOT_RECORD.TOTAL_SECTORS_32)
    LD (FAT_TMP_DWORD), A
    LD A, (FAT_BUFFER + FAT_BOOT_RECORD.TOTAL_SECTORS_32 + 1)
    LD (FAT_TMP_DWORD + 1), A
    LD A, (FAT_BUFFER + FAT_BOOT_RECORD.TOTAL_SECTORS_32 + 2)
    LD (FAT_TMP_DWORD + 2), A
    LD A, (FAT_BUFFER + FAT_BOOT_RECORD.TOTAL_SECTORS_32 + 3)
    LD (FAT_TMP_DWORD + 3), A
.continueMaxClusters:
    LD BC, FAT_TMP_DWORD
    LD DE, FAT_TMP_DWORD
    LD HL, (FAT_BUFFER + FAT_BOOT_RECORD.RESERVED_SECTORS)
    CALL MATH_SUB_WORD_TO_DWORD
    LD HL, (FAT_BUFFER + FAT_BOOT_RECORD.FAT_SIZE)
    CALL MATH_SUB_WORD_TO_DWORD ; a bit rigid, FAT number is not dynamic...
    CALL MATH_SUB_WORD_TO_DWORD
    LD L, (IY + FAT_DRIVE_CONTROL.ROOT_DIR_SIZE)
    LD H, (IY + FAT_DRIVE_CONTROL.ROOT_DIR_SIZE + 1)
    CALL MATH_SUB_WORD_TO_DWORD
    LD A, (IY + FAT_DRIVE_CONTROL.SPC_SHIFT)
    CALL MATH_SHIFT_RIGHT_DWORD_BY_N
    LD A, (FAT_TMP_DWORD)
    LD (IY + FAT_DRIVE_CONTROL.MAX_CLUSTER_NB), A
    LD A, (FAT_TMP_DWORD + 1)
    LD (IY + FAT_DRIVE_CONTROL.MAX_CLUSTER_NB + 1), A
    LD A, (FAT_TMP_DWORD + 2)
    LD (IY + FAT_DRIVE_CONTROL.MAX_CLUSTER_NB + 2), A
    LD A, (FAT_TMP_DWORD + 3)
    LD (IY + FAT_DRIVE_CONTROL.MAX_CLUSTER_NB + 3), A
    ; get Volmue Name
    LD E, (IY + FAT_DRIVE_CONTROL.LBA_ROOT)
    LD D, (IY + FAT_DRIVE_CONTROL.LBA_ROOT + 1)
    LD C, (IY + FAT_DRIVE_CONTROL.LBA_ROOT + 2)
    LD B, (IY + FAT_DRIVE_CONTROL.LBA_ROOT + 3)
    LD HL, FAT_BUFFER
    LD A, (IY + FAT_DRIVE_CONTROL.SDCARD_CS)

    CALL DISK_READ
    LD A, 0x93
    JP C, .error
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
    LD A, 0x01
    LD (IY + FAT_DRIVE_CONTROL.MOUNTED), A

    LD A, 0x00
    OR A ; reset carry flag
    POP HL
    POP DE
    POP BC
    RET
.error:
    PUSH AF
    LD A, 0x00
    LD (IY + FAT_DRIVE_CONTROL.MOUNTED), A
    POP AF
.selectError:
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
    LD A, (FAT_MIRROR_DCB + FAT_DRIVE_CONTROL.SPC)
    CALL MATH_MULT_WORD_BYTE
    LD HL, FAT_MIRROR_DCB + FAT_DRIVE_CONTROL.LBA_DATA_START
    LD DE, FAT_TMP_DWORD
    CALL MATH_ADD_DWORD_TO_DWORD
    LD DE, (FAT_TMP_DWORD)
    LD BC, (FAT_TMP_DWORD + 2)
    POP HL
    POP AF
    RET
.isRoot:
    LD DE, (FAT_MIRROR_DCB + FAT_DRIVE_CONTROL.LBA_ROOT)
    LD BC, (FAT_MIRROR_DCB + FAT_DRIVE_CONTROL.LBA_ROOT + 2)
    POP HL
    POP AF
    RET

; read the FAT table and return the number of the next cluster
; / If no more cluster : 0xFFFF / 
; Cluster Free : 0x0000
;  * Cluster to search for in BC
; * Result in DE
; * Z flag if success, A==FF if end chain reached
; * Carry flag set if bigger than max cluster
FAT_GetNextCluster : 
    PUSH BC
    PUSH HL
; TODO : control BC is not bigger than max cluster
    LD A,B
    CP 0x00
    JP NZ, .getTheFAT
    LD A, C
    CP 0x02
    JP M, .endOfChain
.getTheFAT:
    PUSH BC
    LD L, B
    LD H, 0x00
    LD BC, FAT_MIRROR_DCB + FAT_DRIVE_CONTROL.LBA_FAT1
    LD DE, FAT_TMP_DWORD
    CALL MATH_ADD_WORD_TO_DWORD

    LD A, (FAT_MIRROR_DCB + FAT_DRIVE_CONTROL.SDCARD_CS)
    LD BC, (FAT_TMP_DWORD +2)
    LD DE, (FAT_TMP_DWORD)
    LD HL, FAT_BUFFER
 ;   CALL SDCARD_READ_BLOCK
    CALL DISK_READ
    POP BC

    LD A, C ; index of the cluster in FAT sector
    ADD A ; Time 2 as cluster is word
    LD E, A
    LD A, 0x00 
    ADC A ; add the carry in D
    LD D, A
    ADD HL, DE
    LD E, (HL)
    INC HL
    LD D, (HL)
; verify if the result is 0xFFFF
    LD A, D
    AND E
    CP 0xFF
    JP Z, .endOfChain
    LD A, 0x00
    OR A
    POP HL
    POP BC
    RET
.endOfChain:
    LD A, 0xFF
    OR A
    POP HL
    POP BC
    RET
.error:
    SCF
    POP HL
    POP BC
    RET


; Read sector BCDE and put the result in FAT_Buffer
; * the disk is the one in the mirror DCB
; * Result : Success : A= Drive Letter, carry flag reset
; * Error : A = Error Code, Carry set
FAT_ReadSector :
    LD A, (FAT_MIRROR_DCB + FAT_DRIVE_CONTROL.SDCARD_CS)
    LD HL, FAT_BUFFER
    CALL DISK_READ
    RET


; Get a SPC value (power of 2) in A, return the bit number for shift in A
FAT_GetSPCShift:
    PUSH BC
    LD B, 8
.shiftLoop:
    RLA
    JP C, .shiftFound
    DJNZ .shiftLoop
.noFound:
    SCF
    LD A, 0x00
    POP BC
    RET
.shiftFound:
    DEC B   
    LD A, B
    OR A
    POP BC
    RET



    ENDIF