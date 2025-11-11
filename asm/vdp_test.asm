; V9938 Blue Screen Test Program for Z80
RAM_START EQU 0x4000 ; Start of RAM
; ======= Keypad Variables =======

MODIFER_STATE EQU RAM_START + 0x0100 ; 1 byte
MODIFERS EQU RAM_START + 0x0101 ; 1 byte
KEYPAD_BUFFER EQU RAM_START + 0x0102 ; 4 characters buffer
KEYPAD_STATE EQU RAM_START + 0x0110 ; Keypad state - ROWs * COLS bytes


        ORG     0x5000          ; Start address

; ; V9938 Port definitions
; VRAM_DATA EQU   0x40            ; PORT #0 - VRAM data port
; VRAM_ADDR EQU   0x41            ; PORT #1 - VRAM Address 
; VDP_STAT_REG EQU   0x41            ; PORT #1 - Status Register 
; VDP_REG_SETUP EQU   0x41            ; PORT #1 - Register Setup

; VDP_PAL_REG   EQU   0x42            ; PORT #2 - Palette Register port (MODE1)
; VDP_REG_INDIR EQU   0x43            ; PORT #3 - Register Indirect Addressing 

; COLOR_MAP_BASE_ADDR EQU 0x0A00 ; Base address of color table in VRAM
; PATTERN_LAYOUT_TABLE_ADDR EQU 0x0000 ; Base address of pattern name table in VRAM
  include "jumpTable.inc"

    JP START

    include "serial.asm"
    include "keypad.asm"
    include "stdio.asm"
    include "vdp_core.asm"


CURSOR_IDX:
    DW 0 ; row 0, col 0

START:

    LD HL, CR_LF
    CALL PRINT_STRING
    LD HL, TestMsg
    CALL PRINT_STRING
    LD HL, CR_LF
    CALL PRINT_STRING
    LD HL, CR_LF
    CALL PRINT_STRING


;    LD D, 'X' ; character to write
    CALL INIT_PATTERN_LAYOUT_TABLE
    CALL INIT_COLOR_TABLE

    LD A, STREAM_OUT_VDP|STREAM_OUT_SERIAL
    LD (STREAM_SELECT), A

    ; LD HL, 0x0060
    ; CALL SET_VRAM_ADDR

    LD HL, 320
    LD DE, MeasureMsg
; .stringLoop:
;     LD A, (DE)
;     OR A
;     JP Z, .stringLoopEnd
;     CALL PUTC
;     INC DE
;     JP .stringLoop
; .stringLoopEnd:
    CALL PUTS

    PUSH HL
    LD HL, CR_LF
    CALL PRINT_STRING
    POP HL

    LD HL, 400
    LD DE, TestMsg
; .stringLoop1:
;     LD A, (DE)
;     OR A
;     JP Z, .stringLoopEnd1
;     CALL PUTC
;     INC DE
;     JP .stringLoop1
; .stringLoopEnd1:
    CALL PUTS

    LD B, 0
    LD HL, (CURSOR_IDX) ; put the cursor at 0
    LD C, 0x01
    CALL SET_BLINK

.eventLoop:
;    CALL DISPLAY_KEYPAD_STATE
;    CALL DISPLAY_KEYPAD_BUFFER
    CALL Keypad_Scan2
    CALL ReceiveCharNB_A

    CP 0x00
    JP Z, .eventLoop ; No key pressed, continue loop

    CP '0'
    JP Z, .endLoop
    CP '6'
    JP Z, .right
    CP '4'
    JP Z, .left
    CP '2'
    JP Z, .down
    CP '8'
    JP Z, .up
    CP '9'
    JP Z, .screenVertical
    CP '3'
    JP Z, .screenHorizontal
    CP '5'
    JP Z, .rotateColor
    CP 0x0D      ; Enter key
    JP Z, .enterKey
    CP 0x08      ; Backspace key
    JP Z, .backSpace

    LD HL, (CURSOR_IDX)
    LD C, 0x00
    CALL SET_BLINK ; unset blink at current position
    CALL PUTC
    LD (CURSOR_IDX), HL
    LD C, 0x01
    CALL SET_BLINK ; set blink at new position
    JP .eventLoop


.enterKey:
    LD HL, (CURSOR_IDX)
    LD C, 0x00
    CALL SET_BLINK ; unset blink at current position
    LD A, 0x0A
    CALL PUTC
    LD A, 0x0D
    CALL PUTC
    LD (CURSOR_IDX), HL
    LD C, 0x01
    CALL SET_BLINK ; set blink at new position
    JP .eventLoop

.backSpace:
    LD C, 0x00
    LD HL, (CURSOR_IDX)
    CALL SET_BLINK ; unset blink at current position
;    DEC HL
;    LD (CURSOR_IDX), HL
    LD A, 0x08
    CALL PUTC
    LD (CURSOR_IDX), HL
    LD C, 0x01
    CALL SET_BLINK ; set blink at new position
    JP .eventLoop

.rotateColor:
    LD      C, 7
    LD      A, 0xF0         ; Text color: white (F) 
    OR B ; put B color in background
    CALL    WRITE_REG
    INC B
    LD A, B
    AND 0x0F
    LD B, A
    JP .eventLoop
