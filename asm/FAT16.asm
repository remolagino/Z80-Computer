

    STRUCT PARTITION_ENTRY
STATE   BYTE
BEGINING_HEAD    BYTE
BEGINING_CYLSEC WORD
TYPE    BYTE
END_HEAD BYTE
END_CYLSEC WORD
BEGINING_LBA  DWORD
SIZE    DWORD
    ENDS

    STRUCT MBR
EXEC_CODE   BLOCK 446 , 0x00
PARTITION1  PARTITION_ENTRY
PARTITION2  PARTITION_ENTRY
PARTITION3  PARTITION_ENTRY
PARTITION4  PARTITION_ENTRY
BOOT_SIG    WORD 0xAA55
    ENDS

    STRUCT BOOT_RECORD
JUMP    D24 ; Jump instruction to the boot code
OEM_NAME TEXT  8 ; OEM name
BYTES_PER_SECTOR WORD  ; Bytes per sector
SECTORS_PER_CLUSTER BYTE  ; Sectors per cluster
RESERVED_SECTORS WORD  ; Reserved sectors
FAT_COUNT BYTE  ; Number of FATs
MAX_ROOT_DIR_ENTRIES WORD  ; Maximum number of root directory entries
TOTAL_SECTORS WORD  ; Total sectors (for FAT12)
MEDIA_DESCRIPTOR BYTE  ; Media descriptor
FAT_SIZE WORD  ; Size of each FAT in sectors
SECTORS_PER_TRACK WORD  ; Sectors per track
HEAD_COUNT WORD ; Number of heads
HIDDEN_SECTORS DWORD  ; Hidden sectors
TOTAL_SECTORS_32 DWORD  ; Total sectors for FAT32 (not used in FAT16)
LOGICAL_NUM WORD  ; Logical drive Number
EXTENDED_SIGNATURE BYTE  ; Extended signature
VOLUME_ID DWORD  ; Volume ID (random value)
VOLUME_LABEL TEXT 11 ; Volume label
FAT_NAME TEXT 8 ; File system type
; EXEC_CODE   BLOCK 448, 0x00 ; Boot code (not used in this example)
; BOOT_SIG WORD 0xAA55 ; Boot signature
    ENDS

    STRUCT DIRECTORY_ENTRY
FILENAME    TEXT 8
EXTENSION   TEXT 3
ATTRIBUTE   BYTE
RESERVED    BYTE
CREATION    BYTE
CREA_TIME   WORD
CREA_DATE   WORD
LAST_ACCESS WORD
RESERVED2   WORD
LAST_MODIF_TIME WORD
LAST_MODIF_DATE WORD
START_CLUSTER   WORD
SIZE    DWORD
    ENDS


; ------------- Program START -----------------
    .ORG 0x5000

    JP Main

    INCLUDE "jumpTable.inc"
    INCLUDE "sdcard.asm"
;    INCLUDE "string.asm"




FAT16_PRINT_LENGTH: ; string in LH, length in B
    PUSH HL
.loop:
    CALL SENDCHAR_HL
    INC HL
    DJNZ .loop
    POP HL
    RET



Main:
    CALL SDCARD_INIT ; Initialize the SD card CMD0 to CMD41

    CP 0x00
    JP Z, .continue
    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response
    RET
.continue

    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response

; Get the Master Boot Record
    LD HL, FAT16_MBR
    CALL SDCARD_SendCmd17 ; Send CMD17 to SD card
    CALL SDCARD_Wait_R1 ; Wait for response from SD card
    CALL SDCARD_WaitToken
    CALL SDCARD_READ_BLOCK ; Read a block of data from the SD card

; Compute the address of the partition start
    LD IX, MBR.PARTITION1.BEGINING_LBA
    LD DE, (SDCARD_BUFFER_ADDRESS)
    ADD IX, DE
    LD HL, (IX)
    LD IY, FAT16_PARTITION_START
    CALL FAT16_MULTIPLY_DWORD_512

; Get the Boot sector
    LD HL, FAT16_PARTITION_START
    CALL SDCARD_SendCmd17 ; Send CMD17 to SD card
    CALL SDCARD_Wait_R1 ; Wait for response from SD card
    CALL SDCARD_WaitToken
    CALL SDCARD_READ_BLOCK ; Read a block of data from the SD card

