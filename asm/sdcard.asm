
   IFNDEF __SDCARD__
    DEFINE __SDCARD__ 1



    INCLUDE "jumpTable.inc"
    INCLUDE "spi.asm"
;    INCLUDE "string.asm"


SDCARD_SendCmd: ; Send a command to the SD card (in HL)
    ; Input: HL points to SDCARD_COMMAND structure
    PUSH HL
    PUSH BC
    LD A, 0x00
    LD C, 0x06 ; Number of bytes to send (CMD + ARG + CRC)
.byteLoop:
    CALL SPI_SEND_BYTE
    INC HL; ; Move to next byte in command structure
    DEC C 
    JP NZ, .byteLoop ; Loop until all bytes are sent
    POP BC
    POP HL
    RET

SDCARD_SendCmd17: ; Send a command to the SD card (Address in HL)
    PUSH BC
    PUSH HL
    LD A, 0x00
    LD HL, SDCARD_CMD17 ; Prepare CMD17 command with sector address
    CALL SPI_SEND_BYTE
    POP HL
    PUSH HL ; save original HL to reset at the end
    ;    LD HL, SDCARD_SECTOR_ADDRESS ; Load sector address
    INC HL
    INC HL
    INC HL
    LD C, 0x04 ; Number of bytes to send (CMD + ARG + CRC)
.byteLoop:
    CALL SPI_SEND_BYTE
    DEC HL; ; Move to next byte in command structure
    DEC C 
    JP NZ, .byteLoop ; Loop until all bytes are sent
    LD HL, SDCARD_CMD17 + 0x05 ; CRC byte for CMD17
    CALL SPI_SEND_BYTE ; Send CRC byte
    POP HL
    POP BC
    RET

SDCARD_SendCmd18: ; Send a command to the SD card (Address in HL)
    PUSH BC
    PUSH HL
    LD A, 0x00
    LD HL, SDCARD_CMD18 ; Prepare CMD17 command with sector address
    CALL SPI_SEND_BYTE
    POP HL
    PUSH HL ; push HL to save for reset at the END_CYLSEC
    INC HL
    INC HL
    INC HL
;    LD HL, SDCARD_SECTOR_ADDRESS ; Load sector address
    LD C, 0x04 ; Number of bytes to send (CMD + ARG + CRC)
.byteLoop:
    CALL SPI_SEND_BYTE
    DEC HL; ; Move to next byte in command structure
    DEC C 
    JP NZ, .byteLoop ; Loop until all bytes are sent
    LD HL, SDCARD_CMD18 + 0x05 ; CRC byte for CMD17
    CALL SPI_SEND_BYTE ; Send CRC byte
    POP HL
    POP BC
    RET

SDCARD_INIT_SECTOR_ADDRESS: ; Send a command to the SD card (Address in SDCARD_SECTOR_ADDRESS)
    LD A, 0x00
    LD (SDCARD_SECTOR_ADDRESS), A
    LD (SDCARD_SECTOR_ADDRESS+1), A
    LD (SDCARD_SECTOR_ADDRESS+2), A
    LD (SDCARD_SECTOR_ADDRESS+3), A
    RET

SDCARD_Wait_R1: ; Wait for a response from the SD card - resp in (SDCARD_R1)
    PUSH BC
    PUSH DE
    PUSH HL
    LD C, 0x30 ; Number of wait bytes to send
.byteLoop:
    CALL SPI_READ_BYTE ; Read a byte from the SD card
    ; check if E is still 0xFF, if not this is a valid response
    ; can also just check that bit 7 of E is 0
    LD A, E
    AND 0x80 ; Check if response is valid (bit 7 should be 0)
    JP Z, .validResponse ; If valid response, continue
    DEC C 
    JP NZ, .byteLoop ; Loop until all bytes are sent
.validResponse:
    LD HL, SDCARD_R1 ; Response is valid, return
    LD (HL), E ; Store response in SDCARD_R1
    POP HL
    POP DE
    POP BC
    RET


SDCARD_GetResponse: ; Wait for a response from the SD card
    PUSH BC
    PUSH DE
    PUSH HL
    LD C, 0x04 ; Number of  bytes to get
    LD HL, SDCARD_RESPONSE ; Response buffer address
.byteLoop:
    CALL SPI_READ_BYTE ; Read a byte from the SD card
    LD (HL), E
    INC HL
    DEC C 
    JP NZ, .byteLoop ; Loop until all bytes are sent
.end:
    POP HL
    POP DE
    POP BC
    RET

