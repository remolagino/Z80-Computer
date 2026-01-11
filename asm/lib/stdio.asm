
    IFNDEF __STDIO__
    DEFINE __STDIO__ 1

STREAM_OUT_SERIAL EQU 0x01
STREAM_OUT_VDP EQU 0x02
STREAM_OUT_PRINTER EQU 0x04
STREAM_IN_SERIAL EQU 0x10
STREAM_IN_KEYBOARD EQU 0x20


LF_KEY_CODE EQU 0x0A
CR_KEY_CODE EQU 0x0D

VDP_SCROLL_LINE_IDX EQU 25 ; line index to start scrolling



;VRAM_DATA EQU   0x40            ; PORT #0 - VRAM data port
;    include "jumpTable.inc"
    include "serial.asm"
    include "vdp_core.asm"
    include "keyboard.asm"

PutC: ; Output character in A to standard output at (HL) to standard output
    PUSH AF
    PUSH BC
    LD B, A ; switch B and A as we work on A for stream_select comparison
    LD A, (STDIO_STREAM_SELECT)
    AND STREAM_OUT_SERIAL
    CALL NZ, SIO_PUTC
    LD A, (STDIO_STREAM_SELECT)
    AND STREAM_OUT_VDP
    CALL NZ, VDP_PUTC
    LD A, (STDIO_STREAM_SELECT)
    AND STREAM_OUT_PRINTER
    CALL NZ, PRINTER_PUTC
    POP BC
    POP AF
    RET

PutS: ; Output string in (DE) (0x00 terminated) at (HL) to standard output
    PUSH AF
    LD A, (STDIO_STREAM_SELECT)
    AND STREAM_OUT_SERIAL
    CALL NZ, SIO_PUTS
    LD A, (STDIO_STREAM_SELECT)
    AND STREAM_OUT_VDP
    CALL NZ, VDP_PUTS
    LD A, (STDIO_STREAM_SELECT)
    AND STREAM_OUT_PRINTER
    CALL NZ, PRINTER_PUTS
    POP AF
    RET

PutS_LN: ; Output string in (DE) (0x00 terminated) at (HL) to standard output
    PUSH AF
    LD A, (STDIO_STREAM_SELECT)
    AND STREAM_OUT_SERIAL
    CALL NZ, SIO_PUTS_LN
    LD A, (STDIO_STREAM_SELECT)
    AND STREAM_OUT_VDP
    CALL NZ, VDP_PUTS_LN
    LD A, (STDIO_STREAM_SELECT)
    AND STREAM_OUT_PRINTER
    CALL NZ, PRINTER_PUTS_LN
    POP AF
    RET

GetC: ; Input in A from standard input
    LD A, (STDIO_STREAM_SELECT)
    AND STREAM_IN_SERIAL
    CALL NZ, SIO_GETC
    OR A
    JR NZ, .GetC_Done ; if char received A is non zero
    LD A, (STDIO_STREAM_SELECT)
    AND STREAM_IN_KEYBOARD
    CALL NZ, KBD_GETC
.GetC_Done:
    RET

SIO_PUTC: ; char to print in B
    LD A, B
;    CALL HEX2STR
    CP BKSP_KEY_CODE
    JP Z, .backSpace
;    CP LF
;    JP Z, .lineFeed
;    CP CR
;    JP Z, .chariotReturn
    CP UP_KEY_CODE
    JP Z, .goUp
    CP LEFT_KEY_CODE
    JP Z, .goLeft
    CP DOWN_KEY_CODE
    JP Z, .goDown
    CP RIGHT_KEY_CODE
    JP Z, .goRight

    CALL SendChar_A
    RET
.backSpace:
    LD A, BKSP_KEY_CODE
    CALL SendChar_A
    LD A, ' '
    CALL SendChar_A
    LD A, BKSP_KEY_CODE
    CALL SendChar_A
    RET
.goUp:
    LD A, ESC_KEY_CODE
    CALL SendChar_A
    LD A, '['
    CALL SendChar_A
    LD A, 'A'
    CALL SendChar_A
    RET
.goLeft:
    LD A, ESC_KEY_CODE
    CALL SendChar_A
    LD A, '['
    CALL SendChar_A
    LD A, 'D'
    CALL SendChar_A
    RET
.goDown:
    LD A, ESC_KEY_CODE
    CALL SendChar_A
    LD A, '['
    CALL SendChar_A
    LD A, 'B'
    CALL SendChar_A
    RET
.goRight:
    LD A, ESC_KEY_CODE
    CALL SendChar_A
    LD A, '['
    CALL SendChar_A
    LD A, 'C'
    CALL SendChar_A
    RET


VDP_PUTC: ; char to print in B, at (HL)
    LD A, B
    CP BKSP_KEY_CODE
    JP Z, .backSpace
    CP TAB_KEY_CODE
    JP Z, .horizontalTab
    CP LF_KEY_CODE
    JP Z, .LineFeed
    CP CR_KEY_CODE
    JP Z, .chariotReturn
    CP UP_KEY_CODE
    JP Z, .goUp
    CP LEFT_KEY_CODE
    JP Z, .goLeft
    CP DOWN_KEY_CODE
    JP Z, .goDown
    CP RIGHT_KEY_CODE
    JP Z, .goRight
    CALL VDP_putC_VRAM
    INC HL
    JP .exit
