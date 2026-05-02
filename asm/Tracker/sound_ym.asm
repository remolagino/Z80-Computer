; YM3812 (OPL2) Test Program for Z80
; Sound card connected to port 0x50 (address) and 0x51 (data)
; This program plays a simple sine wave tone

   IFNDEF __SOUND_YM__
   DEFINE __SOUND_YM__ 1

YM_ADDR EQU     0x50            ; YM3812 address/status port
YM_DATA EQU     0x51            ; YM3812 data port

    STRUCT YM3812_STRUCT
TREMOLO   BYTE
VIBRATO   BYTE
SUSTAIN   BYTE
KSR       BYTE
MULT      BYTE
KSL       BYTE
TL        BYTE
AR        BYTE
DR        BYTE
SL        BYTE
RR        BYTE
WAVEFORM   BYTE
FEEDBACK   BYTE
ALGORITHM  BYTE
    ENDS

YM_MOD  YM3812_STRUCT
YM_CARRIER  YM3812_STRUCT
YM_TMP_SOUND_BYTES 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ; Temporary storage for the 6 bytes to write to YM3812

YM_SET_SOUND_CHANNEL:
        LD IX, YM_MOD
        LD HL, YM_TMP_SOUND_BYTES
        CALL YM_SET_SOUND_BYTES

        LD A, 0x20
        LD C, (HL)
        CALL YM_WRITE
        INC HL
        LD A, 0x40
        LD C, (HL)
        CALL YM_WRITE
        INC HL
        LD A, 0x60
        LD C, (HL)
        CALL YM_WRITE
        INC HL
        LD A, 0x80
        LD C, (HL)
        CALL YM_WRITE
        INC HL
        LD A, 0xE0
        LD C, (HL)
        CALL YM_WRITE
        INC HL
        LD A, 0xC0
        LD C, (HL)
        CALL YM_WRITE


        LD IX, YM_CARRIER
        LD HL, YM_TMP_SOUND_BYTES
        CALL YM_SET_SOUND_BYTES
        LD A, 0x20 + 3
        LD C, (HL)
        CALL YM_WRITE
        INC HL
        LD A, 0x40 + 3
        LD C, (HL)
        CALL YM_WRITE
        INC HL
        LD A, 0x60 + 3
        LD C, (HL)
        CALL YM_WRITE
        INC HL
        LD A, 0x80 + 3
        LD C, (HL)
        CALL YM_WRITE
        INC HL
        LD A, 0xE0 + 3
        LD C, (HL)
        CALL YM_WRITE
        INC HL
        LD A, 0xC0 + 3
        LD C, (HL)
        CALL YM_WRITE

        RET

; build the value for registers 20 to 80, E0 and C0 based on the current sound settings
; take the struct in (IX)
; put the result in (HL)  (6 bytes)
YM_SET_SOUND_BYTES:
        PUSH BC
        PUSH HL
        PUSH IX
        ; register 20
        LD A, (IX + YM3812_STRUCT.TREMOLO)
        AND 0x01 ; Tremolo on/off
        RRCA
        LD C, A
        LD A, (IX + YM3812_STRUCT.VIBRATO)
        AND 0x01 ; Vibrato on/off
        RRCA
        RRCA
        OR C
        LD C, A
        LD A, (IX + YM3812_STRUCT.SUSTAIN)
        AND 0x01 ; Sustain on/off
        RRCA
        RRCA
        RRCA
        OR C
        LD C, A
        LD A, (IX + YM3812_STRUCT.KSR)
        AND 0x01 ; KSR on/off
        RRCA
        RRCA
        RRCA
        RRCA
        OR C
        LD C, A
        LD A, (IX + YM3812_STRUCT.MULT)
        AND 0x0F ; Mult value (0-15)
        OR C
        LD (HL), A

        INC HL
        ; register 40
        LD A, (IX + YM3812_STRUCT.KSL)
        AND 0x03 ; KSL value (0-3)
        RRCA
        RRCA
        LD C, A
        LD A, (IX + YM3812_STRUCT.TL)
        AND 0x7F ; TL value (0-127)
        OR C
        LD (HL), A

        INC HL
        ; register 60
        LD A, (IX + YM3812_STRUCT.AR)
        AND 0x0F ; AR value (0-31)
        RRCA
        RRCA
        RRCA
        RRCA
        LD C, A
        LD A, (IX + YM3812_STRUCT.DR)
        AND 0x0F ; DR value (0-31)
        OR C
        LD (HL), A

        INC HL
        ; register 80
        LD A, (IX + YM3812_STRUCT.SL)
        AND 0x0F ; SL value (0-15)
        RRCA
        RRCA
        RRCA
        RRCA
        LD C, A
        LD A, (IX + YM3812_STRUCT.RR)
        AND 0x0F ; RR value (0-15)
        OR C
        LD (HL), A

        INC HL
        ; register E0
        LD A, (IX + YM3812_STRUCT.WAVEFORM)
        AND 0x03 ; WAVEFORM value (0-3)
        LD (HL), A

        INC HL
        ; register E0
        LD A, (IX + YM3812_STRUCT.FEEDBACK)
        AND 0x07 ; FEEDBACK value (0-7)
        RLCA
        LD C, A
        LD A, (IX + YM3812_STRUCT.ALGORITHM)
        AND 0x01 ; ALGORITHM value (0-1)
        OR C
        LD (HL), A

        POP IX
        POP HL
        POP BC
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
.ym_resetLoop:
        LD      A, D
        LD      C, 0x00         ; Clear value
        CALL    YM_WRITE
        
        INC     D
        LD      A, D
        CP      0xF6            ; Stop at 0xF6
        JR      NZ, .ym_resetLoop
        
        ; Specifically turn off all channels (Key Off)
        LD      B, 9            ; 9 channels (0-8)
        LD      D, 0xB0         ; Base register for channel control
.ym_key_off:
        LD      A, D
        LD      C, 0x00         ; Key off, clear frequency
        CALL    YM_WRITE
        
        INC     D
        DJNZ    .ym_key_off
        
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
.ym_waitLoop:
        DJNZ    .ym_waitLoop
        POP     BC
        
        POP     AF
        RET
        
YM_SETSOUND:
        ; Configure Operator 1 (Modulator) for Channel 0
        LD      A, 0x20         ; AM/VIB/EG/KSR/MULT register
        LD      C, 0xD2         ; Multiply by 1
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
        LD      C, 0x02         ; some feedback and algo 1
        CALL    YM_WRITE


        RET


        ENDIF