SDCARD_PrintResponse: ; Print the response from the SD card
    PUSH HL
    LD HL, SDCARD_RESPONSE ; Response buffer address
    LD A, (HL) ; Read first byte of response
    CALL HEX2STR ; Convert response to string for display
    LD A, '-' ; Send '-' character to SIO port A
    CALL SENDCHAR_A ; Send '-' character to SIO port A
    INC HL ; Move to next byte in response buffer
    LD A, (HL) ; Read next byte of response
    CALL HEX2STR ; Convert response to string for display
    LD A, '-' ; Send '-' character to SIO port A
    CALL SENDCHAR_A ; Send '-' character to SIO port A
    INC HL ; Move to next byte in response buffer
    LD A, (HL) ; Read next byte of response
    CALL HEX2STR ; Convert response to string for display
    LD A, '-' ; Send '-' character to SIO port A
    CALL SENDCHAR_A ; Send '-' character to SIO port A
    INC HL ; Move to next byte in response buffer
    LD A, (HL) ; Read next byte of response
    CALL HEX2STR ; Convert response to string for display
    POP HL
    RET

SDCARD_WaitToken: ; Wait for a token from the SD card
    PUSH BC
    PUSH DE
    PUSH HL
    LD C, 0x30 ; Number of  bytes to get
    LD HL, SDCARD_RESPONSE ; Response buffer address
.byteLoop:
    CALL SPI_READ_BYTE
    ; check if E is still 0xFF, if not this is a valid response
    ; can also just check that bit 7 of E is 0
    LD A, E
    CP SDCARD_START_TOKEN_RW
    JP Z, .end
    DEC C 
    JP NZ, .byteLoop ; Loop until all bytes are sent
.end:
    POP HL
    POP DE
    POP BC
    RET


SDCARD_PRINT_BLOCK: ; Read a block of data from the SD card
    PUSH BC
    PUSH DE
    PUSH HL
    LD D, 0x00 ; Number of 16 bytes to read (512 bytes)
    LD HL, (SDCARD_BUFFER_ADDRESS)
;    LD HL, SDCARD_BUFFER
.blockLoop:
    LD C, 0x10 ; Number of bytes to read
.rowLoop:
    CALL SPI_READ_BYTE ; Read a byte from the SD card
    LD (HL), E
    INC HL
    DEC C
    JP NZ, .rowLoop ; Loop until all bytes are sent
    INC D ; Increment block counter
    LD A, D
    CP 0x20 ; Check if D is 32
    JP NZ, .blockLoop ; If not zero, read next block
    LD HL, (SDCARD_BUFFER_ADDRESS) ; Load the buffer address
;    LD HL, SDCARD_BUFFER ; Load the buffer address
    CALL PRINT_HEX
    LD HL, LF_CR ; Load the header string ADDRESS
    CALL PRINT_STRING ; Print the header string
    LD HL, (SDCARD_BUFFER_ADDRESS)
    PUSH DE
    LD DE, 0x0100
    ADD HL, DE ; Load the buffer address
    POP DE
;    LD HL, SDCARD_BUFFER+ 0x100 ; Load the buffer address
    CALL PRINT_HEX ; Print the buffer as hex
.readCRC:
    CALL SPI_READ_BYTE ; Read CRC byte from the SD card
    CALL SPI_READ_BYTE ; Read CRC byte from the SD card
    POP HL
    POP DE
    POP BC
    RET

SDCARD_READ_BLOCK: ; Read a block of data from the SD card
    PUSH BC
    PUSH DE
    PUSH HL
    LD D, 0x00 ; Number of 16 bytes to read (512 bytes)
    LD HL, (SDCARD_BUFFER_ADDRESS)
;    LD HL, SDCARD_BUFFER
.blockLoop:
    LD C, 0x10 ; Number of bytes to read
.rowLoop:
    CALL SPI_READ_BYTE ; Read a byte from the SD card
    LD (HL), E
    INC HL
    DEC C
    JP NZ, .rowLoop ; Loop until all bytes are sent
    INC D ; Increment block counter
    LD A, D
    CP 0x20 ; Check if D is 32
    JP NZ, .blockLoop ; If not zero, read next block
.readCRC:
    CALL SPI_READ_BYTE ; Read CRC byte from the SD card
    CALL SPI_READ_BYTE ; Read CRC byte from the SD card
    POP HL
    POP DE
    POP BC
    RET


SDCARD_INIT:
    CALL SPI_Init

    LD A, 0x00 ; Set CS low
    OUT (PIO_DATA_A), A ; Set CS low

    LD HL, SDCARD_CMD0_MSG ; Prepare CMD0 message   
    CALL PRINT_STRING ; Print CMD0 message
    LD HL, SDCARD_CMD0 ; Prepare CMD0 command
    CALL SDCARD_SendCmd ; Send CMD0 to SD card
    CALL SDCARD_Wait_R1 ; Wait for response from SD card
    LD A, (SDCARD_R1)
