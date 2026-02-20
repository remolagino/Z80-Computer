; ------------------------------------------------------
; -                  math.asm                          -
; -       addition and multiplication for dword        -
; ------------------------------------------------------

    
    IFNDEF _MATH__
    DEFINE __MATH__ 1

    INCLUDE "string.asm"

; Add a DWORD in (HL) to a DWORD in (BC)
; * result in (DE)
MATH_ADD_DWORD_TO_DWORD:
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL
    LD A, (BC)
    ADD A, (HL)
    LD (DE), A
    INC BC
    INC DE
    INC HL
    LD A, (BC)
    ADC A, (HL)
    LD (DE), A
    INC BC
    INC DE
    INC HL
    LD A, (BC)
    ADC A, (HL)
    LD (DE), A
    INC BC
    INC DE
    INC HL
    LD A, (BC)
    ADC A, (HL)
    LD (DE), A
    POP HL
    POP DE
    POP BC
    POP AF
    RET

; Add a WORD in HL to a DWORD in (BC)
; * result in (DE)
MATH_ADD_WORD_TO_DWORD:
    PUSH AF
    PUSH BC
    PUSH DE
    LD A, (BC)
    ADD A, L
    LD (DE), A
    INC BC
    INC DE
    LD A, (BC)
    ADC A, H
    LD (DE), A
    INC BC
    INC DE
    LD A, (BC)
    ADC A, 0x00
    LD (DE), A
    INC BC
    INC DE
    LD A, (BC)
    ADC A, 0x00
    LD (DE), A
    POP DE
    POP BC
    POP AF
    RET

; Substract a WORD in HL to a DWORD in (BC)
; * result in (DE)
MATH_SUB_WORD_TO_DWORD:
    PUSH AF
    PUSH BC
    PUSH DE
    LD A, (BC)
    SUB L
    LD (DE), A
    INC BC
    INC DE
    LD A, (BC)
    SBC A, H
    LD (DE), A
    INC BC
    INC DE
    LD A, (BC)
    SBC A, 0x00
    LD (DE), A
    INC BC
    INC DE
    LD A, (BC)
    SBC A, 0x00
    LD (DE), A
    POP DE
    POP BC
    POP AF
    RET



; Mutliply a word in HL by a Byte in A
; * Result is a DWORD in (BC)
MATH_MULT_WORD_BYTE:
; clean the result Dword
    PUSH AF
    PUSH BC
    LD A, 0x00
    LD (BC), A
    INC BC
    LD (BC), A
    INC BC
    LD (BC), A
    INC BC
    LD (BC), A
    POP BC
    POP AF
; check if a is zero
    CP 0x00
    RET Z
;multiply loop
    PUSH AF
    PUSH DE
    LD D, B
    LD E, C
.multLoop:
    CALL MATH_ADD_WORD_TO_DWORD
    DEC A
    JP NZ, .multLoop
    POP DE
    POP AF
    RET

; Shift right a dword in (BC)
; * Number of shift in A
; * Result in (DE)
MATH_SHIFT_RIGHT_DWORD_BY_N:
    PUSH BC
    PUSH DE
    PUSH DE
    PUSH AF
    LD A, (BC)
    LD E, A
    INC BC
    LD A, (BC)
    LD D, A
    INC BC
    LD A, (BC)
    LD L, A
    INC BC
    LD A, (BC)
    LD H, A
    POP AF
    OR A
    JP Z, .shiftEnd ; no shift if 0
    LD B, A
.shiftLoop:
    SRL H
    RR L
    RR D
    RR E
    DJNZ .shiftLoop
.shiftEnd:
    LD B, D
    LD C, E
    
    POP DE
    LD A, C
    LD (DE), A
    INC DE
    LD A, B
    LD (DE), A
    INC DE
    LD A, L
    LD (DE), A
    INC DE
    LD A, H
    LD (DE), A
    POP DE
    POP BC
    RET

; Format a DWORD in (BC) as printable string in (DE) (10 char long + 0x00)
MATH_DWORD_TO_STRING
    PUSH AF
    PUSH BC
    PUSH DE
    LD A, '0'
    LD (DE), A
    INC DE
    LD A, 'x'
    LD (DE), A
    INC DE
    INC BC
    INC BC
    INC BC
    LD A, (BC)
    CALL Bin2Hex_DE
    DEC BC
    LD A, (BC)
    CALL Bin2Hex_DE
    DEC BC
    LD A, (BC)
    CALL Bin2Hex_DE
    DEC BC
    LD A, (BC)
    CALL Bin2Hex_DE
    LD A, 0x00
    LD (DE), A
    POP DE
    POP BC
    POP AF
    RET

; Format a WORD in BC as printable string in (DE) (10 char long + 0x00)
MATH_WORD_TO_STRING
    PUSH AF
    PUSH BC
    PUSH DE
    LD A, '0'
    LD (DE), A
    INC DE
    LD A, 'x'
    LD (DE), A
    INC DE
    LD A, B
    CALL Bin2Hex_DE
    LD A, C
    CALL Bin2Hex_DE
    LD A, 0x00
    LD (DE), A
    POP DE
    POP BC
    POP AF
    RET


    ENDIF

