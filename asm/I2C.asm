; -------------       I2C            --------------
; ----- Connected to PIO (IORQ 0x00) PORT B -------
; -----  SDA on bit 0, SCL on bit 1     -----------
; -------------------------------------------------
    IFNDEF __I2C__
    DEFINE __I2C__ 1

  
; ==== PIO INIT ====
PIO_ADDR EQU 0x00 ; adresse de base du PIO
PIO_DATA_A EQU PIO_ADDR ; A0 = 0 -> Channel A / A1 = 0 -> Data
PIO_DATA_B EQU PIO_ADDR + 1 ; A0 = 1 -> Channel B / A1 = 0 -> Data
PIO_CTRL_A EQU PIO_ADDR + 2 ; A0 = 0 -> Channel A / A1 = 1 -> Cmd
PIO_CTRL_B EQU PIO_ADDR + 3 ; A0 = 1 -> Channel B / A1 = 1 -> Cmd
PIO_MODE3_CONTROL EQU 0b11001111 ; Set mode 3 control

I2C_SDA_LINE EQU 0x01 ; 
I2C_CLK_LINE EQU 0x02
I2C_SDA_READ EQU I2C_SDA_LINE ; SDA line, High is input, clk line on b2
I2C_SDA_WRITE EQU 0x00 ; SDA line, Low is output
I2C_SCL_H_SDA_H EQU I2C_CLK_LINE + I2C_SDA_LINE
I2C_SCL_H_SDA_L EQU I2C_CLK_LINE
I2C_SCL_L_SDA_H EQU I2C_SDA_LINE
I2C_SCL_L_SDA_L EQU 0x00


I2C_Delay: ; delay look - use B
    LD B, 10
.delay_loop:
    NOP
    DJNZ .delay_loop
    RET

I2C_Init: ; Init PIO for I2C - use A
    LD A, PIO_MODE3_CONTROL ; Set mode 3 Control
    OUT (PIO_CTRL_B), A
    LD A, I2C_SDA_WRITE;
    OUT (PIO_CTRL_B), A
    LD A, 0x07 ; No interrupt, no mask
    OUT (PIO_CTRL_B), A
    LD A, 0x00; Interrupt vector (not use in fact)
    OUT (PIO_CTRL_B), A
    LD A, I2C_SCL_H_SDA_H ; CLK high, SDA high
    OUT (PIO_DATA_B), A
    RET

I2C_Start_condition: ; send start condition - use A, B
    LD A, PIO_MODE3_CONTROL ; Set mode 3 Control
    OUT (PIO_CTRL_B), A
    LD A, I2C_SDA_WRITE;
    OUT (PIO_CTRL_B), A
    LD A, I2C_SCL_H_SDA_H ; CLK high, SDA high
    OUT (PIO_DATA_B), A
    LD A, I2C_SCL_H_SDA_L
    OUT (PIO_DATA_B), A
    LD A, I2C_SCL_L_SDA_L
    OUT (PIO_DATA_B), A
    CALL I2C_Delay
    RET

I2C_Restart_condition: ; send restart condition - use A, B
    LD A, PIO_MODE3_CONTROL ; Set mode 3 Control
    OUT (PIO_CTRL_B), A
    LD A, I2C_SDA_WRITE;
    OUT (PIO_CTRL_B), A
    LD A, I2C_SCL_L_SDA_H ; CLK low, SDA high
    OUT (PIO_DATA_B), A
    LD A, I2C_SCL_H_SDA_H ; CLK high, SDA high
    OUT (PIO_DATA_B), A
    LD A, I2C_SCL_H_SDA_L
    OUT (PIO_DATA_B), A
    LD A, I2C_SCL_L_SDA_L
    OUT (PIO_DATA_B), A
    CALL I2C_Delay
    RET

I2C_Stop_condition: ; send Stop condition - use A, B
    LD A, PIO_MODE3_CONTROL ; Set mode 3 Control
    OUT (PIO_CTRL_B), A
    LD A, I2C_SDA_WRITE;
    OUT (PIO_CTRL_B), A
    LD A, I2C_SCL_H_SDA_L ; CLK high, SDA low
    OUT (PIO_DATA_B), A
    LD A, I2C_SCL_H_SDA_H
    OUT (PIO_DATA_B), A
    CALL I2C_Delay
    RET

