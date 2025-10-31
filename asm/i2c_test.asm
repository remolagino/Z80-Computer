; ------------- Program START -----------------
    .ORG 0x6000

    JP Main

    INCLUDE "jumpTable.inc"
    INCLUDE "I2C.asm"


Main:
    CALL I2C_Init

loop:
    CALL I2C_Start_condition
    LD C, 0xF2
    CALL I2C_sendtest
    CALL I2C_Stop_condition
    JP loop

I2C_sendtest:
    LD A, PIO_MODE3_CONTROL ; Set mode 3 Control
    OUT (PIO_CTRL_B), A
    LD A, I2C_SDA_WRITE; Switch to write on SDA pin
    OUT (PIO_CTRL_B), A
    LD B, 0x80
    ; LD A, I2C_SCL_L_SDA_L
    ; OUT (PIO_DATA_B), A ; maybe unnecessary

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
