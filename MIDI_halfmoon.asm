;MIDI HALFMOON SWITCH control for CLAVIA NORDELECTRO 2
;V 1.0
;By Emanuele Gian gennaio 2011
;
;per mezzo di uno switch a 3 posizioni vengono inviati 3 CC diversi in base alla posizione dello stesso
;Rotary Speaker Fast/Slow CC -> 0x52 ( CC 82 value -> 0 = slow, 127 = fast  )
;Rotary Speaker Run/Stop CC -> 0x53  ( CC 83 value -> 0 = off, 127 = on )

 PROCESSOR 16F84a
 RADIX DEC
 INCLUDE "P16F84a.INC"

;Setup of PIC configuration flags
;XT oscillator
;Disable watch dog timer
;Enable power up timer
;Disable code protect

 __CONFIG 3FF1H
 ORG 0CH		;Reset Vector

;CONSTANT, variables
MIDI_OUT_PIN 			equ 0 ;  pin RA0
LED_PIN					equ 1 ; MIDI tx LED
LED_PIN_fast			equ 2 ;  For debug you can apply a LED on RA1
LED_PIN_slow			equ 3 ;  For debug you can apply a LED on RA2
LED_PIN_brake			equ 4 ;  For debug you can apply a LED on RA3
;
CONTROL_PIN_slow		equ 0 ;  Input switch 1
CONTROL_PIN_fast		equ 1 ;  Input switch 2
CONTROL_PIN_brake		equ 2 ;  Input switch 3



;PORTA 0 - > slow switch: a massa se ON
;PORTA 1 -> fast switch: a massa se ON
;PORTA 2 -> brake on: a massa se ON
	

flags equ 0x0C;
;bit 0 -> slow flag switch (1 se on)
;bit 1 -> fast flag switch (1 se on)
;bit 2 -> brake flag switch (1 se on)
;bit 3 -> 1 se messaggio fast spedito
;bit 4 -> 1 se messaggio slow spedito
;bit 5 -> 1 se messaggio brake on spedito
;bit 6 -> 1 se messaggio brake off spedito

; ----- variabili supporto routine delay per 31250 baud --- NON MODIFICARE -----
temp	equ	0x1F ; locazione registro per temp
xmit	equ	0x1D ; locazione registro per var xmit
i	equ	0x1C
j	equ	0x1B
k	equ	0x1A
;--------------------------------------------------------------------------------

; Program
 ORG 00H			;Punto di inizio del programma al reset della CPU

 bsf	 STATUS,RP0 		;Commuta sul secondo banco dei registri per accedere ai registri TRISA e TRISB
  
 ;movlw 01111111B  		;Attiva pull-ups interni per PORTB
 ;movwf OPTION_REG & 7FH

 bcf OPTION_REG, 7;
		
 movlw 00000000B		;Definizione delle linee di I/O (0=Uscita, 1=Ingresso)
 movwf TRISA & 7FH		;Definizione della porta A

 movlw 11111111B		;Definizione delle linee di I/O (0=Uscita, 1=Ingresso)
 movwf TRISB & 7FH		;Definizione della porta B

 bcf STATUS,RP0			;Riseleziona il banco 0

 bsf	PORTA, MIDI_OUT_PIN	; init midi out pin state 
 bcf	PORTA, LED_PIN; 	debug led off
 bcf	PORTA, LED_PIN_fast; 	rotot fast
 bcf	PORTA, LED_PIN_slow; 	rotor slow
 bcf	PORTA, LED_PIN_brake; 	brake on
 clrf	flags		; azzera registro flags
;


 goto mainloop
;---------------------------------------------

brakeoff:
	movlw	0xB0 			; CC
	movwf	xmit
	call	sendmidi

	movlw	0x53		; CC brake
	movwf	xmit
	call	sendmidi

	movlw	0x00;		; value for brake off (0)
	movwf	xmit
	call	sendmidi
 	bsf flags, 6; mette a 1 il bit 6
	return


brakeon:
	bcf flags, 0; 
	bcf flags, 1;  
	bsf flags, 2; 1 = switch attivo 
	bcf PORTA, LED_PIN_fast;
	bcf PORTA, LED_PIN_slow;
	bsf PORTA, LED_PIN_brake; accende led brake on
	btfsc flags, 5; se flag 5 = 1 allora il messaggio è già stato spedito e torna a mainloop
    return;
	movlw	0xB0 			; CC
	movwf	xmit
	call	sendmidi

	movlw	0x53		; CC brake
	movwf	xmit
	call	sendmidi

	movlw	0x7F		; value for brake off (0 ?)
	movwf	xmit
	call	sendmidi
	bcf flags, 3;
    bcf flags, 4;
    bcf flags, 6;
	bsf flags, 5; mette a 1 il bit 5
	return

