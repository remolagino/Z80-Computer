    ORG 0x0000
   
    JP Main

    INCLUDE "monitor.inc"
    INCLUDE "serial.asm"
    INCLUDE "string.asm"
    INCLUDE "rtclock.asm"
    INCLUDE "keypad.asm"


Main:
    LD SP, STACK_TOP

;-- Delay loop to let time for serial USB to init
    LD C, 0xFF
.loop:
    LD B, 0xFF
.subloop:
    DJNZ .subloop
    DEC C
    JP NZ, .loop
; -- end of delay loop

    CALL Init_RAM
    CALL InitSerial_A
    CALL InitSerial_B
    CALL I2C_Init
    LD HL, CLRSCR
    CALL PrintString
    CALL RtClock_InitCheck
    LD HL, CR_LF
    CALL PrintString
    LD HL, WelcomeMsg
    CALL PrintString
    LD HL, CLOCK
    CALL RtClock_GetTime
    CALL RtClock_PrintTime
    LD HL, CR_LF
    CALL PrintString


    LD A, 'A'
    LD (DRIVE_LETTER), A
    LD A, FS_SERIAL
    LD (FILE_SYSTEM), A
    
    LD A , 0x00 ; Insert Mode by default
    LD (BUFFER_FLAG), A
    LD A, 0x1B ; set the cursor as a bar
    CALL SendChar_A ;
    LD A, '['
    CALL SendChar_A ;
    LD A, CURSOR_INSERT
    CALL SendChar_A ; Echo the control character
    LD A, ' '
    CALL SendChar_A ; Echo the control character
    LD A, 'q'
    CALL SendChar_A ; Echo the control character
 ; cursor change seems to not work with minicom on raspberry pi
 ; hence the echo of a q instead of the change of cursor type
 ; seems to work on windows and the terminal i use

MainLoop:
    LD A, (DRIVE_LETTER)
    CALL SendChar_A
    LD HL, PROMPT
    CALL PrintString
    CALL ReadLine
    LD HL, CR_LF 
    CALL PrintString
    CALL ParseCommand

    JP MainLoop

Init_RAM:
    LD HL, RAM_START
    LD A, 0x02
    LD B, 0x00
.initRAM:
    LD (HL), 0x00 ; Initialize RAM with 0x00
    INC HL
    DJNZ .initRAM ; Loop until all RAM is initialized
    DEC A
    JP NZ, .initRAM
    RET


ReadLine:
    LD IX, BUFFER_ADDRESS  ; Pointeur vers le buffer
    LD B, BUFFER_SIZE     ; Compteur de caract�res
.initBuffer:   
    LD A, 0x00
    LD (IX), A ; Initialize buffer with null terminator
    INC IX ; Increment buffer pointer
    DJNZ .initBuffer ; 

    LD IX, BUFFER_ADDRESS  ; Pointeur vers le buffer

.ReadLineLoop:
; -------------- Serial Input Processing ---------------
    CALL ReceiveCharNB_A
    OR A ; Check if a character was received
    
    JP NZ, .processKey ; If no character received, continue reading
; -------------- Keyboard Processing ----------------
    PUSH BC, DE, HL, IX
    CALL Keypad_Scan

    LD A, (KEYPAD_BUFFER) ; Read the first character from the keypad buffer
    LD HL, KEYPAD_BUFFER
    LD (HL), 0x00 ; Clear the buffer
    INC HL
    LD (HL), 0x00 ; Clear the buffer
    INC HL
    LD (HL), 0x00 ; Clear the buffer
    INC HL
    LD (HL), 0x00 ; Clear the buffer
    INC HL
    LD (HL), 0x00 ; Clear the buffer

    POP IX, HL, DE, BC
    OR A
    JP NZ, .processKey
; ---------------------------------------------------
    JP .ReadLineLoop ; If no character received, continue reading

.processKey:
    CP 0x0D ; Carriage return ?
    RET Z

    CP 0x1B ; Escape key ?
    JP Z, .escapeSequenceStart ; If escape key, send newline

    CP 0x08 ; Backspace ?
    JP Z, .backspace ; If backspace, handle it
    CP 0x7F ; Backspace ?
    JP Z, .backspace ; If backspace, handle it

