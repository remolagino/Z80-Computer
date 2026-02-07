    IFNDEF __MMU__
    DEFINE __MMU__ 1

; MMU - Memory Management Unit
;
; Routines to manage the MMU
; Set Block addresses and destination (ROM/RAM)
; Read Block Addresses
; Initialise the MMU at RESET

; MMU Port Definition
MMU_BASE_ADDR EQU 0x70
MMU_PAGE0_SET EQU MMU_BASE_ADDR + 0x00
MMU_PAGE1_SET EQU MMU_BASE_ADDR + 0x01
MMU_PAGE2_SET EQU MMU_BASE_ADDR + 0x02
MMU_PAGE3_SET EQU MMU_BASE_ADDR + 0x03

MMU_READ EQU MMU_BASE_ADDR
MMU_PAGE0_GET EQU 0x00
MMU_PAGE1_GET EQU 0x40
MMU_PAGE2_GET EQU 0x80
MMU_PAGE3_GET EQU 0xC0

MMU_ROM_SELECT EQU 0x00
MMU_RAM_SELECT EQU 0x80
MMU_ROM_RAM_SELECT_MASK EQU 0x7F

MMU_ACTIVATE EQU MMU_BASE_ADDR + 0x04


MMU_SetPage0: ; Bank# in A, ROM/RAM Select in B (R*M_SELECT)
    PUSH AF
    AND MMU_ROM_RAM_SELECT_MASK
    OR B
    OUT (MMU_PAGE0_SET), A
    POP AF
    RET
MMU_SetPage1: ; Bank# in A, ROM/RAM Select in B (R*M_SELECT)
    PUSH AF
    AND MMU_ROM_RAM_SELECT_MASK
    OR B
    OUT (MMU_PAGE1_SET), A
    POP AF
    RET
MMU_SetPage2: ; Bank# in A, ROM/RAM Select in B (R*M_SELECT)
    PUSH AF
    AND MMU_ROM_RAM_SELECT_MASK
    OR B
    OUT (MMU_PAGE2_SET), A
    POP AF
    RET
MMU_SetPage3: ; Bank# in A, ROM/RAM Select in B (R*M_SELECT)
    PUSH AF
    AND MMU_ROM_RAM_SELECT_MASK
    OR B
    OUT (MMU_PAGE3_SET), A
    POP AF
    RET

MMU_GetPageInfo : ; Page# in B (MMU_PAGE#_GET); result in A (rom ram select in bit 7)
    PUSH BC
    SLA B ; Shift page number to get the correct bits for the MMU read port
    SLA B
    SLA B
    SLA B
    SLA B
    SLA B
    LD C, MMU_READ
    IN A, (C)
    POP BC
    RET

; ONLY USED AT THE BOOT AFTER RESET
; MMU_Init:
;     LD A, 0x00 OR ROM_SELECT; bank 0, ROM
;     OUT (MMU_PAGE0_SET), A
;     LD A, 0x01 OR RAM_SELECT; bank 1, RAM
;     OUT (MMU_PAGE1_SET), A
;     LD A, 0x02 OR RAM_SELECT; bank 2, RAM
;     OUT (MMU_PAGE2_SET), A
;     LD A, 0x03 OR RAM_SELECT; bank 3, RAM
;     OUT (MMU_PAGE3_SET), A
    
;     OUT (MMU_ACTIVATE), A

    ENDIF