.left:
    CALL GO_LEFT
    JP .eventLoop
.right:
    CALL GO_RIGHT
    JP .eventLoop
.up:
    CALL GO_UP
    JP .eventLoop
.down:
    CALL GO_DOWN
    JP .eventLoop

.screenVertical:
    LD      C, 18
    LD A, (SCREEN_OFFSET)
    ADD A, 0x10
    AND A, 0xF0
    LD B, A
    LD A, (SCREEN_OFFSET)
    AND 0x0F
    OR B
;    CALL HEX2STR
    LD (SCREEN_OFFSET), A
    CALL    WRITE_REG

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
    CALL    WRITE_REG

    JP .eventLoop

.endLoop:
    LD HL, CR_LF
    CALL PRINT_STRING
    RET                     ; or HALT


SCREEN_OFFSET:
    DB 0x00


INIT_PATTERN_LAYOUT_TABLE: ; write at adress 0x0000
    PUSH AF
    PUSH BC
    PUSH HL

    LD HL, PATTERN_LAYOUT_TABLE_BASE_ADDR
    CALL SET_VRAM_ADDR

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
    CALL SET_VRAM_ADDR

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

    
OnKeyPressed:
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL

    LD HL, PressedMsg
    CALL PRINT_STRING
    CALL SendChar_IX
    LD HL, CR_LF
    CALL PRINT_STRING

    LD A, (IX)
    CP '4'
    CALL Z, GO_LEFT
    CP '6'
    CALL Z, GO_RIGHT
    CP '8'
    CALL Z, GO_UP
    CP '2'
    CALL Z, GO_DOWN
.continue:
    POP HL
    POP DE
    POP BC
    POP AF
    RET

GO_LEFT:
    PUSH AF
    PUSH BC
    PUSH HL
    LD HL, (CURSOR_IDX) ; check if possible to move left
    LD A, H
    OR L
    JP Z, .leftExit ; if at left edge, do nothing

    LD C, 0x00
    CALL SET_BLINK ; unset blink before moving
    LD HL, (CURSOR_IDX)
    DEC HL
    LD (CURSOR_IDX), HL

    LD C, 0x01
    CALL SET_BLINK ; set blink at new position
.leftExit:
    POP HL
    POP BC
    POP AF
    RET
    
GO_RIGHT:
    PUSH DE
    PUSH HL
    LD DE, (CURSOR_IDX) ; check if possible to move right
    LD HL, 80*26-1
    OR A
    SBC HL, DE
    LD A, H
    OR L
    JP Z, .rightExit ; if at bottom right edge, do nothing
    LD HL, (CURSOR_IDX)
    LD C, 0x00
    CALL SET_BLINK ; unset blink before moving
    LD HL, (CURSOR_IDX)
    INC HL
    LD (CURSOR_IDX), HL
    LD C, 0x01
    CALL SET_BLINK ; set blink at new position
.rightExit:
    POP HL
    POP DE
    RET

GO_UP:
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL
    LD HL, (CURSOR_IDX) ; check if possible to move up
    LD DE, 80
    OR A
    SBC HL, DE
    JP M, .upExit ; if at top edge, do nothing
    LD HL, (CURSOR_IDX)
    LD C, 0x00
    CALL SET_BLINK ; unset blink before moving
    LD HL, (CURSOR_IDX)
    LD DE, 80 ; move up one row
    OR A ; clear carry
    SBC HL, DE
    LD (CURSOR_IDX), HL
    LD C, 0x01
    CALL SET_BLINK ; set blink at new position
.upExit:
    POP HL
    POP DE
    POP BC
    POP AF
    RET

GO_DOWN:
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL
    LD DE, (CURSOR_IDX) ; check if possible to move right
    LD HL, 80*25-1
    OR A
    SBC HL, DE
    JP M, .downExit ; if at left edge, do nothing
    LD HL, (CURSOR_IDX)
    LD C, 0x00
    CALL SET_BLINK ; unset blink before moving
    LD HL, (CURSOR_IDX)
    LD DE, 80 ; move down one row
    ADD HL, DE
    LD (CURSOR_IDX), HL
    LD C, 0x01
    CALL SET_BLINK ; set blink at new position
.downExit:
    POP HL
    POP DE
    POP BC
    POP AF
    RET

OnKeyReleased:
    PUSH HL
    LD HL, ReleasedMsg
    CALL PRINT_STRING
    CALL SendChar_IX
    LD HL, CR_LF
    CALL PRINT_STRING
    POP HL
    RET

CR_LF:
    DB 0x0A, 0x0D, 0x00 ; Carriage return + line feed

PressedMsg:
    DB 'Key Pressed : ', 0x00
ReleasedMsg:
    DB 'Key Released : ', 0x00
TestMsg:
    DB "This.", 0x09,"is.a.te", 0x08, "st mess", 0x09, "age.!!", 0x0D,  "Prout prout !", 0x00,0x0A
MeasureMsg:
    DB "01234567012345670123456701234567012345670123456701234567", 0x00

    END