.StandardChar:  
    LD C, A ; Store the received character in C
    LD HL, BUFFER_END ; Check if the we are at the end of the buffer
    LD DE, IX
    SBC HL, DE ; Compare DE with the end of the buffer
    LD A, L
    OR H
    CP 0x00 ; Check if we are at the end of the buffer
    JP Z, .ReadLineLoop ; If full, do not store  and increment IX
    LD A, (BUFFER_FLAG)
    BIT 0, A ; Check if in insert mode
    JP Z, .insertMode ; If not in insert mode, go to insert mode
.overwriteMode:
    LD (IX), C ; Store the character in the buffer
    CALL SendChar_IX ; Echo the character back
    INC IX  ; Increment the buffer pointer   
    JP .ReadLineLoop ; 
.insertMode:
    LD IY, IX
    LD B, 0x01 ; number of moved char in the loop
.insertModeEndLoop:
    LD A, (IY) ; Read the character at the current position   
    CP 0x00
    JP Z, .insertModeShift ; If not null terminator, loop
    INC IY ; Increment the buffer Pointeur
    INC B ; Increment the number of moved char
    JP .insertModeEndLoop ; Continue loop
.insertModeShift:
    LD D, B
.insertModeShiftLoop:
    LD A, (IY-1) ; Read the character at the previous position
    LD (IY), A
    DEC IY ; Decrement the buffer pointer
    DJNZ .insertModeShiftLoop ; loop until all characters are shifted
    LD (IX), C ; Copy the received character in the buffer
    LD HL, IX
    CALL PrintString ; Print the string
    INC IX ; Increment the buffer Pointeur
    LD B, D
    DEC B
    LD A, B
    OR A
    CP 0x00 ; Check if we are at the end of the buffer
    JP Z, .ReadLineLoop
;    DEC B
.InsertModeCursorLoop:
    LD A, 0x1B ; move cursor one to the left
    CALL SendChar_A
    LD A, '[' 
    CALL SendChar_A
    LD A, 'D' 
    CALL SendChar_A
    DJNZ .InsertModeCursorLoop ; If not zero, move cursor again
    JP .ReadLineLoop ;

.escapeSequenceStart:
    CALL ReceiveChar_A
    CP '[' ; Check for '[' begining of escape sequence
    JP NZ, .StandardChar ; If not, treat as standard character

    LD BC, 0x0000 ; Used to store the escape sequence
.escapeSequence:
    CALL ReceiveChar_A ; Read the next character
    CP 'A' ; Check for 'A' up
    JP Z, .up
    CP 'B' ; Check for 'B' down
    JP Z, .down
    CP 'C' ; Check for 'C' right
    JP Z, .right
    CP 'D' ; Check for 'D' left
    JP Z, .left
.checkEndOfSequence:
    CP '~' ; Check for '~' (end of sequence)	
    JP Z, .endEscapeSequence ; If  '~', escape sequence ends
    XOR 0x30; ; check for number
    CP 0x0A ; Check if it's a number (0-9)
    JP M, .specialChar ; If number, treat as special character
    XOR 0x30 ; Restore A
    JP .StandardChar ; If not, treat as standard character
.specialChar:
    SLA C ; rotate BC left 4 positions
    RL B
    SLA C
    RL B
    SLA C
    RL B
    SLA C
    RL B
    OR C ; put low A nibble in C
    LD C, A
    JP .escapeSequence ; Continue reading escape sequence
    
.endEscapeSequence:
    LD A, C ; put the value of the escape key in A
    CP 0x01
    JP Z, .home
    CP 0x02
    JP Z, .insert
    CP 0x03
    JP Z, .suppr
    CP 0x04
    JP Z, .lineEnd
    CP 0x05
    JP Z, .pageUp
    CP 0x06
    JP Z, .pageDown

    LD A, '(' ; display the result
    CALL SendChar_A ; 
    LD A, C ; display the result in hex
    CALL Hex2Str
    LD A, ')' ; display the result
    CALL SendChar_A ; 

    JP .ReadLineLoop


.up:
    LD A, '^' ; Control character for up arrow
    CALL SendChar_A ; Echo the control character
    JP .ReadLineLoop ; Continue reading ReadLine

