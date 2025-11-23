
; Definition of the keyboard keys

    IFNDEF __KEYPAD_INC__
    DEFINE __KEYPAD_INC__ 1

KEYBOARD_COLUMNS EQU 0x03 ; number of columns
KEYBOARD_ROWS EQU 0x05 ; number of rows
KEYBOARD_CONTROL_ROWS EQU 0x04 ; control key column (enter, bs, del, inser, up, down, left, right)
KEYBOARD_MODIFIERS EQU 0x03 ; modifiers column (shift, control, alt)

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

SHIFT EQU 0x01
CTRL EQU 0x02
ALT EQU 0x08

CTRL_KEYS:
    DB KBD_DELETE, KBD_ENTER, 0x00, 0x00
    DB KBD_UP, KBD__LEFT, KBD__DOWN, KBD__RIGHT

DECODE_MATRIX: ; organised by columns
    DB '^', 'a', 'o', 'b', '0'
    DB 'x', 'e', 'u', 'c', 0x00
    DB '~', 'i', 's', 'd', KBD_ENTER
;    DB '-', 'p', 0x00, 0x0D, 0x00
SHIFT_MATRIX: ; organised by columns
    DB '¨', 'A', 'O', 'B', '0'
    DB 'X', 'E', 'U', 'C', 0x00
    DB 'C', 'I', 'S', 'D', KBD_ENTER
;    DB '-', 'p', 0x00, 0x0D, 0x00
CTRL_MATRIX: ; organised by columns
    DB 0x82, 0x86, 0x84, 0x80, 0x81
    DB 0x88, 0x8A, 0x89, 0x8C, 0x00
    DB 0x83, 0x87, 0x85, 0x8B, 0x8D
;    DB '-', 'p', 0x00, 0x0D, 0x00
ALT_MATRIX: ; organised by columns
    DB '?', 'a', KBD__LEFT, 'e', ' '
    DB '¤', KBD_UP, 'i', KBD__DOWN, 0x00
    DB '~', 'o', KBD__RIGHT, 'u', KBD_ENTER
;    DB '-', 'p', 0x00, 0x0D, 0x00

    ENDIF