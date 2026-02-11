; ------------------------------------------------------
; -                 diskio.asm                         -
; -  Abstract layer between FS and device              -
; ------------------------------------------------------

    
    IFNDEF __DISK_IO__
    DEFINE __DISK_IO__ 1


    INCLUDE "sdcard.asm"



; =============================================================================
; DISK_READ
;  * Params : A = Drive letter (B or C), BCDE = LBA, HL = Buffer
;  * Result : A = Error Code, Carry set if error
; =============================================================================
DISK_READ:
    PUSH AF
    CALL DISK_Select_Hardware
    POP AF

    CP 'B'
    JR Z, .continue
    CP 'C'
    JR Z, .continue
    ; neither B nor C : error
    SCF
    RET
.continue:
    ; Pour 1 (B:) et 2 (C:), on utilise le driver SD
    ; car DISK_Select_Hardware a déjà géré le Chip Select
    CALL SDCARD_READ_BLOCK
    RET


; =============================================================================
; DISK_WRITE
;  * Params : A = Drive letter (B or C), BCDE = LBA, HL = Buffer
;  * Result : A = Error Code, Carry set if error
; =============================================================================
DISK_WRITE:
    PUSH AF
    CALL DISK_Select_Hardware
    POP AF

    CP 'B'
    JR Z, .continue
    CP 'C'
    JR Z, .continue
    ; neither B nor C : error
    SCF
    RET
.continue:
    ; Pour 1 (B:) et 2 (C:), on utilise le driver SD
    ; car DISK_Select_Hardware a déjà géré le Chip Select
    CALL SDCARD_WRITE_BLOCK
    RET


; =============================================================================
; DISK_Select_Hardware
; * Gère l'activation des lignes CS du PIO en fonction du drive dans A
; =============================================================================
DISK_Select_Hardware:
    CP 'C'
    JR Z, .select_sd1    ; Drive C:
    CP 'B'
    JR Z, .select_sd2    ; Drive B:
    RET                  ; Drive A: (pas de CS SPI)

.select_sd1:
    ; Ici : Code pour mettre CS1 à 0 et CS2 à 1 sur ton PIO
    ; Ex: LD A, MASK_CS1_ACTIVE \ OUT (PIO_DATA), A
    RET

.select_sd2:
    ; Ici : Code pour mettre CS1 à 1 et CS2 à 0 sur ton PIO
    RET


    ENDIF