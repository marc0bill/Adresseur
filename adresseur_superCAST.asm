;******************************************************************************
; TITLE: 
; AUTHOR:
; DESCRIPTION: 
;******************************************************************************
  LIST p=18f2331,f=INHX32,r=DEC; Definition du microcontroleur
  #include<p18f2331.inc>       ; Fichier include
  CONFIG OSC = HSPLL,  DEBUG = ON, WDTEN=OFF, LVP = OFF ; PLL enable => 40MHz

;******************************************************************************
;  DEFINITION DE SYMBOLES ET MACRO
;******************************************************************************
#define Add_COL_IN 0
#define Add_ROW_IN 0
#define Add_ROW_OUT_WL 1
#define RESET_Dff 2
#define EN_SR 3
#define CLK_R 4
;#define Add_ROW_OUT_CG 5
#define CLK_C 5;6
;#define Add_COL_OUT 7
#define CHAR_END 0xAA


; -- UART CONFIGURATION
  ;Pour Fosc=40Mhz
  ;#define SPBRGVal 11	; 921 600 Baud
  ;#define SPBRGVal 43 	; 230 400 Baud
  #define SPBRGVal 86 	; 115 200 Baud
  ;#define SPBRGVal 172	;  57 600 Baud
  ;Pour Fosc=16Mhz
  ;#define SPBRGVal 68	;  57 600 Baud
  ;#define SPBRGVal 103	;  38 400 Baud
  ;#define SPBRGVal 138	;  28 800 Baud
  ;#define SPBRGVal 207	;  19 200 Baud
  ;Pour Fosc=10Mhz
  ;#define SPBRGVal 43	;  57 600 Baud
  ;#define SPBRGVal 172	;  14 400 Baud
  #define UTX_LEN 23
  #define URC_LEN 23
  #define FLAG_RC_END 0
  #define FLAG_NEWVAL 1
;******************************************************************************
;  VARIABLE dans ACCESS RAM
;******************************************************************************
  CBLOCK  0x000   ; zone access ram de la banque 0
charFirst:1
addCOL:16  ; 16 mots de 8bits
addROW:4   ; 4 mots de 8bits
charCheck:1
charLast:1
valBit:1
valMot:1
i_shift:1
valAdress:2
; -- UART CONFIGURATION
UTx_go: 1
UTx_size: 1
UTx_i: 1
URc_i: 1
URxChar: 1
flag:1
; --
  ENDC            ; fin de la zone de declaration

  CBLOCK  0x100   ; zone access ram de la banque 1
wreg_lp : 1
bsr_lp : 1
status_lp : 1
temp1:1
temp2:1
temp3:1
temp4:1
  ENDC            ; fin de la zone de declaration

  CBLOCK  0x200   ; zone access ram de la banque 2
URc_str : URC_LEN
  ENDC            ; fin de la zone de declaration
;******************************************************************************
; PROGRAMME
;******************************************************************************
;--- VECTEUR DE RESET ---------------------------------------------------------
  ORG 0x00
  goto main

;--- VECTEUR D'INTERRUPTION HAUTE PRIORITE ------------------------------------
  ORG 0x08
  bra makehp

;--- VECTEUR ET ROUTINE D'INTERRUPTION BAS PRIORITE ---------------------------
  ORG 0x18
  MOVFF STATUS, status_lp
  MOVFF WREG, wreg_lp
  BTFSC PIE1, TXIE
  BTFSS PIR1, TXIF  ; EUSART TX
  BRA SKIP_ITTX
  BRA IT_TX
SKIP_ITTX
  BTFSC PIR1, RCIF  ; EUSART RC
  BRA IT_RC
LOWITEND
  MOVFF wreg_lp, WREG
  MOVFF status_lp, STATUS
  retfie
;--- ROUTINES D'INTERRUPTION BAS PRIORITE -------------------------------------
; INTERRUPT EUSART RC
IT_RC
  MOVFF RCREG, POSTINC2
  TSTFSZ URc_i ; si URc_i==0  => skip
  bra SKIP_TEST_FIST
  movlw CHAR_END
  CPFSEQ charFirst ; ET si charFirst==CHAR_END => skip
  bra LOWITEND