rotorfast:
	bcf flags, 0; 
	bcf flags, 2;  
	bsf flags, 1; 1 = switch attivo 
	bsf PORTA, LED_PIN_fast; accende led rotor fast
	bcf PORTA, LED_PIN_slow;
	bcf PORTA, LED_PIN_brake; 
	btfsc flags, 3; se flag 3 = 1 allora il messaggio è già stato spedito e torna a mainloop
    return;
    btfss flags, 6; se flasg 6 = 1 allora il messaggio rotor brake off era già stato spedito
	call brakeoff;
	movlw	0xB0 		;STATUS = CC
	movwf	xmit
	call	sendmidi

	movlw	0x52		; CC slow/fast
	movwf	xmit
	call	sendmidi

	movlw	0x7F		; 127 fast
	movwf	xmit
	call	sendmidi
	bcf flags, 4;
    bcf flags, 5;
    bcf flags, 6;
 	bsf flags, 3; mette a 1 il bit 3
	return

rotorslow:
	bcf flags, 1; 
	bcf flags, 2;  
	bsf flags, 0; 0 = switch attivo 
	bcf PORTA, LED_PIN_fast; 
	bsf PORTA, LED_PIN_slow; accende led rotor slow
	bcf PORTA, LED_PIN_brake; 
	btfsc flags, 4; se flag 4 = 1 allora il messaggio è già stato spedito e torna a mainloop
    return;
	btfss flags, 6; se flasg 6 = 1 allora il messaggio rotor brake off era già stato spedito
	call brakeoff;
	movlw	0xB0 			; CC
	movwf	xmit
	call	sendmidi

	movlw	0x52		; CC brake
	movwf	xmit
	call	sendmidi

	movlw	0x00		; 0 = slow
	movwf	xmit
	call	sendmidi
	bcf flags, 3;
    bcf flags, 5;
    bcf flags, 6;
    bsf flags, 4; mette a 1 il bit 4
	return
    
mainloop:
	;controlla situazione switch
	btfss PORTB, CONTROL_PIN_slow;
	call rotorslow;
	btfss PORTB, CONTROL_PIN_fast; 
	call rotorfast;
	btfss PORTB, CONTROL_PIN_brake; 
	call brakeon;
	
	
	goto	mainloop
  
; sendmidi transmits one midi byte on RA0
; at 10mhz there are 80 instructions per midi bit
; JOSH: so at 4mhz there should be 32 instructions per midi bit
;
; xmit contains byte to send
; * this should be rewritten to support variable delays for
; * different clock speeds

sendmidi:

	bsf PORTA, LED_PIN;			
	
startb:	
	bcf	PORTA, MIDI_OUT_PIN	; start bit

	;movlw	D'24'		; delay 73 clocks: 2 + (23 * 3 + 1 * 2)
    movlw	D'8'		; delay 25 clocks: 2 + (23 * 3 + 1 * 2)
	movwf	temp		; |
loop1:
	decfsz	temp,f		; |	
	goto	loop1		; end delay

	movlw	D'8'		
	movwf	j

sendloop:			; executes 5 instuctions before setting bit	
	rrf	xmit,f
	btfsc	STATUS, C
	goto	send1
	
; remember midi bits are opposite from our representation
send0:
	nop
	bcf	PORTA, MIDI_OUT_PIN	;send a 0 bit
	goto	endloop

send1:
	bsf	PORTA, MIDI_OUT_PIN	;send a 1 bit
	nop
	nop

endloop:			;
			
	;movlw	D'23'		;delay 70 instructions 2 + (22 * 3 + 1 * 2)	
	movlw	D'7'		;delay 22 instructions 2 + (6 * 3 + 1 * 2)	
	movwf	temp		; |
loop2:	decfsz	temp,f		; |
	goto	loop2		; end delay

	decfsz	j,f		;
	goto	sendloop

stopb:
	nop
	nop
	nop
	nop
	nop
	bsf	PORTA, MIDI_OUT_PIN	; stop bit
					;movlw	D'26'		; delay 79 clocks: 2 + (25 * 3 + 1 * 2)
    nop  ; JOSH ed to add extra op
    nop  ; JOSH ed to add extra op
    movlw	D'26'		; delay 29 clocks: 2 + (9 * 3 + 1 * 4)
	movwf	temp		; |
loop3:	decfsz	temp,f		; |
	goto	loop3		; end delay

 	bcf PORTA, LED_PIN;
	return

	end