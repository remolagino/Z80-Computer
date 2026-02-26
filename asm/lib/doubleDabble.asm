; ------------------------------------------------------
; -                  doubleDabble.asm                  -
; -    Routines to convert binary to packed-BCD        -
; ------------------------------------------------------

    
    IFNDEF __DOUBLEDABBLE__
    DEFINE __DOUBLEDABBLE__ 1

    INCLUDE "./string.asm"

; Convert a binary byte to packed BCD
; * byte in A
; * result in DE 
DBDAB_bin2dec_byte:
    PUSH AF
    PUSH BC
    PUSH HL
    LD DE, 0x0000
    LD H, A
    LD B, 8
.dbdab_loop:
    ADD HL, HL
    LD A,E
    ADC A, A
    DAA
    LD E, A
    LD A, D
    ADC A, A
    DAA
    LD D, A
    DJNZ .dbdab_loop
    POP HL
    POP BC
    POP AF
    RET

; Convert a binary byte to packed BCD
; * byte in A
; * result in (HL) - uses 2 bytes 
DBDAB_bin2dec_byte_HL:
    PUSH DE
    PUSH HL
    CALL DBDAB_bin2dec_byte
    LD (HL), E
    INC HL
    LD (HL), D
    POP HL
    POP DE
    RET

; Convert a binary word to packed BCD
; * word in DE
; * result in (HL) - uses 3 bytes
DBDAB_bin2dec_word:
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL
    LD A, 0x00
    LD (HL), A
    INC HL
    LD (HL), A
    INC HL
    LD (HL), A
    DEC HL
    DEC HL
    LD B, 16
.dbdab_loop:
    SLA E
    RL D
    LD A, (HL)
    ADC A, A
    DAA
    LD (HL), A
    INC HL
    LD A, (HL)
    ADC A, A
    DAA
    LD (HL), A
    INC HL
    LD A, (HL)
    ADC A, A
    DAA
    LD (HL), A
    DEC HL
    DEC HL
    DJNZ .dbdab_loop
    POP HL
    POP DE
    POP BC
    POP AF
    RET


; Convert a binary dword to packed BCD
; * dword in BCDE
; * result in (HL) - uses 5 bytes
DBDAB_bin2dec_dword:
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL
    LD A, 0x00
    LD (HL), A
    INC HL
    LD (HL), A
    INC HL
    LD (HL), A
    INC HL
    LD (HL), A
    INC HL
    LD (HL), A
    DEC HL
    DEC HL
    DEC HL
    DEC HL
    EXX
    LD B, 32
.dbdab_loop:
    EXX
    SLA E
    RL D
    RL C
    RL B

    LD A, (HL)
    ADC A, A
    DAA
    LD (HL), A
    INC HL
    LD A, (HL)
    ADC A, A
    DAA
    LD (HL), A
    INC HL
    LD A, (HL)
    ADC A, A
    DAA
    LD (HL), A
    INC HL
    LD A, (HL)
    ADC A, A
    DAA
    LD (HL), A
    INC HL
    LD A, (HL)
    ADC A, A
    DAA
    LD (HL), A
    DEC HL
    DEC HL
    DEC HL
    DEC HL
    EXX
    DJNZ .dbdab_loop
    EXX
    POP HL
    POP DE
    POP BC
    POP AF
    RET


; Convert a decimal number in packed BCD to bin
; * number in (HL) - use 2 bytes
; * result in BC 
DBDAB_dec2bin_byte:
    RET

; Convert a decimal number in packed BCD to bin
; * number in (HL) - use 2 bytes
; * result in A 
DBDAB_dec2bin_word:
    RET

; Convert a decimal number in packed BCD to bin byte
; * number in (HL) - use 2 bytes
; * result in A 
DBDAB_dec2bin_dword:
    RET


; take A bytes of the BCD number in (HL) and prepare 
; a non null-terminated string in (DE). 
; (DE) at end on string forfurther concatenate
; * Input : HL : start address of BCD number
; * Reg A : number of bytes of the number to print
; * Return : string in (DE)
Dbdab_printable:
    PUSH AF
    PUSH BC
    PUSH HL
    PUSH DE
    CP 0x00
    JP Z, .finalize
    LD B, A
    DEC HL
.endOfNumberLoop:
    INC HL
    DJNZ .endOfNumberLoop
    LD B, A
.printableLoop:
    LD A, (HL) 
    CALL Bin2Hex_DE
    DEC HL
    DJNZ .printableLoop
.finalize:
    LD A, 0x00 ; added to mark end of string for remove
    LD (DE), A
    POP DE
    CALL RemoveLeadingZeros
    POP HL
    POP BC
    POP AF
    RET

RemoveLeadingZeros:
.removeLoop:
    LD A, (DE)
    CP 0x00 ; end of string reached
    JP Z, .zero
    CP '0'
    JP NZ, .gotoEndofString
    LD A, ' '
    LD (DE), A
    INC DE
    JP .removeLoop
