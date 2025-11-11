
    IFNDEF __STDIO__
    DEFINE __STDIO__ 1

STREAM_OUT_SERIAL EQU 0x01
STREAM_OUT_VDP EQU 0x02
STREAM_OUT_PRINTER EQU 0x04
STREAM_IN_SERIAL EQU 0x10
STREAM_IN_KEYBOARD EQU 0x20

;VRAM_DATA EQU   0x40            ; PORT #0 - VRAM data port
    include "jumpTable.inc"
    include "serial.asm"
    include "vdp_core.asm"


PUTC: ; Output character in A to standard output at (HL) to standard output
    PUSH AF
    PUSH BC
    LD B, A
    LD A, (STREAM_SELECT)
    AND STREAM_OUT_SERIAL
    CALL NZ, SIO_PUTC
    LD A, (STREAM_SELECT)
    AND STREAM_OUT_VDP
    CALL NZ, VIDEO_PUTC
    LD A, (STREAM_SELECT)
    AND STREAM_OUT_PRINTER
    CALL NZ, PRINTER_PUTC
    POP BC
    POP AF
    RET

PUTS: ; Output string in (DE) (0x00 terminated) at (HL) to standard output
    PUSH AF
    LD A, (STREAM_SELECT)
    AND STREAM_OUT_SERIAL
    CALL NZ, SIO_PUTS
    LD A, (STREAM_SELECT)
    AND STREAM_OUT_VDP
    CALL NZ, VIDEO_PUTS
    LD A, (STREAM_SELECT)
    AND STREAM_OUT_PRINTER
    CALL NZ, PRINTER_PUTS
    POP AF
    RET

GETC: ; Input in A from standard input
    LD A, (STREAM_SELECT)
    AND STREAM_IN_SERIAL
    CALL NZ, SIO_GETC
    JR C, .GetC_Done
    LD A, (STREAM_SELECT)
    AND STREAM_IN_KEYBOARD
    CALL NZ, KBD_GETC
.GetC_Done:
    RET

SIO_PUTC:
    LD A, B
;    CALL HEX2STR
    CP 0x08
    JP Z, .backSpace
    CP 0x0A
    JP Z, .lineFeed
    CP 0x0D
    JP Z, .chariotReturn
    CALL SendChar_A
    RET
.backSpace:
    LD A, 0x08
    CALL SendChar_A
    LD A, ' '
    CALL SendChar_A
    LD A, 0x08
    CALL SendChar_A
    RET
.lineFeed:
    CALL SendChar_A
    LD A, '{'
    CALL SENDCHAR_A
    RET
.chariotReturn:
    CALL SendChar_A
    LD A, '}'
    CALL SENDCHAR_A
    RET

VIDEO_PUTC:
    LD A, B
    CP 0x08
    JP Z, .backSpace
    CP 0x09
    JP Z, .horizontalTab
    CP 0x0A
    JP Z, .LineFeed
    CP 0x0D
    JP Z, .chariotReturn
;    OUT (VRAM_DATA), A
    CALL WRITE_RAM
    INC HL
    RET
.backSpace:
    PUSH AF
    DEC HL
    LD A, ' '
    CALL WRITE_RAM
    POP AF
    RET
.horizontalTab:
    LD A, L
    AND A, 0x07
    LD B, A
    LD A, 7
    SUB B
    RET Z
    INC A
    LD B, A ; number of space to add
    LD A , ' '
    CALL WRITE_RAM
.tabLoop:
    OUT (VRAM_DATA), A
    INC HL
    DJNZ .tabLoop
    RET
.LineFeed:
    PUSH BC
    LD BC, 80
    ADD HL, BC
    POP BC
    RET
.chariotReturn: ; ### SOME DEBUGGING TO DO
    PUSH HL
    OR A ; clear carry
    LD DE, 80
.numberOfRowsLoop:
    SBC HL, DE
    JP M, .beginningOfScreen ; if negative, we are at the beginning of the screen
    JP .numberOfRowsLoop
.beginningOfScreen:
    LD DE, 80
    ADD HL, DE
    LD DE, HL
    POP HL
    OR A ; clear carry
    SBC HL, DE
    RET

PRINTER_PUTC:
    RET

SIO_PUTS: ; #TODO# Problème sur l'adresse : ca tape dans le début du moniteur
    PUSH DE
    EX DE, HL
    CALL PrintString
    CALL STRING_LENGTH
    LD E, A
    LD D, 0x00
    ADD HL, DE
    POP DE
    RET

VIDEO_PUTS:
    PUSH AF
    PUSH DE
.putsLoop:
    LD A, (DE)
    CP 0x00
    JP Z, .exit
    CALL PUTC
    INC DE
    INC HL
    JP .putsLoop   
.exit:
    POP DE
    POP AF
    RET

PRINTER_PUTS:
    RET

SIO_GETC:
    RET

KBD_GETC:
    RET


STREAM_SELECT: ; bit 0 is serial, bit 1 is video, bit 2 is printer
    DB 0x00


    ENDIF