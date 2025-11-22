
; Definition of the keyboard keys

    IFNDEF __KEYBOARD_INC__
    DEFINE __KEYBOARD_INC__ 1

KEYBOARD_COLUMNS EQU 13 ; number of columns
KEYBOARD_ROWS EQU 0x04 ; number of rows
KEYBOARD_CONTROL_ROWS EQU 13 ; control key column (enter, bs, del, inser, up, down, left, right)
KEYBOARD_MODIFIERS EQU 14 ; modifiers column (shift, control, alt)

KBD_INSERT EQU 0x05
KBD_BKSP EQU 0x08
KBD_TAB EQU 0x09
KBD_ENTER EQU 0x0D
KBD_CAPSLOCK EQU 0x0E
KBD_UP EQU 0x11
KBD__LEFT EQU 0x12
KBD__DOWN EQU 0x13
KBD__RIGHT EQU 0x14
KBD_ESC EQU 0x1B
KBD_DELETE EQU 0x7F

SHIFT EQU 0x11
CTRL EQU 0x22
ALT EQU 0x44


CTRL_KEYS:
    DB KBD_DELETE, KBD_ENTER, 0x00, 0x00
    DB KBD_UP, KBD__LEFT, KBD__DOWN, KBD__RIGHT

 
SHIFT_MATRIX: ; organised by columns
    DB 0x00, KBD_TAB, KBD_CAPSLOCK, 0x00
    DB '1', 'A', 'Q', '<'
    DB '2', 'Z', 'S', 'W'
    DB '3', 'E', 'D', 'X'
    DB '4', 'R', 'F', 'C'
    DB '5', 'T', 'G', 'V'
    DB '6', 'Y', 'H', 'B'
    DB '7', 'U', 'J', ' '
    DB '8', 'I', 'K', 'N'
    DB '9', 'O', 'L', '?'
    DB '0', 'P', 'M', '.'
    DB '°', '¨', '%', '/'
    DB '+', '£', 'µ', '§'

DECODE_MATRIX: ; organised by columns
    DB '²', KBD_TAB, KBD_CAPSLOCK, 0x00
    DB '&', 'a', 'q', '<'
    DB 'é', 'z', 's', 'w'
    DB '"', 'e', 'd', 'x'
    DB "'", 'r', 'f', 'c'
    DB '(', 't', 'g', 'v'
    DB '-', 'y', 'h', 'b'
    DB 'è', 'u', 'j', ' '
    DB '_', 'i', 'k', 'n'
    DB 'ç', 'o', 'l', ','
    DB 'à', 'p', 'm', ';'
    DB ')', '^', 'ù', ':'
    DB '=', 'e', '*', '!'

CTRL_MATRIX: ; organised by columns
    DB 0x00, KBD_TAB, KBD_CAPSLOCK, 0x00
    DB 0x00, 0x00, 0x00, 0x00
    DB 0x00, 0x00, 0x00, 0x00
    DB 0x00, 0x00, 0x00, 0x00
    DB 0x00, 0x00, 0x00, 0x00
    DB 0x00, 0x00, 0x00, 0x00
    DB 0x00, 0x00, 0x00, 0x00
    DB 0x00, 0x00, 0x00, ' '
    DB 0x00, 0x00, 0x00, 0x00
    DB 0x00, 0x00, 0x00, 0x00
    DB 0x00, 0x00, 0x00, 0x00
    DB 0x00, 0x00, 0x00, 0x00
    DB 0x00, 0x00, 0x00, 0x00

ALT_MATRIX: ; organised by columns
    DB 0x00, KBD_TAB, KBD_CAPSLOCK, 0x00
    DB 0x00, 0x00, 0x00, 0x00
    DB '~', 0x00, 0x00, 0x00
    DB '#', '¤', 0x00, 0x00
    DB '{', 0x00, 0x00, 0x00
    DB '[', 0x00, 0x00, 0x00
    DB '|', 0x00, 0x00, 0x00
    DB '`', 0x00, 0x00, ' '
    DB '\', 0x00, 0x00, 0x00
    DB '^', 0x00, 0x00, 0x00
    DB '@', 0x00, 0x00, 0x00
    DB ']', 0x00, 0x00, 0x00
    DB '}', 0x00, 0x00, 0x00

    ENDIF