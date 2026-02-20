
; ------------------------------------------------
; ---- SD Card Management Library ----------------
; ------------------------------------------------    
    
    IFNDEF __SDCARD__
    DEFINE __SDCARD__ 1


    INCLUDE "spi.asm"


SDCARD_SendCmd: ; Send a command to the SD card (in HL)
    ; Input: HL points to SDCARD_COMMAND structure
    PUSH HL
    PUSH BC

    LD A, 0x00
    LD B, 0x06 ; Number of bytes to send (CMD + ARG + CRC)
    CALL SPI_SEND_BYTES
    POP BC
    POP HL
    RET


SDCARD_Wait_R1: ; Wait for a response from the SD card - resp in A
    PUSH BC
    PUSH DE
    PUSH HL
    LD C, 0x30 ; Number of wait bytes to send
.byteLoop:
    CALL SPI_READ_BYTE ; Read a byte from the SD card
    ; check if E is still 0xFF, if not this is a valid response
    ; can also just check that bit 7 of E is 0
    LD E,A ; store received byte
    AND 0x80 ; Check if response is valid (bit 7 should be 0)
    JP Z, .validResponse ; If valid response, continue
    DEC C 
    JP NZ, .byteLoop ; Loop until all bytes are sent
.noValidResponse:
    LD A, SDCARD_ERR_TIMEOUT
    SCF ; set carry flag in case of timeout
    JP .exit
.validResponse:
;    CALL SPI_endCom
    OR A ; reset carry flag
    LD A, E  ; restore return code
.exit:
    POP HL
    POP DE
    POP BC
    RET


SDCARD_GetResponse_: ; get response from  SD card, result in (HL)
    PUSH BC
    PUSH DE
    PUSH HL
    LD C, 0x04 ; Number of  bytes to get
.byteLoop:
    CALL SPI_READ_BYTE ; Read a byte from the SD card
    LD (HL), A
    INC HL
    DEC C 
    JP NZ, .byteLoop ; Loop until all bytes are sent
.end:
    POP HL
    POP DE
    POP BC
    RET


SDCARD_WaitDataToken: ; Wait for a token from the SD card,token in (HL), Z flag set if succesful
    PUSH BC
    PUSH DE
    PUSH HL
    LD B, 0x30 ; Number of  bytes to get
.byteLoop:
    CALL SPI_READ_BYTE
    ; check if E is still 0xFF, if not this is a valid response
    ; can also just check that bit 7 of E is 0
    ;LD A, E
    CP 0xFF
    JR NZ, .foundToken
    DJNZ .byteLoop ; Loop until all bytes are sent
.timeOut:
    LD A, SDCARD_ERR_TIMEOUT
    SCF ; set the Carry flag to detect if time out
    JP .exit
.foundToken:
    CP 0xFE
    JP Z, .success
    AND 0x0F ; keep only error code
    SCF ; carry on for error
    JP .exit
.success:
    XOR A
.exit:
    POP HL
    POP DE
    POP BC
    RET


; Read a block of data from the SD card :
;    * CS (SPI_CS1_BIT or SPI_CS2_BIT) in A
;    * LBA address in BCDE 
;    * result in (HL)
;    * Success : carry flag reset
SDCARD_READ_BLOCK: 
    PUSH BC
    PUSH DE
    PUSH HL
    CP SPI_CS1_BIT
    JP Z, .cs1_select
    CP SPI_CS2_BIT
    JP Z, .cs2_select
    LD A, 0x70
    JP .error
.cs1_select:
    CALL SPI_CS1_SELECT
    JP .convertLBA
.cs2_select:
    CALL SPI_CS2_SELECT
.convertLBA: ; convert LBA to address (multiply by 512)
    LD B, C    ; multiply by 256
    LD C, D
    LD D, E
    LD E, 0
    OR A      ;reset the Carry
    RL D      ; multiply by 2 with carry
    RL C      ; etc.
    RL B
; send CMD17 0x51, 0x00, 0x00, 0x00, 0x00, 0xFF ; CMD17 - READ_SINGLE_BLOCK
    LD A, 0x51
    CALL SPI_SEND_BYTE_A
    LD A, B
    CALL SPI_SEND_BYTE_A
    LD A, C
    CALL SPI_SEND_BYTE_A
    LD A, D
    CALL SPI_SEND_BYTE_A
    LD A, E
    CALL SPI_SEND_BYTE_A
    LD A, 0xFF ; dummy CRC
    CALL SPI_SEND_BYTE_A
