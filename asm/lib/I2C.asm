; -------------       I2C            --------------
; ----- Connected to PIO (IORQ 0x00) PORT B -------
; -----  SDA on bit 0, SCL on bit 1     -----------
; -------------------------------------------------
; -------------------------------------------------
    IFNDEF __I2C__
    DEFINE __I2C__ 1


    INCLUDE "../monitorv2/memoryMapv2.inc"
    INCLUDE "../lib/pio.inc"

  
; ; ==== PIO INIT ====
; PIO_ADDR EQU 0x00 ; adresse de base du PIO
; PIO_DATA_A EQU PIO_ADDR ; A0 = 0 -> Channel A / A1 = 0 -> Data
; PIO_DATA_B EQU PIO_ADDR + 1 ; A0 = 1 -> Channel B / A1 = 0 -> Data
; PIO_CTRL_A EQU PIO_ADDR + 2 ; A0 = 0 -> Channel A / A1 = 1 -> Cmd
; PIO_CTRL_B EQU PIO_ADDR + 3 ; A0 = 1 -> Channel B / A1 = 1 -> Cmd
; PIO_MODE3_CONTROL EQU 0b11001111 ; Set mode 3 control
PIO_PORT_CFG EQU 0x87 ; MISO in, MOSI out, SCLK out, CS out, RTClk I2C in

I2C_SDA_LINE_BIT EQU 0
I2C_SCL_LINE_BIT EQU 1

I2C_READ EQU 1
I2C_WRITE EQU 0


I2C_Delay: ; delay look - use B
    PUSH BC
    LD B, 10
.delay_loop:
    NOP
    DJNZ .delay_loop
    POP BC
    RET

I2C_Apply:
    LD A, PIO_MODE3_CONTROL  ; Force Mode 3 (Bit Control)
    OUT (PIO_CTRL_B), A
    LD A, (PIO_PORT_B_STATUS)
    OUT (PIO_CTRL_B), A ; Applique les directions (1=In, 0=Out)
    RET

SDA_HIGH: ; SDA line set as Input
    PUSH AF
    LD A, (PIO_PORT_B_STATUS)
    SET I2C_SDA_LINE_BIT, A
    LD (PIO_PORT_B_STATUS), A
    CALL I2C_Apply
    POP AF
    RET

SDA_LOW:
    PUSH AF
    LD A, (PIO_PORT_B_STATUS)
    RES I2C_SDA_LINE_BIT, A
    LD (PIO_PORT_B_STATUS), A
    CALL I2C_Apply
    XOR A
    OUT (PIO_DATA_B), A
    POP AF
    RET

SCL_HIGH:
    PUSH AF
    LD A, (PIO_PORT_B_STATUS)
    SET I2C_SCL_LINE_BIT, A
    LD (PIO_PORT_B_STATUS), A
    CALL I2C_Apply
    POP AF
    RET

SCL_LOW:
    PUSH AF
    LD A, (PIO_PORT_B_STATUS)
    RES I2C_SCL_LINE_BIT, A
    LD (PIO_PORT_B_STATUS), A
    CALL I2C_Apply
    XOR A
    OUT (PIO_DATA_B), A
    POP AF
    RET

I2C_Init: ; Init PIO for I2C
    PUSH AF
    LD A, PIO_MODE3_CONTROL ; Set mode 3 Control
    OUT (PIO_CTRL_B), A
    LD A, PIO_PORT_CFG ; get the status
;    OR 0x03; SCL and SDA to input; therefore scl and sda are high
    LD (PIO_PORT_B_STATUS), A ; save the status
    OUT (PIO_CTRL_B), A
    LD A, 0x03 ; No interrupt, no mask
    OUT (PIO_CTRL_B), A
    POP AF
    RET

I2C_Start_condition: ; send start condition
    PUSH AF
    CALL SDA_HIGH
    CALL SCL_HIGH
    CALL SDA_LOW
    CALL I2C_Delay
    CALL SCL_LOW
    CALL I2C_Delay
    POP AF
    RET

I2C_Restart_condition: ; send restart condition
    PUSH AF
    CALL SDA_HIGH     ; Relâcher SDA (entrée/pull-up)
    CALL I2C_Delay
    CALL SCL_HIGH     ; Remonter SCL
    CALL I2C_Delay
    CALL SDA_LOW      ; SDA tombe alors que SCL est haut (START)
    CALL I2C_Delay
    CALL SCL_LOW      ; Verrouiller le bus pour l'octet suivant
    CALL I2C_Delay
    POP AF
    RET

I2C_Stop_condition: ; send Stop condition
    PUSH AF
    CALL SDA_LOW
    CALL I2C_Delay
    CALL SCL_HIGH
    CALL I2C_Delay
    CALL SDA_HIGH
    CALL I2C_Delay
    POP AF
    RET

I2C_SendByte: ; byte to send in A - Ack result in Flag Z (Ack=Z) - use A
    PUSH BC
    LD B, 8
.sendByteLoop:    
    RLA
    JP C, .sendOne
    CALL SDA_LOW
    JP .clock
.sendOne:
    CALL SDA_HIGH
.clock:
    CALL SCL_HIGH
    CALL SCL_LOW
    DJNZ .sendByteLoop
.receiveAck:
    CALL SDA_HIGH ; release SDA line
    CALL SCL_HIGH
    IN A, (PIO_DATA_B)
    CALL SCL_LOW
    BIT I2C_SDA_LINE_BIT, A; set the zero flag for ack
    POP BC
    RET


I2C_ReceiveByte: ; byte received in A ; flag Z cleared
    PUSH BC
    LD B, 8
    LD C, 0 ; receive the byte
    CALL SDA_HIGH
    CALL SCL_LOW
.receiveByteLoop:
;    CALL I2C_Delay
    CALL SCL_HIGH
    CALL I2C_Delay
    IN A, (PIO_DATA_B)
    OR A ; clear carry and zero flag
    BIT I2C_SDA_LINE_BIT, A
    JP Z, .shiftZero
    SCF ; prepare the one
.shiftZero:
    RL C
    CALL SCL_LOW
    DJNZ .receiveByteLoop
    LD A, 0x00
    OR A
    LD A, C
    POP BC
    RET

I2C_Send_Ack: ; send ACK after receive - use A, B
    CALL SDA_LOW
    CALL SCL_HIGH
    CALL I2C_Delay
    CALL SCL_LOW
;    CALL I2C_Delay
    RET

I2C_Send_NAck: ; send NACK after receive - use A, B
    CALL SDA_HIGH
    CALL SCL_HIGH
    CALL I2C_Delay
    CALL SCL_LOW
;    CALL I2C_Delay
    RET

    ENDIF