.backSpace:
    PUSH AF
    DEC HL
    LD A, ' '
    CALL VDP_putC_VRAM
    POP AF
    JP .exit
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
    CALL VDP_putC_VRAM
.tabLoop:
    OUT (VRAM_DATA), A
    INC HL
    DJNZ .tabLoop
    POP BC
    POP AF
    JP .exit
.LineFeed:
    PUSH BC
    LD BC, 80
    ADD HL, BC
    POP BC
    JP .exit
.chariotReturn: ;
    PUSH DE
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
    POP DE
    JP  .exit
.goLeft:
    PUSH AF
    PUSH BC
    LD A, H
    OR L
    JP Z, .goLeft.end ; if at left edge, do nothing
    DEC HL
.goLeft.end:
    POP BC
    POP AF
    JP .exit
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
    JP Z, .goRight.end ; if at bottom right edge, do nothing
    POP HL
    INC HL
    PUSH HL
.goRight.end:
    POP HL
    POP DE
    POP AF
    JP .exit
.goUp: ; 
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL
    LD DE, 80
    OR A
    SBC HL, DE
    JP M, .goUp.end ; if at top edge, do nothing
    POP HL
    LD DE, 80 ; move up one row
    OR A ; clear carry
    SBC HL, DE
    PUSH HL
.goUp.end:
    POP HL
    POP DE
    POP BC
    POP AF
    JP .exit
.goDown: ; 
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL
    LD DE, HL ; check if possible to move right
    LD HL, 80*25-1 ; #TODO Parmetrize this at some point
    OR A
    SBC HL, DE
    JP M, .goDown.end ; if at left edge, do nothing
    POP HL
    LD DE, 80 ; move down one row
    ADD HL, DE
    PUSH HL
.goDown.end:
    POP HL
    POP DE
    POP BC
    POP AF
.exit:
    CALL SCROLL_MANAGEMENT
    RET


SCROLL_MANAGEMENT:
; test if scroll needed
    PUSH BC
    PUSH HL
    LD BC, 80*VDP_SCROLL_LINE_IDX ; start scroll when line 10 is reached
    SBC HL, BC
    POP HL
    POP BC
    RET M

    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL
    LD HL, 80
    LD C, VDP_SCROLL_LINE_IDX+1 ; number of lines to scroll
.screenLoop:
; read line from vram
    LD A, VRAM_READ_MODE
    CALL VDP_Set_VRAM_Address
    LD DE, STDIO_SCROLL_MEMORY
    LD B, 80 ; number of bytes to read
.readLoop:
    IN A, (VRAM_DATA)
    LD (DE), A
    INC DE
    NOP7
    DJNZ .readLoop
; write line to vram   
    PUSH BC
    LD BC, 80 
    SBC HL, BC
    POP BC
    LD A, VRAM_WRITE_MODE
    CALL VDP_Set_VRAM_Address
    LD DE, STDIO_SCROLL_MEMORY
    LD B, 80 ; number of bytes to write
.writeLoop:
    LD A, (DE)
    OUT (VRAM_DATA), A
    INC DE
    NOP7
    DJNZ .writeLoop
    PUSH BC
    LD BC, 160
    ADD HL, BC
    POP BC
    DEC C
    JP NZ, .screenLoop
    POP HL
    LD BC, 80 ; we position back HL to the start of the line
    SBC HL, BC
    POP DE
    POP BC
    POP AF

    RET


PRINTER_PUTC:
    RET

SIO_PUTS_LN: ; #TODO# Problème sur l'adresse : ca tape dans le début du moniteur
    PUSH BC
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
    LD B, CR_KEY_CODE
    CALL SIO_PUTC ;
    LD B, LF_KEY_CODE
    CALL SIO_PUTC ;
    POP HL
    POP DE
    POP BC
    RET

SIO_PUTS: ; #TODO# Problème sur l'adresse : ca tape dans le début du moniteur
    PUSH BC
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
    POP HL
    POP DE
    POP BC
    RET

VDP_PUTS_LN:
    CALL VDP_PUTS
    PUSH BC
    LD B, CR_KEY_CODE
    CALL VDP_PUTC ;
    LD B, LF_KEY_CODE
    CALL VDP_PUTC ;
    POP BC
    RET

VDP_PUTS:
    PUSH AF
    PUSH BC
    PUSH DE
.putsLoop:
    LD A, (DE)
    CP 0x00
    JP Z, .exit
    LD B, A
    CALL VDP_PUTC
    INC DE
    ; INC HL
    JP .putsLoop   
.exit:
    POP DE
    POP BC
    POP AF
    RET

PRINTER_PUTS_LN:
PRINTER_PUTS:
    RET

