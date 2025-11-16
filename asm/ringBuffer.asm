;
; Circular buffer
;


    IFNDEF __RING_BUFFER__
    DEFINE __RING_BUFFER__ 1

BUFFER_CAPACITY EQU 0x0009
IN_BUFFER EQU 0x4200

    STRUCT RING_BUFFER
HEAD_PTR       WORD   0   ; 16-bit word: Points to the next memory location to WRITE data to
TAIL_PTR       WORD   0   ; 16-bit word: Points to the next memory location to READ data from
; Note: HEAD and TAIL pointers will wrap around to the start of the data area.
BUFFER_SIZE    WORD   BUFFER_CAPACITY   ; 16-bit word: Holds the maximum capacity of the buffer (e.g., 256)
                                        ; actual buffer capacity is one less than the buffer size
BUFFER_ADDRESS WORD IN_BUFFER
    ENDS          ; End of the structure definition



INIT_BUFFER: ; Initialised Ring Buffer at HL, capacity in BC, buffer address in DE
    PUSH IX
    LD IX, HL
    LD (IX + RING_BUFFER.HEAD_PTR), 0x0000
    LD (IX + RING_BUFFER.TAIL_PTR), 0x0000
    LD (IX + RING_BUFFER.BUFFER_SIZE), BC
    LD (IX + RING_BUFFER.BUFFER_ADDRESS), DE
    POP IX
    RET

RING_WRITE: ; Write reg A in ring buffer at address HL, carry flag is set if buffer full
    PUSH DE
    PUSH HL
    PUSH IX
    LD IX, HL
    ; test if buffer is full
    LD HL, (IX + RING_BUFFER.HEAD_PTR)
    LD DE, (IX + RING_BUFFER.TAIL_PTR)
    INC HL
    OR A ; clear carry
    SBC HL, DE
    JP Z, .fullBuffer
    LD DE, (IX + RING_BUFFER.BUFFER_SIZE)
    SBC HL, DE
    JP Z, .fullBuffer
    ; adding the elmt in the buffer
    LD HL, (IX + RING_BUFFER.BUFFER_ADDRESS)
    LD DE, (IX + RING_BUFFER.HEAD_PTR)
    ADD HL, DE
    LD (HL), A
    INC DE
    LD HL, (IX + RING_BUFFER.BUFFER_SIZE)
    OR A ; clear carry
    SBC HL, DE
    JP Z, .endOfBuffer ; loop back at the beginning of buffer
    LD (IX + RING_BUFFER.HEAD_PTR), DE
    OR A ; clear carry when if worked
    JP .continue
.endOfBuffer:
    LD (IX + RING_BUFFER.HEAD_PTR), 0x0000
    OR A ; clear carry when if worked
    JP .continue
.fullBuffer:
    SCF ; set the carry as success flag   
.continue:    
    POP IX
    POP HL
    POP DE
    RET

RING_READ: ; put in reg A the first unread elmt in the ring buffer at address HL, carry flag set if empty
    PUSH DE
    PUSH HL
    PUSH IX
    LD IX, HL
    ;check if buffer empty
    LD DE, (IX + RING_BUFFER.TAIL_PTR)
    LD HL, (IX + RING_BUFFER.HEAD_PTR)
    OR A
    SBC HL, DE
    JP Z, .emptyBuffer
    LD HL, (IX + RING_BUFFER.BUFFER_ADDRESS)
    ADD HL, DE
    LD A, (HL)
    ; ; #TODO Remove when behaviour is fine
    ; PUSH AF
    ; LD A, '.'
    ; LD (HL), A
    ; POP AF
    ; ; #TODO Remove above
    INC DE
    OR A
    LD HL, (IX + RING_BUFFER.BUFFER_SIZE)
    SBC HL, DE
    JP Z, .endOfBuffer
    LD (IX + RING_BUFFER.TAIL_PTR), DE
    OR A ; clear carry when if worked
    JP .continue
.endOfBuffer:
    LD (IX + RING_BUFFER.TAIL_PTR), 0x0000
    OR A ; clear carry when if worked
    JP .continue
.emptyBuffer:
    LD A, 0x00
    SCF
.continue:
    POP IX
    POP HL
    POP DE
    RET

PREP_BUFFER: ; fill the buffer data with value in reg D
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL
    PUSH IX

    LD IX, HL
    LD BC, (IX + RING_BUFFER.BUFFER_SIZE)
    LD HL, (IX + RING_BUFFER.BUFFER_ADDRESS)
.prepLoop:
    LD A, D
    LD (HL), A
    INC HL
    DEC BC
    LD A, B
    OR C
    JP NZ, .prepLoop

    POP IX
    POP HL
    POP DE
    POP BC
    POP AF
    RET   


    ENDIF