; Wait R1
    CALL SDCARD_Wait_R1
    JP C, .error
    CP 0x00
    JP NZ, .error
; Read Data Token
    CALL SDCARD_WaitDataToken
    JP C, .error
;Read the block
    LD B, 0x00 ; Number of bytes to read (512 bytes)
.Loop1:
    CALL SPI_READ_BYTE ; Read a byte from the SD card
    LD (HL), A
    INC HL
    DJNZ .Loop1
.Loop2:
    CALL SPI_READ_BYTE ; Read a byte from the SD card
    LD (HL), A
    INC HL
    DJNZ .Loop2
.readCRC:
    CALL SPI_READ_BYTE ; Read CRC byte from the SD card
    CALL SPI_READ_BYTE ; Read CRC byte from the SD card
; reset the SPI lines
    CALL SPI_endCom
; reset the carry flag for success and return
    XOR A
    POP HL
    POP DE
    POP BC
    RET
.error:
    CALL SPI_endCom
    SCF
    POP HL
    POP DE
    POP BC
    RET


; Write a block of data to the SD card :
;    * CS (SPI_CS1_BIT or SPI_CS2_BIT) in A
;    * LBA address in BCDE 
;    * result in (HL)
;    * Success : carry flag reset
SDCARD_WRITE_BLOCK:
    PUSH BC
    PUSH DE
;    PUSH HL
    CP SPI_CS1_BIT
    JP Z, .cs1_select
    CP SPI_CS2_BIT
    JP Z, .cs2_select
    LD A, 0x70
    JP .error
.cs1_select:
    CALL SPI_CS1_SELECT
    JP .convertLBA
.cs2_select:
    CALL SPI_CS2_SELECT
.convertLBA: ; convert LBA to address (multiply by 512)
    LD B, C    ; multiply by 256
    LD C, D
    LD D, E
    LD E, 0
    OR A      ;reset the Carry
    RL D      ; multiply by 2 with carry
    RL C      ; etc.
    RL B
; SDCARD_CMD24  :   DB  0x58, 0x00, 0x00, 0x00, 0x00, 0xFF ; CMD24 - WRITE_BLOCK
    LD A, 0x58
    CALL SPI_SEND_BYTE_A
    LD A, B
    CALL SPI_SEND_BYTE_A
    LD A, C
    CALL SPI_SEND_BYTE_A
    LD A, D
    CALL SPI_SEND_BYTE_A
    LD A, E
    CALL SPI_SEND_BYTE_A
    LD A, 0xFF ; dummy CRC
    CALL SPI_SEND_BYTE_A
; Wait R1
    CALL SDCARD_Wait_R1
    JP C, .error
    CP 0x00
    JP NZ, .error
; Send Data Token
    LD A, 0xFF ; send idle byte
    CALL SPI_SEND_BYTE_A
    LD A, 0xFE ; send data token
    CALL SPI_SEND_BYTE_A
; Send 512B of data
    LD B, 0x00 ; Number of bytes to read (512 bytes)
.Loop1:
    LD A, (HL)
    CALL SPI_SEND_BYTE_A ; Read a byte from the SD card
    INC HL
    DJNZ .Loop1
.Loop2:
    LD A, (HL)
    CALL SPI_SEND_BYTE_A ; Read a byte from the SD card
    INC HL
    DJNZ .Loop2
; send Dummy CRC:
    LD A, 0xFF
    CALL SPI_SEND_BYTE_A ; send CRC byte from the SD card
    LD A, 0xFF
    CALL SPI_SEND_BYTE_A ; send second CRC byte from the SD card
; fetch Data Respone
    CALL SPI_READ_BYTE
    AND 0x1F            ; keep the 5 LS bits
    CP 0x05             ; 00101 = Data accepted
    JP NZ, .error
; --- Attente de la fin d'écriture (Busy) ---
    LD BC, 0x8000
.wait_busy:
    DEC BC
    LD A, B
    OR C
    LD A, 0xFF
    JP Z, .error
    CALL SPI_READ_BYTE
    OR A                ; 0x00 during SDCard write operation
    JR Z, .wait_busy    ; when done, return 0xFF

