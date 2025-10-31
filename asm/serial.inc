; ==== CTC INIT ====
CTC_ADDR EQU 0x20 ; adresse de base du CTC
CTC_CHANNEL_0 EQU CTC_ADDR ; A0 = 0 -> Channel 0
CTC_CHANNEL_1 EQU CTC_ADDR + 1 ; A0 = 1 -> Channel 1
CTC_CHANNEL_2 EQU CTC_ADDR + 2 ; A0 = 2 -> Channel 2
CTC_CHANNEL_3 EQU CTC_ADDR + 3 ; A0 = 3 -> Channel 3

; ==== SIO INIT ====
SIO_ADDR EQU 0x10 ; adresse de base du SIO
SIO_DATA_A EQU SIO_ADDR ; A0 = 0 -> Channel A / A1 = 0 -> Data
SIO_DATA_B EQU SIO_ADDR + 1 ; A0 = 1 -> Channel B / A1 = 0 -> Data
SIO_CTRL_A EQU SIO_ADDR + 2 ; A0 = 0 -> Channel A / A1 = 1 -> Cmd
SIO_CTRL_B EQU SIO_ADDR + 3 ; A0 = 1 -> Channel B / A1 = 1 -> Cmd
