; Cristal de 4 MHz (Fosc)
; CM = 4 / Fosc = 4 / 4 = 1 useg
    
; Sinal sonoro de 2KHz -> T = 1/f = 0,5 mseg -> T/2 = 0.25 mseg
; TMR0 = 256 – TEMPO/CM -> TMR0 = 256 – 0.25mseg/1useg = 6
; TMR0 = 256 – TEMPO/4CM -> TMR0 = 256 – 0.25 mseg/(4x1useg) = 193,5
    
; Sinal sonoro de 3KHz -> T = 1/f = 0.3333 mseg -> T/2 = 0.16666 mseg
; TMR0 = 256 – TEMPO/CM -> TMR0 = 256 – 0.16666mseg/1useg = 89,34
; TMR0 = 256 – TEMPO/4CM -> TMR0 = 256 – 0.16666 mseg/(4x1useg) = 214,35
    
; Sinal sonoro de 800Hz -> T = 1/f = 1,25 mseg -> T/2 = 0,625 mseg
; TMR0 = 256 – TEMPO/4CM -> TMR0 = 256 – 0,625mseg/1useg = -369
; Associando o prescaler ao TMR0 com uma divisão do CM por 2:
; TMR0 = 256 – TEMPO/4CM -> TMR0 = 256 – 0,625 mseg/(2x1useg) = -56,5
; Associando o prescaler ao TMR0 com uma divisão do CM por 4:
; TMR0 = 256 – TEMPO/4CM -> TMR0 = 256 – 0,625 mseg/(4x1useg) = 99,75
; A ZONA_S obrigatoriamente deve ser ligado na porta RB0 (interrupção externa) 

#INCLUDE P16F628A.INC
    
;-> ENTRADAS
#DEFINE ZONA1       PORTA,0 ;Monitora o dispositivo
#DEFINE ZONA2       PORTA,1 ;Monitora o dispositivo
#DEFINE TECLADO	    PORTA,2 ;Monitora o dispositivo
#DEFINE ZONA_S	    PORTB,0 ;Monitora o dispositivo

;-> SAIDAS
#DEFINE LED1	    PORTB,1 ;Controla o dispositivo 
#DEFINE LED2	    PORTB,2 ;Controla o dispositivo 
#DEFINE LED_S	    PORTB,3 ;Controla o dispositivo 
#DEFINE LED_A	    PORTB,4 ;Controla o dispositivo 
#DEFINE SIRENE	    PORTB,5 ;Controla o dispositivo 
#DEFINE RELE        PORTB,6 ;Controla o dispositivo  
 
SALVA_W	    EQU 20H	    ; Usado para salvar o reg. W nas interrupções
SALVA_S	    EQU 21H	    ; Usado para salvar o reg. STATUS nas interrupções
FLAGS	    EQU 22H	    ; Flags do sistema
FREQ	    EQU 23H	    ; Indica a freqüência que será gerado pelo TMR0
CONTA1	    EQU 24H	    ; Contador dos laços de tempo
CONTA2	    EQU 25H	    ; Contador dos laços de tempo
CONTA3	    EQU 26H	    ; Contador dos laços de tempo 
 
	__CONFIG _XT_OSC & _WDT_OFF & _PWRTE_ON & _MCLRE_ON & _BODEN_OFF & _LVP_OFF & _CP_OFF

	ORG 000H
	GOTO INICIO

; -> Interrupção 
	ORG 004H
	MOVWF SALVA_W	    ; Salva contexto
	SWAPF STATUS,W
	MOVWF SALVA_S

	BTFSS INTCON,INTF   ; Int. externa
	GOTO  INTTMR0
	
; -> Interrupção externa: Zona Silenciosa
	
	BCF INTCON,INTF	    ; Zera flag de interrupção externa 	
	BSF FLAGS,0	    ; Indica ao programa principal que ZONA_S foi acionada
	BCF LED_S	    ; Acende o led silencioso
	BSF RELE	    ; Aciona o rele
	
	GOTO FIMINT	    ; Sai da interrupção 
	
; -> Interrupção do Timer 0
INTTMR0:BCF INTCON,T0IF	    ; Zera flag de interrupção do temporizador 0 
	BTFSS FLAGS,1	    ; Gerar sinal sonoro? 
	GOTO SEM_SOM
	
	MOVFW FREQ	    ; Pega valor de recarga do TMR0
	MOVWF TMR0
	
	MOVLW B'00100000'
	XORWF PORTB,F	    ; Inverte sinal da sirene
	GOTO FIMINT	    ; Sai da interrupção 
	
SEM_SOM:BCF SIRENE	    ; Desliga a sirene 	
	 
FIMINT:	SWAPF SALVA_S,W	    ; Recupera contexto
	MOVWF STATUS
	SWAPF SALVA_W,F
	SWAPF SALVA_W,W
	RETFIE
 