.CMD13: ; check write status
    PUSH HL
    LD HL, SDCARD_CMD13
    CALL SDCARD_SendCmd
    POP HL
    CALL SDCARD_Wait_R1 ; Wait for response from SD card
    LD B, A             ; Store R1
    CALL SPI_READ_BYTE  ; Get second byte (Status)
    LD C, A             ; store the status
    ;Test if success : B and C must be 0x00
    LD A, B
    OR C
    JR NZ, .error

; reset the SPI lines
    CALL SPI_endCom
; reset the carry flag for success and return
    XOR A
;    POP HL
    POP DE
    POP BC
    RET
.error:
    CALL SPI_endCom
    SCF
;    POP HL
    POP DE
    POP BC
    RET

; Write a block of data to the SD card :
;    * CS (SPI_CS1_BIT or SPI_CS2_BIT) in A
;    * Return : Success carry flag reset A=0x00
SDCARD_INIT: ; initialize the SD Card
    ; PUSH AF
    ; LD A ,'I'
    ; CALL SendChar_A
    ; POP AF

    PUSH BC
    PUSH HL
    CALL SPI_Init

    CP SPI_CS1_BIT
    JP Z, .cs1_select
    CP SPI_CS2_BIT
    JP Z, .cs2_select
    LD A, 0x70
    JP .error
.cs1_select:
    CALL SPI_CS1_SELECT
    JP .CMD0
.cs2_select:
    CALL SPI_CS2_SELECT
.CMD0:
    ; PUSH AF
    ; LD A ,'0'
    ; CALL SendChar_A
    ; POP AF

    LD HL, SDCARD_CMD0 ; Prepare CMD0 command
    CALL SDCARD_SendCmd ; Send CMD0 to SD card
    CALL SDCARD_Wait_R1 ; Wait for response from SD card
    JP C, .error
    CP 0x01 ; correct response
    JP Z, .CMD8
    AND 0x0F
    OR  SDCARD_CMD0_ERR
    JP .error
.CMD8:
    ; PUSH AF
    ; LD A ,'8'
    ; CALL SendChar_A
    ; POP AF

    LD HL, SDCARD_CMD8 ; Prepare CMD8 command
    CALL SDCARD_SendCmd ; Send CMD8 to SD card
    CALL SDCARD_Wait_R1 ; Wait for response from SD card
    JP C, .error
    CP 0x01 ; correct response
    JP Z, .cmd8_getResp
    AND 0x0F
    OR  SDCARD_CMD8_ERR
    JP .error
.cmd8_getResp:
    CALL SPI_READ_BYTE ; byte 1 (reserved)
    CALL SPI_READ_BYTE ; byte 2 (reserved)
    CALL SPI_READ_BYTE ; byte 3 (voltage)
    CALL SPI_READ_BYTE ; byte 4 (check Pattern)
    CP 0xAA
    JP Z, .CMD55
    LD A, SDCARD_CMD8_ERR + 0x0F
    JP .error
.CMD55:
    LD BC, 200 ; counts number of iteration before success
.cmd41_waitloop:
    DEC BC
    LD A, B
    OR C
    JP Z, .cmd41_timeOut
    ; PUSH AF
    ; LD A ,'5'
    ; CALL SendChar_A
    ; POP AF

    LD HL, SDCARD_CMD55 ; Prepare CMD55 command
    CALL SDCARD_SendCmd ; Send CMD55 to SD card
    CALL SDCARD_Wait_R1 ; Wait for response from SD card
    JP C, .error
    CP 0x01
    JP Z, .ACMD41
    AND 0x0F
    OR SDCARD_CMD55_ERR
    JP .error
.ACMD41:
    ; PUSH AF
    ; LD A ,'4'
    ; CALL SendChar_A
    ; POP AF

    LD HL, SDCARD_ACMD41 ; Prepare ACMD41 command
    CALL SDCARD_SendCmd ; Send ACMD41 to SD card
    CALL SDCARD_Wait_R1 ; Wait for response from SD card
    JP C, .error
    CP 0x01
    JP Z, .cmd41_waitloop
    CP 0x00
    JP Z, .CMD58
    AND 0x0F
    OR SDCARD_CMD41_ERR
    JP .error
.cmd41_timeOut:
    AND 0x0F
    OR SDCARD_CMD41_ERR
    JP .error
