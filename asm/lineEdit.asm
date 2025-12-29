; Function to edit a line
;  - Add character
;  - manage backspace and delete (insert toggle)
;  - cursor keys left and right
;  - cursor keys up and down do nothing for now
;  - return when Enter (0x0D) is pressed
;  - the loop is managed by line edit itself
;  - exit the loop and give back control when enter is pressed

    IFNDEF __LINE_EDIT__
    DEFINE __LINE_EDIT__ 1

    include "memoryMapv2.inc"
    include "stdio.asm"
    include "string.asm"


; LineEdit_Init: ; zero the buffer
;     PUSH AF
;     PUSH BC
;     PUSH HL
;     LD HL, LINE_EDIT_BUFFER_ADDRESS
;     LD B, LINE_EDIT_BUFFER_SIZE+1
;     LD A, 0x00
; .initLoop:
;     LD (HL), A
;     INC HL
;     DJNZ .initLoop
;     ; LD HL, 0x0000
;     ; LD (LineEdit_CURSOR_IDX), HL ; reset cursor idx
;     ; LD HL, 80*15
;     ; LD (LineEdit_LineStart), HL ; reset line start
;     LD A, 0x00
;     LD (LINE_EDIT_INSERT_MODE), A ; insert mode off
;     POP HL
;     POP BC
;     POP AF
;     RET

LineEdit: ;handle line editing (display at HL), exit when Enter is pressed
    LD (LINE_EDIT_LINESTART), HL
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL
    PUSH IX

; Initialise the buffer and variables
    LD HL, LINE_EDIT_BUFFER_ADDRESS
    LD B, LINE_EDIT_BUFFER_SIZE+1
    LD A, 0x00
.initLoop:
    LD (HL), A
    INC HL
    DJNZ .initLoop
    LD A, 0x00
    LD (LINE_EDIT_INSERT_MODE), A ; insert mode off
; end of init

    LD HL, (LINE_EDIT_LINESTART)
    LD DE, MSG_EDITING_EmptyBuffer
    CALL PutS
    LD HL, (LINE_EDIT_LINESTART); replace cursor at line start
 
;   init cursor idx at 0
    LD D, 0x00
    LD E, 0x00
    LD IX, LINE_EDIT_BUFFER_ADDRESS
;    LD HL, 80*15

.lineEditLoop:  
    CALL GetC
    CP 0x00
    JP Z, .displayCursor ; No key pressed, continue loop
; switch off the cursor blink before processing the key
    PUSH BC
    PUSH HL
    LD HL, (LINE_EDIT_LINESTART)
    ADD HL, DE
    LD C, 0x00
    CALL Set_Blink ; unset blink at current position
    POP HL
    POP BC

    CP ENTER_KEY_CODE
    JP Z, .exit
    CP UP_KEY_CODE
    JP Z, .upCursorProcess ; 
    CP DOWN_KEY_CODE
    JP Z, .downCursorProcess ; 
    CP LEFT_KEY_CODE
    JP Z, .leftCursorProcess ; 
    CP RIGHT_KEY_CODE
    JP Z, .rightCursorProcess ; 
    CP BKSP_KEY_CODE
    JP Z, .backspaceProcess ; 
    CP DELETE_KEY_CODE
    JP Z, .deleteProcess ; 
    CP INSERT_KEY_CODE
    JP Z, .insertProcess ; 

; add the character to the buffer
    LD B, A ; temporary save of the character to add
    LD A, (LINE_EDIT_INSERT_MODE)
    OR A
    JP Z, .overwriteMode ; insert mode off
.insertMode:
    PUSH BC
    PUSH DE
    PUSH HL
    LD HL, LINE_EDIT_BUFFER_ADDRESS
    CALL STRING_LENGTH
    SUB LINE_EDIT_BUFFER_SIZE
    JP Z, .insertModeBufferFull ; buffer full, do nothing
    LD A, LINE_EDIT_BUFFER_SIZE
    SUB E
    LD B, 0x00
    LD C, A
    LD HL, LINE_EDIT_BUFFER_END-1
    LD DE, LINE_EDIT_BUFFER_END
    LDDR
    POP HL
    POP DE
    POP BC
    LD A, B ; restore character to add
    LD (IX), A

    PUSH DE
    PUSH HL
    PUSH IX
    POP DE
    CALL PutS ; increment HL on its own
    POP HL
    POP DE
    INC HL
    INC IX ; memory pointer to the proper spot in the buffer
    INC DE ; cursor idx in buffer
     JP .displayCursor
.insertModeBufferFull:
    POP HL
    POP DE
    POP BC
    JP .displayCursor
