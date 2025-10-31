    ; ------------- Program START -----------------
    .ORG 0x5000

    JP Main

;    INCLUDE "jumpTable.inc"
;    INCLUDE "serial.asm"
    INCLUDE "string.asm"


Main:
    CALL ReceiveCharNB_A
    OR A
    JP Z , Main
    CALL Hex2Str
    LD A, ' '
    CALL SendChar_A ; Send space to SIO port A
    JP Main