; Copy The Boot record information to local variable FAT16_BOOTRECORD
    LD DE, (SDCARD_BUFFER_ADDRESS)
    LD HL, BOOT_RECORD.JUMP
    ADD HL, DE
    LD DE, FAT16_BOOTRECORD
    LD BC, 0x0040
    LDIR

 ; Compute the start address of the FAT
    LD HL, (FAT16_BOOTRECORD.RESERVED_SECTORS)
    LD IY, FAT16_TMP ; Use IY as a temporary variable
    CALL FAT16_MULTIPLY_DWORD_512 ; Multiply the reserved sectors by 512
    LD IX, FAT16_FAT_TABLES
    LD IY, FAT16_PARTITION_START
    CALL FAT16_ADD_DWORD ; Add the partition start address
    LD IY, FAT16_TMP
    CALL FAT16_ADD_DWORD ; Add the reserved sectors

; Compute the start address of the root directory 
    LD IX, FAT16_ROOT_DIR
    LD IY, FAT16_FAT_TABLES
    CALL FAT16_ADD_DWORD
    LD IY, FAT16_TMP
    CALL FAT16_RESET_DWORD
    LD HL, (FAT16_BOOTRECORD.FAT_SIZE)
    CALL FAT16_MULTIPLY_DWORD_512
    LD IX, FAT16_ROOT_DIR
    CALL FAT16_ADD_DWORD
    CALL FAT16_ADD_DWORD

; Compute the start address of the Data clusters
; TO DO

; Print the content of the Boot record
    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response
    CALL FAT16_PRINT_CARD_DETAIL
    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response

    LD IX, FAT16_TMP
    LD IY, IX
    CALL FAT16_RESET_DWORD
    
    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response

    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response

; Display Root Directory
    LD HL, 0x0000
    CALL FAT16_LIST_DIR_FROM_CLUSTER
    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response

    LD HL, FAT16_FILETEST
    CALL PRINT_STRING ; Print the Message
    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response
    LD DE, FAT16_FILETEST
    LD HL, 0x0000
    CALL FAT16_FIND_DIR_ENTRY
    LD A, (FAT16_DIR_ENTRY)
    CP 0x00 ; Check if the entry was found
    JP Z, .noEntryFound ; If not found, jump to noEntryFound
    LD HL, FAT16_MSG_SearchFileFound ; Prepare the message
    CALL PRINT_STRING ; Print the message if entry found
    LD A, (FAT16_DIR_ENTRY.START_CLUSTER+1) ; Load the high byte of the cluster number
    CALL HEX2STR ; Convert the high byte to a string for display
    LD A, (FAT16_DIR_ENTRY.START_CLUSTER) ; Load the low byte of the cluster number
    CALL HEX2STR ; Convert the low byte to a string for display
    JP .end
.noEntryFound:
    LD HL, FAT16_MSG_SearchFileNotFound
    CALL PRINT_STRING ; Print the message if no entry found

.end:

    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response
    RET

FAT16_FILETEST  DB 'VGM.TXT', 0x00 ; File to test
FAT16_CurrentDirCluster WORD 0x0000 ; Current directory Cluster


TEST_CASE:
    CALL PRINT_STRING ; Print the end message
    LD A, '|'
    CALL SENDCHAR_A ; Send a tab character to SIO port A
    LD A, 0x09
    CALL SENDCHAR_A ; Send a tab character to SIO port A
    CALL FAT16_PREP_FILENAME
    LD HL, FAT16_PREP_FILENAME_VAR
    CALL PRINT_STRING ; Print the filename
    LD A, '|'
    CALL SENDCHAR_A ; Send a tab character to SIO port A
    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response
    RET

FAT16_LIST_DIR_FROM_CLUSTER: ; display the dir in sector in HL
    PUSH HL
    CALL FAT16_CLUSTER2BYTES ; Convert the cluster number in HL to byte Address
    LD HL, CLUSTER2BYTES_RETURN
    CALL FAT16_LIST_DIR
    POP HL
    RET


