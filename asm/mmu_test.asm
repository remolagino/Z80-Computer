; MMU Test Program

    ORG     0x4000          ; Start address
    JP START

    include "./lib/stdio.asm"
    include "./lib/string.asm"
    include "./monitorv2/memoryMapv2.inc"
    include "./lib/mmu.asm"


START:
    LD HL, (CURSOR_IDX)
    LD DE, START_MSG
    CALL PutS_LN
    LD (CURSOR_IDX), HL

    LD B, 0x00 ; page number to test
.mmu_loop:
    LD DE, MMU_MSG
    CALL PutS
    LD A, B
    LD DE, MMU_WORKSPACE
    CALL Bin2Hex_DE
    LD A, ' '
    LD (DE), A
    INC DE
    LD A, ':'
    LD (DE), A
    INC DE
    LD A, ' '
    LD (DE), A
    INC DE
    CALL MMU_GetPageInfo
    CALL Bin2Hex_DE
    LD A, 0x00
    LD (DE), A
    LD DE, MMU_WORKSPACE    
    CALL PutS_LN
    INC B
    LD A, B
    CP 0x04
    JR NZ, .mmu_loop

    LD A, 0x02
    LD B, MMU_RAM_SELECT
    CALL MMU_SetPage2

;    LD HL, (CURSOR_IDX)
    LD DE, END_MSG
    CALL PutS_LN
    LD (CURSOR_IDX), HL


    RET



START_MSG DB "MMU Test Program", 0
END_MSG DB "Program ended", 0
MMU_MSG DB "Page ", 0
MMU_MSG2 DB " - ", 0
MMU_WORKSPACE DS 16