; -> Configura E/S e interrupções 
INICIO: BSF STATUS,RP0	    ; Banco 1 da RAM
	MOVLW B'10000001'   ;
	MOVWF TRISB	    ; RB1,RB2,RB3,RB4,RB5,RB6,RB7 como saídas
	MOVLW B'11111111'   ;
	MOVWF TRISA	    ; 
	MOVLW B'10000001'   ; Int. ext. por borda de descida 
			    ; TMR0 no modo temporizador com prescaler 1:4 
	MOVWF OPTION_REG
	MOVLW B'10110000'   ; Habilita int. externa e do temporizador 0 
    MOVWF INTCON		
	BCF STATUS,RP0	    ;  Volta para o Banco 0 da RAM 

	MOVLW 7
	MOVWF CMCON
	
	CLRF FLAGS ; Zera as flags do sistema 

RST:BSF LED1		;
	BSF LED2	    ; APAGA LEDS
	BSF LED_S		;
	BSF LED_A		;
	BCF SIRENE	    ; DESLIGA SIRENE
	BCF RELE	    ; DESLIGA RELE
	
	CALL	LP200MS
	
; -> Programa principal 
TST_Z1:	BTFSS ZONA1	    ;ZONA 01 ACIONADA?
		GOTO Z1_ON

		BSF	LED1
		BCF	FLAGS,2
		GOTO	TST_Z2

Z1_ON:	BCF	LED1
		BSF	FLAGS,2

TST_Z2:	BTFSS ZONA2	    ;ZONA 02 ACIONADA?
		GOTO Z2_ON

		BSF	LED2
		BCF	FLAGS,3
		GOTO	TST_TEC

Z2_ON:	BCF	LED2
		BSF	FLAGS,3

TST_TEC:BTFSC TECLADO	    ;Teclado acionado?
		GOTO TST_Z1

		MOVLW	B'00001101'
		ANDWF	FLAGS,W
		BTFSC	STATUS,Z
		GOTO	SOM1

		BTFSS FLAGS,0	    ; ZONA SILENCIOSA ATIVADA ?
		GOTO SOM2

		BCF	FLAGS,0
		BCF	RELE
		BSF	LED_S
		CALL LP200MS
		GOTO	TST_Z1
	    
SOM2:	MOVLW	.193
		MOVWF	FREQ
		BSF		FLAGS,1
		CALL	LP1SEG
		BCF		FLAGS,1
		GOTO	TST_Z1

SOM1:	BCF		LED_A
		MOVLW	.100
		MOVWF	FREQ
		BSF		FLAGS,1
		CALL	LP800MS
		BCF		FLAGS,1

TST_Z1_2:	BTFSC 	ZONA1	    ;ZONA 01 ACIONADA?
			GOTO	TST_Z2_2
			BCF		LED1
			BSF 	RELE
			MOVLW 	.214
			MOVWF 	FREQ
			BSF 	FLAGS,2
			BSF 	FLAGS,1

TST_Z2_2:	BTFSC 	ZONA2	    ;ZONA 02 ACIONADA?
			GOTO	TST_2_TEC
			BSF		RELE
			BCF		LED2
			MOVLW 	.214
			MOVWF 	FREQ
			BSF 	FLAGS,3
			BSF 	FLAGS,1

TST_2_TEC:	BTFSC 	TECLADO	    ;Teclado acionado?
			GOTO 	TST_Z1_2

			BTFSC 	FLAGS,2
			GOTO 	DESL_ALM

			BTFSC 	FLAGS,3
			GOTO 	DESL_ALM

			BTFSS 	FLAGS,0
			GOTO 	RST

DESL_ALM:	BSF 	LED1
			BSF 	LED2
			BSF		LED_S
			CLRF 	FREQ
			BCF 	RELE
			CLRF 	FLAGS
			CALL	LP200MS
			GOTO 	TST_Z1_2
			
; -> Laço de tempo 
LP1SEG:MOVLW .5  ; 5 x 200 mseg = 1 SEG   
	   MOVWF CONTA3 
LP_200:CALL LP200MS   
	   DECFSZ CONTA3,F   
	   GOTO LP_200   
	   RETURN
	   
LP800MS:MOVLW .4  ; 4 x 200 mseg = 800 MILI 
		MOVWF CONTA3 
LP2_200:CALL LP200MS   
	 	DECFSZ CONTA3,F   
	 	GOTO LP2_200   
	 	RETURN

LP200MS:MOVLW .200  ; 200 x 1 mseg   
	    MOVWF CONTA2 
LP_1MS:	MOVLW .250  ; 250 x 4 x 1useg = 1mseg   
	    MOVWF CONTA1 
LOOP:	NOP   
	    DECFSZ CONTA1,F   
	    GOTO LOOP
	    DECFSZ CONTA2,F   
	    GOTO LP_1MS   
	    RETURN 

		END