;******************************************************************************
; TITLE: Firmware du module d'adressage
; AUTHOR: Marc Bocquet
; DESCRIPTION: 
; A chaque frond montant sur RC3, l'adresse est incremente et est recopie
; sur le port B et le port C.
; L'adresse peut etre force directement par l'envoie sur UART de la valeur en
; ASCII. La chaine de caratere doit ce terminer par \r\n 
; Chaque modification de l'adresse provoque l'envoie de l'adresse sur l'UART 
; sous format ASCII.
;******************************************************************************
  LIST p=18f2331,f=INHX32,r=DEC; Definition du microcontroleur
  #include<p18f2331.inc>       ; Fichier include
  CONFIG OSC = XT,  DEBUG = OFF, WDTEN=OFF, LVP = OFF ; 4MHz

;******************************************************************************
;  DEFINITION DE SYMBOLES ET MACRO
;******************************************************************************
movlf MACRO Value, Registre
  movlw Value
  movwf Registre
  endm

; -- UART CONFIGURATION
  ;Pour Fosc=40Mhz
  ;#define SPBRGVal 11	; 921 600 Baud
  ;#define SPBRGVal 43 	; 230 400 Baud
  ;#define SPBRGVal 86 	; 115 200 Baud
  ;#define SPBRGVal 172	;  57 600 Baud
  ;Pour Fosc=8Mhz
  ;#define SPBRGVal 207	;  9 600 Baud
  ;#define SPBRGVal 103	;  19 200 Baud
  ;#define SPBRGVal 34	;  57 600 Baud
  ;Pour Fosc=4Mhz
  #define SPBRGVal 17  ;  57 600 Baud
  #define UTX_LEN 6
  #define URC_LEN 50
  #define FLAG_RC_END 0
;******************************************************************************
;  VARIABLE dans ACCESS RAM
;******************************************************************************
  CBLOCK  0x000   ; zone access ram de la banque 0
valAdress:2
val:2
valtemp:2
; -- UART CONFIGURATION
UTx_go: 1
UTx_size: 1
UTx_i: 1
URc_i: 1
URxChar: 1
CHAR_LF:1
CHAR_CR:1
flag:1
; --
  ENDC            ; fin de la zone de declaration

  CBLOCK  0x100   ; zone access ram de la banque 1
UTx_str : UTX_LEN
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
  movf URc_i, W
  MOVFF RCREG, PLUSW1
  incf URc_i, F
  movf PLUSW1, W
  CPFSEQ CHAR_LF
  bra LOWITEND
  movf URc_i, W
  decf WREG
  decf WREG
  movf PLUSW1, W
  CPFSEQ CHAR_CR
  bra LOWITEND
  bsf flag, FLAG_RC_END
  bra LOWITEND 
; ---------------------
; INTERRUPT EUSART TX
IT_TX
  incf UTx_i
  MOVFF POSTINC0, TXREG
  movlw UTX_LEN
  CPFSLT UTx_i
  BCF PIE1, TXIE    ; Disable Interrupt  
  BRA LOWITEND
;--- ROUTINE D'INTERRUPTION HAUTE PRIORITE ------------------------------------
makehp
  bcf INTCON, INT0F
  clrf WREG
  incf valAdress, F
  ADDWFC valAdress+1, F
  
  BTFSS valAdress+1, 2
  bra nexthp
  clrf valAdress
  clrf valAdress+1
  
nexthp
  movff valAdress, LATB
  movff valAdress+1, LATC
  
  call TXAdress
  
  retfie FAST

;--- ZONE DE DEFINITION DES FONCTION ------------------------------------------

TXAdress
  movlb 1
  
  ;MOVFF valAdress, UTx_str
  ;MOVFF valAdress+1, UTx_str+1
  
  
  MOVFF valAdress, temp1
  MOVFF valAdress+1, temp2
  movlf '0', UTx_str
  movlf '0', UTx_str+1
  movlf '0', UTx_str+2
  movlf '0', UTx_str+3
  
  movlw 3
  CPFSEQ temp2
  bra TXAdress900
  movlw 0xE7
  CPFSGT temp1
  bra TXAdress900
  incf WREG
  SUBWF temp1, f         ; (f) - (W) ->?dest
  movlf '1', UTx_str
  clrf temp2
  
TXAdress900
  movlw 3
  CPFSEQ temp2
  bra TXAdress800
  movlw 0x83
  CPFSGT temp1
  bra TXAdress800
  incf WREG
  SUBWF temp1, f         ; (f) - (W) ->?dest
  clrf temp2
  movlf '9', UTx_str+1
  bra TXAdress90
  
