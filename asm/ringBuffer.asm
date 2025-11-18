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



INIT_BUFFER: ; Initialised Ring Buffer at IY, capacity in BC, buffer address in DE
    LD (IY + RING_BUFFER.HEAD_PTR), 0x0000
    LD (IY + RING_BUFFER.TAIL_PTR), 0x0000
    LD (IY + RING_BUFFER.BUFFER_SIZE), BC
    LD (IY + RING_BUFFER.BUFFER_ADDRESS), DE

    RET

RING_PUT: ; Write reg A in ring buffer at address IY, carry flag is set if buffer full
    PUSH DE
    PUSH HL
    ; test if buffer is full
    LD HL, (IY + RING_BUFFER.HEAD_PTR)
    LD DE, (IY + RING_BUFFER.TAIL_PTR)
    INC HL
    OR A ; clear carry
    SBC HL, DE
    JP Z, .fullBuffer
    LD DE, (IY + RING_BUFFER.BUFFER_SIZE)
    SBC HL, DE
    JP Z, .fullBuffer
    ; adding the elmt in the buffer
    LD HL, (IY + RING_BUFFER.BUFFER_ADDRESS)
    LD DE, (IY + RING_BUFFER.HEAD_PTR)
    ADD HL, DE
    LD (HL), A
    INC DE
    LD HL, (IY + RING_BUFFER.BUFFER_SIZE)
    OR A ; clear carry
    SBC HL, DE
    JP Z, .endOfBuffer ; loop back at the beginning of buffer
    LD (IY + RING_BUFFER.HEAD_PTR), DE
    OR A ; clear carry when if worked
    JP .continue
.endOfBuffer:
    LD (IY + RING_BUFFER.HEAD_PTR), 0x0000
    OR A ; clear carry when if worked
    JP .continue
.fullBuffer:
    SCF ; set the carry as success flag   
.continue:    
    POP HL
    POP DE
    RET

RING_GET: ; put in reg A the first unread elmt in the ring buffer at address IYL, carry flag set if empty
    PUSH DE
    PUSH HL
    ;check if buffer empty
    LD DE, (IY + RING_BUFFER.TAIL_PTR)
    LD HL, (IY + RING_BUFFER.HEAD_PTR)
    OR A
    SBC HL, DE
    JP Z, .emptyBuffer
    LD HL, (IY + RING_BUFFER.BUFFER_ADDRESS)
    ADD HL, DE
    LD A, (HL)
    ; #TODO Remove when behaviour is fine
    PUSH AF
    LD A, '.'
    LD (HL), A
    POP AF
    ; #TODO Remove above
    INC DE
    OR A
    LD HL, (IY + RING_BUFFER.BUFFER_SIZE)
    SBC HL, DE
    JP Z, .endOfBuffer
    LD (IY + RING_BUFFER.TAIL_PTR), DE
    OR A ; clear carry when if worked
    JP .continue
.endOfBuffer:
    LD (IY + RING_BUFFER.TAIL_PTR), 0x0000
    OR A ; clear carry when if worked
    JP .continue
.emptyBuffer:
    LD A, 0x00
    SCF
.continue:
    POP HL
    POP DE
    RET

RING_UNGET: ; put back reg A in tail of ring buffer at address IY, carry flag is set if buffer full
    PUSH DE
    PUSH HL
    ; test if buffer is full
    LD HL, (IY + RING_BUFFER.HEAD_PTR)
    LD DE, (IY + RING_BUFFER.TAIL_PTR)
    INC HL
    OR A ; clear carry
    SBC HL, DE
    JP Z, .fullBuffer
    LD DE, (IY + RING_BUFFER.BUFFER_SIZE)
    SBC HL, DE
    JP Z, .fullBuffer
    ; pushing the elmt back at the tail of the buffer
    LD HL, (IY + RING_BUFFER.BUFFER_ADDRESS)
    LD DE, (IY + RING_BUFFER.TAIL_PTR)
    PUSH AF
    LD A, D
    OR E ; check if DE=0x0000
    JP NZ, .notDEequ0
    LD DE, (IY + RING_BUFFER.BUFFER_SIZE)
.notDEequ0:
    DEC DE
    ADD HL, DE
    POP AF
    LD (HL), A
   ; DEC DE
    LD HL, (IY + RING_BUFFER.BUFFER_SIZE)
    OR A ; clear carry
    SBC HL, DE
    JP Z, .endOfBuffer ; loop back at the beginning of buffer
    LD (IY + RING_BUFFER.TAIL_PTR), DE
    OR A ; clear carry when if worked
    JP .continue
.endOfBuffer:
    LD (IY + RING_BUFFER.TAIL_PTR), 0x0000
    OR A ; clear carry when if worked
    JP .continue
.fullBuffer:
    SCF ; set the carry as success flag   
.continue:    

    POP HL
    POP DE
    RET


RING_IS_EMPTY: ; set the carry if the ring buffer in IY is empty
    PUSH DE
    PUSH HL
    ;check if buffer empty
    LD DE, (IY + RING_BUFFER.TAIL_PTR)
    LD HL, (IY + RING_BUFFER.HEAD_PTR)
    OR A
    SBC HL, DE
    JP Z, .emptyBuffer
    OR A
    POP HL
    POP DE
    RET
.emptyBuffer:
    SCF
    POP HL
    POP DE
    RET
    
RING_IS_FULL: ; set the carry if the ring buffer in IY is full
    PUSH DE
    PUSH HL
    ; test if buffer is full
    LD HL, (IY + RING_BUFFER.HEAD_PTR)
    LD DE, (IY + RING_BUFFER.TAIL_PTR)
    INC HL
    OR A ; clear carry
    SBC HL, DE
    JP Z, .fullBuffer
    LD DE, (IY + RING_BUFFER.BUFFER_SIZE)
    SBC HL, DE
    JP Z, .fullBuffer
    OR A
    POP HL
    POP DE
    RET
.fullBuffer:
    SCF
    POP HL
    POP DE
    RET
    
PREP_BUFFER: ; fill the buffer data in IY with value in reg D
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL
    LD BC, (IY + RING_BUFFER.BUFFER_SIZE)
    LD HL, (IY + RING_BUFFER.BUFFER_ADDRESS)
.prepLoop:
    LD A, D
    LD (HL), A
    INC HL
    DEC BC
    LD A, B
    OR C
    JP NZ, .prepLoop

    POP HL
    POP DE
    POP BC
    POP AF
    RET   


    ENDIF