.down:
    LD A, 'v' ; Control character for down arrow
    CALL SendChar_A ; Echo the control character
    JP .ReadLineLoop ; Continue reading ReadLine

.left: ; D
    LD A, IXH
    CP HIGH BUFFER_ADDRESS ; Check if IX is at the start of the buffer
    JP NZ, .handleLeft ; If at the start, do nothing
    LD A, IXL
    CP LOW BUFFER_ADDRESS ; Check if IX is at the start of the buffer
    JP NZ, .handleLeft ; If at the start, do nothing
    JP .ReadLineLoop ; If not, continue reading ReadLine
.handleLeft:
    LD A, 0x1B ; 
    CALL SendChar_A ; 
    LD A, '[' ; 
    CALL SendChar_A ; 
    LD A, 'D' ; 
    CALL SendChar_A ; Echo the control character
    DEC IX
    JP .ReadLineLoop ; Continue reading ReadLine

.right: ; C
    LD A, (IX) ; 
    CP 0x00 ; Check if at the end of the string
    JP Z, .ReadLineLoop ; If at the end, do nothing
    LD A, 0x1B ; 
    CALL SendChar_A ; 
    LD A, '[' ; 
    CALL SendChar_A ; 
    LD A, 'C' ; 
    CALL SendChar_A ; Echo the control characters
    INC IX
    JP .ReadLineLoop ; Continue reading ReadLine

.backspace:     ; Handle backspace character
    ; If IX is at the start of the buffer, do nothing
    LD A, IXH
    CP HIGH BUFFER_ADDRESS ; Check if IX is at the start of the buffer
    JP NZ, .handleBackspace ; If not, continue
    LD A, IXL
    CP LOW BUFFER_ADDRESS ; Check if IX is at the start of the buffer
    JP NZ, .handleBackspace ; If not, continue
    JP .ReadLineLoop ; if IX at start of buffer, go back to ReadLine
.handleBackspace
    LD IY, IX
    DEC IY
    LD B, 0x00 ; number of moved char in the loop
.backspaceLoop:
    LD A, (IY+1)
    LD (IY), A
    INC IY
    INC B
    OR A
    CP 0x00
    JP NZ, .backspaceLoop
    LD A, 0x1B ; Backspace
    CALL SendChar_A
    LD A, '[' ; Backspace
    CALL SendChar_A
    LD A, 'D' ; Backspace
    CALL SendChar_A
    DEC IX
    LD HL, IX
    CALL PrintString
; g�rer l'effacement des cracteres a la fin de la ligne et le positionnement du curseur
    LD A, ' '
    CALL SendChar_A 
.bsCursorLoop: ; first we move the cursor to the left
    LD A, 0x1B ; Backspace
    CALL SendChar_A
    LD A, '[' ; Backspace
    CALL SendChar_A
    LD A, 'D' ; Backspace
    CALL SendChar_A
    DJNZ .bsCursorLoop ; Loop until all characters are erased

    JP .ReadLineLoop ; Continue reading ReadLine

.suppr:
    LD IY, IX
    LD B, 0x00 ; number of moved char in the loop
.supprLoop:
    LD A, (IY+1)
    LD (IY), A
    INC IY
    INC B
    OR A
    CP 0x00
    JP NZ, .supprLoop
    LD HL, IX
    CALL PrintString
; g�rer l'effacement des cracteres a la fin de la ligne et le positionnement du curseur
    LD A, ' '
    CALL SendChar_A 
.suppCursorLoop:
    LD A, 0x1B ; Backspace
    CALL SendChar_A
    LD A, '[' ; Backspace
    CALL SendChar_A
    LD A, 'D' ; Backspace
    CALL SendChar_A
    DJNZ .suppCursorLoop ; Loop until all characters are erased

    JP .ReadLineLoop ; Continue reading ReadLine

.insert:
    LD A, (BUFFER_FLAG)
    XOR 0x01 ; Toggle the insert mode flag
    LD (BUFFER_FLAG), A 
    LD A, (BUFFER_FLAG)
    BIT 0, A 
    JP NZ, .insertMode_Overwrite
