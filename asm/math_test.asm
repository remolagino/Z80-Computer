; --------------------------------------------
; -        Test for the math library         -
; --------------------------------------------



    .ORG 0x4000

    JP main

    INCLUDE "./lib/stdio.asm"
    INCLUDE "./lib/math.asm"

main:
; dword + dword
    LD DE, MathTest_addDword_msg
    CALL math_MsgPrint_LN

    LD BC, Num1
    LD HL, Num2
    LD DE, NumTmp
    CALL MATH_ADD_DWORD_TO_DWORD

    LD DE, Workspace
    CALL MATH_DWORD_TO_STRING
    CALL math_MsgPrint_LN

    LD BC, Num2
    LD DE, Workspace
    CALL MATH_DWORD_TO_STRING
    CALL math_MsgPrint_LN

    LD BC, NumTmp
    LD DE, Workspace
    CALL MATH_DWORD_TO_STRING
    CALL math_MsgPrint_LN

; dword + word
    LD DE, MathTest_addWordToDword_msg
    CALL math_MsgPrint_LN

    LD BC, Num1
    LD HL, 0x8265
    LD DE, NumTmp
    CALL MATH_ADD_WORD_TO_DWORD

    LD DE, Workspace
    CALL MATH_DWORD_TO_STRING
    CALL math_MsgPrint_LN

    LD BC, HL
    LD DE, Workspace
    CALL MATH_WORD_TO_STRING
    CALL math_MsgPrint_LN

    LD BC, NumTmp
    LD DE, Workspace
    CALL MATH_DWORD_TO_STRING
    CALL math_MsgPrint_LN

; word x byte
    LD DE, MathTest_MultiplyWordByByte_msg
    CALL math_MsgPrint_LN

    LD A, 0xFF
    LD HL, 0xFFFF
    LD BC, NumTmp
    CALL MATH_MULT_WORD_BYTE

    LD DE, Workspace
    CALL Bin2Hex_DE
    LD A, 0x00
    LD (DE), A
    LD DE, Workspace
    CALL math_MsgPrint_LN

    LD BC, HL
    LD DE, Workspace
    CALL MATH_WORD_TO_STRING
    CALL math_MsgPrint_LN

    LD BC, NumTmp
    LD DE, Workspace
    CALL MATH_DWORD_TO_STRING
    CALL math_MsgPrint_LN



    RET

math_MsgPrint: ; print message in DE
    PUSH HL
    LD HL, (CURSOR_IDX)
    CALL PutS
    LD (CURSOR_IDX), HL
    POP HL
    RET
math_MsgPrint_LN: ; print message in DE
    PUSH HL
    LD HL, (CURSOR_IDX)
    CALL PutS_LN
    LD (CURSOR_IDX), HL
    POP HL
    RET


MathTest_addDword_msg:
    DB "Add Dwords" , 0x00
MathTest_addWordToDword_msg:
    DB "Add Word to Dword" , 0x00
MathTest_MultiplyWordByByte_msg:
    DB "Multiply Word By Byte" , 0x00
Num1:
    DWORD 0x0012FF56
Num2:
    DWORD 0x65FFF854
NumTmp:
    DWORD 0xFFFFFFFF
Workspace:
    BLOCK 0x80, 0xFF