
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

    MACRO LONG_NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    ENDM

;VRAM_DATA EQU   0x40            ; PORT #0 - VRAM data port
    include "jumpTable.inc"
    include "serial.asm"
    include "vdp_core.asm"
    include "keyboard.asm"

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
    OR A
    JR NZ, .GetC_Done ; if char received A is non zero
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

SIO_GETC: ; get a character from serial, 0x00 is empty
;    CALL SendChar_A
    CALL ReceiveCharNB_A
    ; transform escaped sequence
    CP ESC
    JP Z, .escape

    ; PUSH AF
    ; LD A, '.'
    ; CALL SENDCHAR_A
    ; POP AF
    ;    PUSH AF
    ; CALL HEX2STR
    ; POP AF

    RET
.escape:
;    LONG_NOP
;    CALL ReceiveCharNB_A
    CALL ReceiveChar_A
    CP '['
    JP Z, .escapedSequence
    SCF
    RET
.escapedSequence:
;    LONG_NOP
;    CALL ReceiveCharNB_A
    CALL ReceiveChar_A
    CP 'A'
    JP Z, .up
    CP 'B'
    JP Z, .down
    CP 'C'
    JP Z, .right
    CP 'D'
    JP Z, .left
    RET
.up:
    LD A, CUR_UP
    RET
.down:
    LD A, CUR_DOWN
    RET
.right:
    LD A, CUR_RIGHT
    RET
.left:
    LD A, CUR_LEFT
    RET

; HAT EQU 0x01
; TREMA EQU 0x02
; TILDE EQU 0x03
PURGE_DEAD_KEY EQU 0x10

KBD_GETC:    ; Return key in A
    CALL Keyboard_GetKey
    ; Add Dead Key management
    CP 0x00
    RET Z
    PUSH BC
    LD B, A ; store the received key in B
    LD A, (DEAD_KEY)
    CP PURGE_DEAD_KEY
    JP Z, .purgeDeadKey:
    CP '^'
    JP Z, .storedDeadKey
    CP '¨'
    JP Z, .storedDeadKey
    CP '~'
    JP Z, .storedDeadKey
.noStoredDeadKey:
    LD A, B
    CP '^'
    JP Z, .newDeadKey
    CP '¨'
    JP Z, .newDeadKey
    CP '~'
    JP Z, .newDeadKey
    JP .exit
.purgeDeadKey:
    LD A, 0x00
    LD (DEAD_KEY), A
    LD A, B
    JP .exit
.newDeadKey:
    LD (DEAD_KEY), A
    LD A, 0x00
    JP .exit
.storedDeadKey:
    LD A, B ; retrieve the new received key
    CP ' '
    JP Z, .compose_space
    CP 'a'
    JP Z, .compose_A
    CP 'e'
    JP Z, .compose_E
    CP 'i'
    JP Z, .compose_I
    CP 'o'
    JP Z, .compose_O
    CP 'u'
    JP Z, .compose_U
    CP '^'
    JP Z, .returnExtraDeadKey
    CP '¨'
    JP Z, .returnExtraDeadKey
    CP '~'
    JP Z, .returnExtraDeadKey
    JP .returnExtraDeadKey
;    JP .exit
.compose_space:
    LD A, (DEAD_KEY)
    LD B, A
    LD A, 0x00
    LD (DEAD_KEY), A
    LD A, B
    JP .exit
.compose_A:
    LD B, A
    LD A, (DEAD_KEY)
    CP '^'
    JP Z, .compose_AHat
    CP '¨'
    JP Z, .compose_ATrema
    CP '~'
    JP Z, .compose_ATilde
    LD A, B
    JP .returnExtraDeadKey
.compose_AHat: ;
    LD A, 0x00
    LD (DEAD_KEY), A
    LD A, 'â'
    JP .exit
.compose_ATrema: ; 
    LD A, 0x00
    LD (DEAD_KEY), A
    LD A, 'ä'
    JP .exit
.compose_ATilde: ; 
    LD A, 0x00
    LD (DEAD_KEY), A
    LD A, 'ã'
    JP .exit
.compose_E:
    LD B, A
    LD A, (DEAD_KEY)
    CP '^'
    JP Z, .compose_EHat
    CP '¨'
    JP Z, .compose_ETrema
    LD A, B
    JP .returnExtraDeadKey
.compose_EHat: ; 
    LD A, 0x00
    LD (DEAD_KEY), A
    LD A, 'ê'
    JP .exit
.compose_ETrema: ; 
    LD A, 0x00
    LD (DEAD_KEY), A
    LD A, 'ë'
    JP .exit
.compose_I:
    LD B, A
    LD A, (DEAD_KEY)
    CP '^'
    JP Z, .compose_IHat
    CP '¨'
    JP Z, .compose_ITrema
    LD A, B
    JP .returnExtraDeadKey
.compose_IHat: ; 
    LD A, 0x00
    LD (DEAD_KEY), A
    LD A, 'î'
    JP .exit
.compose_ITrema: ; 
    LD A, 0x00
    LD (DEAD_KEY), A
    LD A, 'ï'
    JP .exit
.compose_O:
    LD B, A
    LD A, (DEAD_KEY)
    CP '^'
    JP Z, .compose_OHat
    CP '¨'
    JP Z, .compose_OTrema
    CP '~'
    JP Z, .compose_OTilde
    LD A, B
    JP .returnExtraDeadKey
.compose_OHat: ; 
    LD A, 0x00
    LD (DEAD_KEY), A
    LD A, 'ô'
    JP .exit
.compose_OTrema: ; 
    LD A, 0x00
    LD (DEAD_KEY), A
    LD A, 'ö'
    JP .exit
.compose_OTilde: ; 
    LD A, 0x00
    LD (DEAD_KEY), A
    LD A, 'õ'
    JP .exit
.compose_U:
    LD B, A
    LD A, (DEAD_KEY)
    CP '^'
    JP Z, .compose_UHat
    CP '¨'
    JP Z, .compose_UTrema
    LD A, B
    JP .returnExtraDeadKey
.compose_UHat: ; #TODO DO THE ACTUAL COMPOSITION WITH ACCENT
    LD A, 0x00
    LD (DEAD_KEY), A
    LD A, 'û'
    JP .exit
.compose_UTrema: ; #TODO DO THE ACTUAL COMPOSITION WITH ACCENT
    LD A, 0x00
    LD (DEAD_KEY), A
    LD A, 'ü'
    JP .exit
.compose: ; #TODO DO THE ACTUAL COMPOSITION WITH ACCENT
    LD A, 0x00
    LD (DEAD_KEY), A
    LD A, 'â'
    JP .exit
.returnExtraDeadKey:
    CALL Keyboard_UngetKey
    LD A, (DEAD_KEY)
    LD B, A
    LD A, PURGE_DEAD_KEY
    LD (DEAD_KEY), A
    LD A, B
.exit:
    POP BC
    RET

ACCENTED_A:
    DB 'â', 'ä', 'ã'
ACCENTED_E:
    DB 'ê', 'ë', '~e'
ACCENTED_I:
    DB 'î', 'ï', '~i'
ACCENTED_O:
    DB 'ô', 'ö', 'õ'
ACCENTED_U:
    DB 'û', 'ü', '~u'


STREAM_SELECT: ; bit 0 is serial, bit 1 is video, bit 2 is printer
    DB 0x00
DEAD_KEY:
    DB 0x00



    ENDIF