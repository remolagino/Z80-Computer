; --------------------------------------------
; -------- test program for SDARD -------------
; --------------------------------------------
    .ORG 0x4000

    JP Main

    INCLUDE "./lib/diskio.asm"
    INCLUDE "./lib/stdio.asm"
    INCLUDE "./lib/string.asm"


Main:
    CALL SDCARD_INIT
    JP C, .error

; CMD17 + Read block

    LD DE, SDCARD_GetBlock_MSG
    CALL SDCARD_MsgPrint
    LD HL, 0x8400 ; write the data far in RAM
    LD BC, 0x00
    LD DE, 0x00
    LD A, 'C'
    CALL DISK_READ
    JP C, .error
    CALL SDCARD_CodePrint

    LD A, 0xAA
    LD HL, 0x8410
    LD (HL), A

    LD DE, SDCARD_WriteBlock_MSG
    CALL SDCARD_MsgPrint

    LD HL, 0x8400 ; write the data far in RAM
    LD BC, 0x00
    LD DE, 0x00
    LD A, 'C'
    CALL DISK_WRITE
    JP C, .error
    CALL SDCARD_CodePrint

    LD DE, SDCARD_STATUS_MSG
    CALL SDCARD_MsgPrint
    CALL SDCARD_GET_STATUS
    JP C, .error
    CALL SDCARD_CodePrint

    LD DE, SDCARD_GetBlock_MSG
    CALL SDCARD_MsgPrint
    LD HL, 0x8600 ; write the data far in RAM
    LD BC, 0x00
    LD DE, 0x00
    LD A, 'C'
    CALL DISK_READ
    JP C, .error
    CALL SDCARD_CodePrint


    CALL SPI_endCom

    RET
.error:
    CALL SDCARD_ErrorMsgPrint
    CALL SPI_endCom
    LD A, 0x00
    RET

SDCARD_PrintResponse: ; Print the response from the SD card
    PUSH BC
    PUSH DE
    PUSH HL
    LD DE, SDCARD_BUFFER
    LD HL, SDCARD_RESPONSE ; Response buffer address
    LD B, 4
.loop:
    LD A, (HL) ; Read first byte of response
    CALL Bin2Hex_DE
    LD A, '-' ; Send '-' character to SIO port A
    LD (DE), A
    INC DE
    INC HL ; Move to next byte in response buffer
    DJNZ .loop
    LD A, 0x00 ; Null terminator for string
    LD (DE), A
    LD HL, (CURSOR_IDX)
    LD DE, SDCARD_BUFFER
    CALL PutS_LN
    LD (CURSOR_IDX), HL
    POP HL
    POP DE
    POP BC
    RET

; SDCARD_PRINT_BLOCK: ; Read a block of data from the SD card
;     PUSH BC
;     PUSH DE
;     PUSH HL
;     LD D, 0x00 ; Number of 16 bytes to read (512 bytes)
;     LD HL, SDCARD_BUFFER
; .blockLoop:
;     LD C, 0x10 ; Number of bytes to read
; .rowLoop:
;     CALL SPI_READ_BYTE ; Read a byte from the SD card
;     LD (HL), A
;     INC HL
;     DEC C
;     JP NZ, .rowLoop ; Loop until all bytes are sent
;     INC D ; Increment block counter
;     LD A, D
;     CP 0x20 ; Check if D is 32
;     JP NZ, .blockLoop ; If not zero, read next block
; .readCRC:
;     CALL SPI_READ_BYTE ; Read CRC byte from the SD card
;     CALL SPI_READ_BYTE ; Read CRC byte from the SD card

;     LD HL, SDCARD_BUFFER ; Load the buffer address
;     LD DE, SDCARD_PRINTABLE_BUFFER_ADDRESS ; Load the printable buffer address
;     CALL MemoryDump
;     LD HL, (CURSOR_IDX)
;     CALL PutS_LN

; ; TODO PAUSE to stop scrolling

;     LD (CURSOR_IDX), HL
;     LD HL, SDCARD_BUFFER+ 0x100 ; Load the buffer address
;     LD DE, SDCARD_PRINTABLE_BUFFER_ADDRESS ; Load the printable buffer address
;     CALL MemoryDump ; Print the buffer as hex
;     LD HL, (CURSOR_IDX)
;     CALL PutS_LN
;     LD (CURSOR_IDX), HL
;     POP HL
;     POP DE
;     POP BC
;     RET

SDCARD_MsgPrint: ; print message in DE
    PUSH HL
    LD HL, (CURSOR_IDX)
    CALL PutS
    LD (CURSOR_IDX), HL
    POP HL
    RET

SDCARD_CodePrint: ; print code in A as hex
    PUSH AF
    PUSH DE
    PUSH HL
    LD DE, SDCARD_BUFFER
    CALL Bin2Hex_DE ; Convert response to string for display
    LD A, 0x00
    LD (DE), A
    LD DE, SDCARD_BUFFER
    LD HL, (CURSOR_IDX)
    CALL PutS_LN ; Print 
    LD (CURSOR_IDX), HL
    POP HL
    POP DE
    POP AF
    RET

SDCARD_ErrorMsgPrint: ; print and error message for error code in A
    PUSH AF
    PUSH DE
    PUSH HL

    LD DE, SDCARD_ERRROR_MSG
    LD HL, (CURSOR_IDX)
    CALL PutS
    LD DE, SDCARD_BUFFER
    CALL Bin2Hex_DE ; Convert response to string for display
    LD A, 0x00
    LD (DE), A
    LD DE, SDCARD_BUFFER
    CALL PutS_LN
    LD (CURSOR_IDX), HL

    POP HL
    POP DE
    POP AF
    RET

; Text Constants
LF_CR:
    DB 0x0D, 0x0A, 0x00
SDCARD_INIT_SUCCESS_MSG:
    DB "SD Card initialized successfully.", 0x00
SDCARD_ERRROR_MSG:
    DB "Error: Invalid response from SD card : ", 0x00
SDCARD_STATUS_MSG:
    DB "Get Status Result : ", 0x00
SDCARD_GetBlock_MSG :
    DB "Block Received :", 0x00
SDCARD_WriteBlock_MSG:
    DB "Write back the block : ", 0x00

; Variables
SDCARD_R1:
    DB 0x00 ; R1 response for SD card commands
SDCARD_RESPONSE:
    DB 0x00, 0x00, 0x00, 0x00 ; Response buffer for SD card commands
SDCARD_SECTOR_ADDRESS:
    DB 0x00, 0x00, 0x00, 0x00 ; Sector address for SD card commands

SDCARD_BUFFER:
   BLOCK 0x200 , 0x00 ; 512 bytes buffer for SD card data