.insertMode_Insert:
    LD A, 0x1B
    CALL SendChar_A ;
    LD A, '['
    CALL SendChar_A ;
    LD A, CURSOR_INSERT
    CALL SendChar_A ; Echo the control character
    LD A, ' '
    CALL SendChar_A ; Echo the control character
    LD A, 'q'
    CALL SendChar_A ; Echo the control character

    JP .ReadLineLoop ; Continue reading ReadLine
.insertMode_Overwrite:
    LD A, 0x1B
    CALL SendChar_A ;
    LD A, '['
    CALL SendChar_A ;
    LD A, CURSOR_OVERWRITE
    CALL SendChar_A ; Echo the control character
    LD A, ' '
    CALL SendChar_A ; Echo the control character
    LD A, 'q'
    CALL SendChar_A ; Echo the control character
    JP .ReadLineLoop ; Continue reading ReadLine
; .insertStr:
;     DB "<Insert 0>", 0x00 ; Insert string
; .overwriteStr:
;     DB "<Overwrite 1>", 0x00 ; Erase string

.home:
    LD HL, IX
    LD DE, BUFFER_START
    SBC HL, DE ; distance from start to cursor
    LD B, L ; works for buffer shorter than 256
    LD A, B
    OR A
    CP 0x00 ; Check if at the start of the string
    JP Z, .ReadLineLoop ; If at the start, do nothing 
.homeCursorLoop:
    LD A, 0x1B ; Backspace
    CALL SendChar_A
    LD A, '[' ; Backspace
    CALL SendChar_A
    LD A, 'D' ; Backspace
    CALL SendChar_A
    DJNZ .homeCursorLoop ; Loop until cursor on left
    LD IX, BUFFER_START

    JP .ReadLineLoop ; Continue reading ReadLine


.lineEnd:
    LD HL, .lineEndStr ; Load the insert string address
    CALL PrintString ; Print the insert string
    JP .ReadLineLoop ; Continue reading ReadLine
.lineEndStr:
    DB "<End>", 0x00 ; Insert string

.pageUp:
    LD HL, .pageUpStr ; Load the insert string address
    CALL PrintString ; Print the insert string
    JP .ReadLineLoop ; Continue reading ReadLine
.pageUpStr:
    DB "<PageUp>", 0x00 ; Insert string

.pageDown:
    LD HL, .pageDownStr ; Load the insert string address
    CALL PrintString ; Print the insert string
    JP .ReadLineLoop ; Continue reading ReadLine
.pageDownStr:
    DB "<PageDown>", 0x00 ; Insert string



SendNewline:
    LD HL, INFO_MSG
    CALL PrintString
    LD HL, BUFFER_ADDRESS ; Reset buffer pointer
    CALL PrintString
;    LD HL, BUFFER_ADDRESS ; Reset buffer pointer
;    CALL PrintHex
    RET

; -------------------------------------------
ParseCommand: ;Parse command line and execute command
    LD HL, BUFFER_ADDRESS ; Load the buffer address
    LD IX, COMMANDS_LIST ; Load the commands list address
;.spaceRemoval:
    CALL SpaceRemoval
    LD A, (HL) ; Read the first character
    CP 0x00 ; Check for null terminator
    RET Z ; If null terminator, return
.parse:
    LD A, (HL) ; Read the first character
    CP ' '
    JP Z, .checkEndToken ; If space, check IX is 0x00
    CP (IX) ; compare buffer with command list
    JP NZ, .noMatch ; If not match, go to no match
.checkEndToken:
    LD A, (IX) ; Read the command character
    CP 0x00 ; Check for null terminator
    JP Z, .endParse ; If null terminator, command recognised
    INC IX ; Increment command list pointer
    INC HL ; Increment buffer pointer
    JP .parse

.endParse:
    PUSH HL
    INC IX ; Increment command list Pointeur
    LD L, (IX) ; Read the command character
    INC IX ; Increment command list Pointeur
    LD H, (IX) ; Read the command character
    JP (HL) ; Jump to the command function

.noMatch: ; if commande not found, go to next command
    INC IX ; Increment command list pointer
    LD A, (IX) ; Read the next character
    CP 0x00 ; Check for null terminator
    JR NZ, .noMatch ; If not null terminator, continue loop
    INC IX ; Increment IX past the command pointer
    INC IX
    INC IX ; Increment IX to the next command
    LD A, (IX) ; Read the first character
    CP 0xFF ; Check for end of command list
    JR Z, .endParseNoMatch ; If end of command list, stop parsing
    LD HL, BUFFER_ADDRESS
    CALL SpaceRemoval ; Remove spaces from the command
    JR .parse ; Go back to parse the next command

