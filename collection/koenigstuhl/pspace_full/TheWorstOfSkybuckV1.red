;redcode
;name TheWorstOfSkybuckV1
;author Skybuck Flying
;assert 1
;strategy Most of my crappy warriors united into one.
;strategy Uses a strategy switcher.
;version 1
;date 30 january 2008
;comments Let's make a warrior where all my crappy warriors are united :)
;comments and use a strategy switcher to see if it can work against some other warriors ;)

DestroyerBegin

StrategyPSpaceLocation	equ 10
Strategies		equ 8

; load previous round results
PreviousRoundResult	ldp.ab	#0, $0

; load strategy value since we have to execute it possibly.
LoadStrategyValue	ldp.a #StrategyPSpaceLocation, $StrategyValue

; if previous round result is zero (=lost) then skip over jump to strategy table so that first
; the strategy is changed/incremented.
; if it is not zero then don't skip the jump, and thus jump to strategy table.
seq.ab $0, $PreviousRoundResult
jmp.a $StrategyTable

; increment the strategy value
add.a #1, $StrategyValue

; mod the strategy value to max strategies
mod.a #Strategies, $StrategyValue

; store the strategy value back into space
stp.ab $StrategyValue, #StrategyPSpaceLocation

StrategyTable
	add.a #1, $StrategyValue
StrategyValue 
	jmp.a $0, $0
StrategyJumps
	jmp.a Strategy0
	jmp.a Strategy1
	jmp.a Strategy2
	jmp.a Strategy3
	jmp.a Strategy5
	jmp.a Strategy6
	jmp.a Strategy7

Strategy0
	; strategy zero of recycled bits is the scanner, 
	; the best counter strategy I have for now seems to be the MiniShootingStarV2

	MiniShootingStarBegin

		Target equ 131

		spl $1
		mov -1, 0
		SourceDest nop $0, Target
		mov }SourceDest, >SourceDest
		jmp Target-2

	MiniShootingStarEnd

Strategy1
	DivideAndConquerLength equ (DivideAndConquerEnd-DivideAndConquerBegin)

	; strategy one of recycled bits is the paper
	; which copies itself, the best counter attack I have for now is the divide and conquer v2 quicker
	; it ties with it 99% to 100%
	DivideAndConquerBegin


		Initialization

		Copy
			mov }Source, >Dest
		Loop	djn Copy, #DivideAndConquerLength 
			sub #(DivideAndConquerLength -(SpawnHere-DivideAndConquerBegin)), $Dest
			spl @Dest
		SpawnHere
			mov.ab #DivideAndConquerLength, $Loop
			mov.a #(DivideAndConquerBegin-Source), $Source
			div #2, $Dest
			djn Copy, #8
			mov $0, $1
		Source
		Dest
			dat #DivideAndConquerBegin, #(CORESIZE / 2) - (DivideAndConquerLength / 2)

	DivideAndConquerEnd

Strategy2
	; strategy two of recycled bits is the Once
	; a simply imp will take care of it
	ImpBegin
		mov 0, 1
	ImpEnd

Strategy3

ParasiteBegin

	slt counter, #-(ParasiteEnd-1)
	jmp ParasiteSkip

	slt #-(ParasiteBegin+2), counter
	jmp ParasiteSkip

	jmz.f ParasiteSkip, @counter; skips instructions like spl 0,0 and mov 0,0 and jmp 0,0
action

	spl @counter ; executes all others like a parasite.
;	nop  0; give it a chance to run  ; bomb disabled
;	mov bomb, @counter ; bomb it
ParasiteSkip
	add #2891, counter
jmp ParasiteBegin

counter dat #0-(2891*2209)
;bomb dat $0, $0

ParasiteEnd