SIO_GETC: ; get a character from serial, 0x00 is empty
;    CALL SendChar_A
    CALL ReceiveCharNB_A
    ; transform escaped sequence
    CP ESC_KEY_CODE
    JP Z, .escape
    CP 0x7F
    RET NZ
    LD A, 'X'
    RET
.escape:
    CALL ReceiveChar_A
    CP '['
    JP Z, .escapedSequence

    RET
.escapedSequence:
    CALL ReceiveChar_A
    CP 'A'
    JP Z, .up
    CP 'B'
    JP Z, .down
    CP 'C'
    JP Z, .right
    CP 'D'
    JP Z, .left
    CP '2'
    JP Z, .insert
    CP '3'
    JP Z, .delete
    LD A, '?'
    RET
.up:
    LD A, UP_KEY_CODE
    RET
.down:
    LD A, DOWN_KEY_CODE
    RET
.right:
    LD A, RIGHT_KEY_CODE
    RET
.left:
    LD A, LEFT_KEY_CODE
    RET
.insert:
    CALL ReceiveChar_A
    CP '~'
    JP Z, .send_insert
    LD A, '?'
    RET
.send_insert:
    LD A, INSERT_KEY_CODE
    RET
.delete:
    CALL ReceiveChar_A
    CP '~'
    JP Z, .send_delete
    LD A, '?'
    RET
.send_delete:
    LD A, DELETE_KEY_CODE
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
    LD A, (STDIO_DEAD_KEY)
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
    LD (STDIO_DEAD_KEY), A
    LD A, B
    JP .exit
.newDeadKey:
    LD (STDIO_DEAD_KEY), A
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
    LD A, (STDIO_DEAD_KEY)
    LD B, A
    LD A, 0x00
    LD (STDIO_DEAD_KEY), A
    LD A, B
    JP .exit
.compose_A:
    LD B, A
    LD A, (STDIO_DEAD_KEY)
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
    LD (STDIO_DEAD_KEY), A
    LD A, 'â'
    JP .exit
.compose_ATrema: ; 
    LD A, 0x00
    LD (STDIO_DEAD_KEY), A
    LD A, 'ä'
    JP .exit
.compose_ATilde: ; 
    LD A, 0x00
    LD (STDIO_DEAD_KEY), A
    LD A, 'ã'
    JP .exit
.compose_E:
    LD B, A
    LD A, (STDIO_DEAD_KEY)
    CP '^'
    JP Z, .compose_EHat
    CP '¨'
    JP Z, .compose_ETrema
    LD A, B
    JP .returnExtraDeadKey
.compose_EHat: ; 
    LD A, 0x00
    LD (STDIO_DEAD_KEY), A
    LD A, 'ê'
    JP .exit
.compose_ETrema: ; 
    LD A, 0x00
    LD (STDIO_DEAD_KEY), A
    LD A, 'ë'
    JP .exit
.compose_I:
    LD B, A
    LD A, (STDIO_DEAD_KEY)
    CP '^'
    JP Z, .compose_IHat
    CP '¨'
    JP Z, .compose_ITrema
    LD A, B
    JP .returnExtraDeadKey
.compose_IHat: ; 
    LD A, 0x00
    LD (STDIO_DEAD_KEY), A
    LD A, 'î'
    JP .exit
.compose_ITrema: ; 
    LD A, 0x00
    LD (STDIO_DEAD_KEY), A
    LD A, 'ï'
    JP .exit
.compose_O:
    LD B, A
    LD A, (STDIO_DEAD_KEY)
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
    LD (STDIO_DEAD_KEY), A
    LD A, 'ô'
    JP .exit
.compose_OTrema: ; 
    LD A, 0x00
    LD (STDIO_DEAD_KEY), A
    LD A, 'ö'
    JP .exit
.compose_OTilde: ; 
    LD A, 0x00
    LD (STDIO_DEAD_KEY), A
    LD A, 'õ'
    JP .exit
.compose_U:
    LD B, A
    LD A, (STDIO_DEAD_KEY)
    CP '^'
    JP Z, .compose_UHat
    CP '¨'
    JP Z, .compose_UTrema
    LD A, B
    JP .returnExtraDeadKey
.compose_UHat: ;
    LD A, 0x00
    LD (STDIO_DEAD_KEY), A
    LD A, 'û'
    JP .exit
.compose_UTrema: ; 
    LD A, 0x00
    LD (STDIO_DEAD_KEY), A
    LD A, 'ü'
    JP .exit
.compose: ; 
    LD A, 0x00
    LD (STDIO_DEAD_KEY), A
    LD A, 'â'
    JP .exit
.returnExtraDeadKey:
    CALL Keyboard_UngetKey
    LD A, (STDIO_DEAD_KEY)
    LD B, A
    LD A, PURGE_DEAD_KEY
    LD (STDIO_DEAD_KEY), A
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


; STDIO_STREAM_SELECT: ; bit 0 is serial, bit 1 is video, bit 2 is printer
;     DB 0x00
; STDIO_DEAD_KEY:
;     DB 0x00



    ENDIF