#include "680xlogic.asm"

displayStrobe: 	.equ $2800
displayBcd: 	.equ $2802
displayStrobeC:	.equ $2801
displayBcdC:	.equ $2803
lampRow:		.equ $2400
lampRowC:		.equ $2401
lampStrobe:		.equ $2402
lampStrobeC:	.equ $2403
switchStrobe:	.equ $3002
switchStrobeC:	.equ $3003
switchRow:		.equ $3000
switchRowC:		.equ $3001
solenoidA:		.equ $2200
solenoidAC		.equ $2201
solenoidB:		.equ $2202
solenoidBC:		.equ $2203

RAM:			.equ $0000
cRAM:			.equ $0100
temp:			.equ RAM + $00
counter:		.equ RAM + $02
counter2:		.equ RAM + $03
strobe:			.equ RAM + $07
lampRow1:		.equ RAM + $08
lampRow8:		.equ lampRow1 + 7 
displayBcd1:	.equ RAM + $10
displayBcd16:	.equ RAM + $1F
switchRow1:		.equ RAM + $20
switchRow8:		.equ switchRow1 + 7 
solAStatus:		.equ RAM + $28
solBStatus:		.equ RAM + $29
curCol:			.equ RAM + $50
curSwitchRowLsb	.equ RAM + $52
tempX:			.equ RAM + $53
tempQ:			.equ RAM + $54 ; 55

queue:			.equ RAM + $60	; closed | switch? | number#6
queueLast:		.equ RAM + $6F

settleRow1:		.equ cRAM + $00
settleRow8:		.equ settleRow1+  8*8-1
solenoid1:		.equ cRAM + $40
solenoid8:		.equ solenoid1 + 7
solenoid9:		.equ solenoid1 + 8
solenoid16:		.equ solenoid1 + 15
pA_10:			.equ cRAM + $50
pA_1m:			.equ pA_10 + 5
pB_10:			.equ pA_1m + 1
pB_1m:			.equ pB_10 + 5
pC_10:			.equ pB_1m + 1
pC_1m:			.equ pC_10 + 5
pD_10:			.equ pC_1m + 1
pD_1m:			.equ pD_10 + 5  
displayCol:		.equ cRAM + $68
state:			.equ cRAM + $69	; gameover | ? | ? | ?
queueStart:		.equ cRAM + $70
queueEnd:		.equ cRAM + $71

instant:		.equ 4
debounce:		.equ 1
slow:			.equ 2

switchSettle:	.equ cRAM + $30
; through $7F ?

none:	.org $6000 + 256
	rts
	
	.msfirst
callbackTable: 	.org $6000
	.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none
	.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none
	.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none
	.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none
	.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none
	.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none
	.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none
	.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none
; on = how many cycles it must be on for before registering (1 cycle = 16ms (?)) (max 7)
; off = how many cycles it must be off for
; onOnly = if true, don't notify of an off event (also set off = 0 for efficiency)
; gameover = whether the switch is active in gameover mode (these callbacks must check whether in game over when triggered)
#define SW(on,off,onOnly,gameover) .db (gameover<<7)(onOnly<<6)|(on<<3)|(off) 
settleTable: ; must be right after callbackTable
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	
main:		.org $7800
	
	ldaA 	#0
	staA	temp
	ldaA	#$FF
	staA	temp + 1
	ldS		temp

test:
	