FAT16_PREP_FILENAME: ; Prepare the filename in (HL) return in (FAT16_PREP_FILENAME_VAR)
    PUSH BC
    PUSH DE
    PUSH HL
    ; Prepare the filename variable
    PUSH HL
    ; Clear the filename variable
    LD HL, FAT16_PREP_FILENAME_VAR
    LD A, 0x00
    LD B, 0x0D; Length of the filename
.loop:
    LD (HL), A
    INC HL
    DJNZ .loop

    POP HL
    ; prepare the filename
    LD DE, FAT16_PREP_FILENAME_VAR
    LD B, 0x08
.nameLoop:
    LD A, (HL) ; 
    CP 0x20
    JP Z, .endNameLoop ; If the character is a space, skip it
    LD (DE), A ; Store the character in the filename variable
    INC DE
.endNameLoop:
    INC HL
    DJNZ .nameLoop
    ; prepare the extension
    LD A, '.'
    LD (DE), A ; Store the dot in the filename variable
    INC DE
    LD B, 0x03
.extLoop:
    LD A, (HL) ;
    CP 0x20
    JP Z, .endExtLoop ; If the character is a space, skip it
    LD (DE), A ; Store the character in the filename variable
    INC DE
.endExtLoop:
    INC HL
    DJNZ .extLoop
    ; end the filename with 0x00
    LD A, 0x00
    LD (DE), A ; Store the null terminator in the filename variable
; remove the dot if the extension is empty
    LD HL, FAT16_PREP_FILENAME_VAR
.removeDotLoop:
    LD A, (HL)
    INC HL
    CP '.'
    JP NZ, .removeDotLoop ; If the character is not a dot, continue
    LD A, (HL) ; Load the first character after the extension
    CP 0x00 ; Check if the first character is null
    JP NZ, .end ; If it is null, remove the dot
    DEC HL ; Move back to the dot character
    LD (HL), 0x00 ; Remove the dot
.end
    POP HL
    POP DE
    POP BC
    RET
FAT16_PREP_FILENAME_VAR DB 0x00, 0x00, 0x00, 0x00
                        DB 0x00, 0x00, 0x00, 0x00
                        DB 0x00, 0x00, 0x00, 0x00, 0x00



; ------------------------------------
FAT16_CLUSTER2BYTES: ; Compute the byte address of cluster HL return in (CLUSTER2BYTES_TMPVAR)
    PUSH HL
    PUSH IX
    PUSH IY
    LD A, H
    OR A, L
    JP Z, .noCluster ; If HL is zero, no cluster to display
    LD IX, CLUSTER2BYTES_RETURN
    LD IY,IX
    CALL FAT16_RESET_DWORD ; Reset the temporary variable

    LD IY, CLUSTER2BYTES_TMPVAR2
    DEC HL
    DEC HL
    LD A, H
    AND A ; Clear the carry flag
    RRA
    LD (IY+3), A
    LD A, L
    RRA
    LD (IY+2), A
    LD A, 0x00
    RRA
    LD (IY+1), A
    LD (IY), 0x00
    CALL FAT16_ADD_DWORD
    LD IY, FAT_16_DATA_AREA
    CALL FAT16_ADD_DWORD

    LD HL, IX
    JP .exit
.noCluster:
    LD A, (FAT16_ROOT_DIR)
    LD (CLUSTER2BYTES_RETURN), A
    LD A, (FAT16_ROOT_DIR+1)
    LD (CLUSTER2BYTES_RETURN+1), A
    LD A, (FAT16_ROOT_DIR+2)
    LD (CLUSTER2BYTES_RETURN+2), A
    LD A, (FAT16_ROOT_DIR+3)
    LD (CLUSTER2BYTES_RETURN+3), A
.exit:
    POP IY
    POP IX
    POP HL
    RET
CLUSTER2BYTES_RETURN DWORD 0x00000000
CLUSTER2BYTES_TMPVAR2 DWORD 0x00000000


FAT16_PRINT_SECTOR: ; Address in (HL)
    CALL SDCARD_SendCmd17 ; Send CMD17 to SD card
    CALL SDCARD_Wait_R1 ; Wait for response from SD card
    CALL SDCARD_WaitToken

    CALL SDCARD_PRINT_BLOCK ; Read a block of data from the SD card
    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response
    RET