SKIP_TEST_FIST
  incf URc_i, F
  movlw URC_LEN
  CPFSEQ URc_i
  bra LOWITEND
  bsf flag, FLAG_RC_END
  clrf URc_i
  LFSR FSR2, charFirst ; pour la reception
  bra LOWITEND 
; ---------------------
; INTERRUPT EUSART TX
IT_TX
  ;clrf WREG
  ;CPFSEQ UTx_i
  ;CHAR_END
  
  
  
  incf UTx_i
  MOVFF POSTINC0, TXREG
  movlw UTX_LEN
  CPFSLT UTx_i
  BCF PIE1, TXIE    ; Disable Interrupt  
  BRA LOWITEND
;--- ROUTINE D'INTERRUPTION HAUTE PRIORITE ------------------------------------
makehp ; ROUTINE IT du au TRIG
  bcf INTCON, INT0F
  incf i_shift
  movlw 128
  CPFSEQ i_shift
  bra nexthp
;--- Decalage ROW ---
  clrf i_shift
  RLCF addROW, W
  BTFSS WREG, 7; Bit Test f, Skip if Set
  bcf LATC, Add_ROW_IN
  BTFSC WREG, 7; Bit Test f, Skip if Clear
  bsf LATC, Add_ROW_IN
  bsf LATB, CLK_R
  RLCF addROW+3, f
  RLCF addROW+2, f
  RLCF addROW+1, f
  RLCF addROW, F
  bcf LATB, CLK_R
  BSF flag, FLAG_NEWVAL
  retfie FAST
;--- Decalage COL ---
nexthp
  RLCF addCOL, W
  BTFSS WREG, 7; Bit Test f, Skip if Set
  bcf LATB, Add_COL_IN
  BTFSC WREG, 7; Bit Test f, Skip if Clear
  bsf LATB, Add_COL_IN
  bsf LATB, CLK_C
  RLCF addCOL+15, f
  RLCF addCOL+14, f
  RLCF addCOL+13, f
  RLCF addCOL+12, f
  RLCF addCOL+11, f
  RLCF addCOL+10, f
  RLCF addCOL+9, f
  RLCF addCOL+8, f
  RLCF addCOL+7, f
  RLCF addCOL+6, f
  RLCF addCOL+5, f
  RLCF addCOL+4, f
  RLCF addCOL+3, f
  RLCF addCOL+2, f
  RLCF addCOL+1, f
  RLCF addCOL, F
  bcf LATB, CLK_C
  BSF flag, FLAG_NEWVAL
  retfie FAST
;--- ZONE DE DEFINITION DES FONCTION ------------------------------------------

TXAdress
  
  return
  
 
  
;--- PROGRAMME PRINCIPAL ------------------------------------------------------
main
  movlb 0
; ------------------------- PIC  CONFIGURATION --------------------------------
; UART CONFIGURATION
  BSF TRISC, TRISC6	;
  BSF TRISC, TRISC7	;
  BSF BAUDCON, BRG16	; 16-bit
  clrf SPBRGH
  movlw SPBRGVal
  movwf SPBRG
  movlw 0x24
  movwf TXSTA           ; 8-bit, Transmission enabled, High Speed
  BSF RCSTA, CREN	; Enable Reception
  BSF RCSTA, SPEN	; Enable UART module
  BCF IPR1, TXIP	; Low priority
  BCF IPR1, RCIP	; Low priority
  BCF PIE1, TXIE	; Disable des interruptions sur TX
  BSF PIE1, RCIE	; Autorisaiton des interruptions sur RX
  CLRF UTx_go
  CLRF UTx_size
  CLRF UTx_i
  CLRF URc_i
  CLRF flag
  CLRF charCheck
  CLRF charLast
  CLRF valBit
  CLRF valMot
  CLRF i_shift
  CLRF valAdress
  CLRF valAdress+1
  LFSR FSR0, addCOL ; Pour l'envoie
  LFSR FSR2, charFirst ; pour la reception
