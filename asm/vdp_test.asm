; V9938 Blue Screen Test Program for Z80
; RAM_START EQU 0x4000 ; Start of RAM
; ======= Keypad Variables =======

; MODIFER_STATE EQU RAM_START + 0x0100 ; 1 byte
; MODIFERS EQU RAM_START + 0x0101 ; 1 byte
; KEYPAD_BUFFER EQU RAM_START + 0x0102 ; 4 characters buffer
; KEYPAD_STATE EQU RAM_START + 0x0110 ; Keypad state - ROWs * COLS bytes


    ORG     0x5000          ; Start address

    include "jumpTable.inc"
    include "memoryMapv2.inc"
    JP Main

;    include "serial.asm"
    include "stdio.asm"
    include "vdp_core.asm"
    include "lineEdit.asm"

CURSOR_IDX:
    DW 0 ; row 0, col 0

Main:

    LD HL, CR_LF
    CALL PRINT_STRING
; STREAM_IN_KEYBOARD|
    LD A, STREAM_OUT_VDP|STREAM_OUT_SERIAL|STREAM_IN_KEYBOARD|STREAM_IN_SERIAL
    LD (STREAM_SELECT), A
    LD HL, STREAM_MSG
    CALL PRINT_STRING
    LD A, (STREAM_SELECT)
    CALL HEX2STR

    LD HL, CR_LF
    CALL PRINT_STRING
    LD HL, CR_LF
    CALL PRINT_STRING

    CALL INIT_PATTERN_LAYOUT_TABLE
    CALL INIT_COLOR_TABLE

    LD HL, 320
    LD DE, MEASURE_MSG
    CALL PutS

    LD DE, TEST_MSG
    CALL PutS

    CALL LineEdit_Init
    LD DE, EDIT_BUFFER_ADDRESS
    CALL PutS

    LD B, 0
    LD (CURSOR_IDX), HL ; put the cursor at 0
    LD C, 0x01
    CALL Set_Blink

.eventLoop:
 
    CALL GetC

    CP 0x00
    JP Z, .eventLoop ; No key pressed, continue loop


    CP '²'
    JP Z, .endLoop
    ; CP '9'
    ; JP Z, .screenVertical
    ; CP '3'
    ; JP Z, .screenHorizontal
    ; CP '5'
    ; JP Z, .rotateColor
    CP CR      ; Enter key
    JP Z, .enterKey
    CP DELETE
    JP Z, .delete
    CP INSERT
    JP Z, .insert

    LD HL, (CURSOR_IDX)
    LD C, 0x00
    CALL Set_Blink ; unset blink at current position
    CALL PutC
    LD (CURSOR_IDX), HL
    LD C, 0x01
    CALL Set_Blink ; set blink at new position
    JP .eventLoop

.delete:
    LD HL, (CURSOR_IDX)
    LD C, 0x00
    CALL Set_Blink ; unset blink at current position
    LD A, BS
    CALL PutC
    LD (CURSOR_IDX), HL
    LD C, 0x01
    CALL Set_Blink ; set blink at new position
    JP .eventLoop

.insert:
    LD HL, (CURSOR_IDX)
    LD C, 0x00
    CALL Set_Blink ; unset blink at current position
    LD A,'¤'
    CALL PutC
    LD (CURSOR_IDX), HL
    LD C, 0x01
    CALL Set_Blink ; set blink at new position
    JP .eventLoop

.enterKey:
    LD HL, (CURSOR_IDX)
    LD C, 0x00
    CALL Set_Blink ; unset blink at current position
    LD A, LF
    CALL PutC
    LD A, CR
    CALL PutC
    LD (CURSOR_IDX), HL
    LD C, 0x01
    CALL Set_Blink ; set blink at new position
    JP .eventLoop

.rotateColor:
    LD C, 7
    LD A, 0xF0         ; Text color: white (F) 
    OR B ; put B color in background
    CALL Write_Reg
    INC B
    LD A, B
    AND 0x0F
    LD B, A
    JP .eventLoop

.screenVertical:
    LD C, 18
    LD A, (SCREEN_OFFSET)
    ADD A, 0x10
    AND A, 0xF0
    LD B, A
    LD A, (SCREEN_OFFSET)
    AND 0x0F
    OR B
;    CALL HEX2STR
    LD (SCREEN_OFFSET), A
    CALL Write_Reg
    JP .eventLoop
.screenHorizontal:
    LD      C, 18
    LD A, (SCREEN_OFFSET)
    ADD A, 0x01
    AND A, 0x0F
    LD B, A
    LD A, (SCREEN_OFFSET)
    AND 0xF0
    OR B
;    CALL HEX2STR
    LD (SCREEN_OFFSET), A
    CALL Write_Reg
    JP .eventLoop
.endLoop:
    LD HL, CR_LF
    CALL PRINT_STRING
    RET                     ; or HALT


INIT_PATTERN_LAYOUT_TABLE: ; write at adress 0x0000
    PUSH AF
    PUSH BC
    PUSH HL

    LD HL, PATTERN_LAYOUT_TABLE_BASE_ADDR
    CALL Set_VRAM_Address
    LD HL, 80*27 ; number of bytes to write (0x0B0D = 2821 bytes)
.loop:
    LD A, ' ' ; value to write to initialize VRAM
    OUT (VRAM_DATA), A
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    DEC HL
    LD A, H
    OR L
    JP NZ, .loop
.loopEnd:
    POP HL
    POP BC
    POP AF
    RET

INIT_COLOR_TABLE: ; write at adress 0x0000
    PUSH AF
    PUSH BC
    PUSH HL
    LD HL, COLOR_TABLE_BASE_ADDR
    CALL Set_VRAM_Address

    LD HL, 270 ; number of bytes to write (0x0B0D = 2821 bytes)
.loop:
    LD A, 0x00 ; value to write to initialize VRAM
    OUT (VRAM_DATA), A
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    DEC HL
    LD A, H
    OR L
    JP NZ, .loop
.loopEnd:
    POP HL
    POP BC
    POP AF
    RET


CR_LF:
    DB CR, LF, 0x00 ; Carriage return + line feed

PRESSED_MSG:
    DB 'Key Pressed : ', 0x00
RELEASED_MSG:
    DB 'Key Released : ', 0x00
STREAM_MSG:
    DB "Stream Selected : ", 0x00
TEST_MSG:
    DB HTAB, HTAB, "This.is.a.test message.!!", CR, LF,  "Prout", CUR_UP, CUR_LEFT, CUR_LEFT, "prout !", 0x00
MEASURE_MSG:
    DB "01234567012345670123456701234567012345670123456701234567", 0x00

SCREEN_OFFSET:
    DB 0x00

    END