FAT16_FIND_DIR_ENTRY: ; Fetch the entry with name in (DE) in dir at cluster address HL
    PUSH BC
    PUSH DE
    PUSH HL
    PUSH IX
    LD IX, DE ; Store the address of the file to search
    CALL FAT16_CLUSTER2BYTES ; Convert the cluster number in HL to byte Address
    LD HL, CLUSTER2BYTES_RETURN
    CALL SDCARD_SendCmd18 ; Send CMD18 to SD card
    CALL SDCARD_Wait_R1 ; Wait for response from SD card
    CALL SDCARD_WaitToken
    LD D, 0x04 ; <== Max Number of blocks to read (64 dir entry max)
.dirLoop:
    LD C, 0x10 ; Number of 16 bytes to read (512 bytes)
.blockLoop:
    LD HL, FAT16_DIR_ENTRY
    LD B, 0x20 ; Number of bytes to read
.rowLoop:
    CALL SPI_READ_BYTE ; Read a byte from the SD card
    LD (HL), E
    INC HL
    DJNZ .rowLoop ; Loop until all bytes are sent

    LD A, (FAT16_DIR_ENTRY)
    CP 0x00 ; check if there is new records
    JP Z, .noMatchFound
    CP 0xE5 ; check entry is erased
    JP Z, .postNameCheck
    LD A, (FAT16_DIR_ENTRY.ATTRIBUTE) ; check if LFN or hidden or volume label
    AND 0x0A
    JP NZ, .postNameCheck
; Check if the name in name.ext matches the name in DE
    LD HL, FAT16_DIR_ENTRY.FILENAME
    CALL FAT16_PREP_FILENAME
    LD HL, FAT16_PREP_FILENAME_VAR
    LD B, 0x0D ; Length of the name
;    PUSH DE
;    LD DE, (FAT16_FILE_ADDRESS) ; Load the address of the file to search
.nameLoop:
    LD A, (IX) ; Load the first character of the name to compare
    CP (HL) ; Compare with the name in the directory entry
    JP NZ, .postNameCheck
    CP 0x00
    JP Z, .matchFound ; If the character is null, we found a match
    INC HL
    INC IX
    DJNZ .nameLoop
.matchFound:
;    CALL FAT16_PrintDirEntry
    JP .end
.postNameCheck:
    DEC C ; Decrement block counter
    LD A, C
    CP 0x00 ; Check if D is 16 (means we read a 512 Byte block)
    JP NZ, .blockLoop ; If not zero, read next block
.readCRC:
    CALL SPI_READ_BYTE ; Read CRC byte from the SD card
    CALL SPI_READ_BYTE ; Read CRC byte from the SD Card
    CALL SDCARD_WaitToken
    DEC D
    LD A, D
    CP 0x00 ; Check if D is 0 (means we read all blocks)
    JP NZ, .dirLoop
.noMatchFound:
    ; LD HL, FAT16_MSG_SearchFileNotFound
    ; CALL PRINT_STRING ; Print the message if no match found
.end:
    LD HL, SDCARD_CMD12 ; Prepare CMD12 command
    CALL SDCARD_SendCmd ; Send CMD58 to SD card
    CALL SDCARD_Wait_R1 ; Wait for response from SD card
    CALL SDCARD_GetResponse
    ; LD HL, LF_CR ; Prepare line feed and carriage return    
    ; CALL PRINT_STRING ; Print response
    POP IX
    POP HL
    POP DE
    POP BC
    RET

; -----------------------------
FAT16_LIST_DIR: ; Display all the directory entry at address (HL)
    PUSH BC
    PUSH DE
    PUSH HL
    CALL SDCARD_SendCmd18 ; Send CMD18 to SD card
    CALL SDCARD_Wait_R1 ; Wait for response from SD card
    CALL SDCARD_WaitToken

    LD HL, DIR_ENTRY_HEADER
    CALL PRINT_STRING
    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response
    LD B, 0x04
.dirLoop:
    LD D, 0x00 ; Number of 16 bytes to read (512 bytes)
