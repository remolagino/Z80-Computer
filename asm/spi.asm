    IFNDEF __SPI__
    DEFINE __SPI__ 1



; ==== PIO INIT ====
PIO_ADDR EQU 0x00 ; adresse de base du PIO
PIO_DATA_A EQU PIO_ADDR ; A0 = 0 -> Channel A / A1 = 0 -> Data
;PIO_DATA_B EQU PIO_ADDR + 1 ; A0 = 1 -> Channel B / A1 = 0 -> Data
PIO_CTRL_A EQU PIO_ADDR + 2 ; A0 = 0 -> Channel A / A1 = 1 -> Cmd
;PIO_CTRL_B EQU PIO_ADDR + 3 ; A0 = 1 -> Channel B / A1 = 1 -> Cmd
PIO_MODE3_CONTROL EQU 0b11001111 ; Set mode 3 control

SPI_CS_OR_Msk EQU 0x10 ; Chip Select
SPI_CS_AND_Msk EQU 0xEF ; Chip Select
SPI_SCLK EQU 0x20 ; ; clk line, High is input
SPI_MOSI_OR_Msk EQU 0x40 ; Master Out Slave In
SPI_MOSI_AND_Msk EQU 0xBF ; Master Out Slave In
SPI_MISO EQU 0x80 ; Master In Slave Out
SPI_MISO_BIT EQU 7 ; MISO bit position



SPI_Init: ; Init PIO for SPI on Port A - use A
    PUSH BC
    LD A, PIO_MODE3_CONTROL ; Set mode 3 Control
    OUT (PIO_CTRL_A), A
    LD A, SPI_MISO; set MISO as input
    OUT (PIO_CTRL_A), A
    LD A, 0x07 ; No interrupt, no mask
    OUT (PIO_CTRL_A), A
    LD A, 0x00; Interrupt vector (not use in fact)
    OUT (PIO_CTRL_A), A

    LD A, SPI_CS_OR_Msk ; Set CS high, clk low
    OR SPI_MOSI_OR_Msk ; Set MOSI high
    OUT (PIO_DATA_A), A 
    LD B, 0x50
.initloop:
    XOR SPI_SCLK
    OUT (PIO_DATA_A), A ; Set SCLK high
    XOR SPI_SCLK
    OUT (PIO_DATA_A), A ; Set SCLK low
    DJNZ .initloop ; Loop until all bits are sent
    NOP
    NOP
    NOP
    NOP
    AND SPI_CS_AND_Msk ; Set CS low
    OUT (PIO_DATA_A), A ; Set CS low
    POP BC
    RET

SPI_SEND_BYTE: ; Send a byte to the SD card (byte in (HL)
    PUSH BC
    LD A, 0x00
    LD B, 0x08 ; Number of bits to send
    LD C, (HL)
.bitLoop:
    AND SPI_MOSI_AND_Msk ; Clear MOSI line
    RLC C
    JP NC, .zerobit
    OR SPI_MOSI_OR_Msk ; Set MOSI line
.zerobit:
    OUT (PIO_DATA_A), A ; Set MOSI line
    XOR SPI_SCLK
    OUT (PIO_DATA_A), A ; Set SCLK high
    XOR SPI_SCLK
    OUT (PIO_DATA_A), A ; Set SCLK low
    DJNZ .bitLoop ; Loop until all bits are sent
    POP BC
    RET


SPI_READ_BYTE: ; read a byte in SPI - result in E (modify E)
    PUSH BC
    LD E, 0xFF ; Response message
    LD A, 0x00 
    LD B, 0x08 ; Number of bits to send
.bitLoop:
    RLC E ; rotate response left
    OR SPI_MOSI_OR_Msk ; Set MOSI line high
    OR SPI_MISO ; Set MISO line high
    OUT (PIO_DATA_A), A ; Send MOSI high MISO high
    XOR SPI_SCLK
    OUT (PIO_DATA_A), A ; Set SCLK high
    IN A, (PIO_DATA_A) ; Read response from MISO line
    BIT SPI_MISO_BIT,A
    JP NZ, .continue ; If MISO is high, don't reset bit in response
    RES 0, E 
.continue:
    XOR SPI_SCLK
    OUT (PIO_DATA_A), A ; Set SCLK low
    DJNZ .bitLoop ; Loop until all bits are sent
    POP BC
    RET


    ENDIF