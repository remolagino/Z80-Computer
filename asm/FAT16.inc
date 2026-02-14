; ------------------------------------------------------
; -                 FAST16.inc                         -
; -  Include for the structures linked to              -
; -                FAT 16 elements                     -
; ------------------------------------------------------

    
    IFNDEF __FAST16_INC__
    DEFINE __FAST16_INC__ 1



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

    STRUCT DIR_ENTRY
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


    ENDIF