.blockLoop:
    LD HL, FAT16_DIR_ENTRY
    LD C, 0x20 ; Number of bytes to read
.rowLoop:
    CALL SPI_READ_BYTE ; Read a byte from the SD card
    LD (HL), E
    INC HL
    DEC C
    JP NZ, .rowLoop ; Loop until all bytes are sent

    LD A, (FAT16_DIR_ENTRY)
    CP 0x00 ; check if there is new records
    JP Z, .noMoreRecord
    CP 0xE5 ; check entry is erased
    JP Z, .noDisplay
    LD A, (FAT16_DIR_ENTRY.ATTRIBUTE) ; check if LFN or hidden or volume label
    AND 0x0A
    JP NZ, .noDisplay
    CALL FAT16_PrintDirEntry
.noDisplay:
    INC D ; Increment block counter
    LD A, D
    CP 0x10 ; Check if D is 16 (means we read a 512 Byte block)
    JP NZ, .blockLoop ; If not zero, read next block
.readCRC:
    CALL SPI_READ_BYTE ; Read CRC byte from the SD card
    CALL SPI_READ_BYTE ; Read CRC byte from the SD Card
    CALL SDCARD_WaitToken
    DJNZ .dirLoop
.noMoreRecord:
    LD HL, SDCARD_CMD12 ; Prepare CMD12 command
    CALL SDCARD_SendCmd ; Send CMD58 to SD card
    CALL SDCARD_Wait_R1 ; Wait for response from SD card
    CALL SDCARD_GetResponse
    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response
    POP HL
    POP DE
    POP BC
    RET




FAT16_PrintDirEntry: ; dir entry in FAT16_DIR_ENTRY
    PUSH BC
    PUSH HL
    PUSH IY

    LD HL, FAT16_DIR_ENTRY.FILENAME
    LD B, 0x08
    CALL FAT16_PRINT_LENGTH
    LD A, '.'
    CALL SENDCHAR_A
    LD HL, FAT16_DIR_ENTRY.EXTENSION
    LD B, 0x03
    CALL FAT16_PRINT_LENGTH
;     CALL FAT16_PREP_FILENAME
;    LD HL, FAT16_PREP_FILENAME_VAR
;    CALL PRINT_STRING ; Print the filename
    LD A, 0x09
    CALL SENDCHAR_A
    LD A, (FAT16_DIR_ENTRY.ATTRIBUTE)
    CALL HEX2STR
    LD A, 0x09
    CALL SENDCHAR_A
    LD A, (FAT16_DIR_ENTRY.CREATION)
    CALL HEX2STR
    LD A, 0x09
    CALL SENDCHAR_A

    LD IY, FAT16_DIR_ENTRY.LAST_MODIF_TIME
    CALL FAT16_PrintTime
    LD A, ' '
    CALL SENDCHAR_A

    LD IY, FAT16_DIR_ENTRY.LAST_MODIF_DATE
    CALL FAT16_PrintDate
    LD A, ' '
    CALL SENDCHAR_A

    LD A, (FAT16_DIR_ENTRY.START_CLUSTER+1)
    CALL HEX2STR
    LD A, (FAT16_DIR_ENTRY.START_CLUSTER)
    CALL HEX2STR
    LD A, 0x09
    CALL SENDCHAR_A

    PUSH IX
    LD IX, FAT16_DIR_ENTRY.SIZE
    CALL FAT16_PRINT_DWORD
    POP IX
    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response

    POP IY
    POP HL
    POP BC
    RET
DIR_ENTRY_HEADER:
    DB 'NAME    .ext', 0x09, 'Attr', 0x09, 'Crea', 0x09
    DB 'Time',0x09, ' Date',0x09,' Start',0x09,'Size',0x00