.endParseNoMatch:
    LD HL, BUFFER_ADDRESS 
    CALL SpaceRemoval
    CALL PrintString
    LD A, ' '
    CALL SendChar_A
    LD A, ':'
    CALL SendChar_A
    LD A, ' '   
    CALL SendChar_A
    LD HL, UNKNOWN_CMD_MSG ; Load the unknown command message address
    CALL PrintString ; Print the unknown command message
    LD HL, CR_LF 
    CALL PrintString
    RET

; Commands for the monitor - ALWAYS POP HL EVEN IF NO USE FOR HL
Cmd_DriveA:
    POP HL
    LD A, 'A'
    LD (DRIVE_LETTER), A
    LD A, FS_SERIAL
    LD (FILE_SYSTEM), A
    RET
    
Cmd_DriveB:
    POP HL
    LD A, 'B'
    LD (DRIVE_LETTER), A
    LD A, FS_EEPROM
    LD (FILE_SYSTEM), A
    RET
    
Cmd_DriveC:
    POP HL
    LD A, 'C'
    LD (DRIVE_LETTER), A
    LD A, FS_SDCARD
    LD (FILE_SYSTEM), A
    RET

Cmd_Echo:
    POP HL
    CALL SpaceRemoval ; Remove spaces from the command
    CALL PrintString
    LD HL, CR_LF 
    CALL PrintString
    RET

Cmd_Exec:
    POP HL
    CALL Str2Digits ; Convert string to Number
    JP NZ, .notANumber ; If not a number, error
    LD HL, CMD_EXEC_MSG ; Load the buffer address
    CALL PrintString ; Print the command message
    LD A, D
    CALL Hex2Str
    LD A, E
    CALL Hex2Str
    LD HL, CR_LF 
    CALL PrintString
;Hack HL PUSH to emulate a CALL-RET
    LD HL, .savePC
    PUSH HL
    LD HL, DE
    JP (HL) ; Jump to the address parsed by Str2Digits
.savePC
    LD HL, CR_LF 
    CALL PrintString
    RET
.notANumber:
    LD HL, CMD_EXEC_ERROR_MSG ; Load the buffer address
    CALL PrintString ; Print the command message
    LD HL, CR_LF 
    CALL PrintString
    RET

Cmd_Dump:
    POP HL
    CALL Str2Digits ; Convert string to number
    JP NZ, .notANumber ; If not a number, error
    LD HL, DE
    CALL PrintHex ; Print the command message
    LD HL, CR_LF 
    CALL PrintString
    RET
.notANumber:
     LD HL, CMD_DUMP_ERROR_MSG ; Load the buffer address
     CALL PrintString ; Print the command message
    LD HL, CR_LF 
    CALL PrintString
     RET

Cmd_List:
    POP HL
    CALL Str2Digits ; Convert string to Number
    JP NZ, .notANumber ; If not a number, error
    LD HL, CMD_LIST_MSG ; Load the buffer address
    CALL PrintString ; Print the command message
    LD A, D
    CALL Hex2Str
    LD A, E
    CALL Hex2Str
    LD HL, CR_LF 
    CALL PrintString
    LD HL, DE ; Load the buffer Address
    CALL PrintString
    LD HL, CR_LF
    CALL PrintString
    RET
.notANumber:
    LD HL, CMD_LIST_ERROR_MSG ; Load the buffer address
    CALL PrintString ; Print the command message
    LD HL, CR_LF 
    CALL PrintString
    RET

Cmd_Load:
    POP HL
    CALL Str2Digits ; get the destination address
    JP NZ, .notANumber ; If not a number, error
    PUSH DE ; destination address on the stack
    CALL Str2Digits ; get the file size
    JP NZ, .notANumberPopDE ; If not a number, error
    LD BC, DE ; put the size in BC
    LD HL, CMD_LOAD_MSG1 ; Load the buffer address
    CALL PrintString ; Print the command message
    LD A, B ; get the size and print it
    CALL Hex2Str
    LD A, C
    CALL Hex2Str
    LD HL, CMD_LOAD_MSG2 ; Load the buffer address
    CALL PrintString ; Print the command message
    POP DE ; get the destination address from the STACK
    LD A, D
    CALL Hex2Str
    LD A, E
    CALL Hex2Str
    LD HL, CR_LF 
    CALL PrintString
    LD HL, CMD_LOAD_MSG_WAITING ; Load the buffer address
    CALL PrintString ; Print the command message
    LD HL, CR_LF
    CALL PrintString
    LD HL, 0x0000
