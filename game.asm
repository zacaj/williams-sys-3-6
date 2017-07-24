; Laser Ball solenoids
;#DEFINE KICKOUT 		01
;#DEFINE LEFT_KICKER 	02
;#DEFINE DROP_LA			03
;#DEFINE DROP_SER		04
;#DEFINE EJECT_HOLE		05
;#DEFINE DROP_BA			06
;#DEFINE DROP_LL			07
;#DEFINE RIGHT_KICKER	08
;#DEFINE SOUND1			09 ; thru 13
;#DEFINE KNOCKER			14
;#DEFINE	FLASHERS		15
;#DEFINE COIN_LOCKOUT	16

; Hot Tip solenoids
#DEFINE TOP_EJECT 	01
#DEFINE DROP_TIP	02
#DEFINE DROP_HOT	03
#DEFINE LEFT_EJECT	04
#DEFINE OUTHOLE		05
#DEFINE CHIME_10	09
#DEFINE CHIME_100	10
#DEFINE CHIME_1000	11
#DEFINE CHIME_10k	12
#DEFINE CLICKER		13
#DEFINE	KNOCKER		14
#DEFINE BUZZER		15

#DEFINE done jmp afterQueueEvent
#DEFINE noValidate ldaA 10b\ oraA >state\ staA state
; switch callbacks:

none:	.org $7800 + $500 + 256 ; size of callback table
	done
	
startGame:
	lampOff(6,8) ; game over
	enablePf
	
	fireSolenoid(2)
	fireSolenoid(3)
	
	; clear lights
	ldX	lampCol1
	ldaA	0b
lClearLights:
	staA	0, X
	staA	flashLampCol1 - lampCol1, X
	inX
	cpX	lampCol8 + 1
	bne	lClearLights
	;
	
	; reset scores
	jsr 	resetScores
	
	; reset ball count
	ldaA	$10
	staA	ballCount

	ldaB	0
	staB	curPlayer + 1
	
	; invalidate playfield
	ldaA	lr(1)
	oraA	>flc(8)
	staA	flc(8)
	oraA	>lc(8)
	staA	lc(8)
	
	lampOn(2,7) ; one player
	
	ldaA	sr(1) ; check outhole
	bitA	>sc(2)
	ifne ; ball in hole
		fireSolenoid(5)
	endif
	
	rts
	
	

sw32:
	done
	
addP2_10:
	;ldX		#pB_10
	;ldaA	#9
	;jmp 	addScore
	delay(1000)
	addScore(1,9)
	done
	
swTilt: noValidate
	lampOn(5,8) ; tilt
	disablePf
	done
	
swStart: noValidate
	ldaA >lc(8)
	bitA lr(6)
	ifne ; in game over
		jsr startGame
	else 
		ldaA	$10
		cmpA	>ballCount
		ifeq ; add player
			ldaA	00011110b
			andA	>lc(7) ; player count lights
			bitA	lr(5)
			ifeq	; if not on P4 already, add player
				aslA
				ldaB	11100001b
				andB	>lc(7)
				staB	lc(7)
				oraA	>lc(7)
				staA	lc(7)
			endif
		else ; restart game
			jsr startGame
		endif		
	endif
	
	done
	
swOuthole: noValidate
	ldaA	>lc(8) ; !game over
	bitA	lr(6)
	ifeq ; !game over
		ldaA	00001111b ; player up lights
		bitA	>flc(8)	; check if any player is flashing
		ifne ; any flashing -> playfield invalid
			lampOff(5,8) ; tilt
			
			enablePf
			fireSolenoid(OUTHOLE)
		else ; none flashing -> playfield valid -> end ball
			andA	>lc(8)
			ldaB	>lc(3)
			bitB	lr(1)
			ifeq ; shoot again not lit
				; go to next player
				aslA
				inc	curPlayer + 1
				bitA	>lc(7)	; is player count < player #
				ifne ; last player
					ldaA	00000001b; ; back to player 1
					ldaB	0
					staB	curPlayer + 1
					
					; increase ball count
					ldaB	>ballCount
					addB	$10
					cmpB	$40
					ifeq ; game over
						lampOn(6,8)
						disablePf
						done
					else
						staB	ballCount
					endif		
				endif
				
				staA	lc(8)
			endif
			
			; flash player light
			ldaA	00001111b ; player up lights
			oraA	>flc(8)
			staA	flc(8)
			
			
			enablePf
			
			fireSolenoid(OUTHOLE)
		endif
	endif		
	done
	
swEjectHole:
	;fireSolenoid(EJECT_HOLE)
	done
	
swLeftEject:
	ldaA	>lc(8)
	bitA	lr(6)
	ifeq ; in game
		lampOn(1,3)
		lampOn(7,8)
	endif
	fireSolenoid(LEFT_EJECT)
	done
	
swTopEject:
	fireSolenoid(TOP_EJECT)
	done
	
swRKicker:
	;fireSolenoid(RIGHT_KICKER)
	done
swHotTip:
	delay(400)
	fireSolenoid(DROP_HOT)
	fireSolenoid(DROP_TIP)
	done
	
; end callbacks
	.msfirst
; needs to be on $**00 address
callbackTable: 	.org $7800 + $500 ; note: TRANSPOSED
	.dw swTilt		\.dw swTilt		\.dw swStart	\.dw none\.dw none\.dw none\.dw swTilt\.dw none
	.dw swOuthole	\.dw swTilt	\.dw sw32		\.dw none\.dw none\.dw none\.dw none\.dw none
	.dw none		\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none
	.dw none		\.dw none\.dw none\.dw addP2_10\.dw swLeftEject\.dw none\.dw none\.dw swEjectHole
	.dw none		\.dw none\.dw none\.dw none\.dw swHotTip\.dw none\.dw none\.dw none
	.dw swRKicker	\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none
	.dw none		\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none
	.dw none		\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none
; on = how many cycles it must be on for before registering (1 cycle = 64ms (?)) (max 7)
; off = how many cycles it must be off for
; onOnly = if true, don't notify of an off event (also set off = 0 for efficiency)
; gameover = whether the switch is active in gameover or tilt mode (these callbacks must check whether in game over when triggered if they want to act different)
#define SW(on,off,onOnly,gameover) .db (onOnly<<7)|(gameover<<6)|(on<<3)|(off) 
settleTable: ; must be right after callbackTable
	SW(0,7,1,0)\SW(0,7,1,0)\SW(1,2,1,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,1,0)\SW(0,7,0,1)
	SW(7,7,1,1)\SW(0,7,1,0)\SW(7,0,1,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(7,7,1,1)\SW(7,7,1,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(7,7,1,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(7,7,1,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)