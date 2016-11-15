;
; Lab7.asm
;
; Created: 11/8/2016 10:12:25 AM
; Author : Mathew
;***********************************************************
;*
;*
;*	This is the skeleton file for Lab 7 of ECE 375
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register
.def	speed = r17
.def	change = r18

.equ	EngEnR = 4				; right Engine Enable Bit
.equ	EngEnL = 7				; left Engine Enable Bit
.equ	EngDirR = 5				; right Engine Direction Bit
.equ	EngDirL = 6				; left Engine Direction Bit



.equ	MovFwd = (1<<EngDirR|1<<EngDirL)	; Move Forward Command
.equ	MovBck = $00				; Move Backward Command
.equ	TurnR = (1<<EngDirL)			; Turn Right Command
.equ	TurnL = (1<<EngDirR)			; Turn Left Command
.equ	Halt = (1<<EngEnR|1<<EngEnL)		; Halt Command

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

		; Set up interrupt vectors for any interrupts being used
.org	$0002
		rcall	SpeedUp
		reti

.org	$0004
		rcall	SpeedDown
		reti

.org	$0006
		rcall	SpeedMax
		reti

.org	$0008
		rcall	SpeedMin
		reti

.org	$0046					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:							; The initialization routine
		; Initialize the Stack Pointer (VERY IMPORTANT!!!!)
		ldi		mpr, low(RAMEND)
		out		SPL, mpr		; Load SPL with low byte of RAMEND
		ldi		mpr, high(RAMEND)
		out		SPH, mpr		; Load SPH with high byte of RAMEND

    ; Initialize Port B for output
		ldi		mpr, $FF		; Set Port B Data Direction Register
		out		DDRB, mpr		; for output
		ldi		mpr, 0b01101000		; Initialize Port B Data Register
		out		PORTB, mpr		; so move forward is active

	; Initialize Port D for input
		ldi		mpr, $00		; Set Port D Data Direction Register
		out		DDRD, mpr		; for input
		ldi		mpr, $FF		; Initialize Port D Data Register
		out		PORTD, mpr		; so all Port D inputs are Tri-State

	;init constant-ish thingys
		ldi		change, 17

		; Set the Interrupt Sense Control to falling edge 
		ldi		mpr, $AA
		sts		EICRA, mpr
		; Configure the External Interrupt Mask
		ldi		mpr, $0f
		out		EIMSK, mpr
		; Turn on interrupts
			; NOTE: This must be the last thing to do in the INIT function

		;Initialize TCCR0
		ldi		mpr, 0b01111001
		out		TCCR0, mpr
		clr		mpr
		out		TCNT0, mpr
		ldi		mpr, $77
		out		OCR0, mpr

		;Initialize TCCR1
		ldi		mpr, 0b01111001
		out		TCCR2, mpr
		clr		mpr
		out		TCNT2, mpr
		ldi		mpr, $77
		out		OCR2, mpr

		ldi		speed, 7
		sei



;***********************************************************
;*	Main Program
;***********************************************************
MAIN:							; The Main program
		rjmp MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************
SpeedUp:
		IN mpr, OCR0
		CPI mpr, $00
		BREQ doneup
		SUB mpr, change
		OUT OCR0, mpr
		OUT OCR2, mpr
		DEC speed
		ldi mpr, 0b01100000
		add mpr, speed
		OUT PORTB, mpr
		doneup:
		ret

SpeedDown:
		IN mpr, OCR0
		CPI mpr, $FF
		BREQ donedown
		ADD mpr, change
		OUT OCR0, mpr
		OUT OCR2, mpr
		INC speed
		ldi mpr, 0b01100000
		add mpr, speed
		OUT PORTB, mpr
		donedown:
		ret

SpeedMax:
		ldi		mpr, $ff
		out		OCR2, mpr
		out		OCR0, mpr
		ldi		speed, 15
		ldi mpr, 0b01100000
		add mpr, speed
		OUT PORTB, mpr		
		ret

SpeedMin:
		ldi		mpr, $00
		out		OCR2, mpr
		out		OCR0, mpr
		ldi		speed, 0
		ldi mpr, 0b01100000
		OUT PORTB, mpr
		ret

;-----------------------------------------------------------
;	You will probably want several functions, one to handle the 
;	left whisker interrupt, one to handle the right whisker 
;	interrupt, and maybe a wait function
;------------------------------------------------------------

;-----------------------------------------------------------
; Func: Template function header
; Desc: Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------


;***********************************************************
;*	Stored Program Data
;***********************************************************

; Enter any stored data you might need here

;***********************************************************
;*	Additional Program Includes
;***********************************************************
; There are no additional file includes for this program