.receiveBytes:
    CALL ReceiveChar_B
    LD (DE), A ; Store the byte in memory
    INC DE ; Increment the address
    DEC BC ; Decrement the byte counter
    INC HL ; Increment the byte counter (for display)
    LD A, C
    AND 0x07
    JP NZ, .noDot
    LD A, '.'
    CALL SendChar_A ; Send the character to SIO port A
.noDot:
    LD A, B
    OR C
    JP NZ, .receiveBytes ; If not, continue receiving data
.endOfFile:
    LD BC, HL
    LD HL, CR_LF 
    CALL PrintString
    LD HL, CMD_LOAD_MSG_END ; Load the buffer address
    CALL PrintString ; Print the command message
    LD A, B
    CALL Hex2Str
    LD A, C
    CALL Hex2Str
    LD HL, CR_LF 
    CALL PrintString
    RET
.notANumberPopDE:
    POP DE ; pop the destination address from the stack
.notANumber:
    LD HL, CMD_LOAD_ERROR_MSG ; Load the buffer address
    CALL PrintString ; Print the command message
    LD HL, CR_LF 
    CALL PrintString
    RET

Cmd_LoadTxt:
    POP HL
    CALL Str2Digits ; Convert string to Number
    JP NZ, .notANumber ; If not a number, error
    LD HL, CMD_LOADTXT_MSG ; Load the buffer address
    CALL PrintString ; Print the command message
    LD A, D
    CALL Hex2Str
    LD A, E
    CALL Hex2Str
    LD HL, CMD_LOADTXT_MSG_WAITNG ; Load the buffer address
    CALL PrintString ; Print the command message
    LD HL, CR_LF 
    CALL PrintString
    LD BC, 0x0000 ; Initialize BC to 0
.receiveData:
    CALL ReceiveChar_A
    CP 0xFF ; EOF ?
    JP Z, .endOfFile
    LD (DE), A ; Store the character in memory
    INC DE ; Increment the address
    INC BC ; Increment the byte counter
    JP .receiveData ; Continue receiving data
.endOfFile:
    INC DE
    LD A, 0x00
    LD (DE), A
    LD HL, CMD_LOADTXT_MSG_END ; Load the buffer address
    CALL PrintString ; Print the command message
    LD A, B
    CALL Hex2Str
    LD A, C
    CALL Hex2Str
    LD HL, CR_LF 
    CALL PrintString
    RET
.notANumber:
    LD HL, CMD_LOADTXT_ERROR_MSG ; Load the buffer address
    CALL PrintString ; Print the command message
    LD HL, CR_LF 
    CALL PrintString
    RET

Cmd_Write:
    POP HL
    LD HL, CMD_WRITE_MSG ; Load the buffer address
    CALL PrintString ; Print the command message
    LD HL, CR_LF 
    CALL PrintString
    RET
    
Cmd_clrscr:
    POP HL
    LD HL, CLRSCR ; Load the buffer address
    CALL PrintString ; Print the command message
    RET

Cmd_Help:
    POP HL
    LD HL, CMD_HELP_MSG ; Load the buffer address
    CALL PrintString ; Print the command message
    LD HL, CR_LF 
    CALL PrintString
    RET

Cmd_ls:
    POP HL
    LD A, (FILE_SYSTEM)
    CP FS_SERIAL
    JP NZ, Wrong_File_System
    LD HL, BUFFER_ADDRESS
    CALL SerFS_TxtCmd
    RET

Cmd_cwd:
    POP HL
    LD A, (FILE_SYSTEM)
    CP FS_SERIAL
    JP NZ, Wrong_File_System
    LD HL, BUFFER_ADDRESS
    CALL SerFS_TxtCmd
    RET