.CMD58
    ; PUSH AF
    ; LD A ,'Z'
    ; CALL SendChar_A
    ; POP AF

    LD HL, SDCARD_CMD58 ; Prepare CMD58 command
    CALL SDCARD_SendCmd ; Send CMD58 to SD card
    CALL SDCARD_Wait_R1 ; Wait for response from SD card
    JP C, .error
    CP 0x00
    JP Z, .cmd58_getResp
    AND 0x0F
    OR SDCARD_CMD58_ERR
    JP .error
.cmd58_getResp:
    CALL SPI_READ_BYTE ; byte 1 (reserved)
    LD B, A
    CALL SPI_READ_BYTE ; byte 2 (reserved)
    CALL SPI_READ_BYTE ; byte 3 (voltage)
    CALL SPI_READ_BYTE ; byte 4 (check Pattern)
    LD A, B
    AND 0x40            ; keep only bit 6 (CCS)
    RLCA                ;rotate left ...
    RLCA                ; ... to put it in bit 0
    OR A
    CALL SPI_endCom
    POP HL
    POP BC
    RET
.error:
    CALL SPI_endCom
    SCF
    POP HL
    POP BC
    RET
    
    
; Read the write status (CMD13) from the SD card :
;    * CS (SPI_CS1_BIT or SPI_CS2_BIT) in A
;    * Return : Success Carry flag cleared and A=0x00
SDCARD_GET_STATUS:
    PUSH HL
    CP SPI_CS1_BIT
    JP Z, .cs1_select
    CP SPI_CS2_BIT
    JP Z, .cs2_select
    LD A, 0x72
    JP .error
.cs1_select:
    CALL SPI_CS1_SELECT
    JP .CMD13
.cs2_select:
    CALL SPI_CS2_SELECT
.CMD13:
    LD HL, SDCARD_CMD13
    CALL SDCARD_SendCmd
    CALL SDCARD_Wait_R1 ; Wait for response from SD card
    LD B, A             ; Store R1
    CALL SPI_READ_BYTE  ; Get second byte (Status)
    LD C, A             ; store the status
    CALL SPI_endCom
    ;Test if success : B and C must be 0x00
    LD A, B
    OR C
    JR NZ, .error
    XOR A               ; Tout est OK
    POP HL
    RET
.error:
    CALL SPI_endCom   
    LD A, C
;    LD A, 0x13          ; Code erreur "Status Error"
    SCF
    POP HL
    RET


; SD Card Commands
; Standard SD Card Commands
SDCARD_CMD0   :   DB  0x40, 0x00, 0x00, 0x00, 0x00, 0x95 ; CMD0 - GO_IDLE_STATE
SDCARD_CMD8   :   DB  0x48, 0x00, 0x00, 0x01, 0xAA, 0x87 ; CMD8 - SEND_IF_COND
SDCARD_CMD13  :   DB  0x4D, 0x00, 0x00, 0x00, 0x00, 0xFF ; CMD13 - SEND_STATUS
SDCARD_CMD16  :   DB  0x50, 0x00, 0x00, 0x00, 0x02, 0xFF ; CMD16 - SET_BLOCKLEN (set block length to 512 bytes)
SDCARD_CMD55  :   DB  0x77, 0x00, 0x00, 0x00, 0x00, 0x65 ; CMD55 - APP_CMD
SDCARD_CMD58  :   DB  0x7A, 0x00, 0x00, 0x00, 0x00, 0xFD ; CMD58 - READ_OCR
SDCARD_ACMD41 :   DB  0x69, 0x40, 0x00, 0x00, 0x00, 0x77 ; CMD41 - SEND_OP_COND (ACMD41)

; Control Tokens
SDCARD_START_TOKEN_RW EQU 0xFE ; Start token single block read/write, mult block read; 
SDCARD_WRITE_OK EQU 0x05 ; Data accepted token
SDCARD_WRITE_CRC_ERR EQU 0x0B ; Data rejected CRC error token
SDCARD_WRITE_DEVICE_ERR EQU 0x0D ; Data rejected write error token
SDCARD_ERR_TIMEOUT EQU 0xFF ; Code erreur pour le time out

SDCARD_CMD0_ERR EQU 0x10
SDCARD_CMD8_ERR EQU 0x20
SDCARD_CMD55_ERR EQU 0x30
SDCARD_CMD41_ERR EQU 0x40
SDCARD_CMD58_ERR EQU 0x50
SDCARD_CMD13_ERR EQU 0x60

    ENDIF