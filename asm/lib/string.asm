    IFNDEF __STRING__
    DEFINE __STRING__ 1

; String functions
; - StringLength: ; Calculate the length of the string in HL, return in A
; - Hex2Str: ; convert a number to hex format (number in A, result in (HL), null terminated)
; - Byte2HexStr: ; convert a number to hex format (number in A, result in (DE), DE at end of string, not null terminated)
; - MemoryDump: ;Memory Dump in hex format (address in HL, always 16 x16 bytes, Result in DE)
; - SpaceRemoval: ; Remove leading spaces from the string in (HL) - move (HL)
; - Char2Digit: ; convert one 0-9-A-F character (in A) to a number (in A) ; if not a number negative
; - StrB2Digits: ;Convert a byte in hexstring (in (HL)) to a number (in A) Zero flag Z is success
; - StrW2Digits: ;Convert a word in hexstring (in (HL)) to a number (in DE) Zero flag Z is success
; - Hex2BCD: ; Convert a hex number in E to BCD in HL
;


 ;   INCLUDE "serial.asm"
;    include "./lib/stdio.asm"
    
; ------------------------------------------------------------
HEX_HEADER_STRING: ; Header string for hex dump
    DB "        0  1  2  3  4  5  6  7   8  9  A  B  C  D  E  F", 0x00    
HEX_HEADER_STRING_LF: ; Header string for hex dump
    DB "        0  1  2  3  4  5  6  7   8  9  A  B  C  D  E  F", 0x0A, 0x0D, 0x00    
 
STRING_CR_LF:
    DB 0x0A, 0x0D, 0x00 ; Carriage return + line feed


; ------------------------------------------------------------
StringLength: ; Calculate the length of the string in HL, return in A
    PUSH BC
    PUSH HL
    LD B, 0x00 ; Initialize length to 0
;    LD IY, HL ; Pointeur vers le buffer
.stringLengthLoop:
    LD A,(HL)
    CP 0x00 ; Check for null terminator
    JP Z, .stringLengthEnd ; If null terminator, return length in B
    INC HL ; Increment buffer pointer
    INC B ; Increment length
    JP .stringLengthLoop ; Continue loop
.stringLengthEnd:
    LD A, B ; put result in A
    POP HL
    POP BC
    RET

; ------------------------------------------------------------
Hex2Str: ; convert a number to hex format (number in A, result in (HL), null terminated)
    PUSH DE
    EX DE, HL
    CALL Byte2HexStr
    LD A, 0x00
    LD (DE), A
    DEC DE
    DEC DE
    EX DE, HL
    POP DE
    RET

Byte2HexStr: ; convert a number to hex format (number in A, result in (DE), DE at the end of string, not null terminated)
    PUSH AF
    SRL A ; Shift right to get the high nibble
    SRL A
    SRL A 
    SRL A 
    CP 0x0A ; Check if nibble is greater than 9
    JP NC, .hexDigit ; If not, convert to hex digit
    OR A, 0x30 ; Convert to ASCII '0' - '9'
    JP .printAndNextNible
.hexDigit:  
    ADD A, 0x37 ; Convert to ASCII 'A' - 'F'
.printAndNextNible:
;    CALL SendChar_A ; Send the character to the SIO port A
;    CALL PutC ; Send the character to the SIO port A
    LD (DE), A
    INC DE
    POP AF ; Restore the original value in A
    PUSH AF
    AND 0x0F ; Get the low nibble
    CP 0x0A ; Check if nibble is greater than 9
    JP NC, .hexDigit2 ; If not, convert to hex digit
    OR A, 0x30 ; Convert to ASCII '0' - '9'
    JP .printAndNextNible2
.hexDigit2:  
    ADD A, 0x37 ; Convert to ASCII 'A' - 'F'
.printAndNextNible2: 
;   CALL SendChar_A ; Send the character to the SIO port A
;    CALL PutC ; Send the character to the SIO port A
    LD (DE), A
    INC DE
    ; LD A, 0x00
    ; LD (DE), A ; Null terminator
    POP AF
    RET


