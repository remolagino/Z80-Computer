

    IFNDEF __SERIAL__
    DEFINE __SERIAL__ 1



; ==== CTC ADDRESS ====
CTC_ADDR EQU 0x20 ; adresse de base du CTC
CTC_CHANNEL_0 EQU CTC_ADDR ; A0 = 0 -> Channel 0
CTC_CHANNEL_1 EQU CTC_ADDR + 1 ; A0 = 1 -> Channel 1
CTC_CHANNEL_2 EQU CTC_ADDR + 2 ; A0 = 2 -> Channel 2
CTC_CHANNEL_3 EQU CTC_ADDR + 3 ; A0 = 3 -> Channel 3

; ==== SIO ADDRESS ====
SIO_ADDR EQU 0x10 ; adresse de base du SIO
SIO_DATA_A EQU SIO_ADDR ; A0 = 0 -> Channel A / A1 = 0 -> Data
SIO_DATA_B EQU SIO_ADDR + 1 ; A0 = 1 -> Channel B / A1 = 0 -> Data
SIO_CTRL_A EQU SIO_ADDR + 2 ; A0 = 0 -> Channel A / A1 = 1 -> Cmd
SIO_CTRL_B EQU SIO_ADDR + 3 ; A0 = 1 -> Channel B / A1 = 1 -> Cmd


; ------------------------------------------------------------
InitSerial_A: ; initialisation of SIO Channel A (Terminal)
; initialisation of CTC Channel 1 - 
    LD A, 0b01010111  ; CTC Mode : no interrupt, Counter, 
                      ; prescaler 16, Rising, Auto, constant,
                      ; continue op, control
    OUT (CTC_CHANNEL_1), A ; 
    LD A, 1 ; Time constant : 1 for 115200 baud (see calculation)
    OUT (CTC_CHANNEL_1), A ;

; ------------------------------------------------------------
; Initialisation du SIO canal A
; ------------------------------------------------------------

    ; Reset du SIO canal A
    LD A, 0x18           ; WR0 : Channel Reset
    OUT (SIO_CTRL_A), A

    ; Mode register pointer to WR4
    LD A, 0x04           ; WR0: Select WR4
    OUT (SIO_CTRL_A), A

    ; WR4: Async mode, 1 stop bit, no parity, x16 clock
    LD A, 0b01000100     ; Async, 8-bit, 1 stop, x16 clock
    OUT (SIO_CTRL_A), A

    ; WR0: Select WR3
    LD A, 0x03
    OUT (SIO_CTRL_A), A

    ; WR3: RX enable, 8-bit
    LD A, 0b11000001     ; RX Enable, 8 bits/char
    OUT (SIO_CTRL_A), A

    ; WR0: Select WR1 (no interrupts)
    LD A, 0x01
    OUT (SIO_CTRL_A), A

    LD A, 0x00           ; WR1: no interrupt
    OUT (SIO_CTRL_A), A

    ; WR0: Select WR5
    LD A, 0x05
    OUT (SIO_CTRL_A), A

    ; WR5: TX Enable, DTR active, 8-bit
    LD A, 0b11101000     ; TX Enable, RTS, DTR, 8 bits/char
    OUT (SIO_CTRL_A), A

    RET

; ------------------------------------------------------------
InitSerial_B: ; initialisation of SIO Channel B 
; initialisation of CTC Channel 2 - 
    LD A, 0b01010111  ; CTC Mode : no interrupt, Counter, 
                      ; prescaler 16, Rising, Auto, constant,
                      ; continue op, control
    OUT (CTC_CHANNEL_2), A ; 
    LD A, 1 ; Time constant for 115200 baud (with 16x clk on SIO)
    OUT (CTC_CHANNEL_2), A ;

