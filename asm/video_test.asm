; V9938 Blue Screen Test Program for Z80
RAM_START EQU 0x4000 ; Start of RAM
; ======= Keypad Variables =======

MODIFER_STATE EQU RAM_START + 0x0100 ; 1 byte
MODIFERS EQU RAM_START + 0x0101 ; 1 byte
KEYPAD_BUFFER EQU RAM_START + 0x0102 ; 4 characters buffer
KEYPAD_STATE EQU RAM_START + 0x0110 ; Keypad state - ROWs * COLS bytes


        ORG     0x5000          ; Start address

; V9938 Port definitions
VRAM_DATA EQU   0x40            ; PORT #0 - VRAM data port
VRAM_ADDR EQU   0x41            ; PORT #1 - VRAM Address 
VDP_STAT_REG EQU   0x41            ; PORT #1 - Status Register 
VDP_REG_SETUP EQU   0x41            ; PORT #1 - Register Setup

VDP_PAL_REG   EQU   0x42            ; PORT #2 - Palette Register port (MODE1)
VDP_REG_INDIR EQU   0x43            ; PORT #3 - Register Indirect Addressing 

COLOR_MAP_BASE_ADDR EQU 0x0A00 ; Base address of color table in VRAM
PATTERN_LAYOUT_TABLE_ADDR EQU 0x0000 ; Base address of pattern name table in VRAM
  include "jumpTable.inc"

    JP START

    include "serial.asm"
    include "keypad.asm"
    include "stdio.asm"


CURSOR_IDX:
    DW 0 ; row 0, col 0

START:
;    LD D, 'X' ; character to write
    CALL INIT_PATTERN_LAYOUT_TABLE
    CALL INIT_COLOR_TABLE
    LD A, 0x03
    LD (STREAM_SELECT), A
    LD HL, 0x0060
    CALL SET_VRAM_ADDR
    LD HL, TestMsg
    CALL PUTS  ; ##### SOMETHING TO FIX HERE 
;    CALL WRITE_RAM
    LD C, 0x01
    CALL SET_BLINK

    LD B, 0
.eventLoop:
;    CALL DISPLAY_KEYPAD_STATE
;    CALL DISPLAY_KEYPAD_BUFFER
    CALL Keypad_Scan2
    CALL ReceiveCharNB_A

    CP 0x00
    JP Z, .eventLoop ; No key pressed, continue loop

    ; CALL HEX2STR
    ; PUSH AF
    ; LD A, ' '
    ; CALL SENDCHAR_A
    ; POP AF

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
    CP 0x0D ; Enter key
    JP Z, .enterKey
    CP 0x08 ; Backspace key
    JP Z, .backSpace


    LD D, A
    CALL WRITE_RAM
    LD C, 0x00
    CALL SET_BLINK ; unset blink at current position
    LD HL, (CURSOR_IDX)
    INC HL
    LD (CURSOR_IDX), HL
    LD C, 0x01
    CALL SET_BLINK ; set blink at new position
    JP .eventLoop
        LD C, 0x00
    CALL SET_BLINK ; unset blink at current position

.enterKey:
    LD C, 0x00
    CALL SET_BLINK ; unset blink at current position
; Compute the index of the beginning of the next line
    PUSH HL
    OR A ; clear carry
    LD DE, 80
    LD HL, (CURSOR_IDX)
.numberOfRowsLoop:
    SBC HL, DE
    JP M, .beginningOfScreen ; if negative, we are at the beginning of the screen
    JP .numberOfRowsLoop
.beginningOfScreen:
    LD DE, HL
    LD HL, (CURSOR_IDX)
    OR A ; clear carryBonjour
    SBC HL, DE
    LD (CURSOR_IDX), HL
    POP HL

    LD C, 0x01
    CALL SET_BLINK ; set blink at new position
    JP .eventLoop

.backSpace:
    LD C, 0x00
    CALL SET_BLINK ; unset blink at current position
    LD HL, (CURSOR_IDX)
    DEC HL
    LD (CURSOR_IDX), HL
    LD D, ' '
    CALL WRITE_RAM
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

; Delay:
;     PUSH BC
;     LD B, 255
; .loop:
;     NOP
;     NOP
;     DJNZ .loop
;     POP BC
;     RET

SCREEN_OFFSET:
    DB 0x00

WRITE_REG: ; REG number in C, Value in A
    PUSH AF
    ;PUSH BC
    ;DI
    OUT (VDP_REG_SETUP), A
    LD A, C
    OR 0x80
    ;EI
    OUT (VDP_REG_SETUP), A
    ;POP BC
    POP AF
    RET

WRITE_REG_INDIRECT: ; REG number in A (add +128 for no auto increment), Values in (HL), number of values in B
    LD C, 17 ; 17: indirect register number
    CALL WRITE_REG

    LD C, VDP_REG_INDIR        ; you can also write ld bc,#nn9B, which is faster
    OTIR
    RET

INIT_PATTERN_LAYOUT_TABLE: ; write at adress 0x0000
    PUSH AF
    PUSH BC
    PUSH HL

    LD HL, PATTERN_LAYOUT_TABLE_ADDR
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
    LD HL, COLOR_MAP_BASE_ADDR
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

SET_VRAM_ADDR: ; Set VRAM address from HL
    PUSH AF
    PUSH BC
    PUSH HL
    LD A, H
    RLCA
    RLCA
    AND 0x03 ; keep only A14 et A15 in the 2 rightmost positions

    LD C, 14