MemoryDump: ;Memory Dump in hex format (address in HL, always 16 x16 bytes, Result in DE)
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL

    PUSH HL
    LD HL, HEX_HEADER_STRING_LF ; Load the header string address
.printHeaderLoop:
    LDI
    LD A, (HL)
    OR A
    JP NZ, .printHeaderLoop
    
    POP HL
    LD A, L
    AND 0xF0 ; align on 16 bytes
    LD L, A
    LD C, 0x10 ; Number of rows to print
.printHexRowStart:
    LD A, H
    CALL Byte2HexStr ; Convert H to hex 
    LD A, L
    CALL Byte2HexStr ; Convert Lto hex 
    LD A ,' '
    LD (DE), A
    INC DE
    LD A ,':'
    LD (DE), A
    INC DE 
    LD A ,' '
    LD (DE), A
    INC DE
 
    LD B, 0x10 ; Number of bytes to print
    PUSH HL ; Store HL address for char loop
.printHexLoop:
    LD A, (HL)
    CALL Byte2HexStr ; Convert to hex and copy to DE
    LD A, ' '
    LD (DE), A
    INC DE
    LD A, B
    CP 0x09 ; Check if we are at the 8th byte
    JP NZ, .next
    LD A, ' '
    LD (DE), A
    INC DE
.next
    INC HL ; Increment address
    DJNZ .printHexLoop ; Loop for 16 bytes
    LD A ,' '
    LD (DE), A
    INC DE
    LD (DE), A
    INC DE

    LD B, 0x10
    POP HL ; Restore the address in HL for char loop
.printCharLoop: 
    LD A, (HL)
    CP 0x20 ; Check if character is printable
    JP C, .notPrintable ; If not, print '.'
    CP 0x7F ; Check if character is printable
    JP C, .printable ; If not, print '.'
    CP 0xA0
    JP C, .notPrintable ; If not, print '.'
.printable
    LD (DE), A
    INC DE
    JP .printCharEnd
.notPrintable:
    LD A, '.' ; Print '.' for non-printable characters
    LD (DE), A
    INC DE
.printCharEnd:
    INC HL ; Increment address
    DJNZ .printCharLoop ; Loop for 16 bytes
    LD A, 0x0D ; Carriage return
    LD (DE), A
    INC DE
    LD A, 0x0A
    LD (DE), A
    INC DE

    DEC C ; Decrement row counter
    LD A,C
    OR A ; Check if C is zero
    JP NZ, .printHexRowStart ; If not zero, print next row
    LD A, 0x00
    LD (DE), A ; Null terminator
    POP HL
    POP DE
    POP BC
    POP AF
    RET

; ------------------------------------------------------------
SpaceRemoval: ; Remove leading spaces from the string in (HL) - move (HL)
    LD A, (HL) ; Read the first character
    CP ' '; Check for space
    INC HL ; Increment buffer pointer
    JP Z, SpaceRemoval ; If space, continue parsing
    DEC HL ; Decrement buffer pointer
    RET

Char2Digit: ; convert one 0-9-A-F character (in A) to a number (in A) ; if not a number negative
    XOR 0x30 ; check if line 3x
    CP 0x0A ; Check if num betwwen 0 and 9
    RET M ; 
    XOR 0x30 ; restore A
    XOR 0x40 ; check if line 4 (A to F)
    CP 0x00 ; remove @
    JP Z, .notANumber
    CP 0x07 ; check if byte is A to F
    JP M, .betwwen_A_and_F ; If negative it's between A & F
    XOR 0x40 ; restore A
    XOR 0x60 ; check if line 4 (a to a)
    CP 0x00 ; remove '
    JP Z, .notANumber
    CP 0x07 ; check if byte is A to F
    JP P, .notANumber ; If possitive it's not between A & F
.betwwen_A_and_F:
    ADD  0x09 ; Convert to number A-F
    RET
.notANumber:
;    AND  0x0F ; remove @ SEEMS USELESS
    OR  0xF0 ; set sign flag
    RET