piaSetup:
	ldaA	#00000000b	;select direction (3rd bit = 0)
	staA 	displayStrobeC
	ldaA 	#00111111b	;set LED pins to outputs
	staA 	displayStrobe
	ldaA 	#00000100b 	;select data (3rb bit = 1)
	staA 	displayStrobeC
	
	ldaA	#00000000b	;select direction (3rd bit = 0)
	staA 	displayBcdC
	ldaA 	#11111111b	;set display BCD to output
	staA 	displayBcd
	ldaA 	#00000100b 	;select data (3rb bit = 1)
	staA 	displayBcdC
	
	ldaA	#00000000b	;select direction (3rd bit = 0)
	staA 	lampRowC
	ldaA 	#11111111b	;set to output
	staA 	lampRow
	ldaA 	#00000100b 	;select data (3rb bit = 1)
	staA 	lampRowC
	
	ldaA	#00000000b	;select direction (3rd bit = 0)
	staA 	lampStrobeC
	ldaA 	#11111111b	;set to output
	staA 	lampStrobe
	ldaA 	#00000100b 	;select data (3rb bit = 1)
	staA 	lampStrobeC
	
	ldaA	#00000000b	;select direction (3rd bit = 0)
	staA 	switchStrobeC
	ldaA 	#11111111b	;set to output
	staA 	switchStrobe
	ldaA 	#00000100b 	;select data (3rb bit = 1)
	staA 	switchStrobeC
	
	ldaA	#00000000b	;select direction (3rd bit = 0)
	staA 	switchRowC
	ldaA 	#00000000b	;set to input
	staA 	switchRow
	ldaA 	#00000100b 	;select data (3rb bit = 1)
	staA 	switchRowC
	
	ldaA	#00000000b	;select direction (3rd bit = 0)
	staA 	solenoidAC
	staA	solenoidBC
	ldaA 	#11111111b	;set to output
	staA 	solenoidA
	staA 	solenoidB
	ldaA 	#00000100b 	;select data (3rb bit = 1)
	staA 	solenoidAC
	staA 	solenoidBC
	
;

	ldaA	#00
	staB	displayBcd1
	
	ldaA	#$FF	
	staA 	displayStrobe

	ldaA	#00
	staA	strobe
	staA	displayCol
	
	ldX 	#0
	stX		curCol
	
	ldaA	#0
	staA	curSwitchRowLsb
	
; fill solenoid status with off
	ldaA	#$FF
	ldX		#solenoid1
lSolDefault:
	staA	0, X
	inX
	cpX		#solenoid16
	ble		lSolDefault
	
; empty settle
	ldaA	#$00
	ldX		#settleRow1
lSettleDefault:
	staA		0, X
	inX
	cpX		#settleRow8 + 7
	ble		lSettleDefault
	
; empty queue
	ldaA	#$FF
	ldX		#queue
lEmptyQueue:
	staA		0, X
	inX
	cpX		#queueLast
	ble		lEmptyQueue
	
	ldaA	#0
	staA	queueStart
	staA	queueEnd
	
; test numbers
	ldX		#displayBcd1 + 1
	ldaA	#0
lTestNumbers:
	staA	0, X
	inX
	incA
	andA	#00000111b
	cpX		#displayBcd16
	ble		lTestNumbers
	
	
; setup complete
	clI		; enable timer interrupt
	
	
end:
	ldaA	#00001111b
	andA	queueStart
	
	
				ldaA	#1000b	; gameover
				bitA	state
				ifne	; in gameover
					ldaA #10000000b; 
					bitA
				endif
				
skipSwitch:
				
	
				
	jmp		end
	.dw 0
	.dw 0
	.dw 0
	.dw 0
	.dw 0
		
interrupt:	
	inc		counter
	ldaA	#0
	cmpA	counter
	bne		counterHandled
	inc 	counter2
	ldaA	#4
	cmpA	counter2
	bne		counterHandled
	
	ldaA	#0
	staA	counter2
	ldaA	#01110111b
	cmpA	displayBcd1
	beq		on
	
	ldaA	#$F0
	staA	lampRow1
	ldaA	#01110111b
	staA	displayBcd1	
	bra		counterHandled
on:
	ldaA	#$0F
	staA	lampRow1
	ldaA	#00110011b
	staA	displayBcd1	

counterHandled:
; move switch column
	ldaA	strobe
	staA	switchStrobe
	
; update display 
	ldX		curCol
	ldaA	displayCol
	ldaB 	#$FF
	staB	displayBcd
	staA	displayStrobe
	bitA	#00001000b
	ifeq
		ldaB	displayBcd1, X
	else
		ldaB	displayBcd1 + 8, X
	endif
	staB	displayBcd
	