Strategy4
	;strategy four of recycled bits is the Stone
	;it's some kind of bomber mostly
	;my multiply and conquer defeat it 66% of the time ;) :)
	
	MultiplyAndConquerLength equ (MultiplyAndConquerEnd - MultiplyAndConquerBegin)

	MultiplyAndConquerSourceReset equ (MultiplyAndConquerBegin - MultiplyAndConquerSource)
	MultiplyAndConquerDestReset equ (MultiplyAndConquerEnd - MultiplyAndConquerDest)
	
	MultiplyAndConquerBegin


		MultiplyAndConquerInitialization

		MultiplyAndConquerCopy
			mov }MultiplyAndConquerSource, >MultiplyAndConquerDest
		MultiplyAndConquerLoop	
			djn MultiplyAndConquerCopy, #MultiplyAndConquerLength
		MultiplyAndConquerSpawn
		;	nop $0, $0	; filling for nicer pattern
			sub.ab #(MultiplyAndConquerLength-(MultiplyAndConquerSpawnHere-MultiplyAndConquerBegin)), $MultiplyAndConquerDest
			spl @MultiplyAndConquerDest
			add.ab #(MultiplyAndConquerLength-(MultiplyAndConquerSpawnHere-MultiplyAndConquerBegin)), $MultiplyAndConquerDest
		;	nop $0, $0	; filling for nicer pattern

		MultiplyAndConquerSpawnHere

		MultiplyAndConquerResetLoopCounter
			mov.ab #MultiplyAndConquerLength, $MultiplyAndConquerLoop

		MultiplyAndConquerResetSource
		MultiplyAndConquerResetDest
			mov $MultiplyAndConquerResetter, $MultiplyAndConquerSource
		; Dest := Dest + ( ( L * 2 ) - L );
		MultiplyAndConquerMultipleIncrementation
			mul.ab #2, $MultiplyAndConquerIncrementation

		MultiplyAndConquerAddIncrementation	
			add.b $MultiplyAndConquerIncrementation, $MultiplyAndConquerDest
			sub.ab #MultiplyAndConquerLength, $MultiplyAndConquerDest

		MultiplyAndConquerReloop
		; further extensions could be made here after core conquer
		;	djn Copy, #9
		;	mov 0, 1

		MultiplyAndConquerIncrementation
			jmp MultiplyAndConquerCopy, #MultiplyAndConquerLength

		MultiplyAndConquerSource
		MultiplyAndConquerDest
			dat #MultiplyAndConquerBegin, #MultiplyAndConquerEnd

		MultiplyAndConquerResetter
			dat #MultiplyAndConquerSourceReset, #MultiplyAndConquerDestReset

		;Incrementation
		;	dat $0, #WarriorLength

	MultiplyAndConquerEnd

Strategy5


NastyBomberBegin
	check
							; stealth pattern: scan

	slt #NastyBomberBegin, bomb_counter			; stealth pattern: skip
	jmp skip					; stealth pattern: skip

	nop $0, $0					; stealth pattern: scan
	
	slt bomb_counter, #(8000-(NastyBomberEnd+1))	; stealth pattern: skip
	jmp skip					; stealth pattern: skip
	jmp skipskip					; stealth pattern: skip

	bombit

	nop $0, $0					; stealth pattern: scan

	skipskip mov bomb, @bomb_counter		; stealth pattern: skip

	skip

	add #2891, bomb_counter				; stealth pattern: skip

	jmp check					; stealth pattern: skip

	bomb dat $0, $0					; stealth pattern: scan
	bomb_counter dat #NastyBomberEnd, #NastyBomberEnd	; stealth pattern: skip
NastyBomberEnd

Strategy6

SuperWarriorLength equ SuperWarriorEnd-SuperWarriorStart

SuperWarriorBombingLength			equ	(CORESIZE-(SuperWarriorLength+WARRIORS))
SuperWarriorBombingStartingLocation		equ	SuperWarriorEnd

; the jump bomber is slower then the kill bomber
; set it a bit further ahead but be carefull not to fuck yourself up the ass so make sure to subtract
; the jumpbombingstartinglocation from the bombinglength as to not fuckyourself up the ass later on ;) :):):)
SuperWarriorJumpBombingLength		equ	CORESIZE-(SuperWarriorLength + SuperWarriorJumpBombingStartingLocation)
SuperWarriorJumpBombingStartingLocation	equ	CORESIZE/2

; perform full core jump insertion after initial half looping
SuperWarriorJumpBombingLengthOnReset			equ CORESIZE-SuperWarriorLength
SuperWarriorJumpBombingStartingLocationOnReset	equ SuperWarriorEnd	

SuperWarriorStart

; jump to JumpBomber to try and hook enemy SuperWarriors and let them clear the fricking core ;)
jmp JumpBomberBegin	

	KillOffInstances dat #0, #0	; bomb to kill off enemy instances which jump to here.

JumpBomberEndPoint 	; captured SuperWarrior instances will start executing at the line below the first time, 
		  	; or above if it's a second SuperWarrior instance and those will be killed off for maximum speed
			; the idea is to let only one enemy SuperWarrior instance enter for maximum bombing speed/time steal.
			; so the moral of the story: enemy SuperWarriors will clear the core for us ! yeah !

BomberBegin

	BomberLooping
		spl 1	; extra instruction too also stun motherfuckers ;) :) and steal more time :)
		mov BomberBomb, >BomberDualCounter
		djn.a BomberLooping, BomberDualCounter

	BomberReset

		; when loop is done, and the core has been cleared, reset the bomber to prepare for another core clear.
		mov.a #SuperWarriorBombingLength, BomberDualCounter
		mov.ab #SuperWarriorBombingStartingLocation, BomberDualCounter	; little bit strange, copies 14, instead of 12, minor problem ;)

	BomberRepeatCoreClear

		; keep clearing the core endlessly. Don't do that for now.. let SuperWarriors die at the end of the bombing run, any new capture SuperWarriors will start new bombing run.
		; mostly work around because max cycles is modded to coresize and thus can't be determined correctly for max cycles larger then core size
		; so this disabled jmp functions as an end game kind of mechanism ;)
		; jmp BomberBegin		; could be disabled to mimic end mode, yes let's do that now that stun has been included into bomber.

	BomberData
		BomberDualCounter	dat #SuperWarriorBombingLength, #SuperWarriorBombingStartingLocation ; dual-counter: A-field = bombing length, B-field = bombing location.
		BomberBomb		dat #0, #0	

BomberEnd

JumpBomberBegin

	JumpBomberLoopBegin

		JumpBomberCalculateJumpInsertionInstructionParameters

			; clear/zero a-field of jump insertion instruction.
			mov.a #0, JumpBomberInsertion

			; subtract JumpInsertionCounter.b from JumpInsertion.a instruction (makes the jump point back to jump insertion counter)
			sub.ba JumpBomberInsertionCounter, JumpBomberInsertion

			; jump back must not be towards jump instruction counter but to jump end point
			; so add the JumpEndpoint to JumpInsertion.A, and compensate/subtract JumpInsertionCounter offset to get an spot-on/exact location
			add.a #(JumpBomberEndPoint-JumpBomberInsertionCounter), JumpBomberInsertion


		JumpBomberInsertJump			
			mov JumpBomberInsertion, >JumpBomberInsertionCounter

		JumpBomberRepeatLoop
			djn.a JumpBomberBegin, JumpBomberInsertionCounter

		JumpBomberReset
			mov.a #SuperWarriorJumpBombingLengthOnReset, JumpBomberInsertionCounter	; dual counter: A-field = bomber length, B-field = bombing location. 
			mov.ab #SuperWarriorJumpBombingStartingLocationOnReset, JumpBomberInsertionCounter
		
		JumpBomberRepeatCoreInsertion
			; keep inserting jump instructions into the core
			jmp JumpBomberLoopBegin

	JumpBomberLoopEnd

		JumpBomberData

			JumpBomberInsertionCounter dat #SuperWarriorJumpBombingLength, SuperWarriorJumpBombingStartingLocation

		JumpBomberSelfModifieingJumpInsertion

;			JumpBomberInsertion jmp 0, {0

			; variation do not kill of enemy SuperWarrior instances:
			JumpBomberInsertion jmp 0, 0

JumpBomberEnd

SuperWarriorEnd

Strategy7

spl protectleft1
spl protectright1

MiniProtectorV4Length equ MiniProtectorV4End - MiniProtectorV4Begin
BombingLength equ ((CORESIZE - (MiniProtectorV4Length + right)) / 3) + 5; because there are 3 warriors incrementing/decrementing per direction :)

MiniProtectorV4Begin

left dat #-1

protectleft1
mov MiniProtectorV4bomb, <left
protectleft1loop djn protectleft1, #BombingLength
mov.ab #-1, left			; reset bombing position
mov.ab #BombingLength, protectleft1loop ; reset bombing length
jmp protectleft1

MiniProtectorV4bomb dat #0

protectright1
mov MiniProtectorV4bomb, >right
protectright1loop djn protectright1, #BombingLength
mov.ab #1, right				; reset bombing position
mov.ab #BombingLength, protectright1loop	; reset bombing length
jmp protectright1

right dat #1

MiniProtectorV4End


DestroyerEnd
	
End