; -------------------------------------------
StrW2Digits: ;Convert a word in hexstring (in (HL)) to a number (in DE) Zero flag Z is success
    PUSH BC
;    PUSH DE
    CALL SpaceRemoval
    LD DE, 0x0000; initialize DE to 0
    LD B, 3 ; Number of bytes to read
.char2digitLoop:
    LD A, (HL) ; Read the first character
    CALL Char2Digit ; Convert to number
    OR A ; initialise sign flag
    JP M, .notANumber
    OR E
    LD E, A
    SLA E
    RL D
    SLA E
    RL D
    SLA E
    RL D
    SLA E
    RL D
    INC HL ; Increment HL to get the next characters
    DJNZ .char2digitLoop ; Loop for 4 characters
    LD A, (HL) ; Read the last character
    CALL Char2Digit ; Convert to number
    OR A ; initialise sign flag
    JP M, .notANumber
    OR E  
    LD E, A
    INC HL ; increment to verify the buffer end
    LD A, (HL) ; Read the first character
    CP 0x00 ; Check for null terminator
    JP Z, .dump_end ; If not null terminator, error
    CP ' ' ; Check for space
    JP Z, .dump_end ; If not space, error
.notANumber:
    LD A, 0x01 ; Null terminator
    OR A ; Set Zero flag to NZ to indicate error
    JP .end
.dump_end
    LD A, 0x00 ; Null terminator
    OR A ; Set Zero flag to Z indicate success 
.end:
;    POP DE
    POP BC
    RET

StrB2Digits: ;Convert a byte in hexstring (in (HL)) to a number (in A) Zero flag Z is success
    PUSH BC
;    PUSH DE
    CALL SpaceRemoval
    ; LD DE, 0x0000; initialize DE to 0
;     LD B, 3 ; Number of bytes to read
; .char2digitLoop:
    LD A, (HL) ; Read the first character
    CALL Char2Digit ; Convert to number
    OR A ; initialise sign flag
    JP M, .notANumber
    RLCA
    RLCA
    RLCA
    RLCA
    LD B, A
    INC HL ; Increment HL to get the next characters
    ; DJNZ .char2digitLoop ; Loop for 4 characters
    LD A, (HL) ; Read the last character
    CALL Char2Digit ; Convert to number
    OR A ; initialise sign flag
    JP M, .notANumber
    OR B  
    LD B, A
    INC HL ; increment to verify the buffer end
    LD A, (HL) ; Read the first character
    CP 0x00 ; Check for null terminator
    JP Z, .dump_end ; If not null terminator, error
    CP ' ' ; Check for space
    JP Z, .dump_end ; If not space, error
.notANumber:
    LD A, 0x01 ; 
    OR A ; Set Zero flag to NZ to indicate error
    JP .end
.dump_end
    LD A, 0x00 ; 
    OR A ; Set Zero flag to Z indicate success 
    LD A, B ; put the result in A
.end:
;    POP DE
    POP BC
    RET

Hex2BCD: ; Convert a hex number in E to BCD in HL
    PUSH BC
    PUSH DE
    LD HL, 0x0000
    LD A, E
    LD B, 0x00 ; Initialize B to 0
.hundredLoop:
    INC B
    SUB 100 ; Subtract 100 from A
    JP NC, .hundredLoop ; If A >= 100, continue loop
    DEC B
    ADD 100
    LD H, B
    LD B, 0x00
.tenLoop:    
    INC B
    SUB 10 ; Subtract 10 from A
    JP NC, .tenLoop ; If A >= 10, continue loop
    DEC B
    ADD 10
    RLC B
    RLC B
    RLC B
    RLC B
    LD L, B
    LD B, 0x00 ; Initialize B to 0
.unitLoop:
    INC B
    SUB 1 ; Subtract 1 from a
    JP NC, .unitLoop ; If A >= 1, continue loop
    DEC B
    ADD 1
    LD A, L
    OR B
    LD L, A
    POP DE
    POP BC
    RET

    ENDIF