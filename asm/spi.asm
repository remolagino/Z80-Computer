; -------------       SPI            --------------
; ----- Connected to PIO (IORQ 0x00) PORT A -------
; -----  CS bit 4, SCLK bit 5           -----------
; -----  MOSI bit 6, MISO bit 7         -----------
; -------------------------------------------------
    IFNDEF __SPI__
    DEFINE __SPI__ 1

    INCLUDE "./monitorv2/memoryMapv2.inc"
    INCLUDE "./lib/pio.inc"


; ; ==== PIO INIT ====
; PIO_ADDR EQU 0x00 ; adresse de base du PIO
; PIO_DATA_A EQU PIO_ADDR ; A0 = 0 -> Channel A / A1 = 0 -> Data
; ;PIO_DATA_B EQU PIO_ADDR + 1 ; A0 = 1 -> Channel B / A1 = 0 -> Data
; PIO_CTRL_A EQU PIO_ADDR + 2 ; A0 = 0 -> Channel A / A1 = 1 -> Cmd
; ;PIO_CTRL_B EQU PIO_ADDR + 3 ; A0 = 1 -> Channel B / A1 = 1 -> Cmd
; PIO_MODE3_CONTROL EQU 0b11001111 ; Set mode 3 control

; SPI_CS_OR_Msk EQU 0x10 ; Chip Select
; SPI_CS_AND_Msk EQU 0xEF ; Chip Select
; SPI_SCLK EQU 0x20 ; ; clk line, High is input
; SPI_MOSI_OR_Msk EQU 0x40 ; Master Out Slave In
; SPI_MOSI_AND_Msk EQU 0xBF ; Master Out Slave In
SPI_MISO_ EQU 0x80 ; Master In Slave Out
SPI_MISO_BIT EQU 7 ; MISO bit position
SPI_MOSI_BIT EQU 6 ; MOSI bit position
SPI_SCLK_BIT EQU 5 ; SCLK bit position
SPI_CS_BIT EQU 4 ; CS bit position

SPI_Init: ; Init PIO for SPI on Port A - use A
    PUSH BC
    LD A, PIO_MODE3_CONTROL ; Set mode 3 Control
    OUT (PIO_CTRL_A), A
    LD A, SPI_MISO_; set MISO as input
    OUT (PIO_CTRL_A), A
    LD A, 0x03 ; No interrupt, no mask
    OUT (PIO_CTRL_A), A
    ; LD A, 0x00; Interrupt vector (not use in fact)
    ; OUT (PIO_CTRL_A), A
    LD A, (PIO_PORT_A_STATUS)
    SET SPI_CS_BIT, A; Set CS high
    RES SPI_SCLK_BIT, A; Set SCLK low
    SET SPI_MOSI_BIT, A; Set MOSI high
;    LD A, SPI_CS_OR_Msk ; Set CS high, clk low
;    OR SPI_MOSI_OR_Msk ; Set MOSI high
    OUT (PIO_DATA_A), A 
    LD B, 0x50
.initloop:
    SET SPI_SCLK_BIT, A
;    XOR SPI_SCLK
    OUT (PIO_DATA_A), A ; Set SCLK high
    RES SPI_SCLK_BIT, A
;    XOR SPI_SCLK
    OUT (PIO_DATA_A), A ; Set SCLK low
    DJNZ .initloop ; Loop until all bits are sent
    NOP
    NOP
    NOP
    NOP
    RES SPI_CS_BIT, A; Set CS low
;    AND SPI_CS_AND_Msk ; Set CS low
    OUT (PIO_DATA_A), A ; Set CS low
    POP BC
    RET

SPI_SEND_BYTE_A: ; Send a byte to the SD card (byte in A)
    PUSH BC
    LD C, A
    LD A, 0x00
    RES SPI_SCLK_BIT, A
    OUT (PIO_DATA_A), A ; Set SCLK low
    LD B, 0x08 ; Number of bits to send
.bitLoop:
    RES SPI_MOSI_BIT, A ; Clear MOSI line
    RLC C
    JP NC, .zerobit
    SET SPI_MOSI_BIT, A ; Set MOSI line
.zerobit:
    OUT (PIO_DATA_A), A ; Set MOSI line
    SET SPI_SCLK_BIT, A
    OUT (PIO_DATA_A), A ; Set SCLK high
    RES SPI_SCLK_BIT, A
    OUT (PIO_DATA_A), A ; Set SCLK low
    DJNZ .bitLoop ; Loop until all bits are sent
    POP BC
    RET

SPI_SEND_BYTE: ; Send a byte to the SD card (byte in (HL)
    PUSH BC
;    LD A, 0x00
    RES SPI_SCLK_BIT, A
    OUT (PIO_DATA_A), A ; Set SCLK low
    LD B, 0x08 ; Number of bits to send
    LD C, (HL)
.bitLoop:
    RES SPI_MOSI_BIT, A ; Clear MOSI line
    RLC C
    JP NC, .zerobit
    SET SPI_MOSI_BIT, A ; Set MOSI line
.zerobit:
    OUT (PIO_DATA_A), A ; Set MOSI line
    SET SPI_SCLK_BIT, A
    OUT (PIO_DATA_A), A ; Set SCLK high
    RES SPI_SCLK_BIT, A
    OUT (PIO_DATA_A), A ; Set SCLK low
    DJNZ .bitLoop ; Loop until all bits are sent
    POP BC
    RET


SPI_READ_BYTE: ; read a byte in SPI - result in A
    PUSH BC
    PUSH DE
    LD E, 0xFF ; Response message
    LD A, 0x00 
    SET SPI_MOSI_BIT, A ; Set MOSI line high
    RES SPI_SCLK_BIT, A
    OUT (PIO_DATA_A), A ; Set SCLK low
    LD B, 0x08 ; Number of bits to send
.bitLoop:
    RLC E ; rotate response left
;    OR SPI_MOSI_OR_Msk ; Set MOSI line high
;    OR SPI_MISO ; Set MISO line high
;    SET SPI_MISO_BIT, A ; Set MISO line high
;    OUT (PIO_DATA_A), A ; Send MOSI high MISO high
    SET SPI_SCLK_BIT, A
    OUT (PIO_DATA_A), A ; Set SCLK high
    IN A, (PIO_DATA_A) ; Read response from MISO line
    BIT SPI_MISO_BIT,A
    JP NZ, .continue ; If MISO is high, don't reset bit in response
    RES 0, E 
.continue:
    RES SPI_SCLK_BIT, A
    OUT (PIO_DATA_A), A ; Set SCLK low
    DJNZ .bitLoop ; Loop until all bits are sent
    LD A, E ; Load response byte in A
    POP DE
    POP BC
    RET


    ENDIF