Cmd_cd:
    POP HL
    LD A, (FILE_SYSTEM)
    CP FS_SERIAL
    JP NZ, Wrong_File_System
    LD HL, BUFFER_ADDRESS
    CALL SerFS_TxtCmd
    RET

Cmd_cat:
    POP HL
    LD A, (FILE_SYSTEM)
    CP FS_SERIAL
    JP NZ, Wrong_File_System
    LD HL, BUFFER_ADDRESS
    CALL SerFS_TxtCmd
    RET

Cmd_run:
    POP HL
    LD A, (FILE_SYSTEM)
    CP FS_SERIAL
    JP NZ, Wrong_File_System
    LD HL, BUFFER_ADDRESS
.send_loop:
    CALL SendCharB_HL
    INC HL
    LD A, (HL)
    OR A
    JP NZ, .send_loop
    ;LD A, 0x0D
    ;CALL SendChar_A
    CALL ReceiveChar_B ; get Ack or Nack
    CP 0x06 ; Check for ACK
    JP NZ, .errorMsg
    CALL ReceiveChar_B ; get the two bytes for the size
    LD B, A
    CALL Hex2Str
    CALL ReceiveChar_B
    LD C, A
    CALL Hex2Str
    LD HL, CR_LF
    CALL PrintString
    LD HL, PROGRAM_BASE_ADDRESS
.receive_loop:
    CALL ReceiveChar_B
    LD (HL), A
;    CALL Hex2Str
    DEC BC
    INC HL
    LD A, C
    OR B
    JP Z, .end_loop
    ; LD A, B
    ; CALL Hex2Str
    ; LD A, C
    ; CALL Hex2Str
    LD A, '.'
    CALL SendChar_A
    JP .receive_loop
.end_loop:
    LD A, '/'
    CALL SendChar_A
    CALL ReceiveChar_B
    CALL Hex2Str
    LD HL, CR_LF
    CALL PrintString
    CALL PROGRAM_BASE_ADDRESS
    RET
.errorMsg:
    CALL ReceiveChar_B
    CP 0x06
    JP Z, .error_loop
    CALL SendChar_A
    JP .errorMsg
.error_loop:
    RET

SerFS_TxtCmd: ; send command in HL and display response
.send_loop:
    CALL SendCharB_HL
    INC HL
    LD A, (HL)
    OR A
    JP NZ, .send_loop
;    LD A, 0x0D
;    CALL SendChar_A
.receive_loop:
    CALL ReceiveChar_B
    CP 0x06
    JP Z, .end_loop
    CALL SendChar_A
    JP .receive_loop
.end_loop:
    RET


Wrong_File_System:
    LD HL, WRONG_FILE_SYSTEM_MSG
    CALL PrintString
    LD HL, CR_LF 
    CALL PrintString

    RET

GetBaseAddress_HL: ; return the return address of the CALL in HL
    POP HL
    PUSH HL
    RET

GetBaseAddress_BC: ; return the return address of the CALL in BC
    POP BC
    PUSH BC
    RET

GetBaseAddress_DE: ; return the return address of the CALL in DE
    POP DE
    PUSH DE
    RET

GetBaseAddress_IX: ; return the return address of the CALL in IX
    POP IX
    PUSH IX
    RET

GetBaseAddress_IY: ; return the return address of the CALL in IY
    POP IY
    PUSH IY
    RET

;  -------------------------------------------
; Padding to 0x1900
    DS 0x1900 - $    ; pad to 0x1900 , judt below 8KB

    ORG 0x1900
; Jump API table
    JP SendChar_HL
    JP SendChar_IX
    JP SendChar_A
    JP PrintString
    JP ReceiveChar_A
    JP ReceiveChar_B
    JP PrintHex
    JP Hex2Str
    JP Char2Digit
    JP Str2Digits
    JP StringLength
    JP SpaceRemoval
    JP GetBaseAddress_HL
    JP GetBaseAddress_BC
    JP GetBaseAddress_DE
    JP GetBaseAddress_IX
    JP GetBaseAddress_IY
    JP Keypad_Scan
    JP Hex2BCD

OnKeyPressed:
OnKeyReleased:
;  -------------------------------------------
; Fin du programme
    DS 0x4000 - $    ; pad to 16kB