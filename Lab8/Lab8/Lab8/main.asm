.include "m128def.inc"				; Include definition file

;************************************************************
;* Variable and Constant Declarations
;************************************************************
.def	mpr = r16				; Multi-Purpose Register
.def	cmd = r17				; Command register

.equ	RightBt = 0				
.equ	LeftBt = 1				
.equ	ForBt = 2
.equ	BackBt = 3
.equ	HaltBt = 4
.equ	FreezeBt = 5

;**************************************************************
;* Beginning of code segment
;**************************************************************
.cseg

;--------------------------------------------------------------
; Interrupt Vectors
;--------------------------------------------------------------
.org	$0000				; Reset and Power On Interrupt
		rjmp	INIT		; Jump to program initialization

.org	$0046				; End of Interrupt Vectors
;--------------------------------------------------------------
; Program Initialization
;--------------------------------------------------------------
INIT:
    ; Initialize the Stack Pointer (VERY IMPORTANT!!!!)
		ldi		mpr, low(RAMEND)
		out		SPL, mpr		; Load SPL with low byte of RAMEND
		ldi		mpr, high(RAMEND)
		out		SPH, mpr		; Load SPH with high byte of RAMEND

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

		ldi		mpr, (1<<TXC1)
		sts		UcSR1A, mpr

		;Enable transfer and enable transfer interrupts
		ldi mpr, (1<<TXEN1)
		sts UCSR1B, mpr

		ldi		mpr, (1<<UPM11|1<<UPM01|1<<UCSZ11|1<<UCSZ10)
		sts UCSR1C, mpr

		;Set frame format: 8 data bits, 2 stop bits

;---------------------------------------------------------------
; Main Program
;---------------------------------------------------------------
MAIN:
		in		mpr, PIND		; Get whisker input from Port D
		andi	mpr, (1<<LeftBt|1<<RightBt|1<<ForBt|1<<BackBt|1<<HaltBt|1<<FreezeBt)
		cpi		mpr, (1<<LeftBt)
		brne	RIGHT			; Continue with next check
		rcall	SendLeft		
		rjmp	MAIN			; Continue with program

RIGHT:	cpi		mpr, (1<<RightBt)	
		brne	FORWARD			
		rcall	SendRight			
		rjmp	MAIN			; Continue through main

FORWARD:	cpi		mpr, (1<<ForBt)
		brne	BACKWARD			
		rcall	SendForward			
		rjmp	MAIN			; Continue through main

BACKWARD:	cpi		mpr, (1<<BackBt)	
		brne	HALT			
		rcall	SendBackward	
		rjmp	MAIN			; Continue through main

HALT:	cpi		mpr, (1<<HaltBt)
		brne	FREEZE			
		rcall	SendHalt		
		rjmp	MAIN			; Continue through main

FREEZE:	cpi		mpr, (1<<FreezeBt)
		brne	MAIN			
		rcall	SendFreeze		
		rjmp	MAIN			; Continue through main

;****************************************************************
;* Subroutines and Functions
;****************************************************************

;----------------------------------------------------------------
; Sub:	HitRight
; Desc:	Handles functionality of the TekBot when the right whisker
;		is triggered.
;----------------------------------------------------------------
SendLeft:
		rcall	SendAddr
		ldi		cmd, 0b10010000
		rcall	SendCmd
		ret

SendRight:
		rcall	SendAddr
		; write out the right command to usart
		ldi cmd, 0b10100000
		rcall SendCmd
		ret

SendForward:
		rcall	SendAddr
		; write out the forward command to usart
		ldi cmd, 0b10110000
		rcall SendCmd
		ret

SendBackward:
		rcall	SendAddr
		; write out the backward command to usart
		ldi cmd, 0b10000000
		rcall SendCmd
		ret

SendHalt:
		rcall	SendAddr
		; write out the halt command to usart
		ldi cmd, 0b11001000
		rcall SendCmd
		ret

SendFreeze:
		rcall	SendAddr
		; write out the freeze command to usart
		ldi cmd, 0b11111000
		rcall SendCmd
		ret

SendAddr:
		ldi cmd, 0b00110101
		rcall SendCmd
		ldi cmd, 0b10100000
		rcall SendCmd
		ret 

SendCmd:
		lds mpr, UCSR1A
		ANDI mpr, (1<<UDRE1)
		CPI mpr,  (1<<UDRE1) ; Loop until UDR1 is empty
		rjmp SendCmd

		sts UDR1, cmd
		ret