; ---------------------------- Initialisation ----------------------------------
  clrf charFirst
  clrf addCOL
  clrf addCOL+1
  clrf addCOL+2
  clrf addCOL+3
  clrf addCOL+4
  clrf addCOL+5
  clrf addCOL+6
  clrf addCOL+7
  clrf addCOL+8
  clrf addCOL+9
  clrf addCOL+10
  clrf addCOL+11
  clrf addCOL+12
  clrf addCOL+13
  clrf addCOL+1
  clrf addCOL+15
  clrf addROW
  clrf addROW+1
  clrf addROW+2
  clrf addROW+3
; ---------------------
  bsf LATB, RESET_Dff   ; RESET Active
  bcf LATB, Add_COL_IN
  bcf LATC, Add_ROW_IN
  bcf LATB, EN_SR
  bcf LATB, CLK_R
  bcf LATB, CLK_C
  bsf LATB, Add_ROW_OUT_WL
;  bsf LATB, Add_ROW_OUT_CG
; ---------------------			
  bcf TRISB, Add_COL_IN
  bcf TRISC, Add_ROW_IN
  bcf TRISB, RESET_Dff
  bcf TRISB, EN_SR
  bcf TRISB, CLK_R
  bcf TRISB, CLK_C
  bsf TRISB, Add_ROW_OUT_WL
;  bsf TRISB, Add_ROW_OUT_CG
; ---------------------	
  bcf LATB, RESET_Dff   ; RESET deactivation
  
  bsf RCON, IPEN
  bcf INTCON, INT0F
  bsf INTCON, INT0E
  bsf INTCON, GIEH
  bsf INTCON, GIEL
;--- Boucle infinie ---
boubleinf
  BTFSC flag, FLAG_NEWVAL
  call TXAdress
  
  
  
  
  BTFSS flag, FLAG_RC_END ; Si nouvelle adresse envoye par UART
  bra boubleinf
  bcf flag, FLAG_RC_END
;--- Verification charLast ---
  movlw CHAR_END
  CPFSEQ charLast
  bra END_TRAITEMENT_RECEPTION
; ---------------------	
  clrf valMot
  LFSR FSR1, addCOL
BOUCLE_COL
  movlw 8
  movwf valBit
BOUCLE_COL_BIT
  movf valMot, w
  bcf LATB, CLK_C
  BTFSS PLUSW1, 7; Bit Test f, Skip if Set
  bcf LATB, Add_COL_IN
  BTFSC PLUSW1, 7; Bit Test f, Skip if Clear
  bsf LATB, Add_COL_IN
  RLNCF PLUSW1, F
  bsf LATB, CLK_C
  DECFSZ valBit
  bra BOUCLE_COL_BIT
  incf valMot
  movlw 16
  CPFSEQ valMot
  bra BOUCLE_COL
  bcf LATB, CLK_C
  bcf LATB, Add_COL_IN
; ---------------------	
  clrf valMot
  LFSR FSR1, addROW
BOUCLE_ROW
  movlw 8
  movwf valBit
BOUCLE_ROW_BIT
  movf valMot, w
  bcf LATB, CLK_R
  BTFSS PLUSW1, 7; Bit Test f, Skip if Set
  bcf LATC, Add_ROW_IN
  BTFSC PLUSW1, 7; Bit Test f, Skip if Clear
  bsf LATC, Add_ROW_IN
  RLNCF PLUSW1, F
  bsf LATB, CLK_R
  DECFSZ valBit
  bra BOUCLE_ROW_BIT
  incf valMot
  movlw 4
  CPFSEQ valMot
  bra BOUCLE_ROW
  bcf LATB, CLK_R
  bcf LATC, Add_ROW_IN
; ---------------------	
END_TRAITEMENT_RECEPTION
  clrf charFirst
  clrf charLast
  bra boubleinf

  END      ; Fin

  