; ------------------------------------------------------------
; Initialisation du SIO canal B
; ------------------------------------------------------------
    ; Reset du SIO canal B
    LD A, 0x18           ; WR0 : Channel Reset
    OUT (SIO_CTRL_B), A

    ; Mode register pointer to WR4
    LD A, 0x04           ; WR0: Select WR4
    OUT (SIO_CTRL_B), A

    ; WR4: Async mode, 1 stop bit, no parity, x16 clock
    LD A, 0b01000100     ; Async, 8-bit, 1 stop, x16 clock
    OUT (SIO_CTRL_B), A

    ; WR0: Select WR3
    LD A, 0x03
    OUT (SIO_CTRL_B), A

    ; WR3: RX enable, 8-bit
    LD A, 0b11000001     ; RX Enable, 8 bits/char
    OUT (SIO_CTRL_B), A

    ; WR0: Select WR1 (no interrupts)
    LD A, 0x01
    OUT (SIO_CTRL_B), A

    LD A, 0x00           ; WR1: no interrupt
    OUT (SIO_CTRL_B), A

    ; WR0: Select WR5
    LD A, 0x05
    OUT (SIO_CTRL_B), A

    ; WR5: TX Enable, DTR active, 8-bit
    LD A, 0b11101000     ; TX Enable, RTS, DTR, 8 bits/char
    OUT (SIO_CTRL_B), A

    RET


; ------------------------------------------------------------
; Print a message (0 terminated string, address in HL)
; ------------------------------------------------------------

PrintString: ; Print a message (0 terminated string, address in HL)
    PUSH AF
    PUSH HL
.loop:
    LD A, (HL)
    OR A
    JP Z, .end
    CALL SendChar_HL ; Send the character in HL to SIO port A
    INC HL
    JP .loop ; Continue printing the string
.end:
    POP HL
    POP AF
    RET


SendChar_HL: ; Send a character in (HL) to the SIO port A
  PUSH AF
.wait:
 ; Select Register 0 (status register) for SIO Port A
    LD A, 0       ; Register 0
    OUT (SIO_CTRL_A), A ; Write to control port A to select reg 0
    IN A, (SIO_CTRL_A)
    BIT 2, A             ; TX Buffer Empty?
    JR Z, .wait
    LD A, (HL)
    OUT (SIO_DATA_A), A
    POP AF
    RET

SendCharB_HL: ; Send a character in (HL) to the SIO port B
    PUSH AF
.wait:
 ; Select Register 0 (status register) for SIO Port A
    LD A, 0       ; Register 0
    OUT (SIO_CTRL_B), A ; Write to control port A to select reg 0
    IN A, (SIO_CTRL_B)
    BIT 2, A             ; TX Buffer Empty?
    JR Z, .wait
    LD A, (HL)
    OUT (SIO_DATA_B), A
    POP AF
    RET

SendChar_IX: ; Send a character in (IX) to the SIO port A
    PUSH AF
.wait:
 ; Select Register 0 (status register) for SIO Port A
    LD A, 0       ; Register 0
    OUT (SIO_CTRL_A), A ; Write to control port A to select reg 0
    IN A, (SIO_CTRL_A)
    BIT 2, A             ; TX Buffer Empty?
    JR Z, .wait
    LD A, (IX)
    OUT (SIO_DATA_A), A
    POP AF
    RET

SendChar_A: ; Send a character in A to the SIO port A
    PUSH AF
.wait:
 ; Select Register 0 (status register) for SIO Port A
    LD A, 0       ; Register 0
    OUT (SIO_CTRL_A), A ; Write to control port A to select reg 0
    IN A, (SIO_CTRL_A)
    BIT 2, A             ; TX Buffer Empty?
    JR Z, .wait
    POP AF
    OUT (SIO_DATA_A), A
    RET

ReceiveChar_A:     ; Wait for a character on Port A to be received (stored in A) Blocking
    LD A, 0
    OUT (SIO_CTRL_A), A        ; RR0
    IN A, (SIO_CTRL_A)
    BIT 0, A             ; RX char available ?
    JP Z, ReceiveChar_A

    IN A, (SIO_DATA_A)         ; read character
    RET

ReceiveCharNB_A:     ; Get a character from Port A NON BLOCKING (stored in A _ 0x00 is empty)
    LD A, 0
    OUT (SIO_CTRL_A), A        ; RR0
    IN A, (SIO_CTRL_A)
    BIT 0, A             ; RX char available ?
    JP NZ, .ReceiveChar_A
    LD A, 0x00            ; No character received
    RET
.ReceiveChar_A:
    IN A, (SIO_DATA_A)         ; Read character
    RET

ReceiveChar_B:     ; Wait for a character on Port B to be received (stored in A) Blocking
    LD A, 0
    OUT (SIO_CTRL_B), A        ; RR0
    IN A, (SIO_CTRL_B)
    BIT 0, A             ; RX char available ?
    JP Z, ReceiveChar_B

    IN A, (SIO_DATA_B)         ; Read character
    RET

    ENDIF