TXAdress800
  movlw 3
  CPFSEQ temp2
  bra TXAdress700
  movlw 0x1F
  CPFSGT temp1
  bra TXAdress700
  incf WREG
  SUBWF temp1, f         ; (f) - (W) ->?dest
  clrf temp2
  movlf '8', UTx_str+1
  bra TXAdress90
  
TXAdress700
  movlw 2
  CPFSEQ temp2
  bra TXAdress600
  movlw 0xBB
  CPFSGT temp1
  bra TXAdress600
  incf WREG
  SUBWF temp1, f         ; (f) - (W) ->?dest
  clrf temp2
  movlf '7', UTx_str+1
  bra TXAdress90
  
TXAdress600
  movlw 2
  CPFSEQ temp2
  bra TXAdress500
  movlw 0x57
  CPFSGT temp1
  bra TXAdress500
  incf WREG
  SUBWF temp1, f         ; (f) - (W) ->?dest
  clrf temp2
  movlf '6', UTx_str+1
  bra TXAdress90
  
TXAdress500
  movlw 1
  CPFSEQ temp2
  bra TXAdress400
  movlw 0xF3
  CPFSGT temp1
  bra TXAdress400
  incf WREG
  SUBWF temp1, f         ; (f) - (W) ->?dest
  clrf temp2
  movlf '5', UTx_str+1
  bra TXAdress90
  
TXAdress400
  movlw 1
  CPFSEQ temp2
  bra TXAdress300
  movlw 0x8F
  CPFSGT temp1
  bra TXAdress300
  incf WREG
  SUBWF temp1, f         ; (f) - (W) ->?dest
  clrf temp2
  movlf '4', UTx_str+1
  bra TXAdress90
  
TXAdress300
  movlw 1
  CPFSEQ temp2
  bra TXAdress200
  movlw 0x2B
  CPFSGT temp1
  bra TXAdress200
  incf WREG
  SUBWF temp1, f         ; (f) - (W) ->?dest
  clrf temp2
  movlf '3', UTx_str+1
  bra TXAdress90

TXAdress200
  movlw 0
  CPFSEQ temp2
  bra TXAdress100
  movlw 0xC7
  CPFSGT temp1
  bra TXAdress100
  incf WREG
  SUBWF temp1, f         ; (f) - (W) ->?dest
  clrf temp2
  movlf '2', UTx_str+1 
  bra TXAdress90
  
TXAdress100
  movlw 0
  CPFSEQ temp2
  bra TXAdress90
  movlw 0x63
  CPFSGT temp1
  bra TXAdress90
  incf WREG
  SUBWF temp1, f         ; (f) - (W) ->?dest
  clrf temp2
  movlf '1', UTx_str+1

  
TXAdress90
  movlw 0
  CPFSEQ temp2
  bra TXAdress80
  movlw 0x59
  CPFSGT temp1
  bra TXAdress80
  incf WREG
  SUBWF temp1, f         ; (f) - (W) ->?dest
  clrf temp2
  movlf '9', UTx_str+2
  bra TXAdress0
  
TXAdress80
  movlw 0
  CPFSEQ temp2
  bra TXAdress70
  movlw 0x4F
  CPFSGT temp1
  bra TXAdress70
  incf WREG
  SUBWF temp1, f         ; (f) - (W) ->?dest
  clrf temp2
  movlf '8', UTx_str+2
  bra TXAdress0

TXAdress70
  movlw 0
  CPFSEQ temp2
  bra TXAdress60
  movlw 0x45
  CPFSGT temp1
  bra TXAdress60
  incf WREG
  SUBWF temp1, f         ; (f) - (W) ->?dest
  clrf temp2
  movlf '7', UTx_str+2
  bra TXAdress0
  
TXAdress60
  movlw 0
  CPFSEQ temp2
  bra TXAdress50
  movlw 0x3B
  CPFSGT temp1
  bra TXAdress50
  incf WREG
  SUBWF temp1, f         ; (f) - (W) ->?dest
  clrf temp2
  movlf '6', UTx_str+2
  bra TXAdress0
  
TXAdress50
  movlw 0
  CPFSEQ temp2
  bra TXAdress40
  movlw 0x31
  CPFSGT temp1
  bra TXAdress40
  incf WREG
  SUBWF temp1, f         ; (f) - (W) ->?dest
  clrf temp2
  movlf '5', UTx_str+2
  bra TXAdress0
  
