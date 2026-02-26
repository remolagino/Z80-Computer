; ------------------------------------------------------
; -                   dbdab_test.asm                   -
; -        Test for doubleDabble.asm library           -
; ------------------------------------------------------

    .ORG 0x4000

    JP Main
    INCLUDE "./monitorv2/memoryMapv2.inc"
    INCLUDE "./lib/doubleDabble.asm"
    INCLUDE "./lib/stdio.asm"
    INCLUDE "./lib/string.asm"


Main:
    LD BC, 0x7735
    LD DE, 0x93f0
    LD A, 0x00
.loop:
    ; LD HL, DBDAB_DECIMAL
    ; CALL DBDAB_bin2dec_byte_HL

    ; LD HL, DBDAB_DECIMAL
    ; CALL DBDAB_bin2dec_word

    LD HL, DBDAB_DECIMAL
    CALL DBDAB_bin2dec_dword
    PUSH DE
    PUSH HL
;    LD A, 3
    LD DE, DBDAB_WORKSPACE
    LD HL, DBDAB_DECIMAL
;    CALL Dbdab_printable
    CALL DBDAB_DwordCompactPrintable
    LD HL, (CURSOR_IDX)
    CALL PutS
    LD A, 0x09
    CALL PutC
    LD (CURSOR_IDX), HL
    POP HL
    POP DE

    INC E
    LD A, E
    CP 0x00
    JP NZ, .loop

    PUSH HL
    LD HL, (CURSOR_IDX)
    LD DE, LF_CR
    CALL PutS
    LD (CURSOR_IDX), HL
    POP HL

    RET
    

; print number in (HL)
Dbdab_print_byte:
    PUSH AF
    PUSH DE
    PUSH HL
    LD DE, DBDAB_WORKSPACE
    INC HL
    LD A, (HL) 
    CALL Bin2Hex_DE
    DEC HL
    LD A, (HL)
    CALL Bin2Hex_DE
    LD A, 0x00
    LD (DE), A
    LD HL, (CURSOR_IDX)
    LD DE, DBDAB_WORKSPACE
    CALL RemoveLeadingZeros
    CALL PutS
    LD A, 0x09
    CALL PutC
    LD (CURSOR_IDX), HL
    POP HL
    POP DE
    POP AF
    RET

; print number in (HL)
Dbdab_print_word:
    PUSH AF
    PUSH DE
    PUSH HL
    LD DE, DBDAB_WORKSPACE
    INC HL
    INC HL
    LD A, (HL) 
    CALL Bin2Hex_DE
    DEC HL
    LD A, (HL)
    CALL Bin2Hex_DE
    DEC HL
    LD A, (HL)
    CALL Bin2Hex_DE
    LD A, 0x00
    LD (DE), A
    LD HL, (CURSOR_IDX)
    LD DE, DBDAB_WORKSPACE
    CALL RemoveLeadingZeros
    CALL PutS
    LD A, 0x09
    CALL PutC
    LD (CURSOR_IDX), HL
    POP HL
    POP DE
    POP AF
    RET


; print number in (HL)
Dbdab_print_dword:
    PUSH AF
    PUSH DE
    PUSH HL
    LD DE, DBDAB_WORKSPACE
    INC HL
    INC HL
    INC HL
    INC HL
    LD A, (HL) 
    CALL Bin2Hex_DE
    DEC HL
    LD A, (HL)
    CALL Bin2Hex_DE
    DEC HL
    LD A, (HL)
    CALL Bin2Hex_DE
    DEC HL
    LD A, (HL)
    CALL Bin2Hex_DE
    DEC HL
    LD A, (HL)
    CALL Bin2Hex_DE
    LD A, 0x00
    LD (DE), A
    LD DE, DBDAB_WORKSPACE
    CALL RemoveLeadingZeros
    LD HL, (CURSOR_IDX)
    CALL PutS
    LD A, 0x09
    CALL PutC
    LD (CURSOR_IDX), HL
    POP HL
    POP DE
    POP AF
    RET

; RemoveLeadingZeros:
;     PUSH DE
; .removeLoop:
;     LD A, (DE)
;     CP 0x00 ; end of string reached
;     JP Z, .zero
;     CP '0'
;     JP NZ, .exit
;     LD A, ' '
;     LD (DE), A
;     INC DE
;     JP .removeLoop
; .zero:
;     DEC DE
;     LD A, '0'
;     LD (DE), A
; .exit:
;     POP DE
;     RET


LF_CR:
    DB 0x0A, 0x0D, 0x00

DBDAB_DECIMAL:
    BLOCK 0x10, '='
DBDAB_WORKSPACE:
    BLOCK 0x20, '@'