; read switches
	ldX		curCol
	ldaA	switchRow
	tab
	eorA	switchRow1, X ; A contains any switches that have changed state
	
	ldaB	curSwitchRowLsb 	;	B now contains LSB of callbackTable row addr
	staB	temp + 1 			; temp = switch / 2
	staB	tempX + 1			; tempX = cRAM
	ldaB	#callbackTable >> 8
	staB	temp
	ldaB	#cRAM >> 8
	staB	tempX
	
	ldaB	#00000001b ; B is the bit of the current switch in row
	
	; temp now contains the beginning of the row in the callbackTable
swNext:
	bitA	#00000001b	 ; Z set if switch not different
	ifne		; if bit set, switch different
		pshA ; store changed switches left
		ldX		tempX
		ldaA	0, X ; A now how long the switch has left to settle
		andA	#00001111b ; need to remove upper F ( sets Z if A = 0)
		ifne 	; A>0 -> settling
			decA
			staA	0, X	; sets Z if now A = 0
			ifeq ; A=0 -> now settled, fire event
settled:		
				ldX		curCol
				tBA	; A now the bit in row
				eorA	switchRow1, X ; toggle bit in row
				staA	switchRow1, X ; A now state of row
				
				
				
				; todo somehow actually fire it here
				;asl		temp + 1
				;ldX		temp	
				;ldX		0, X
				;jsr		0, X
			endif
		else ; =0 -> was settled, so now it's not
			; get the settle time
			ldaA	tempX + 1
			staA	temp + 1 	; get temp in sync with tempX LSB
			ldX		temp
			
			; temp contains half the address of the callback, so add diff between settleTable and callbackTable
			ldaA	settleTable - callbackTable, X ; A has settle settings
			
			; need to get correct 3 bits from switch settings
			bitB	switchRow
			ifne ; switch just turned on
				lsrA
				lsrA
			else
				aslA
			endif
			andA	#1110b ; A now has 3 bit settle time * 2
						
			ldX		tempX
			staA	0, X		; start settling	
			beq		settled		; quick out for 0 settle
		endif
			
		pulA
	endif
	inc tempX + 1
	aslB
	lsrA			; pop lowest bit off, set Z if A is empty
	bne		swNext 	; more 'switched' bits, keep processing 
	
	
; update lamps
	ldX		curCol
	ldaA	#$FF	;lamp row is inverted
	staA	lampRow
	ldaA	strobe
	staA	lampStrobe
	ldaA	switchRow1, X
	staA	lampRow
	ldaA	#00

; update solenoids
	; if a solenoid is set to <254, --
	; if =255, off, otherwise on
	; leave it at 254
	
	inc		curCol	; indexed can't use base >255, so temp inc X by 255 (1 MSB)
	ldaA	#254
	ldX		curCol
	ldaB	solenoid1 - cRAM, X
	cmpA	solenoid1 - cRAM, X
	ifge 	; solenoid <=254, turn on
		ifgt	; solenoid < 254, decrement
			dec		solenoid1 - cRAM, X
		endif
		sec
	else
		clc
	endif
	ror		solAStatus
	cmpA	solenoid9 - cRAM, X
	ifge 	; solenoid <=254, turn on
		ifgt	; solenoid < 254, decrement
			dec		solenoid9 - cRAM, X
		endif
		sec
	else
		clc
	endif
	ror		solBStatus
	dec		curCol
	
; update strobe	
	ldX		curCol
	inX 	
	ldaA	#8 	; pitch
	addA	curSwitchRowLsb
	staA	curSwitchRowLsb
	asl		strobe
	inc		displayCol
	ldaA	#0
	cmpA	strobe ; strobe done?  reset
	ifeq		
		ldaA	solAStatus
		staA	solenoidA
		ldaA	solBStatus
		staA	solenoidB
	
		ldaA	#00000001b
		staA	strobe
		
		ldX 	#0
		
		ldaA	#0
		staA	curSwitchRowLsb
		staA	solAStatus
		staA	solBStatus
		
		ldaB	displayCol	; reset display col only if it's > 7 
		cmpB	#$F8	; since it needs to count to 15 instead of 7
		ifgt
			staA	displayCol
		endif
	endif
	
	stX		curCol
	rti

pointers: 	.org $7FF8  	
	.msfirst
	.dw interrupt			
	.dw interrupt			
	.dw interrupt			
	.dw main
	
	
	.end