; ------------------  I2C EEPROM (24C32)   ---------------

    


; ------------- Program START -----------------
    .ORG 0x6000

    JP Main

    INCLUDE "jumpTable.inc"
    INCLUDE "serial.asm"

Main:
    LD HL, MSG1
    CALL PrintString
    LD HL, CR_LF
    CALL PrintString
    LD HL, MSG1
    CALL SendCmd

    LD HL, MSG2
    CALL PrintString
    LD HL, CR_LF
    CALL PrintString
    LD HL, MSG2
    CALL SendCmd

    LD HL, MSG3
    CALL PrintString
    LD HL, CR_LF
    CALL PrintString
    LD HL, MSG3
    CALL SendCmd
     
    ; LD HL, MSG4
    ; CALL SendCmd
     
    ; LD HL, MSG5
    ; CALL SendCmd
     
    ; LD HL, MSG6
    ; CALL SendCmd
     
    RET

SendCmd: ; send command in HL and display response
.send_loop:
    CALL SendCharB_HL
    INC HL
    LD A, (HL)
    OR A
    JP NZ, .send_loop
    LD A, 0x0D
    CALL SendChar_A
.receive_loop:
    CALL ReceiveChar_B
    CP 0x06
    JP Z, .end_loop
    CALL SendChar_A
    JP .receive_loop
.end_loop:
    RET


SendCharB_HL: ; Send a character in (HL) to the SIO port B
.wait:
 ; Select Register 0 (status register) for SIO Port A
    LD A, 0       ; Register 0
    OUT (SIO_CTRL_B), A ; Write to control port A to select reg 0
    IN A, (SIO_CTRL_B)
    BIT 2, A             ; TX Buffer Empty?
    JR Z, .wait
    LD A, (HL)
    OUT (SIO_DATA_B), A
    RET


MSG1:
    DB "pwd", 0x0D, 0x00
MSG2:
    DB "ls", 0x0D, 0x00
MSG3:
    DB "cat test plan.txt", 0x0D, 0x00
MSG4:
    DB "cd ../..", 0x0D, 0x00
MSG5:
    DB "pwd", 0x0D, 0x00
MSG6:
    DB "ls", 0x0D, 0x00

CR_LF:
    DB 0x0A, 0x0D, 0x00 ; Carriage return + line feed
