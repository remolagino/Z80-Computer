; ------------------------------------------------------
; -                 diskio.asm                         -
; -  Abstract layer between FS and device              -
; ------------------------------------------------------

    
    IFNDEF __DISK_IO__
    DEFINE __DISK_IO__ 1


    INCLUDE "sdcard.asm"



; =============================================================================
; DISK_INIT
;  * Params : A = Drive letter (B or C)
;  * Result : Success : A= Drive Letter, carry flag reset
;           * Error : A = Error Code, Carry set
; =============================================================================
DISK_INIT:
    CALL SDCARD_INIT
    RET
;     PUSH BC
;     PUSH AF
;     CALL DISK_Select_Hardware
;     JP C, .error
;     CALL SDCARD_INIT
;     JP C, .error
;     POP AF
;     OR A
;     POP BC
;     RET
; .error:
;     LD B, A
;     POP AF
;     LD A, B
;     SCF
;     POP BC
;     RET

; =============================================================================
; DISK_READ
;  * Params : A = Drive letter (B or C), BCDE = LBA, HL = Buffer
;  * Result : Success : A= Drive Letter, carry flag reset
;  * Error : A = Error Code, Carry set
; =============================================================================
DISK_READ:
    CALL SDCARD_READ_BLOCK
    RET
;     PUSH BC
;     PUSH AF
;     CALL DISK_Select_Hardware
;     JP C, .error
;     CALL SDCARD_READ_BLOCK
;     JP C, .error
;     POP AF
;     OR A
;     POP BC
;     RET
; .error:
;     LD B, A
;     POP AF
;     LD A, B
;     SCF
;     POP BC
;     RET


; =============================================================================
; DISK_WRITE
;  * Params : A = Drive letter (B or C), BCDE = LBA, HL = Buffer
;  * Result : Success : A= Drive Letter, carry flag reset
;  * Error : A = Error Code, Carry set
; =============================================================================
DISK_WRITE:
    CALL SDCARD_WRITE_BLOCK
    RET
;     PUSH BC
;     PUSH AF
;     CALL DISK_Select_Hardware
;     JP C, .error
;     CALL SDCARD_WRITE_BLOCK
;     JP C, .error
;     POP AF
;     OR A
;     POP BC
;     RET
; .error:
;     LD B, A
;     POP AF
;     LD A, B
;     SCF
;     POP BC
;     RET

; =============================================================================
; DISK_STATUS
;  * Params : A = Drive letter (B or C)
;  * Result : Success : A= Drive Letter, carry flag reset
;  * Error : A = Error Code, Carry set
; =============================================================================
DISK_STATUS:
    PUSH BC
    PUSH AF
    CALL DISK_Select_Hardware
    JP C, .error
    CALL SDCARD_GET_STATUS
    JP C, .error
    POP AF
    OR A
    POP BC
    RET
.error:
    LD B, A
    POP AF
    LD A, B
    SCF
    POP BC
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
    SCF
    LD A, 0x71
    RET                  ; Drive A: (pas de CS SPI)
.select_sd1:
    LD A, SPI_CS1_BIT
    OR A
    RET
.select_sd2:
    LD A, SPI_CS2_BIT
    OR A
    RET


    ENDIF