I2C_SendByte: ; byte to send in C - Ack result in Flag Z (Ack=Z) - use A, B
    LD A, PIO_MODE3_CONTROL ; Set mode 3 Control
    OUT (PIO_CTRL_B), A
    LD A, I2C_SDA_WRITE; Switch to write on SDA pin
    OUT (PIO_CTRL_B), A
    LD B, 0b10000000
    LD A, I2C_SCL_L_SDA_L
    OUT (PIO_DATA_B), A ; maybe unnecessary
.I2C_SendByteLoop:
    LD A, B
    AND C
    JP Z, .I2C_SendClk
    LD A, I2C_SDA_LINE ; set SDA value at high
.I2C_SendClk:
    OUT (PIO_DATA_B), A ; position SDA according to bit
    XOR I2C_CLK_LINE
    OUT (PIO_DATA_B), A ; rising clock pulse
    XOR I2C_CLK_LINE
    OUT (PIO_DATA_B), A ; falling clock pulse
    SRL B
    JP NZ, .I2C_SendByteLoop
.I2C_Receive_Ack: ; Ack result in Flag Z (Ack=Z)
    ; LD A, I2C_SCL_L_SDA_H
    ; OUT (PIO_DATA_B), A ; prepare for ack
    LD A, PIO_MODE3_CONTROL ; Set mode 3 Control
    OUT (PIO_CTRL_B), A
    LD A, I2C_SDA_READ; Switch to read on SDA pin
    OUT (PIO_CTRL_B), A
    XOR I2C_CLK_LINE
    OUT (PIO_DATA_B), A ; rising clock pulse
    IN A, (PIO_DATA_B)
    LD B, A ; save the input in B. Ack in bit SDA (0:ack, 1: nack)
    LD A, PIO_MODE3_CONTROL ; Set mode 3 Control
    OUT (PIO_CTRL_B), A
    LD A, I2C_SDA_WRITE; Switch to read on SDA pin
    OUT (PIO_CTRL_B), A

    LD A, B
    XOR I2C_CLK_LINE
    OUT (PIO_DATA_B), A ; falling clock pulse
    LD A, I2C_SDA_LINE
    AND B ; Save ACK result in flag Z
    CALL I2C_Delay
    RET

I2C_ReceiveByte: ; byte received in C - use A, B, C
    LD A, PIO_MODE3_CONTROL ; Set mode 3 Control
    OUT (PIO_CTRL_B), A
    LD A, I2C_SDA_READ; Switch to read on SDA pin
    OUT (PIO_CTRL_B), A
    LD B, 0x08
    LD C, 0x00
    LD A, I2C_SCL_L_SDA_L
    OUT (PIO_DATA_B), A ; maybe unnecessary
.I2C_ReceiveByteLoop:
    SLA C
    XOR I2C_CLK_LINE
    OUT (PIO_DATA_B), A ; rising clock pulse
    IN A, (PIO_DATA_B)
    BIT 0, A ; look at received bit in SDA
    JP Z, .I2C_receive_continue
    LD D, A ; save A in D
    LD A, 0x01 ; put 1 in C
    OR C
    LD C, A
    LD A, D
.I2C_receive_continue:
    XOR I2C_CLK_LINE
    OUT (PIO_DATA_B), A ; falling clock pulse
    DJNZ .I2C_ReceiveByteLoop
    RET

I2C_Send_Ack: ; send ACK after receive - use A, B
    LD A, PIO_MODE3_CONTROL ; Set mode 3 Control
    OUT (PIO_CTRL_B), A
    LD A, I2C_SDA_WRITE; Switch to write on SDA pin
    OUT (PIO_CTRL_B), A
    LD A, I2C_SCL_L_SDA_L
    OUT (PIO_DATA_B), A ; prepare for ack
    XOR I2C_CLK_LINE
    OUT (PIO_DATA_B), A ; rising clock pulse
    XOR I2C_CLK_LINE
    OUT (PIO_DATA_B), A ; falling clock pulse
    CALL I2C_Delay
    RET

I2C_Send_NAck: ; send NACK after receive - use A, B
    LD A, PIO_MODE3_CONTROL ; Set mode 3 Control
    OUT (PIO_CTRL_B), A
    LD A, I2C_SDA_WRITE; Switch to write on SDA pin
    OUT (PIO_CTRL_B), A
    LD A, I2C_SCL_L_SDA_H
    OUT (PIO_DATA_B), A ; prepare for ack
    XOR I2C_CLK_LINE
    OUT (PIO_DATA_B), A ; rising clock pulse
    XOR I2C_CLK_LINE
    OUT (PIO_DATA_B), A ; falling clock pulse
    CALL I2C_Delay
    RET

    ENDIF
