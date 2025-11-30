; Function to edit a line
;  -Add cahracter
;  -manage backspace and delete (insert toggle)
;  - cursor keys left and right
;  - return when Enter (0x0D) is pressed

    IFNDEF __LINE_EDIT__
    DEFINE __LINE_EDIT__ 1

    include "memoryMapv2.inc"
    include "stdio.asm"


LineEdit_Init: ; zero the buffer
    PUSH AF
    PUSH BC
    PUSH HL
    LD HL, EDIT_BUFFER_ADDRESS
    LD B, EDIT_BUFFER_SIZE
    LD A, 0x00
.initLoop:
    LD (HL), A
    INC HL
    DJNZ .initLoop
    LD (HL), 0x00
    POP HL
    POP BC
    POP AF
    RET

LineEdit: ; process the char in A
; we need to track the cursor position
; start from 0
    RET


    ENDIF