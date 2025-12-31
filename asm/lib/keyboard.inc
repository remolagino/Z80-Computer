
; Definition of the keyboard keys

    IFNDEF __KEYBOARD_INC__
    DEFINE __KEYBOARD_INC__ 1

KEYBOARD_COLUMNS EQU 13 ; number of columns
KEYBOARD_ROWS EQU 4 ; number of rows
KEYBOARD_CONTROL_COL EQU 13 ; control key column (enter, bs, del, inser, up, down, left, right)
KEYBOARD_MODIFIERS_COL EQU 14 ; modifiers column (shift, control, alt)

INSERT_KEY_CODE EQU 0x05
BKSP_KEY_CODE EQU 0x08
TAB_KEY_CODE EQU 0x09
ENTER_KEY_CODE EQU 0x0D
CAPSLOCK_KEY_CODE EQU 0x0E
UP_KEY_CODE EQU 0x11
LEFT_KEY_CODE EQU 0x12
DOWN_KEY_CODE EQU 0x13
RIGHT_KEY_CODE EQU 0x14
ESC_KEY_CODE EQU 0x1B
DELETE_KEY_CODE EQU 0x7F

SHIFT EQU 0x11
CTRL EQU 0x22
ALT EQU 0x44



CTRL_KEYS_MATRIX:
    DB BKSP_KEY_CODE, ENTER_KEY_CODE, INSERT_KEY_CODE, DELETE_KEY_CODE
    DB UP_KEY_CODE, LEFT_KEY_CODE, DOWN_KEY_CODE, RIGHT_KEY_CODE

 
SHIFT_MATRIX: ; organised by columns
    DB 0x00, TAB_KEY_CODE, CAPSLOCK_KEY_CODE, 0x00
    DB '1', 'A', 'Q', '>'
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
    DB '²', TAB_KEY_CODE, CAPSLOCK_KEY_CODE, 0x00
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
    DB '=', '$', '*', '!'

CTRL_MATRIX: ; organised by columns
    DB 0x00, TAB_KEY_CODE, CAPSLOCK_KEY_CODE, 0x00
    DB '1', 0x82, 0x86, '>'
    DB '2', 0x88, 0x8A, 0x84
    DB '3', 0x83, 0x87, 0x89
    DB '4', 0x80, 0x81, 0x85
    DB '5', 'T', 'G', 'V'
    DB '6', 'Y', 'H', 'B'
    DB '7', 'U', 'J', ' '
    DB '8', 'I', 'K', 'N'
    DB '9', 'O', 'L', '?'
    DB '0', 'P', 'M', '.'
    DB '°', '¨', 0xDF, '/'
    DB '+', '£', 'µ', '§'

ALT_MATRIX: ; organised by columns
    DB 0x00, TAB_KEY_CODE, CAPSLOCK_KEY_CODE, 0x00
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