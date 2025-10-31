 org 0x0000

         LD SP, 0xFF00 ; Initialisation de la pile


LCD_ADDR EQU 0x70 ; adresse de base du LCD
LCD_CMD EQU LCD_ADDR ; A0 = 0 -> registre de commande
LCD_DATA EQU LCD_ADDR + 1 ; A0 = 1 -> registre de données
 ; -----------------------------------------------------
 ; Routine de delai simple
DELAY:
         LD B, 0xFF
DELAY_LOOP1:
         LD C, 0xFF
DELAY_LOOP2:
         DEC C
         JP NZ, DELAY_LOOP2
         DEC B
         JP NZ, DELAY_LOOP1
         RET
   
 ; -----------------------------------------------------
; Envoi d'une commande a l'ecran LCD
LCD_WriteCmd:
         LD A, (HL) ; A = commande a l'adresse HL
         OUT (LCD_CMD), A ; envoi de la commande
         CALL DELAY ; delai pour le LCD
         RET

; -----------------------------------------------------
; Envoi d'un caractere a l'ecran LCD
LCD_WriteChar:
         LD A, (HL) ; A = caractere a l'adresse HL
         OUT (LCD_DATA), A ; envoi du caractere
         CALL DELAY ; delai pour le LCD
         RET

   ; -----------------------------------------------------
; Initialisation de l'ecran LCD (mode 8 bits)
LCD_Init:
        LD HL, Cmds
NextCmd:
        LD A, (HL)
        CP 0xFF                 ; Fin de la liste ?
        RET Z
        CALL LCD_WriteCmd
        INC HL
        JP NextCmd

; --------------------------
; Affichage d'un texte
PrintHello:
        LD HL, Msg
NextChar:
        LD A, (HL)
        CP 0                   ; Fin de chaîne ?
        RET Z
        CALL LCD_WriteChar
        INC HL
        JP NextChar

; --------------------------
; Données : commandes d'initialisation
Cmds:
        DB 0x38    ; Function Set: 8-bit, 2 lines, 5x8 font
        DB 0x0C    ; Display ON, cursor OFF, blink OFF
        DB 0x06    ; Entry mode: cursor moves right
        DB 0x01    ; Clear display
        DB 0x02    ; Return home
        DB 0xFF    ; Fin des commandes

; --------------------------
; Texte à afficher
Msg:
        DB "HELLO WORLD",0

; --------------------------
; Main program
Start:
        CALL LCD_Init
        CALL PrintHello
Loop:
        JP Loop

;  -------------------------------------------
; Fin du programme
         DS 0x4000 - $    ; pad to 16kB