;    LD A, 0x00 ; Set Address A16-A15-A14
    CALL WRITE_REG
    LD A, L
;    LD A, 0x00 ; Set Address A7..A0

    OUT (VRAM_ADDR), A

    LD A, H
    AND 0x3F ; keep only A13..A8
    OR 0x40 ; data write mode
    OUT (VRAM_ADDR), A
    POP HL
    POP BC
    POP AF
    RET

SET_BLINK: ; set or unset blink at address (CURSOR_IDX) based on C value (0: unset, 1: set)
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL

    LD HL, (CURSOR_IDX)
    LD A, L
    AND 0x07 ; get the 3 lowest bits to shift the blink to the right position
    ADD A, 1; make sure there is only one shift when offset is 0
    LD B, A ; save shift count in B

    SRL H ; divide HL by 8 to get the index 
    RR L  ; in the color table of the byte 
    SRL H ; containing the char to blink
    RR L
    SRL H
    RR L 

    LD DE, COLOR_MAP_BASE_ADDR
    ADD HL, DE ; compute the address in VRAM of the color byte
    CALL SET_VRAM_ADDR

    LD A, C
.shift_loop:  ; Shift the blink  to the right position
    RRCA
    DJNZ .shift_loop
    OUT (VRAM_DATA), A

    POP HL
    POP DE
    POP BC
    POP AF
    RET


WRITE_RAM: ; write at adress (CURSOR_IDX) the character in reg D
    PUSH AF
    ; PUSH BC
    PUSH HL

    LD HL, (CURSOR_IDX)
    CALL SET_VRAM_ADDR
    LD A, D ; value to write to VRAM
    OUT (VRAM_DATA), A

    POP HL
    ; POP BC
    POP AF
    RET
    
DISPLAY_KEYPAD_BUFFER:
    PUSH AF
    PUSH BC
    PUSH HL

    LD HL, 0x0000
    CALL SET_VRAM_ADDR

    LD HL, KEYPAD_BUFFER
    LD B, 4 
.display_loop:
    LD A, (HL)
    OUT (VRAM_DATA), A
    INC HL
    DJNZ .display_loop

    POP HL
    POP BC
    POP AF
    RET

DISPLAY_KEYPAD_STATE:
    PUSH AF
    PUSH BC
    PUSH HL
    LD HL, 160
    CALL SET_VRAM_ADDR
    LD HL, KEYPAD_STATE
    LD B, KEYPAD_COLUMNS * KEYPAD_ROWS 
.display_loop:
    LD A, (HL)
    CP 0x01
    JR Z, .printPressed
    LD A, '.' ; not pressed
    JR .displayChar
.printPressed:
    LD A, '#' ; pressed
.displayChar:
    OUT (VRAM_DATA), A
    INC HL
    DJNZ .display_loop

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
    LD HL, (CURSOR_IDX) ; check if possible to move left
    LD A, H
    OR L
    RET Z ; if at left edge, do nothing

    ; LD D, ' '
    ; CALL WRITE_RAM
    LD C, 0x00
    CALL SET_BLINK ; unset blink before moving
    LD HL, (CURSOR_IDX)
    DEC HL
    LD (CURSOR_IDX), HL
    ; LD D, 'X'
    ; CALL WRITE_RAM
    LD C, 0x01
    CALL SET_BLINK ; set blink at new position
    RET
    
GO_RIGHT:
    LD DE, (CURSOR_IDX) ; check if possible to move right
    LD HL, 80*26-1
    OR A
    SBC HL, DE
    LD A, H
    OR L
    RET Z ; if at left edge, do nothing

    ; LD D, ' '
    ; CALL WRITE_RAM
    LD C, 0x00
    CALL SET_BLINK ; unset blink before moving
    LD HL, (CURSOR_IDX)
    INC HL
    LD (CURSOR_IDX), HL
    ; LD D, 'X'
    ; CALL WRITE_RAM
    LD C, 0x01
    CALL SET_BLINK ; set blink at new position
    RET

GO_UP:
    LD HL, (CURSOR_IDX) ; check if possible to move right
    LD DE, 80
    OR A
    SBC HL, DE
    RET M ; if at left edge, do nothing

    ; LD D, ' '
    ; CALL WRITE_RAM
    LD C, 0x00
    CALL SET_BLINK ; unset blink before moving
    LD HL, (CURSOR_IDX)
    LD DE, 80 ; move up one row
    OR A ; clear carry
    SBC HL, DE
    LD (CURSOR_IDX), HL
    ; LD D, 'X'
    ; CALL WRITE_RAM
    LD C, 0x01
    CALL SET_BLINK ; set blink at new position
    RET

GO_DOWN:
    LD DE, (CURSOR_IDX) ; check if possible to move right
    LD HL, 80*25-1
    OR A
    SBC HL, DE
    RET M ; if at left edge, do nothing

    ; LD D, ' '
    ; CALL WRITE_RAM
    LD C, 0x00
    CALL SET_BLINK ; unset blink before moving
    LD HL, (CURSOR_IDX)
    LD DE, 80 ; move down one row
    ADD HL, DE
    LD (CURSOR_IDX), HL
    ; LD D, 'X'
    ; CALL WRITE_RAM
    LD C, 0x01
    CALL SET_BLINK ; set blink at new position
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
    DB "This is a test message !!", 0x00


    END