; error check
    AND 0x7E ; Check if response is valid (R1 response)
    JP Z, .continue1
    CALL HEX2STR ; Convert response to string for display
    LD HL, SDCARD_ERRROR_MSG ; Prepare error message
    CALL PRINT_STRING ; Print error message
    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response
    LD A, 0x01
    RET
.continue1:
    LD A, (SDCARD_R1)
    CALL HEX2STR ; Convert response to string for display
    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response

    LD HL, SDCARD_CMD8_MSG ; Prepare CMD0 message   
    CALL PRINT_STRING ; Print CMD0 message
    LD HL, SDCARD_CMD8 ; Prepare CMD8 command
    CALL SDCARD_SendCmd ; Send CMD8 to SD card
    CALL SDCARD_Wait_R1 ; Wait for response from SD card
    CALL SDCARD_GetResponse
    LD A, (SDCARD_R1)
; error check
    AND 0x7E ; Check if response is valid (R1 response)
    JP Z, .continue2
    CALL HEX2STR ; Convert response to string for display
    LD HL, SDCARD_ERRROR_MSG ; Prepare error message
    CALL PRINT_STRING ; Print error message
    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response
    LD A, 0x02
    RET
.continue2:
    CALL HEX2STR ; Convert response to string for display
    LD A, '-'
    CALL SENDCHAR_A ; Send '-' character to SIO port A
    CALL SDCARD_PrintResponse ; Print the response from the SD Card
    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response

   LD HL, SDCARD_CMD55_MSG ; Prepare CMD0 message   
    CALL PRINT_STRING ; Print CMD0 message
.cmd41_waitloop:
    LD HL, SDCARD_CMD55 ; Prepare CMD8 command
    CALL SDCARD_SendCmd ; Send CMD8 to SD card
    CALL SDCARD_Wait_R1 ; Wait for response from SD card
; error check
    AND 0x7E ; Check if response is valid (R1 response)
    JP Z, .continue3
    CALL HEX2STR ; Convert response to string for display
    LD HL, SDCARD_ERRROR_MSG ; Prepare error message
    CALL PRINT_STRING ; Print error message
    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response
    LD A, 0x03
    RET
.continue3:
    LD HL, SDCARD_ACMD41 ; Prepare ACMD41 command
    CALL SDCARD_SendCmd ; Send ACMD41 to SD card
    CALL SDCARD_Wait_R1 ; Wait for response from SD card
    LD A, (SDCARD_R1)
    CP 0x00
    JP NZ, .cmd41_waitloop

    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response

    LD HL, SDCARD_ACMD41_MSG ; Prepare ACMD41 message   
    CALL PRINT_STRING ; Print CMD0 message

    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response
    LD A, 0x00 ; Init went well
    RET


