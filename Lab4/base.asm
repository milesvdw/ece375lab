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
		; Move strings from Program Memory to Data Memory
		
		ldi r24, $1F
		ldi ZH,high(2*STRING1)
		ldi ZL,low(2*STRING1)
		ldi YL, low(LCDLn1Addr)
		ldi YH, high(LCDLn1Addr)
		preplcd1:
			lpm mpr, Z+
			st Y+, mpr
			dec r24
			brne preplcd1

		ldi r24, $0F
		ldi ZH,high(2*STRING2)
		ldi ZL,low(2*STRING2)
		ldi YL, low(LCDLn2Addr)
		ldi YH, high(LCDLn2Addr)
		preplcd2:
			lpm mpr, Z+
			st Y+, mpr
			dec r24
			brne preplcd2
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

		rcall LCDWrite
		rjmp	MAIN			; jump back to main and create an infinite
								; while loop.  Generally, every main program is an
								; infinite while loop, never let the main program
								; just run off

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: Template function header
; Desc: Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------
FUNC:							; Begin a function with a label
		; Save variables by pushing them to the stack

		; Execute the function here
		
		; Restore variables by popping them from the stack,
		; in reverse order

		ret						; End a function with RET

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
