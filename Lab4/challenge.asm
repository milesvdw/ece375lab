;***********************************************************
;*
;*	Lab4
;*
;*	Print on LCD
;*
;*	This is the file for Lab 4 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Mathew
;*	   Date: 10/16
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register is
								; required for LCD Driver
								
.def	ilcnt = r18				; Inner Loop Counter
.def	olcnt = r19				; Outer Loop Counter
								

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp INIT				; Reset interrupt

.org	$0046					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:							; The initialization routine
		; Initialize Stack Pointer
		ldi r16, high(RAMEND)
		out SPH, r16
		ldi r16, low(RAMEND)
		out SPL, r16
		; Initialize LCD Display
		rcall LCDInit

		; NOTE that there is no RET or RJMP from INIT, this
		; is because the next instruction executed is the
		; first instruction of the main program

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:							; The Main program
		; Display the strings on the LCD Display
;		ld Z, mpr
;		ldi mpr, LCDLn1Addr
;		ld Y, mpr
;		ldi r24, 16

		ldi r23, $00 ;offset counter
		ldi r22, $00 ;empty register for adc
		marquis:
			; Move strings from Program Memory to Data Memory
			mov r21, r23
			ldi r24, $20
			ldi ZH,high(2*STRING1)
			ldi ZL,low(2*STRING1)
			ldi YL, low(LCDLn1Addr)
			ldi YH, high(LCDLn1Addr)
			add YL, r23 ;add in the offset
			adc YH, r22

			preplcd:
				lpm mpr, Z+
				st Y+, mpr
				inc r21
				
				cpi r21, 32
				breq RESETY
				resetreturn:

				dec r24

				brne preplcd

			push r21
			push r22
			push r23

			rcall LCDWrite

			ldi mpr, 100
			rcall WaitLp
			
			pop r23
			pop r22
			pop r21

			inc r23
			cpi r23, 32
			breq resetOffset
			marquisContinue:
			rjmp marquis

		rjmp	MAIN			; jump back to main and create an infinite
								; while loop.  Generally, every main program is an
								; infinite while loop, never let the main program
								; just run off

resetOffset:
	ldi r23, $00
	rjmp marquisContinue

RESETY:	
	ldi YL, low(LCDLn1Addr)
	ldi YH, high(LCDLn1Addr)
	clr r21
	rjmp resetreturn


WaitLp:
	push	mpr			; Save wait register
	push	ilcnt			; Save ilcnt register
	push	olcnt			; Save olcnt register

Loop:	ldi		olcnt, 224		; load olcnt register
OLoop:	ldi		ilcnt, 237		; load ilcnt register
ILoop:	dec		ilcnt			; decrement ilcnt
	brne	ILoop			; Continue Inner Loop
	dec		olcnt		; decrement olcnt
	brne	OLoop			; Continue Outer Loop
	dec		mpr		; Decrement wait 
	brne	Loop			; Continue Wait loop	

	pop		olcnt		; Restore olcnt register
	pop		ilcnt		; Restore ilcnt register
	pop		mpr		; Restore wait register
	ret				; Return from subroutine


;***********************************************************
;*	Stored Program Data
;***********************************************************

;-----------------------------------------------------------
; An example of storing a string. Note the labels before and
; after the .DB directive; these can help to access the data
;-----------------------------------------------------------
STRING_BEG:
.DB		"My Test String"		; Declaring data in ProgMem
STRING_END:
STRING1:
	.DB "MATHEW          "
STRING2:
	.DB "HELLO WORLD     "

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver
