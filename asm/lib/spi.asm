; -------------       SPI            --------------
; ----- Connected to PIO (IORQ 0x00) PORT B -------
; -----  CS1 bit 4, SCLK bit 5           -----------
; -----  MOSI bit 6, MISO bit 7         -----------
; ----- TODO : Add CS2 on bit 3 for second SD card -----------
; -------------------------------------------------
    IFNDEF __SPI__
    DEFINE __SPI__ 1

    INCLUDE "pio.inc"


PIO_PORT_CFG EQU 0x87 ; MISO in, MOSI out, SCLK out, CS out, RTClk I2C in
SPI_MISO_BIT EQU 7 ; MISO bit position
SPI_MOSI_BIT EQU 6 ; MOSI bit position
SPI_SCLK_BIT EQU 5 ; SCLK bit position
SPI_CS1_BIT EQU 4 ; CS bit position
SPI_CS2_BIT EQU 3 ; CS bit position

SPI_Init: ; Init PIO for SPI on Port B - use A
    PUSH AF
    PUSH BC
    LD A, PIO_MODE3_CONTROL ; Set mode 3 Control
    OUT (PIO_CTRL_B), A
    LD A, PIO_PORT_CFG; set MISO as input
    OUT (PIO_CTRL_B), A
    LD A, 0x03 ; No interrupt, no mask
    OUT (PIO_CTRL_B), A
    LD A, 0xFF ; Set all bits high (MISO input will read high, MOSI SCLK CS will be high)
    SET SPI_CS1_BIT, A ; Set CS1 high
    SET SPI_CS2_BIT, A ; Set CS2 high
    RES SPI_SCLK_BIT, A; Set SCLK low
    SET SPI_MOSI_BIT, A; Set MOSI high
    OUT (PIO_DATA_B), A 
    LD B, 0x50
.initloop:
    SET SPI_SCLK_BIT, A
    OUT (PIO_DATA_B), A ; Set SCLK high
    RES SPI_SCLK_BIT, A
    OUT (PIO_DATA_B), A ; Set SCLK low
    DJNZ .initloop ; Loop until all bits are sent

;    RES SPI_CS1_BIT, A; Set CS low
    RES SPI_MOSI_BIT, A; Set MOSI low
    RES SPI_SCLK_BIT, A; Set SCLK low
    OUT (PIO_DATA_B), A ; Set CS low
    POP BC
    POP AF
    RET

SPI_CS1_SELECT:
    PUSH AF
    IN A, (PIO_DATA_B)
    RES SPI_CS1_BIT, A
    SET SPI_CS2_BIT, A
    OUT (PIO_DATA_B), A
    POP AF
    RET

SPI_CS2_SELECT:
    PUSH AF
    IN A, (PIO_DATA_B)
    RES SPI_CS2_BIT, A
    SET SPI_CS1_BIT, A
    OUT (PIO_DATA_B), A
    POP AF
    RET


SPI_endCom:
    PUSH AF
;    LD A, 0xFF ; Set all bits high (MISO input will read high, MOSI SCLK CS will be high)
    IN A, (PIO_DATA_B)
    SET SPI_CS1_BIT, A; Set CS high
    SET SPI_CS2_BIT, A; Set CS high    
    RES SPI_SCLK_BIT, A; Set SCLK low
    SET SPI_MOSI_BIT, A; Set MOSI high
    OUT (PIO_DATA_B), A 
    LD A, 0xFF
    CALL SPI_SEND_BYTE_A
    POP AF
    RET

SPI_SEND_BYTE_A: ; Send a byte to the SD card (byte in A)
    PUSH BC
    LD C, A
;    LD A, 0xFF
    IN A, (PIO_DATA_B) ; restore CS1 or CS2 byte
;    RES SPI_CS1_BIT, A
    RES SPI_SCLK_BIT, A
    SET SPI_MISO_BIT, A ; Set MISO line high - do nothing as input
    OUT (PIO_DATA_B), A ; Set SCLK low
    LD B, 0x08 ; Number of bits to send
.bitLoop:
    RES SPI_MOSI_BIT, A ; Clear MOSI line
    RLC C
    JP NC, .zerobit
    SET SPI_MOSI_BIT, A ; Set MOSI line
.zerobit:
    OUT (PIO_DATA_B), A ; Set MOSI line
    SET SPI_SCLK_BIT, A
    OUT (PIO_DATA_B), A ; Set SCLK high
    RES SPI_SCLK_BIT, A
    OUT (PIO_DATA_B), A ; Set SCLK low
    DJNZ .bitLoop ; Loop until all bits are sent
    SET SPI_MOSI_BIT, A ; MOSI high in idle
    OUT (PIO_DATA_B), A ; Set SCLK low
    POP BC
    RET

SPI_SEND_BYTES: ; Send multiple bytes to the SD card (HL points to data, B is length)
    PUSH BC
    PUSH HL
.sendLoop:
    LD A, (HL)
    CALL SPI_SEND_BYTE_A ; Send byte in A
    INC HL
    DJNZ .sendLoop ; Loop until all bytes are sent
    POP HL
    POP BC
    RET


SPI_READ_BYTE: ; read a byte in SPI - result in A
    PUSH BC
    PUSH DE
    LD E, 0xFF ; Response message
    IN A, (PIO_DATA_B) ; restore CS1 or CS2 bit
;    LD A, 0xFF 
;    RES SPI_CS1_BIT, A ; Set CS line low
    SET SPI_MOSI_BIT, A ; Set MOSI line high
    RES SPI_SCLK_BIT, A
    OUT (PIO_DATA_B), A ; Set SCLK low
    LD B, 0x08 ; Number of bits to send
.bitLoop:
    RLC E ; rotate response left
    SET SPI_SCLK_BIT, A
    LD C, A
    OUT (PIO_DATA_B), A ; Set SCLK high
    IN A, (PIO_DATA_B) ; Read response from MISO line
    BIT SPI_MISO_BIT,A
    JP NZ, .continue ; If MISO is high, don't reset bit in response
    RES 0, E 
.continue:
    LD A, C
    RES SPI_SCLK_BIT, A
    OUT (PIO_DATA_B), A ; Set SCLK low
    DJNZ .bitLoop ; Loop until all bits are sent
    LD A, E ; Load response byte in A
    POP DE
    POP BC
    RET


    ENDIF