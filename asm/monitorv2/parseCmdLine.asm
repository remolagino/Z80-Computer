    IFNDEF __PARSE_CMD_LINE__
    DEFINE __PARSE_CMD_LINE__ 1

; parse the command line given in (HL)
; compare with the command list in (BC)
; Results : - zero flag set if match found
;           - address to jump to in HL
;           - parameters for the command in (DE)

    include "memoryMapv2.inc"
    include "../lib/string.asm"
    include "../lib/serial.asm"


START_PARSE_MSG:
    DB "Parsing cmd : ", 0x00
TOKEN_MSG:
    DB "Parsing token : ", 0x00
; Parse the command line given in (HL) - compare with the command list in (BC)
; - Results : - zero flag set if match found, flag is NZ if no match found
;           - jump to address of the command (in HL)
;           - parameters for the command in (DE)
ParseAndExecCommand:
    PUSH BC
    CALL SpaceRemoval
    LD D, H ; store initial HL in DE
    LD E, L ; store initial HL in DE

    ; PUSH HL
    ; LD HL, START_PARSE_MSG
    ; CALL PrintString
    ; LD H, D ; store initial HL in DE
    ; LD L, E ; store initial HL in DE
    ; CALL PrintString
    ; LD HL, STRING_CR_LF
    ; CALL PrintString
    ; POP HL

.checkNewToken:   
    ; PUSH HL
    ; LD HL, TOKEN_MSG
    ; CALL PrintString
    ; LD H, B
    ; LD L, C
    ; CALL PrintString
    ; LD HL, STRING_CR_LF
    ; CALL PrintString
    ; POP HL
.checkToken:
    LD A, (BC)
    CP (HL)
    JP NZ, .charNoMatch
    CP 0x00 ; both token and cmd end
    JP Z, .match
    INC BC
    INC HL
;    CALL SendChar_A
    JP .checkToken
.charNoMatch:
    CP 0x00
    JP NZ, .nextToken
    LD A, (HL)
    CP ' '
    JP Z, .match
    JP .nextTokenSkipAdress
.nextToken:
    CP 0x00 ; end of token ?
    JP Z, .nextTokenSkipAdress
    INC BC
    LD A, (BC)
    JP .nextToken
.nextTokenSkipAdress:
    LD H, D ; set HL at beginning of command line
    LD L, E ; set HL at beginning of command line
    INC BC
    LD A, (BC); check if end of list
    CP 0xFF ; token end-of-list marker
    JR Z, .noMatch
    INC BC
    INC BC ; skip the address after the token
    JP .checkNewToken
.noMatch:
    CP 0x00 ; unset the zero flag (A contains 0xFF)
    POP BC
    RET
.match:
    CALL SpaceRemoval
    EX DE, HL ; parmaters in DE
    INC BC
    LD A, (BC)
    LD L, A
    INC BC
    LD A, (BC)
    LD H, A
    POP BC
;    XOR A ; set the zero flag
    JP (HL)


    ENDIF