TXAdress40
  movlw 0
  CPFSEQ temp2
  bra TXAdress30
  movlw 0x27
  CPFSGT temp1
  bra TXAdress30
  incf WREG
  SUBWF temp1, f         ; (f) - (W) ->?dest
  clrf temp2
  movlf '4', UTx_str+2
  bra TXAdress0
  
TXAdress30
  movlw 0
  CPFSEQ temp2
  bra TXAdress20
  movlw 0x1D
  CPFSGT temp1
  bra TXAdress20
  incf WREG
  SUBWF temp1, f         ; (f) - (W) ->?dest
  clrf temp2
  movlf '3', UTx_str+2
  bra TXAdress0
  
TXAdress20
  movlw 0
  CPFSEQ temp2
  bra TXAdress10
  movlw 0x13
  CPFSGT temp1
  bra TXAdress10
  incf WREG
  SUBWF temp1, f         ; (f) - (W) ->?dest
  clrf temp2
  movlf '2', UTx_str+2
  bra TXAdress0
  
TXAdress10
  movlw 0
  CPFSEQ temp2
  bra TXAdress0
  movlw 0x09
  CPFSGT temp1
  bra TXAdress0
  incf WREG
  SUBWF temp1, f         ; (f) - (W) ->?dest
  clrf temp2
  movlf '1', UTx_str+2
  
  
TXAdress0
  movf temp1, w
  addwf UTx_str+3, F
  
  LFSR FSR0, UTx_str
  clrf UTx_i
  BSF PIE1, TXIE    ; Enable Interrupt  
  movlb 0
  return
  
  
;--- PROGRAMME PRINCIPAL ------------------------------------------------------
main
  movlb 0
  BSF OSCCON, IRCF0
  BSF OSCCON, IRCF1
  BSF OSCCON, IRCF2   
; ------------------------- PIC  CONFIGURATION --------------------------------
; UART CONFIGURATION
  BSF TRISC, TRISC6	;
  BSF TRISC, TRISC7	;
  BSF BAUDCON, BRG16	; 16-bit
  clrf SPBRGH
  movlf SPBRGVal, SPBRG
  movlf 0x24, TXSTA 	; 8-bit, Transmission enabled, High Speed
  BSF TXSTA, TXEN	;
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
  LFSR FSR0, UTx_str
  LFSR FSR1, URc_str
  LFSR FSR2, URc_str
  movlf 0x0A, CHAR_LF   ; \n : LF : Line Feed
  movlf 0x0D, CHAR_CR   ; \r : CR : Carrige Return
  movff CHAR_CR, UTx_str+4
  movff CHAR_LF, UTx_str+5

  
; ---------------------
  movlf  0xFF, valAdress
  movlf  0xFF, valAdress+1
  movff valAdress, LATB
  movff valAdress+1, LATC
  
  bcf TRISB, 0
  bcf TRISB, 1
  bcf TRISB, 2
  bcf TRISB, 3
  bcf TRISB, 4
  bcf TRISB, 5
  bcf TRISB, 6
  bcf TRISB, 7
  bcf TRISC, 0 
  bcf TRISC, 1
  
  bsf RCON, IPEN
  bcf INTCON, INT0F
  bsf INTCON, INT0E
  bsf INTCON, GIEH
  bsf INTCON, GIEL
  
  
;--- Boucle infinie ---
boubleinf
  BTFSS flag, FLAG_RC_END
  bra boubleinf
  bcf flag, FLAG_RC_END
  clrf val
  clrf val+1
  clrf WREG
  decf URc_i, F
  decf URc_i, F
  BZ nextURc
  decf URc_i, F
  LFSR FSR2, URc_str
loopURc
  movff POSTINC2, valtemp
  movlw 48	           ; soustraire à W la valeur ASCII de 0 = 48 en decimal
  SUBWF valtemp, W         ; (f) - (W) ->?dest
  addwf val, F
  clrf WREG
  addwfc val+1, F
  decf URc_i, F
  BN nextURc
  
  MOVLW 10
  MULWF val ; 10 * valL -> PRODH:PRODL
  MOVFF PRODH, valtemp+1 ;
  MOVFF PRODL, valtemp ;
  MOVLW 10
  MULWF val+1 ; 10 * valH -> PRODH:PRODL
  MOVF PRODL, W ;
  ADDWF valtemp+1, F ; Add cross
  ;MOVFF PRODH, valtemp+2
  movff valtemp, val
  movff valtemp+1, val+1
  
  bra loopURc
  
nextURc
  CLRF URc_i
  movff val, valAdress
  movff val+1, valAdress+1
  movff valAdress, LATB
  movff valAdress+1, LATC
  
  call TXAdress
  
  bra boubleinf

  END      ; Fin

  