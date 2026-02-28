; ------------------------------------------------------
; -                  FATtools.asm                      -
; -  routines to help manage file names and path      -
; ------------------------------------------------------

    
    IFNDEF __FAT_TOOLS__
    DEFINE __FAT_TOOLS__ 1

    INCLUDE "./doubleDabble.asm"

; Validate the filename in (DE) and prepare a normalised string
; in (HL)
; * transform toto.txt in 'TOTO____TXT'
; * Return : Carry flag if name not conform
FATtools_FileNamePrep:
    PUSH BC
    PUSH DE
    PUSH HL

    LD A, (DE)
    CP 0x00
    JP Z, .error
    CP '.'
    JP NZ, .nameLoopProcess
    INC DE
    LD A, (DE)
    CP 0x00
    JP Z, .sameDir
    CP '.'
    JP NZ, .error
    INC DE
    LD A, (DE)
    CP 0x00
    JP Z, .parentDir
    JP .error
.nameLoopProcess:
    LD B, 8
.nameLoop:
    LD A,(DE)
    CP 0x00
    JP Z, .nameLoopAddSpace
    CP '.'
    JP Z, .nameLoopAddSpace
    CALL FATtools_CheckChar
    JP C, .error
    INC DE
    JP .nameLoopNoDot
.nameLoopAddSpace:
    LD A, ' '
.nameLoopNoDot:
    LD (HL), A
    INC HL
    DJNZ .nameLoop
    LD A, (DE)
    CP 0x00
    JP Z, .extProcess
    CP '.'
    JP NZ, .error
    INC DE
    LD A, (DE)
    CP 0x00 ; no extension after dot : error
    JP Z, .error
.extProcess:
    LD B, 3
.extLoop:
     LD A,(DE)
    CP 0x00
    JP Z, .extLoopAddSpace
    CP '.'
    JP Z, .extLoopAddSpace
    CALL FATtools_CheckChar
    JP C, .error
    INC DE
    JP .extLoopNoDot
.extLoopAddSpace:
    LD A, ' '
.extLoopNoDot:
    LD (HL), A
    INC HL
    DJNZ .extLoop
    LD A, (DE)
    CP 0x00
    JP NZ, .error
    LD A, 0x00
    LD (HL), A
    POP HL
    POP DE
    POP BC
    RET
.sameDir:
    LD DE, FATTOOLS_SAME_DIR
    LD B, 12
.sameDirLoop:
    LD A, (DE)
    LD (HL), A
    INC DE
    INC HL
    DJNZ .sameDirLoop
    OR A ; reset carry
    POP HL
    POP DE
    POP BC
    RET
.parentDir:
    LD DE, FATTOOLS_PARENT_DIR
    LD B, 12
.parentDirLoop:
    LD A, (DE)
    LD (HL), A
    INC DE
    INC HL
    DJNZ .parentDirLoop
    OR A ; reset carry
    POP HL
    POP DE
    POP BC
    RET
.error:
    SCF
    POP HL
    POP DE
    POP BC
    RET

; check if char in A is acceptable
; * transform lower case to upper case
; * if not good, SCF
FATtools_CheckChar:
    PUSH BC
    PUSH HL
    CP 0x21
    JP C, .error
    CP 0x7F
    JP NC, .error
    LD B, 15
    LD HL, FATTOOLS_FORBIDDEN_CHARS
.forbidCharLoop:
    CP (HL) 
    JP Z, .error
    INC HL
    DJNZ .forbidCharLoop
    CP 'a'
    JP C, .notLower
    CP '{'
    JP NC, .notLower
    AND 0xDF
.notLower:
    OR A
    POP HL
    POP BC
    RET
.error:
    POP HL
    POP BC
    SCF
;    LD A, 0xFF
    RET


; Take a relative path in (DE) and update the PATH_STRING in (HL).
FATtools_CanonicalizePath:
    PUSH BC
    PUSH DE
    PUSH HL
    LD A, (DE)
    CP 0x00
    JP Z, .exit
    CP '/'
    JP NZ, .gotoEndOfCurrPathLoop
    LD (HL), A ; make sure (hl) starts with '/',0x00
    INC HL
    LD A, 0x00
    LD (HL), A
.gotoEndOfCurrPathLoop:
    LD A, (HL)
    CP 0x00
    JP Z, .copyRelativePath
    INC HL
    JP .gotoEndOfCurrPathLoop
.copyRelativePath:
    DEC HL
    LD A, (HL)
    CP '/'
    JP Z, .removeDESlash
    INC HL
.removeDESlash:
    LD A, (DE)
    CP '/'
    JP NZ, .addHLSlash
    INC DE
.addHLSlash:
    LD A, '/'
    LD (HL), A
    INC HL
.copyRelativePathLoop:
    LD A, (DE)
    LD (HL), A
    CP 0x00
    JP Z, .normalizePath
    INC HL
    INC DE
    JP .copyRelativePathLoop
.normalizePath:
    LD B, 0
.normalizePathLoop:
    DEC HL
    LD A, (HL)
    CP 0x00 ; start of path string reached
    JP Z, .compactPath ; change with better method
    CP '.'
    JP Z, .firstDot
    JP .normalizePathLoop