.overwriteMode:
    LD A, LINE_EDIT_BUFFER_SIZE
    SUB E
    JP Z, .displayCursor ; buffer full, do nothing
    LD A, B ; restore character to add
    LD (IX), A
    INC IX ; memory pointer to the proper spot in the buffer
    INC DE ; cursor idx in buffer
    CALL PutC ; increment HL on its own
    JP .displayCursor
.upCursorProcess:
    JP .displayCursor
.downCursorProcess:
    JP .displayCursor
.leftCursorProcess:
    LD A, D ; DE contains cursor idx in buffer
    OR E
    JP Z, .displayCursor ; if at beginning of line, do nothing
    DEC IX
    DEC E
;    DEC HL
    LD A, LEFT_KEY_CODE
    CALL PutC
    JP .displayCursor
.rightCursorProcess:
    LD A, (IX)
    OR A
    JP Z, .displayCursor ; if at end of buffer, do nothing
    INC IX
    INC E
;    INC HL
    LD A, RIGHT_KEY_CODE
    CALL PutC
    JP .displayCursor
.backspaceProcess:
    LD A, E
    OR A
    JP Z, .displayCursor ; if at beginning of line, do nothing

    PUSH BC
    PUSH DE
    PUSH HL

    PUSH IX
    POP HL
    LD DE, HL
    DEC DE
.backspaceLoop:
    LDI
    LD A, (DE)
    OR A
    JP NZ, .backspaceLoop ;

    POP HL
    POP DE
    POP BC

    DEC IX
;    DEC HL
    LD A, BKSP_KEY_CODE
    CALL PutC
    DEC E

    PUSH HL
    PUSH DE
    PUSH IX
    POP DE
    CALL PutS
    LD A, ' ' ; clear last char
    CALL PutC
    POP DE
    POP HL
    JP .displayCursor
.deleteProcess:
    LD A, (IX)
    OR A
    JP Z, .displayCursor ; if at end of line, do nothing

    PUSH BC
    PUSH DE
    PUSH HL

    PUSH IX
    POP HL
    LD DE, HL
    INC HL
.deleteLoop:
    LDI
    LD A, (DE)
    OR A
    JP NZ, .deleteLoop ;

    POP HL
    POP DE
    POP BC

    PUSH HL
    PUSH DE
    PUSH IX
    POP DE
    CALL PutS
    LD A, ' ' ; clear last char
    CALL PutC
    POP DE
    POP HL
    JP .displayCursor
.insertProcess:
    LD A, (LINE_EDIT_INSERT_MODE)
    XOR 0x01
    LD (LINE_EDIT_INSERT_MODE), A
    JP .displayCursor
.displayCursor:
    PUSH BC
    PUSH HL
    LD HL, (LINE_EDIT_LINESTART)
    ADD HL, DE
    LD C, 0x01
    CALL Set_Blink ; set blink at new position
    POP HL
    POP BC
    JP .lineEditLoop
.exit:
    POP IX
    POP HL
    POP DE
    POP BC
    POP AF
    RET


; display_test:
;     PUSH HL
;     PUSH DE
;     PUSH AF
; ; display the buffer
;     LD HL, 80*20+8
;     LD DE, EDIT_BUFFER_ADDRESS
;     CALL PutS
;     LD A, '<'
;     CALL PutC
;     LD A, ' '
;     CALL PutC
; ; display buffer position
;     LD HL, (LineEdit_CURSOR_IDX)
;     LD E, L
;     CALL Hex2BCD
;     LD DE, HL
;     LD HL, 80*21+17
;     LD A, D
;     CALL Hex2Str 
;     LD A, E
;     CALL Hex2Str
; ; display buffer length
;     LD HL, EDIT_BUFFER_ADDRESS
;     CALL STRING_LENGTH
;     LD E, A
;     CALL Hex2BCD
;     LD DE, HL
;     LD HL, 80*21+45
;     LD A, D
;     CALL Hex2Str 
;     LD A, E
;     CALL Hex2Str
; ; display insert mode
;     LD HL, 80*22+14
;     LD A, (LineEdit_INSERT_MODE)
;     ADD A, '0'
;     CALL PutC
;     POP AF
;     POP DE
;     POP HL
;     RET



; display_BCD: ; number to display in A
;     PUSH AF
;     PUSH DE
;     PUSH HL
;     LD E, A
;     CALL HEX2BCD
;     LD A, H
;     CALL HEX2STR
;     LD A, L
;     CALL HEX2STR
;     LD A, ' '
;     CALL SENDCHAR_A
;     POP HL
;     POP DE
;     POP AF
;     RET

; MSG_EDITING_BufferPos:
;     DB "buffer pos (E) :           - Buffer Length : ", 0x00
; MSG_EDITING_InsertMode:
;     DB "insert mode : ", 0x00
; MSG_EDITING_Buffer:
;     DB "Buffer >                                                               ", 0x00
MSG_EDITING_EmptyBuffer:
    DB "                                                                                ", 0x00


    ENDIF