FAT16_PrintTime: ; Word in (IY)
    PUSH BC
    LD A, (IY+1)
    AND 0xF8
    SRL A
    SRL A
    SRL A
    LD E, A
    CALL HEX2BCD
    LD A, L
    CALL HEX2STR
    LD A, ':'
    CALL SENDCHAR_A
    LD A, (IY+1)
    AND 0x07
    SLA A
    SLA A
    SLA A
    LD B, A
    LD A, (IY)
    AND 0xE0
    SRL A
    SRL A
    SRL A
    SRL A
    SRL A
    OR B
    LD E, A
    CALL HEX2BCD
    LD A, L
    CALL HEX2STR
    LD A, ':'
    CALL SENDCHAR_A
    LD A, (IY)
    AND 0x1F
    SLA A
    LD E, A
    CALL HEX2BCD
    LD A, L
    CALL HEX2STR   
    POP BC
    RET

FAT16_PrintDate: ; Word in (IY)
    PUSH BC
    PUSH HL

    LD A, '2'
    CALL SENDCHAR_A
    LD A, '0'
    CALL SENDCHAR_A
    LD A, (IY+1)
    AND 0xFE
    SRL A
    SUB 20
    LD E, A
    CALL HEX2BCD
    LD A, L
    CALL HEX2STR
    LD A, '/'
    CALL SENDCHAR_A
    LD A, (IY+1)
    AND 0x01
    SLA A
    SLA A
    SLA A
    LD B, A
    LD A, (IY)
    AND 0xE0
    SRL A
    SRL A
    SRL A
    SRL A
    SRL A
    OR B
    LD E, A
    CALL HEX2BCD
    LD A, L
    CALL HEX2STR
    LD A, '/'
    CALL SENDCHAR_A
    LD A, (IY)
    AND 0x1F
;    SLA A
    LD E, A
    CALL HEX2BCD
    LD A, L
    CALL HEX2STR   

    POP HL
    POP BC
    RET


FAT16_ADD_DWORD: ; Add DWORD in IY to DWORD in (IX), result in (IX)
    LD A, (IX)
    ADD A, (IY) ; Add the high byte
    LD (IX), A ; Store the result in IX
    LD A, (IX+1)
    ADC A, (IY+1) ; Add the middle byte with carry
    LD (IX+1), A ; Store the result in IX
    LD A, (IX+2)    
    ADC A, (IY+2) ; Add the low byte with carry
    LD (IX+2), A ; Store the result in IX
    LD A, (IX+3)
    ADC A, (IY+3) ; Add the low byte with carry
    LD (IX+3), A ; Store the result in IX
    RET

FAT16_MULTIPLY_DWORD_512: ; Multiply WORD in HL by 512, result in (IY)
    LD (IY), 0x00
    LD A, L ; Load the LSB
    SLA A ; Shift left to prepare for display
    LD (IY + 1), A
    LD A, H ; Load the MSB
    RL A
    LD (IY +2), A
    LD A, 0x00 ; Load the third byte of the LBA
    RL A
    LD (IY+3), A
    RET

FAT16_RESET_DWORD: ; reset the DWORD in (IY)
    LD (IY), 0x00
    LD (IY+1), 0x00
    LD (IY+2), 0x00
    LD (IY+3), 0x00
    RET

FAT16_PRINT_DWORD: ; Print DWORD in (IX)
    LD A, (IX+3) ; Load the high byte
    CALL HEX2STR ; Convert the high byte to a string for display
    LD A, (IX + 2) ; Load the middle byte
    CALL HEX2STR ; Convert the middle byte to a string for display
    LD A, '-' ; Add a dash after the middle byte
    CALL SENDCHAR_A ; Send the dash character to SIO port A
    LD A, (IX + 1) ; Load the high byte
    CALL HEX2STR ; Convert the high byte to a string for display
    LD A, (IX) ; Load the high byte
    CALL HEX2STR ; Convert the high byte to a string for display
    RET