; SD Card Commands
; Standard SD Card Commands
SDCARD_CMD0   :   DB  0x40, 0x00, 0x00, 0x00, 0x00, 0x95 ; CMD0 - GO_IDLE_STATE
SDCARD_CMD1   :   DB  0x41, 0x00, 0x00, 0x00, 0x00, 0xFF ; CMD1 - SEND_OP_COND
SDCARD_CMD6   :   DB  0x46, 0x00, 0x00, 0x00, 0x00, 0xFF ; CMD6 - SWITCH_FUNC
SDCARD_CMD8   :   DB  0x48, 0x00, 0x00, 0x01, 0xAA, 0x87 ; CMD8 - SEND_IF_COND
SDCARD_CMD9   :   DB  0x49, 0x00, 0x00, 0x00, 0x00, 0xFF ; CMD9 - SEND_CSD
SDCARD_CMD10  :   DB  0x4A, 0x00, 0x00, 0x00, 0x00, 0xFF ; CMD10 - SEND_CID
SDCARD_CMD12  :   DB  0x4C, 0x00, 0x00, 0x00, 0x00, 0xFF ; CMD12 - STOP_TRANSMISSION
SDCARD_CMD13  :   DB  0x4D, 0x00, 0x00, 0x00, 0x00, 0xFF ; CMD13 - SEND_STATUS
SDCARD_CMD16  :   DB  0x50, 0x00, 0x00, 0x00, 0x02, 0xFF ; CMD16 - SET_BLOCKLEN (set block length to 512 bytes)
SDCARD_CMD17  :   DB  0x51, 0x00, 0x00, 0x00, 0x00, 0xFF ; CMD17 - READ_SINGLE_BLOCK
SDCARD_CMD17_2  : DB  0x51, 0x00, 0x05, 0xC0, 0x00, 0xFF ; CMD17 - READ_SINGLE_BLOCK
SDCARD_CMD18  :   DB  0x52, 0x00, 0x00, 0x00, 0x00, 0xFF ; CMD18 - READ_MULTIPLE_BLOCK
SDCARD_CMD24  :   DB  0x58, 0x00, 0x00, 0x00, 0x00, 0xFF ; CMD24 - WRITE_BLOCK
SDCARD_CMD25  :   DB  0x59, 0x00, 0x00, 0x00, 0x00, 0xFF ; CMD25 - WRITE_MULTIPLE_BLOCK
SDCARD_CMD27  :   DB  0x5B, 0x00, 0x00, 0x00, 0x00, 0xFF ; CMD27 - PROGRAM_CSD
SDCARD_CMD32  :   DB  0x60, 0x00, 0x00, 0x00, 0x00, 0xFF ; CMD32 - ERASE_WR_BLK_START
SDCARD_CMD33  :   DB  0x61, 0x00, 0x00, 0x00, 0x00, 0xFF ; CMD33 - ERASE_WR_BLK_END
SDCARD_CMD38  :   DB  0x66, 0x00, 0x00, 0x00, 0x00, 0xFF ; CMD38 - ERASE
SDCARD_CMD55  :   DB  0x77, 0x00, 0x00, 0x00, 0x00, 0x65 ; CMD55 - APP_CMD
SDCARD_CMD56  :   DB  0x78, 0x00, 0x00, 0x00, 0x00, 0xFF ; CMD56 - GEN_CMD (used for data transfer)
SDCARD_CMD58  :   DB  0x7A, 0x00, 0x00, 0x00, 0x00, 0xFD ; CMD58 - READ_OCR
SDCARD_CMD59  :   DB  0x7B, 0x00, 0x00, 0x00, 0x00, 0xFF ; CMD59 - CRC_ON_OFF
; ACMD commands (Application Specific Commands)
SDCARD_ACMD13 :   DB  0x6A, 0x00, 0x00, 0x00, 0x00, 0xFF ; ACMD13 - SD_STATUS
SDCARD_ACMD22 :   DB  0x6E, 0x00, 0x00, 0x00, 0x00, 0xFF ; ACMD22 - SEND_NUM_WR_BLOCKS
SDCARD_ACMD23 :   DB  0x6F, 0x00, 0x00, 0x00, 0x00, 0xFF ; ACMD23 - SET_WR_BLK_ERASE_COUNT
SDCARD_ACMD41 :   DB  0x69, 0x40, 0x00, 0x00, 0x00, 0x77 ; CMD41 - SEND_OP_COND (ACMD41)
SDCARD_ACMD42 :   DB  0x6A, 0x00, 0x00, 0x00, 0x00, 0xFF ; ACMD42 - SET_CLR_CARD_DETECT
SDCARD_ACMD51 :   DB  0x6F, 0x00, 0x00, 0x00, 0x00, 0xFF ; ACMD51 - SEND_SCR

; Control Tokens
SDCARD_DATA_ACCEPTED EQU 0x05 ; Data accepted token
SDCARD_DATA_REJECTED_CRC EQU 0x0B ; Data rejected CRC error token
SDCARD_DATA_REJECTED_WRITE EQU 0x0D ; Data rejected write error token
SDCARD_START_TOKEN_RW EQU 0xFE ; Start token single block read/write, mult block read
SDCARD_START_TOKEN_MBW EQU 0xFC ; Start token multi block write
SDCARD_STOP_TRANSMISSION EQU 0xFD ; Stop token for data transmission

; Text Constants
LF_CR:
    DB 0x0D, 0x0A, 0x00
SDCARD_INIT_SUCCESS_MSG:
    DB "SD Card initialized successfully.", 0x00
SDCARD_ERRROR_MSG:
    DB "- Error: Invalid response from SD card.", 0x00
SDCARD_CMD0_MSG :
    DB "CMD0   :", 0x00
SDCARD_CMD8_MSG :
    DB "CMD8   :", 0x00
SDCARD_CMD55_MSG :
    DB "CMD55-ACMD41 -> Waiting for sdcard ready", 0x00
SDCARD_ACMD41_MSG :
    DB "ACMD41 : sdcard ready", 0x00
SDCARD_CMD58_MSG :
    DB "CMD58  :", 0x00
SDCARD_CMD17_MSG :
    DB "CMD17  :", 0x00

; Variables
SDCARD_R1:
    DB 0x00 ; R1 response for SD card commands
SDCARD_RESPONSE:
    DB 0x00, 0x00, 0x00, 0x00 ; Response buffer for SD card commands
SDCARD_SECTOR_ADDRESS:
    DB 0x00, 0x00, 0x00, 0x00 ; Sector address for SD card commands

SDCARD_BUFFER_ADDRESS WORD 0xA000
    ALIGN 0x10
;SDCARD_BUFFER:
;    BLOCK 0x200 , 0x00 ; 16 bytes buffer for SD card data





    ENDIF