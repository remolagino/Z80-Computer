
    IFNDEF __STDIO__
    DEFINE __STDIO__ 1

STREAM_OUT_SERIAL EQU 0x01
STREAM_OUT_VDP EQU 0x02
STREAM_OUT_PRINTER EQU 0x04
STREAM_IN_SERIAL EQU 0x10
STREAM_IN_KEYBOARD EQU 0x20

BS EQU 0x08
HTAB EQU 0x09
LF EQU 0x0A
CR EQU 0x0D
CUR_UP EQU 0x11
CUR_LEFT EQU 0x12
CUR_DOWN EQU 0x13
CUR_RIGHT EQU 0x14
ESC EQU 0x1B

;VRAM_DATA EQU   0x40            ; PORT #0 - VRAM data port
    include "jumpTable.inc"
;    include "serial.asm"
    include "vdp_core.asm"


PUTC: ; Output character in A to standard output at (HL) to standard output
    PUSH AF
    PUSH BC
    LD B, A ; switch B and A as we work on A for stream_select comparison
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

SIO_PUTC: ; char to print in B
    LD A, B
;    CALL HEX2STR
    CP BS
    JP Z, .backSpace
    CP LF
    JP Z, .lineFeed
    CP CR
    JP Z, .chariotReturn
    CP CUR_UP
    JP Z, .goUp
    CP CUR_LEFT
    JP Z, .goLeft
    CP CUR_DOWN
    JP Z, .goDown
    CP CUR_RIGHT
    JP Z, .goRight

    CALL SENDCHAR_A
    RET
.backSpace:
    LD A, BS
    CALL SENDCHAR_A
    LD A, ' '
    CALL SENDCHAR_A
    LD A, BS
    CALL SENDCHAR_A
    RET
.lineFeed:
    CALL SENDCHAR_A
    RET
.chariotReturn:
    CALL SENDCHAR_A
    RET
.goUp:
    LD A, ESC
    CALL SENDCHAR_A
    LD A, '['
    CALL SENDCHAR_A
    LD A, 'A'
    CALL SENDCHAR_A
    RET
.goLeft:
    LD A, ESC
    CALL SENDCHAR_A
    LD A, '['
    CALL SENDCHAR_A
    LD A, 'D'
    CALL SENDCHAR_A
    RET
.goDown:
    LD A, ESC
    CALL SENDCHAR_A
    LD A, '['
    CALL SENDCHAR_A
    LD A, 'B'
    CALL SENDCHAR_A
    RET
.goRight:
    LD A, ESC
    CALL SENDCHAR_A
    LD A, '['
    CALL SENDCHAR_A
    LD A, 'C'
    CALL SENDCHAR_A
    RET


VIDEO_PUTC: ; char to print in B, at (HL)
    LD A, B
    CP BS
    JP Z, .backSpace
    CP HTAB
    JP Z, .horizontalTab
    CP LF
    JP Z, .LineFeed
    CP CR
    JP Z, .chariotReturn
    CP CUR_UP
    JP Z, .goUp
    CP CUR_LEFT
    JP Z, .goLeft
    CP CUR_DOWN
    JP Z, .goDown
    CP CUR_RIGHT
    JP Z, .goRight
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
    PUSH AF
    PUSH BC
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
    POP BC
    POP AF
    RET
.LineFeed:
    PUSH BC
    LD BC, 80
    ADD HL, BC
    POP BC
    RET
.chariotReturn: ; Debugging done, missing PUSH POP
    PUSH DE
    PUSH HL
;    CALL Print_HL_Hex
    OR A ; clear carry
    LD DE, 80
.numberOfRowsLoop:
    SBC HL, DE
;    CALL Print_HL_Hex
    JP M, .beginningOfScreen ; if negative, we are at the beginning of the screen
    JP .numberOfRowsLoop
.beginningOfScreen:
    LD DE, 80
    ADD HL, DE
;    CALL Print_HL_Hex
    LD DE, HL
    POP HL
    OR A ; clear carry
;    CALL Print_HL_Hex
    SBC HL, DE
;    CALL Print_HL_Hex
    POP DE
    RET
.goLeft:
    PUSH AF
    PUSH BC
    LD A, H
    OR L
    JP Z, .goLeft.exit ; if at left edge, do nothing
    DEC HL
.goLeft.exit:
    POP BC
    POP AF
    RET
.goRight:
    PUSH AF
    PUSH DE
    PUSH HL
    LD DE, HL ; check if possible to move right
    LD HL, 80*26-1
    OR A ; clear carry
    SBC HL, DE
    LD A, H
    OR L
    JP Z, .goRight.exit ; if at bottom right edge, do nothing
    POP HL
    INC HL
    PUSH HL
.goRight.exit:
    POP HL
    POP DE
    POP AF
    RET
.goUp: ; # TODO UPDATE
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL
    LD DE, 80
    OR A
    SBC HL, DE
    JP M, .goUp.exit ; if at top edge, do nothing
    POP HL
    LD DE, 80 ; move up one row
    OR A ; clear carry
    SBC HL, DE
    PUSH HL
.goUp.exit:
    POP HL
    POP DE
    POP BC
    POP AF
    RET
.goDown: ; # TODO - Update
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL
    LD DE, HL ; check if possible to move right
    LD HL, 80*25-1 ; #TODO Parmetrize this at some point
    OR A
    SBC HL, DE
    JP M, .goDown.exit ; if at left edge, do nothing
    POP HL
    LD DE, 80 ; move down one row
    ADD HL, DE
    PUSH HL
.goDown.exit:
    POP HL
    POP DE
    POP BC
    POP AF
    RET



; Print_HL_Hex:
;     PUSH AF
;     LD A, "<"
;     CALL SENDCHAR_A
;     LD A, H
;     CALL HEX2STR
;     LD A, L
;     CALL HEX2STR
;     LD A, ">"
;     CALL SENDCHAR_A
;     POP AF
;     RET

PRINTER_PUTC:
    RET

SIO_PUTS: ; #TODO# Problème sur l'adresse : ca tape dans le début du moniteur
    PUSH DE
    PUSH HL
    LD HL, DE
.loop:
    LD A, (HL)
    OR A
    JP Z, .end
    LD B, A
    CALL SIO_PUTC ;
    INC HL
    JP .loop ; Continue printing the string
.end:
    LD B, CR
    CALL SIO_PUTC ;
    LD B, LF
    CALL SIO_PUTC ;
    POP HL
    POP DE
    RET

VIDEO_PUTS:
    PUSH AF
    PUSH DE
.putsLoop:
    LD A, (DE)
    CP 0x00
    JP Z, .exit
    LD B, A
    CALL VIDEO_PUTC
    INC DE
    ; INC HL
    JP .putsLoop   
.exit:
    LD B, CR
    CALL VIDEO_PUTC ;
    LD B, LF
    CALL VIDEO_PUTC ;
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