FAT16_PRINT_CARD_DETAIL:
    PUSH BC
    PUSH HL
    PUSH IX

    LD HL, FAT16_MSG_PartStart
    CALL PRINT_STRING
    LD IX, FAT16_PARTITION_START
    CALL FAT16_PRINT_DWORD
    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response

    LD HL, FAT16_MSG_FatAddr
    CALL PRINT_STRING
    LD IX, FAT16_FAT_TABLES
    CALL FAT16_PRINT_DWORD
    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response

    LD HL, FAT16_MSG_DirRoot
    CALL PRINT_STRING
    LD IX, FAT16_ROOT_DIR
    CALL FAT16_PRINT_DWORD
    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response

    LD HL, FAT16_MSG_DataArea
    CALL PRINT_STRING
    LD IX, FAT_16_DATA_AREA
    CALL FAT16_PRINT_DWORD
    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response

    LD HL, FAT16_MSG_MediaExt
    CALL PRINT_STRING
    LD A, (FAT16_BOOTRECORD.MEDIA_DESCRIPTOR) ; Load the OEM name from the boot record
    CALL HEX2STR ; Print the OEM name
    LD A, '-' ; Add a dash after the OEM name
    CALL SENDCHAR_A ; Send the dash character to SIO port A
    LD A, (FAT16_BOOTRECORD.EXTENDED_SIGNATURE) ; Load the OEM name from the boot record
    CALL HEX2STR ; Print the OEM name
    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response

    LD HL, FAT16_MSG_FatName
    CALL PRINT_STRING
    LD HL, FAT16_BOOTRECORD.FAT_NAME
    LD B, 0x08
    CALL FAT16_PRINT_LENGTH ; Print the FAT name
    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response

    LD HL, FAT16_MSG_OemName
    CALL PRINT_STRING
    LD HL, FAT16_BOOTRECORD.OEM_NAME
    LD B, 0x08
    CALL FAT16_PRINT_LENGTH ; Print the FAT name
    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response

    LD HL, FAT16_MSG_VolLabel
    CALL PRINT_STRING
    LD HL, FAT16_BOOTRECORD.VOLUME_LABEL
    LD B, 0x0B
    CALL FAT16_PRINT_LENGTH ; Print the FAT name
    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response

    LD HL, FAT16_MSG_ReservedSec
    CALL PRINT_STRING
    LD HL, (FAT16_BOOTRECORD.RESERVED_SECTORS)
    LD A, H ; MSB of reserved sectors
    CALL HEX2STR ; Print the OEM name
    LD A, L ; LSB of Reserved sectors
    CALL HEX2STR ; Print the OEM name
    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response

    LD HL, FAT16_MSG_bytesPerSector
    CALL PRINT_STRING
    LD HL, (FAT16_BOOTRECORD.BYTES_PER_SECTOR)
    LD A, H ; MSB of bytes per sector
    CALL HEX2STR ; Print the OEM name
    LD A, L ; LSB of bytes per sector
    CALL HEX2STR ; Print the OEM name
    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response

    LD HL, FAT16_MSG_sectorPerCluster
    CALL PRINT_STRING
    LD A, (FAT16_BOOTRECORD.SECTORS_PER_CLUSTER) ; MSB of bytes per sector
    CALL HEX2STR ; Print the OEM name
    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response

    LD HL, FAT16_MSG_FatCount
    CALL PRINT_STRING
    LD A, (FAT16_BOOTRECORD.FAT_COUNT) ; MSB of bytes per sector
    CALL HEX2STR ; Print the OEM name
    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response

    LD HL, FAT16_MSG_MaxRootDirEntry
    CALL PRINT_STRING
    LD HL, (FAT16_BOOTRECORD.MAX_ROOT_DIR_ENTRIES)
    LD A, H ; MSB of bytes per sector
    CALL HEX2STR ; Print the OEM name
    LD A, L ; LSB of bytes per sector
    CALL HEX2STR ; Print the OEM name
    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response

    LD HL, FAT16_MSG_TotalSector
    CALL PRINT_STRING
    LD HL, (FAT16_BOOTRECORD.TOTAL_SECTORS)
    LD A, H ; MSB of bytes per sector
    CALL HEX2STR ; Print the OEM name
    LD A, L ; LSB of bytes per sector
    CALL HEX2STR ; Print the OEM name
    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response

    LD HL, FAT16_MSG_FatSize
    CALL PRINT_STRING
    LD HL, (FAT16_BOOTRECORD.FAT_SIZE)
    LD A, H ; MSB of bytes per sector
    CALL HEX2STR ; Print the OEM name
    LD A, L ; LSB of bytes per sector
    CALL HEX2STR ; Print the OEM name
    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response

    LD HL, FAT16_MSG_HiddenSector
    CALL PRINT_STRING
    LD IX, FAT16_BOOTRECORD.HIDDEN_SECTORS
    CALL FAT16_PRINT_DWORD
    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response

    LD HL, FAT16_MSG_LogicalNum
    CALL PRINT_STRING
    LD HL, (FAT16_BOOTRECORD.LOGICAL_NUM)
    LD A, H ; MSB of bytes per sector
    CALL HEX2STR ; Print the OEM name
    LD A, L ; LSB of bytes per sector
    CALL HEX2STR ; Print the OEM name
    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response

    LD HL, FAT16_MSG_VolId
    CALL PRINT_STRING
    LD IX, FAT16_BOOTRECORD.VOLUME_ID
    CALL FAT16_PRINT_DWORD
    LD HL, LF_CR ; Prepare line feed and carriage return    
    CALL PRINT_STRING ; Print response

    POP IX
    POP HL
    POP BC
    RET