.firstDot:
    DEC HL
    LD A, (HL)
    CP '.'
    JP Z, .twoDots
    CP '/'
    JP NZ, .normalizePathLoop
    INC HL ; replace the dot with a +
    LD A, '+'
    LD (HL), A
    DEC HL ; replace the dash with a +
    LD (HL), A
    DEC HL
    LD A, (HL)
    CP '.'
    JP Z, .firstDot
    LD A, B
    CP 0x00
    JP NZ,.twoDotsTokenRemoval
    JP .normalizePathLoop    
.twoDots:
    INC B
    INC HL ; replace the dot with a +
    LD A, '+'
    LD (HL), A
    DEC HL ; replace the dot with a +
    LD (HL), A
    DEC HL ; replace the dash with a +
    LD (HL), A
    DEC HL
    LD A, (HL)
    CP '.'
    JP NZ, .twoDotsTokenRemoval
    JP .firstDot
.twoDotsTokenRemoval:
.twoDotsOuterLoop:
.twoDotsLoop:
    LD A, (HL)
    CP 0x00
    JP Z, .compactPath
    CP '/'
    JP Z, .twoDotsLoopEnd
    LD A, '+'
    LD (HL), A
    DEC HL
    JP .twoDotsLoop
.twoDotsLoopEnd:
    LD A, '+'
    LD (HL), A
    DEC HL
    DJNZ .twoDotsOuterLoop
    LD A, (HL)
    CP 0x00
    JP Z, .compactPath
    JP .normalizePath
.compactPath:
    INC HL
    LD A, '/'
    LD (HL), A
    INC HL
    LD DE, HL
.compactLoop:
    LD A, (HL)
    CP 0x00
    JP Z, .endCompact
    CP '+'
    JP Z, .remove
    ; CP '/'
    ; JP Z, .removeExtraSlash
    LD (DE), A
    INC DE
.removeExtraSlash:
; TODO : ADD SUPPRESSION OF CONSECUTIVE SLASH
.remove:
    INC HL
    JP .compactLoop
.endCompact:
    LD (DE), A
.exit:
    POP HL
    POP DE
    POP BC
    RET


; Parse the path in (DE), send the token in (BC)
; * NZ means a token has been processed
; * Z means no more token
FATtools_getPathElement:
    LD BC, DE
    LD A, (DE)
    CP 0x00
    RET Z
.parseLoop:
    LD A, (DE)
    CP 0x00
    JP Z, .endPath
    CP '/'
    JP Z, .endToken
    INC DE
    JP .parseLoop
.endToken:
    LD A, 0x00
    LD (DE), A
    INC DE
.endPath:
    LD A, 0x01
    OR A
    RET
.error:
    SCF
    RET

; convert a date word to its string représentation
; * params : date word in BC YYYYYYYM MMMDDDDD
; * string représentation in (DE)
FATtools_WordToDate:
    PUSH HL
; day
    LD A, C
    AND 0x1F ; day in 5 LSb
    CALL DBDAB_bin2dec_byte
    LD A, L
    CALL Bin2Hex_DE
    LD A, '/'
    LD (DE), A
    INC DE
; month
    LD A, B
    RRA
    LD A, C
    RLA
    RLA
    RLA
    RLA
    AND 0x0F
    CALL DBDAB_bin2dec_byte
    LD A, L
    CALL Bin2Hex_DE
    LD A, '/'
    LD (DE), A
    INC DE
; year
    LD A, '2'
    LD (DE), A
    INC DE
    LD A, '0'
    LD (DE), A
    INC DE
    LD A, B
    OR A
    RRA
    SUB 20 ; a bit hacky, we suppose there won't be files too old
    CALL DBDAB_bin2dec_byte
    LD A, L
    CALL Bin2Hex_DE
    POP HL
    RET


; convert a time word to its string représentation
; * params : time word in BC hhhhhmmm mmmsssss 
; * string représentation in (DE)
FATtools_WordToTime:
    PUSH BC
    PUSH HL
; hours
    LD A, B
    AND 0xF8 ; hours in 5 MSb of B
    RRA
    RRA
    RRA
    CALL DBDAB_bin2dec_byte
;    CALL Bin2BCD
    LD A, L
    CALL Bin2Hex_DE
    LD A, ':'
    LD (DE), A
    INC DE
; minutes
    LD A, B
    AND 0x07
    RL C
    RLA
    RL C
    RLA
    RL C
    RLA
    CALL DBDAB_bin2dec_byte
;    CALL Bin2BCD
    LD A, L
    CALL Bin2Hex_DE
    POP HL
    POP BC
    RET



    
FATTOOLS_SAME_DIR:
    DB ".          ", 0x00
FATTOOLS_PARENT_DIR:
    DB "..         ", 0x00
FATTOOLS_FORBIDDEN_CHARS:
    DB 0x22, 0x2A, 0x2B, 0x2C, 0x2F, 0x3A, 0x3B, 0x3C, 0x3D
    DB 0x3E, 0x3F, 0x5B, 0x5C, 0x5D, 0x7C, 0x2E




    ENDIF