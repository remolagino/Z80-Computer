; YM3812 (OPL2) Test Program for Z80
; Sound card connected to port 0x50 (address) and 0x51 (data)
; This program plays a simple sine wave tone

        ORG     0x5000          ; Start address

YM_ADDR EQU     0x50            ; YM3812 address/status port
YM_DATA EQU     0x51            ; YM3812 data port

KEYPAD_ADDR EQU 0x60
KEYPAD_BASECOL EQU KEYPAD_ADDR
KEYPAD_COLNUM EQU 0x04


START:
        CALL    YM_RESET        ; Properly reset the YM3812
        
        CALL YM_SETSOUND

.mainLoop:
    CALL keypadSCan
    LD A, (KEYPAD_BUFFER+3)
    AND 0x08 ; mask for the Enter key
    JP NZ, prog_end
    
    LD A, (KEYPAD_BUFFER)
    AND 0x01 ; mask for the first row
    JP Z, .noPress
    LD A,(KEYPAD_STATE)
    CP 0x01
    JP Z,.mainLoop
    LD A, 0x01
    LD (KEYPAD_STATE), A
        ; Turn on the note
        LD A, 0xB0
        LD C, 0x32
        CALL YM_WRITE

    JP .mainLoop
.noPress:
    LD A, (KEYPAD_STATE)
    CP 0x01
    JP NZ, .endNoPress
        ; Turn off the note
        LD      A, 0xB0
        LD      C, 0x12         ; Key Off (bit 5 = 0)
        CALL    YM_WRITE
.endNoPress:
    LD A, 0x00
    LD (KEYPAD_STATE), A
    JP .mainLoop

prog_end:
    CALL    YM_RESET        ; Properly reset the YM3812
    RET
        

; Subroutine to properly reset YM3812
; Clears all registers to silent state
YM_RESET:
        PUSH    AF
        PUSH    BC
        PUSH    DE
        
        ; Clear test register and set waveform select enable
        LD      A, 0x01
        LD      C, 0x20         ; Enable waveform select
        CALL    YM_WRITE
        
        ; Clear all channel registers (0x20-0xF5)
        LD      D, 0x20         ; Start register
YM_RST_LOOP:
        LD      A, D
        LD      C, 0x00         ; Clear value
        CALL    YM_WRITE
        
        INC     D
        LD      A, D
        CP      0xF6            ; Stop at 0xF6
        JR      NZ, YM_RST_LOOP
        
        ; Specifically turn off all channels (Key Off)
        LD      B, 9            ; 9 channels (0-8)
        LD      D, 0xB0         ; Base register for channel control
YM_KEY_OFF:
        LD      A, D
        LD      C, 0x00         ; Key off, clear frequency
        CALL    YM_WRITE
        
        INC     D
        DJNZ    YM_KEY_OFF
        
        POP     DE
        POP     BC
        POP     AF
        RET

; Subroutine to write to YM3812
; A = register address, C = data value
YM_WRITE:
        PUSH    AF
        OUT     (YM_ADDR), A    ; Write register address
        
        ; Wait ~3.3 microseconds (12 cycles at 3.58 MHz)
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        
        LD      A, C
        OUT     (YM_DATA), A    ; Write data
        
        ; Wait ~23 microseconds (84 cycles at 3.58 MHz)
        PUSH    BC
        LD      B, 25
YM_WAIT:
        DJNZ    YM_WAIT
        POP     BC
        
        POP     AF
        RET
        
YM_SETSOUND:
        ; Configure Operator 1 (Modulator) for Channel 0
        LD      A, 0x20         ; AM/VIB/EG/KSR/MULT register
        LD      C, 0x02         ; Multiply by 1
        CALL    YM_WRITE
        
        LD      A, 0x40         ; KSL/TL (Key Scale Level/Total Level)
        LD      C, 0x10         ; Total Level = 16 (moderate volume)
        CALL    YM_WRITE
        
        LD      A, 0x60         ; AR/DR (Attack Rate/Decay Rate)
        LD      C, 0xC1         ; Fast attack, medium decay
        CALL    YM_WRITE
        
        LD      A, 0x80         ; SL/RR (Sustain Level/Release Rate)
        LD      C, 0xA2         ; Medium sustain, medium release
        CALL    YM_WRITE
        
        ; Configure Operator 2 (Carrier) for Channel 0
        LD      A, 0x23         ; AM/VIB/EG/KSR/MULT register
        LD      C, 0x00         ; Multiply by 1
        CALL    YM_WRITE
        
        LD      A, 0x43         ; KSL/TL
        LD      C, 0x00         ; Max volume (0 = loudest)
        CALL    YM_WRITE
        
        LD      A, 0x63         ; AR/DR
        LD      C, 0x71         ; Fast attack, medium decay
        CALL    YM_WRITE
        
        LD      A, 0x83         ; SL/RR
        LD      C, 0x55         ; Medium sustain, medium release
        CALL    YM_WRITE
        
        ; Set frequency (A4 = 440 Hz)
        LD      A, 0xA0         ; Frequency low byte for channel 0
        LD      C, 0x41         ; Low byte of F-number
        CALL    YM_WRITE
        
        LD      A, 0xB0         ; Key On + Frequency high + Block
        LD      C, 0x12         ; Key On + Block 3 + high F-number
        CALL    YM_WRITE

        LD      A, 0xC0         ; Feedback + Algo
        LD      C, 0x00         ; some feedback and algo 1
        CALL    YM_WRITE


        RET

keypadSCan:
    PUSH BC
    PUSH HL
    LD C, KEYPAD_BASECOL
    LD B, KEYPAD_COLNUM

    LD HL, KEYPAD_BUFFER
.rowLoop:
    IN A, (C)
    LD (HL), A
    INC C
    INC HL
    DJNZ .rowLoop

    POP HL
    POP BC
    RET



KEYPAD_BUFFER
    DB 0x00, 0x00, 0x00, 0x00, 0x00

KEYPAD_STATE 
    DB 0x00, 0x00, 0x00, 0x00, 0x00
    DB 0x00, 0x00, 0x00, 0x00, 0x00
    DB 0x00, 0x00, 0x00, 0x00, 0x00
    DB 0x00, 0x00, 0x00, 0x00, 0x00
        END