SEPARATOR DB 'SEPARATOR->'
FAT16_BOOTRECORD BOOT_RECORD
FAT16_DIR_ENTRY DIRECTORY_ENTRY

FAT16_TMP DWORD 0x00000000 ; temp variable for calculations
FAT16_512_BLOCK DWORD 0x00000200 ; constante to go to next block 
FAT16_CLUSTER_SIZE DWORD 0x00008000 ; constante to go to next block 
FAT16_MBR DWORD 0x00000000 ; Start of the MBR
FAT16_PARTITION_START DWORD 0x00000000 ; Start of the FAT16 partition
FAT16_FAT_TABLES DWORD 0x00000000 ; Start of the FAT16 tables
FAT16_ROOT_DIR DWORD 0x00000000 ; Start of the FAT16 root directory
FAT_16_DATA_AREA DWORD 0x00060000 ; Start of the FAT16 data area
; FAT_16_VOLUME_LABEL DB '           ', 0x00 ; Volume label
; FAT_16_FAT_NAME DB '        ', 0x00 ; File system type


; Text Constants
FAT16_MSG_MBR DB 'MBR', 0x0A, 0x0D, 0x00
FAT16_MSG_BOOT DB 'BOOT', 0x0A, 0x0D, 0x00
FAT16_MSG_FAT DB 'FAT', 0x0A, 0x0D, 0x00
FAT16_MSG_ROOTDIR DB 'ROOT DIR', 0x0A, 0x0D, 0x00

FAT16_MSG_FatAddr DB 'FAT Address : ', 0x00
FAT16_MSG_PartStart DB 'Partition Start Address : ', 0x00
FAT16_MSG_DirRoot DB 'Dir Root : ', 0x00
FAT16_MSG_DataArea DB 'Data Area : ', 0x00
FAT16_MSG_MediaExt DB 'Media - Extended Sig : ', 0x00
FAT16_MSG_FatName DB 'FAT Name : ', 0x00
FAT16_MSG_OemName DB 'OEM Name : ', 0x00
FAT16_MSG_VolLabel DB 'Volume Label : ', 0x00
FAT16_MSG_ReservedSec DB 'Reserved sectors : ', 0x00
FAT16_MSG_sectorPerCluster DB 'Sectors per cluster : ', 0x00
FAT16_MSG_bytesPerSector DB 'Bytes per Sector : ', 0x00
FAT16_MSG_FatCount DB 'Fat Count : ', 0x00
FAT16_MSG_MaxRootDirEntry DB 'Max Root Dir Entry : ', 0x00
FAT16_TotalSectors DB 'Total Sctors : ', 0x00
FAT16_MSG_FatSize DB 'Fat Size : ', 0x00
FAT16_MSG_HiddenSector DB 'Hidden Sector(s) : ', 0x00
FAT16_MSG_TotalSector DB 'Total Sectors : ' , 0x00
FAT16_MSG_LogicalNum DB 'Logical Num : ', 0x00
FAT16_MSG_VolId DB 'Volume ID : ', 0x00
FAT16_MSG_SearchFileNotFound DB 'File not found', 0x00 ; Message to display if no match found
FAT16_MSG_SearchFileFound DB 'File found -> Cluster : ', 0x00 ; Message to display if match found