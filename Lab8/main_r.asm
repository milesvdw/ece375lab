;***********************************************************
;*
;*	Enter Name of file here
;*
;*	Enter the description of the program here
;*
;*	This is the RECEIVE skeleton file for Lab 8 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Enter your name
;*	   Date: Enter Date
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multi-Purpose Register
.def	usart = r17
.def	reciever = r18
.def	state = r19				;State 0: Waiting for first byte
								;State 1: Waiting for second byte
.def	current = r20

.def	freeze = r21

.equ	WskrR = 0				; Right Whisker Input Bit
.equ	WskrL = 1				; Left Whisker Input Bit
.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit

.equ	BotAddress = 0b00110101;(Enter your robot's address here (8 bits))

;/////////////////////////////////////////////////////////////
;These macros are the values to make the TekBot Move.
;/////////////////////////////////////////////////////////////
.equ	MovFwd =  (1<<EngDirR|1<<EngDirL)	;0b01100000 Move Forward Action Code
.equ	MovBck =  $00						;0b00000000 Move Backward Action Code
.equ	TurnR =   (1<<EngDirL)				;0b01000000 Turn Right Action Code
.equ	TurnL =   (1<<EngDirR)				;0b00100000 Turn Left Action Code
.equ	Halt =    (1<<EngEnR|1<<EngEnL)		;0b10010000 Halt Action Code



;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

		; Set up interrupt vectors for any interrupts being used
.org	$0002
		rcall HitRight
		reti

.org	$0004
		rcall HitLeft
		reti

;clock interrupt
.org	$001C
		ldi mpr, 1
		reti
;Should have Interrupt vectors for:
;- USART receive
.org	$003C
		rcall Recieve
		reti

.org	$0046					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
	;Stack Pointer (VERY IMPORTANT!!!!)
		ldi		mpr, low(RAMEND)
		out		SPL, mpr		; Load SPL with low byte of RAMEND
		ldi		mpr, high(RAMEND)
		out		SPH, mpr		; Load SPH with high byte of RAMEND
	;I/O Ports
	    ; Initialize Port B for output
		ldi		mpr, $FF		; Set Port B Data Direction Register
		out		DDRB, mpr		; for output
		ldi		mpr, $00		; Initialize Port B Data Register
		out		PORTB, mpr		; so all Port B outputs are low		

	; Initialize Port D for input
		ldi		mpr, $00		; Set Port D Data Direction Register
		out		DDRD, mpr		; for input
		ldi		mpr, $FF		; Initialize Port D Data Register
		out		PORTD, mpr		; so all Port D inputs are Tri-State
	;USART1
		;Set baudrate at 2400bps
		ldi		mpr, $01
		sts		UBRR1H, mpr
		ldi		mpr, $A0
		sts		UBRR1L, mpr
		ldi		mpr, (1<<RXC1|1<<U2X1|1<<TXC1)
		sts		UcSR1A, mpr
		ldi		mpr, (1<<RXCIE1|1<<RXEN1|1<<TXEN1)
		sts		UcSR1B, mpr
		ldi		mpr, (1<<UPM10|1<<UPM11|1<<UCSZ11|1<<UCSZ10)
		sts		UcSR1C, mpr
		;Enable receiver and enable receive interrupts
		;Set frame format: 8 data bits, 2 stop bits
	;External Interrupts
		;Set the External Interrupt Mask
		ldi		mpr, $03
		out		EIMSK, mpr
		;Set the Interrupt Sense Control to falling edge detection
		ldi		mpr, $0A
		sts		EICRA, mpr

	;Timer Interrupts
		ldi		mpr, 0b00000000
		out		TIMSK, mpr
		ldi		mpr, 0b00000000
		out		TCCR1A, mpr
		ldi		mpr, 0b00000101
		out		TCCR1B, mpr
		ldi		mpr, 0b00000000
		sts		TCCR1C, mpr

		clr		current
		clr		freeze

	;Other
	sei

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
		rjmp	MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************
Recieve:
		push	mpr
		rcall disable_interrupts

		;recieve data
		lds		reciever, UDR1
		
		 ; Loop until UDR1 is empty

		cpi		reciever, 0b01010101
		breq	freezer 

		;compare to bot address
		cpi		reciever, BotAddress
		brne	bad
		
		rec2:
		lds mpr, UCSR1A
		ANDI mpr, (1<<RXC1)
		CPI mpr,  (1<<RXC1)
		 ; Loop until UDR1 is empty
		BRNE	rec2

		;receive instruction code
		
		lds	reciever, UDR1

		;compare intstruction line with possible instructions
		cpi		reciever, 0b10010000 ;Left
		brne	Right			
		rjmp	instruction
		RIGHT:	
		cpi		reciever, 0b10100000 ;Right
		brne	FORWARD			
		rjmp	instruction			; Continue to end
											
		FORWARD:
		cpi		reciever, 0b10110000 ;Forward
		brne	BACKWARD					
		rjmp	instruction			; Continue to end
											
		BACKWARD:
		cpi		reciever, 0b10000000 ;Backward
		brne	HALT1					
		rjmp	instruction			; Continue to end
										
		HALT1:
		cpi		reciever, 0b11001000 ;Halt
		brne	FREEZE1						
		rjmp	instruction			; Continue to end

		FREEZE1:	
		cpi		reciever, 0b11111000 ;Freeze
		brne	end	
		rjmp	flshfreeze
					
		instruction:	
		clc
		rol		reciever

		;set instruction to current movement
		mov		current, reciever
		out		PORTB, current	

		;reset state and end recieving
		End:
		rcall  enable_interrupts
		pop		mpr
		ret

;Action to take if reciever sends freeze command
flshfreeze:
		lds mpr, UCSR1A
		ANDI mpr, (1<<UDRE1)
		CPI mpr,  (1<<UDRE1)
		 ; Loop until UDR1 is empty
		BRNE flshfreeze

		lds mpr, UCSR1A ; Flush buffer
		sts UCSR1A, mpr
		
		ldi mpr, 0b01010101 ;Transmit freeze command
		sts UDR1, mpr
		rjmp end

;Action to take if freeze code is recieved from other reciever
freezer:
		cli

		ldi	mpr, $00 ;Stop
		out PORTB, mpr

		rcall wait ;Wait 1 sec X5
		rcall wait
		rcall wait
		rcall wait
		rcall wait

		cpi freeze, 2 ;Check counter
		brge freezer ;Loop

		inc freeze

		out PORTB, current ;Resume previous function
		sei
		rjmp End

;Terminate the recieve function prematurely		
bad:
		rcall	enable_interrupts
		pop		mpr
		ret	


HitRight:
		rcall	disable_interrupts
		push	mpr			; Save mpr register

		; Move Backwards for a second
		ldi		mpr, MovBck	; Load Move Backward command
		out		PORTB, mpr	; Send command to por
		rcall	Wait			; Call wait function

		
		; Turn left for a second
		ldi		mpr, TurnL	; Load Turn Left Command
		out		PORTB, mpr	; Send command to port
		rcall	Wait			; Call wait function

		; Move Forward again	
		ldi		mpr, MovFwd	; Load Move Forward command
		out		PORTB, mpr	; Send command to port

		ldi		mpr, $ff
		out		EIFR, mpr
		rcall	enable_interrupts
		pop		mpr		; Restore mpr
		out		PORTB, current
		ret				; Return from subroutine

;----------------------------------------------------------------
; Sub:	HitLeft
; Desc:	Handles functionality of the TekBot when the left whisker
;		is triggered.
;----------------------------------------------------------------
HitLeft:
		rcall disable_interrupts
		push	mpr			; Save mpr register


		; Move Backwards for a second
		ldi		mpr, MovBck	; Load Move Backward command
		out		PORTB, mpr	; Send command to port
		rcall	Wait			; Call wait function

		; Turn right for a second
		ldi		mpr, TurnR	; Load Turn Left Command
		out		PORTB, mpr	; Send command to port
		rcall	Wait			; Call wait function

		; Move Forward again	
		ldi		mpr, MovFwd	; Load Move Forward command
		out		PORTB, mpr	; Send command to port


		ldi		mpr, $ff
		out		EIFR, mpr
		rcall	enable_interrupts
		pop		mpr		; Restore 
		out		PORTB, current
		ret				; Return from subroutine

;----------------------------------------------------------------
; Sub:	Wait
; Desc:	A wait based on a clock interrupt
;----------------------------------------------------------------
Wait:
	push	 mpr
	sei
	ldi		mpr, 0b00000100 ; Enable timer interrupt
	out		TIMSK, mpr

	ldi		mpr, 0b10111111 ; Set timer to proper value so it takes 1 sec
	out		TCNT1H, mpr		; to interrupt
	ldi		mpr, $00
	out		TCNT1L, mpr

	clr		mpr
	loop:
		cpi mpr, 1			; Timer interrupt sets mpr to 1
		brne loop

	ldi		mpr, 0b00000000 ;Disable timer interrupt
	out		TIMSK, mpr
	pop mpr
	ret
		
;Enable Whisker Interrupts
Enable_Interrupts:
	push	mpr
	ldi		mpr, $03
	out		EIMSK, mpr
	pop		mpr
	ret

;Disable Whisker Interrupts
Disable_Interrupts:
	push	mpr
	ldi		mpr, $00
	out		EIMSK, mpr
	pop		mpr
	ret