.zero:
    DEC DE
    LD A, '0'
    LD (DE), A
    INC DE
    JP .exit
.gotoEndofString:
    INC DE
    LD A, (DE)
    CP 0x00
    JP NZ, .gotoEndofString
.exit:
    RET


; take A bytes of the BCD number in (HL) and prepare 
; a non null-terminated string in (DE). 
; (DE) at end on string for further concatenate
; * Input : HL : start address of BCD number
; * Return : string in (DE)
DBDAB_DwordCompactPrintable:
;    PUSH DE
    PUSH HL
    INC HL ; goto MSB
    INC HL
    INC HL
    INC HL
    LD A, (HL)
    CP 0x10
    JP C, .noGiga
    CALL MSnibble2Hex
    LD (DE), A
    INC DE
    LD A, '.'
    LD (DE), A
    INC DE
    LD A, (HL)
    CALL LSnibble2Hex
    LD (DE), A
    DEC HL
    INC DE
    LD A, (HL)
    CALL MSnibble2Hex
    LD (DE), A
    INC DE
    LD A, 'G'
    LD (DE), A
    JP .exit    
.noGiga:
    CP 0x00
    JP Z, .no100M
    LD A, ' '
    LD (DE), A
    INC DE
    LD A, (HL)
    CALL LSnibble2Hex
    LD (DE), A
    INC DE
    DEC HL
    LD A, (HL)
    CALL MSnibble2Hex
    LD (DE), A
    INC DE
    LD A, (HL)
    CALL LSnibble2Hex
    LD (DE), A
    INC DE
    LD A, 'M'
    LD (DE), A
    JP .exit
.no100M:
    DEC HL
    LD A, (HL)
    CP 0x10
    JP C, .no10M
    CALL MSnibble2Hex
    LD (DE), A
    INC DE
    LD A, (HL)
    CALL LSnibble2Hex
    LD (DE), A
    INC DE
    LD A, '.'
    LD (DE), A
    INC DE
    DEC HL
    LD A, (HL)
    CALL MSnibble2Hex
    LD (DE), A
    INC DE
    LD A, 'M'
    LD (DE), A
    JP .exit
.no10M:
    CP 0x00
    JP Z, .no1M
    LD A, (HL)
    CALL LSnibble2Hex
    LD (DE), A
    INC DE
    LD A ,'.'
    LD (DE), A
    INC DE
    DEC HL
    LD A, (HL)
    CALL MSnibble2Hex
    LD (DE), A
    INC DE
    LD A, (HL)
    CALL LSnibble2Hex
    LD (DE), A
    INC DE
    LD A, 'M'
    LD (DE), A
    JP .exit
.no1M:
    DEC HL
    LD A, (HL)
    CP 0x10
    JP C, .no100K
    LD A, ' '
    LD (DE), A
    INC DE
    LD A, (HL)
    CALL MSnibble2Hex
    LD (DE), A
    INC DE
    LD A, (HL)
    CALL LSnibble2Hex
    LD (DE), A
    INC DE
    DEC HL
    LD A, (HL)
    CALL LSnibble2Hex
    LD (DE), A
    INC DE
    LD A, 'K'
    LD (DE), A
    JP .exit
.no100K:
    CP 0x00
    JP Z, .no10K
    CALL LSnibble2Hex
    LD (DE), A
    INC DE
    DEC HL
    LD A, (HL)
    CALL MSnibble2Hex
    LD (DE), A
    INC DE
    LD A, '.'
    LD (DE), A
    INC DE
    LD A, (HL)
    CALL LSnibble2Hex
    LD (DE), A
    INC DE
    LD A, 'K'
    LD (DE), A
    JP .exit
.no10K:
    DEC HL
    LD A, (HL)
    CP 0x10
    JP C, .no1K
    CALL MSnibble2Hex
    LD (DE), A
    INC DE
    LD A ,'.'
    LD (DE), A
    INC DE
    LD A, (HL)
    CALL LSnibble2Hex
    LD (DE), A
    INC DE
    DEC HL
    LD A, (HL)
    CALL MSnibble2Hex
    LD (DE), A
    INC DE
    LD A, 'K'
    LD (DE), A
    JP .exit
.no1K:
    LD A, ' '
    LD (DE), A
    INC DE
    LD A, (HL)
    CALL LSnibble2Hex
    LD (DE), A
    INC DE
    DEC HL
    LD A, (HL)
    CALL MSnibble2Hex
    LD (DE), A
    INC DE
    LD A, (HL)
    CALL LSnibble2Hex
    LD (DE), A
    JP .exit
.exit:
    INC DE
;    LD A, 0x00
;    LD (DE), A
    POP HL
;    POP DE
    RET
    



    ENDIF