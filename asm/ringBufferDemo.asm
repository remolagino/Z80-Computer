;
; Circular buffer
;

    ORG 0x5000

    include "jumptable.inc"

    JP START

    include "ringbuffer.asm"

START:

    LD IY, MY_RX_BUFFER
    LD BC, 17 ; capacity is 17
    LD DE, 0x4200
    CALL INIT_BUFFER
    LD D, '.'
    CALL PREP_BUFFER
    CALL PRINT_RING
    LD A, 0x09
    CALL SENDCHAR_A
    CALL PRINT_BUFFER_DATA
    PUSH HL
    LD HL, CRLF
    CALL PRINT_STRING
    CALL PRINT_STRING
    POP HL


.loop:
    CALL RECEIVE_CHAR_A
    CP 0x0D
    JP Z, .exit
    CP '²'
    JP Z, .readRing
    CP 0x09
    JP Z, .bufferStatus
    CP 0x08
    JP Z, .pushBack

    PUSH AF
    PUSH HL
    LD HL, WRITE_BUFFER_MSG
    CALL PRINT_STRING
    POP HL
    POP AF

    CALL RING_PUT
    JP C, .fullBufferMsg
    CALL SENDCHAR_A

    PUSH AF
    PUSH HL
    LD HL, CRLF
    CALL PRINT_STRING
    POP HL
    POP AF

    CALL PRINT_RING
    LD A, 0x09
    CALL SENDCHAR_A
    CALL PRINT_BUFFER_DATA
    PUSH HL
    LD HL, CRLF
    CALL PRINT_STRING
    POP HL

    JP .loop
.fullBufferMsg:
    CALL SENDCHAR_A
    PUSH HL
    LD HL, FULL_BUFFER_MSG
    CALL PRINT_STRING
    POP HL
    CALL PRINT_RING
    LD A, 0x09
    CALL SENDCHAR_A
    CALL PRINT_BUFFER_DATA
    PUSH HL
    LD HL, CRLF
    CALL PRINT_STRING
    POP HL
    JP .loop

.readRing:
    PUSH HL
    LD HL, READ_BUFFER_MSG
    CALL PRINT_STRING
    POP HL
    CALL RING_GET
    JP C, .emptyBufferMsg
    CALL SENDCHAR_A
    PUSH HL
    LD HL, CRLF
    CALL PRINT_STRING
    POP HL
    CALL PRINT_RING
    LD A, 0x09
    CALL SENDCHAR_A
    CALL PRINT_BUFFER_DATA
    PUSH HL
    LD HL, CRLF
    CALL PRINT_STRING
    POP HL
    JP .loop
.emptyBufferMsg:
    CALL HEX2STR
    PUSH HL
    LD HL, EMPTY_BUFFER_MSG
    CALL PRINT_STRING
    POP HL
    CALL PRINT_RING
    LD A, 0x09
    CALL SENDCHAR_A
    CALL PRINT_BUFFER_DATA
    PUSH HL
    LD HL, CRLF
    CALL PRINT_STRING
    POP HL
    JP .loop
.pushBack:
    PUSH HL
    LD HL, UNGET_BUFFER_MSG
    CALL PRINT_STRING
    POP HL
    LD A, '@'
    CALL SENDCHAR_A
    CALL RING_UNGET
    JP C, .pushbackBufferFull
    PUSH HL
    LD HL, CRLF
    CALL PRINT_STRING
    POP HL
    CALL PRINT_RING
    LD A, 0x09
    CALL SENDCHAR_A
    CALL PRINT_BUFFER_DATA
    PUSH HL
    LD HL, CRLF
    CALL PRINT_STRING
    POP HL
    JP .loop
.pushbackBufferFull:
    PUSH HL
    LD HL, FULL_BUFFER_MSG
    CALL PRINT_STRING
    LD HL, CRLF
    CALL PRINT_STRING
    POP HL
    CALL PRINT_RING
    LD A, 0x09
    CALL SENDCHAR_A
    CALL PRINT_BUFFER_DATA
    PUSH HL
    LD HL, CRLF
    CALL PRINT_STRING
    POP HL


.bufferStatus:
    CALL RING_IS_EMPTY
    JP C, .bufferEmpty
    CALL RING_IS_FULL
    JP C, .bufferFull
    PUSH HL
    LD HL, BUFFER_STATUS_NOT_EMPTY_MSG
    CALL PRINT_STRING
    POP HL
    JP .loop
.bufferEmpty:
    PUSH HL
    LD HL, BUFFER_STATUS_EMPTY_MSG
    CALL PRINT_STRING
    POP HL
    JP .loop
.bufferFull:
    PUSH HL
    LD HL, BUFFER_STATUS_FULL_MSG
    CALL PRINT_STRING
    POP HL
    JP .loop
.exit:
    RET

PRINT_RING: ; print the data of the ring buffer structure in IY
    PUSH AF
    PUSH HL
    
    LD HL, (IY + RING_BUFFER.HEAD_PTR)
    LD A, H
    CALL HEX2STR
    LD A, L
    CALL HEX2STR
    LD A, '-'
    CALL SENDCHAR_A

    LD HL, (IY + RING_BUFFER.TAIL_PTR)
    LD A, H
    CALL HEX2STR
    LD A, L
    CALL HEX2STR
    LD A, '-'
    CALL SENDCHAR_A

    LD HL, (IY + RING_BUFFER.BUFFER_SIZE)
    LD A, H
    CALL HEX2STR
    LD A, L
    CALL HEX2STR
    LD A, '-'
    CALL SENDCHAR_A

    LD HL, (IY + RING_BUFFER.BUFFER_ADDRESS)
    LD A, H
    CALL HEX2STR
    LD A, L
    CALL HEX2STR

    ; LD HL, CRLF
    ; CALL PRINT_STRING

    POP HL
    POP AF
    RET

PRINT_BUFFER_DATA: ; print the data of the ring buffer in iY
    PUSH AF
    PUSH BC
    PUSH HL

    LD BC, (IY + RING_BUFFER.BUFFER_SIZE)
    LD HL, (IY + RING_BUFFER.BUFFER_ADDRESS)
.printLoop:
    LD A, (HL)
    CALL SENDCHAR_A
    INC HL
    DEC BC
    LD A, B
    OR C
    JP NZ, .printLoop

    ; LD HL, CRLF
    ; CALL PRINT_STRING

    POP HL
    POP BC
    POP AF
    RET


CRLF:
    DB 0x0D, 0x0A, 0x00
EMPTY_BUFFER_MSG:
    DB " - Buffer is empty", 0x0D, 0x0A, 0x00
FULL_BUFFER_MSG:
    DB " - Buffer is full", 0x0D, 0x0A, 0x00
READ_BUFFER_MSG:
    DB "Value Read : ", 0x00
WRITE_BUFFER_MSG:
    DB "Value Written : ", 0x00
UNGET_BUFFER_MSG:
    DB "Value pushed back : ", 0x00
BUFFER_STATUS_EMPTY_MSG:
    DB "Buffer is empty", 0x0D, 0x0A, 0x00
BUFFER_STATUS_FULL_MSG:
    DB "Buffer is full", 0x0D, 0x0A, 0x00
BUFFER_STATUS_NOT_EMPTY_MSG:
    DB "Buffer contains data", 0x0D, 0x0A, 0x00

MY_RX_BUFFER    RING_BUFFER  ; This reserves 6 bytes for the control fields (SIZE, HEAD, TAIL)

