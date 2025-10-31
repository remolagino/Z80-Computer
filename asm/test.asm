    .ORG 0x5000

    jp main

    INCLUDE "jumpTable.inc"
    INCLUDE "serial.asm"
;    INCLUDE "string.asm"


main:
    LD HL, CR_LF
    CALL PRINT_STRING

    LD E, 0xFF
.loop:
    INC E
    CALL HEX2BCD
    LD A, H
    CALL HEX2STR ; Send the hex value of E to SIO port A
    LD A, L
    CALL HEX2STR ; Send the hex value of L to SIO port A
    LD A, 0x09
    CALL SENDCHAR_A
    LD A, E
    CP 0xFF
    JP NZ, .loop

    LD HL, CR_LF
    CALL PRINT_STRING ; Print CR LF

    RET

CR_LF DB 0x0D, 0x0A, 0x00 ; Carriage Return and Line Feed