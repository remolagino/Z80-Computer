


    ORG     0x4000          ; Start address
    JP START

    include "../lib/stdio.asm"
    include "../monitorv2/memoryMapv2.inc"
    include "mkeyboard.asm"
    include "sound_ym.asm"
    

START:

    LD A, 0x33
    LD (0xc0c5), A

    LD HL, (CURSOR_IDX)
    LD DE, START_MSG
    CALL PutS_LN
    LD (CURSOR_IDX), HL

    CALL mKeyboard_Init

    LD HL, kbdtest_onkeypressed
    LD (M_KEYBOARD_ONKEYPRESSED_HANDLER), HL
    LD HL, kbdtest_onkeyreleased
    LD (M_KEYBOARD_ONKEYRELEASED_HANDLER), HL

    CALL YM_RESET        ; Properly reset the YM3812
        
    CALL YM_SETSOUND


.mainLoop:
    CALL mKeyboard_Scan

    JP NC, .mainLoop

    CALL    YM_RESET        ; Properly reset the YM3812
    LD HL, (CURSOR_IDX)
    LD DE, END_MSG
    CALL PutS_LN
    LD (CURSOR_IDX), HL

    LD A, 0x11
    LD (0xc0c5), A

    RET

kbdtest_onkeypressed:
    LD A, (IX)
    CP 'a'
    CALL Z, playNote

    PUSH DE
    PUSH HL
    LD HL, (CURSOR_IDX)
    LD DE, KEY_PRESSED_MSG
    CALL PutS
    LD A, (IX)
    CALL PutC
    LD DE, CR_LF
    CALL PutS
    LD (CURSOR_IDX), HL
    POP HL
    POP DE
    RET

kbdtest_onkeyreleased:
    LD A, (IX)
    CP '²'
    JP Z, kbdtest_end

    CP 'a'
    CALL Z, stopNote

    PUSH DE
    PUSH HL
    LD HL, (CURSOR_IDX)
    LD DE, KEY_RELEASED_MSG
    CALL PutS
    LD A, (IX)
    CALL PutC
    LD DE, CR_LF
    CALL PutS
    LD (CURSOR_IDX), HL
    POP HL
    POP DE
    RET

playNote:
;    PUSH BC
    LD A, 0xB0
    LD C, 0x32
    CALL YM_WRITE
;    POP BC
    RET

stopNote:
    ; Turn off the note
;    PUSH BC
    LD      A, 0xB0
    LD      C, 0x12         ; Key Off (bit 5 = 0)
    CALL    YM_WRITE
;    POP BC
    RET

kbdtest_end:
    SCF
    RET

CR_LF     DB 0x0D, 0x0A, 0x00
START_MSG DB "YM3812 Test Program", 0x00
END_MSG   DB "Program ended", 0x00
KEY_PRESSED_MSG DB "Key Pressed: ", 0x00
KEY_RELEASED_MSG DB "Key Released: ", 0x00

    END