; -------------       PIO            --------------
; ----- Configuration of the PIO Ports  -----------
; -------------------------------------------------
    IFNDEF __PIO__
    DEFINE __PIO__ 1



; ==== PIO INIT ====
PIO_ADDR EQU 0x00 ; adresse de base du PIO

PIO_DATA_A EQU PIO_ADDR ; A0 = 0 -> Channel A / A1 = 0 -> Data
PIO_DATA_B EQU PIO_ADDR + 1 ; A0 = 1 -> Channel B / A1 = 0 -> Data
PIO_CTRL_A EQU PIO_ADDR + 2 ; A0 = 0 -> Channel A / A1 = 1 -> Cmd
PIO_CTRL_B EQU PIO_ADDR + 3 ; A0 = 1 -> Channel B / A1 = 1 -> Cmd
PIO_MODE3_CONTROL EQU 0b11001111 ; Set mode 3 control


    ENDIF ; __PIO__