#include "ti86.inc"
;.plugin lite86
.org _asm_exec_ram
 call _clrLCD
 call _runindicoff
 call _flushallmenus
 ld a,1
 ld (Select),a
 ld bc,256*51+90
 ld (_penCol),bc
 ld hl,PointsText
 call _vputs
 ld bc,256*51+45
 ld (_penCol),bc
 call _vputs
 push hl
 ld hl,(Record)
 call DispHL
 ld bc,256*58+45
 ld (_penCol),bc
 pop hl
 call _vputs
 ld hl,(Num300Games)
 call DispHL
 ld hl,256*58+97
 ld (_penCol),hl
 ld hl,Pelit300Text+4
 call _vputs
 ld hl,(Games)
 call DispHL
 ld hl,Points
 ld (hl),-1
 ld de,Points+1
 ld bc,15
 ldir
 ld hl,Locks
 ld de,Locks+1
 ld bc,12
 ld (hl),0
 ldir
 ld bc,1
 ld (_penCol),bc
 xor a
DispNumbersLoop:
 inc a
 push af
 call DispA
 call vnewline
 pop af
 cp 6
 jr nz,DispNumbersLoop
 ld hl,Texts
 ld b,4
TextLoop1:
 call _vputs
 call vnewline
 djnz TextLoop1
 xor a
 ld (_penRow),a
 ld b,6
TextLoop2:
 ld a,49
 ld (_penCol),a
 call _vputs
 call NewRow
 djnz TextLoop2
GameLoop:
 ld hl,Points
 ld b,10
 ld de,34
PointsShowStart:
 ld (_penCol),de
 ld a,e
 ld (Column),a
PointsLoop:
 push bc
 ld a,(hl)
 cp -1
 jr z,DontShow
 push hl
 call DispA
 pop hl
DontShow:
Column =$+1
 ld a,34
 ld (_penCol),a
 call NewRow
 inc hl
 pop bc
 djnz PointsLoop
 ld de,82
;2nd column
 ld a,(Column)
 cp e
 ld b,6
 jr nz,PointsShowStart
 ld a,(GamePointer)
 cp 15
 jr nz,RandomizeDice
 ld hl,(Games)
 inc hl
 ld (Games),hl
 ld hl,(TotalPoints)
 ld de,(Record)
 call _cphlde
 jr c,NoHighScore
 ld (Record),hl
NoHighScore:
 ld de,300
 call _cphlde
 jr c,Wait
 ld hl,(Num300Games)
 inc hl
 ld (Num300Games),hl
Wait:
 halt
 call _getky
 or a
 jr z,Wait
SaveGame:
 ld hl,_asapvar
 rst 20h
 rst 10h
 ld a,b
 ld hl,SaveGameData-_asm_exec_ram+4
 add hl,de
 adc a,0
 call _set_abs_dest_addr
 xor a
 ld hl,SaveGameData
 call _set_abs_src_addr
 ld hl,SaveGameDataEnd-SaveGameData
 call _set_mm_num_bytes
 call _mm_ldir
Quit:
 call _clrScrn
 jp _homeup
RandomizeDice:
 ld b,5
 ld hl,Dice-1
 ld de,Locks-1
RandomLoop:
 push bc
 inc hl
 inc de
 ld a,(de)
 or a
 jr nz,SkipDie
 push hl
 push de
 call RandLFSR
 pop de
 pop hl
 inc a
 ld (hl),a
SkipDie:
 pop bc
 djnz RandomLoop
 ld bc,38*256+49
 ld (_penCol),bc
 ld hl,Dice
 ld b,5
DiceShowLoop:
 ld a,(hl)
 push hl
 call DispA
 pop hl
 inc hl
 ld a,(_penCol)
 add a,5
 ld (_penCol),a
 djnz DiceShowLoop
 ld a,(Round)
 inc a
 cp 3
 jr z,Decision
 ld (Round),a
;clear previous locks first
ShowLocks:
 ld hl,$fc00+(16*45+6)
 ld de,10
 ld c,5
 ld b,6
 ld (hl),0
 inc hl
 djnz $-3
 add hl,de
 dec c
 jr nz,$-9
 ld bc,44*256+48
 ld (_penCol),bc
 ld hl,Locks
 push hl
 ld b,5
LockShowLoop:
 ld a,(_penCol)
 push af
 ld a,(hl)
 or a
 jr z,$+7
 ld a,'*'
 call _vputmap
 pop af
 add a,9
 ld (_penCol),a
 inc hl
 djnz LockShowLoop
 pop hl
LockMenu:
 halt
 push hl
 call _getky
 pop hl
 or a
 jr z,LockMenu
 cp K_F1
 jr z,Lock1Change
 cp K_F2
 jr z,Lock2Change
 cp K_F3
 jr z,Lock3Change
 cp K_F4
 jr z,Lock4Change
 cp K_F5
 jr z,Lock5Change
 cp K_EXIT
 jp z,SaveGame
 cp K_SECOND
 jp z,RandomizeDice
 jr LockMenu
Lock5Change:
 inc hl
Lock4Change:
 inc hl
Lock3Change:
 inc hl
Lock2Change:
 inc hl
Lock1Change:
 ld a,(hl)
 cpl
 ld (hl),a
 jr ShowLocks
Decision:
 xor a
 ld (Round),a
 ld b,5
 ld hl,Locks
LockRemoveLoop:
 ld (hl),a
 inc hl
 djnz LockRemoveLoop
;arrange dice
 ld de,Dice
 push de
 ld a,4
 ld (addr),a
BigLoop:
 push af
addr =$+1
 ld b,4
 ld h,d
 ld l,e
 ld a,(de)
Loop:
 inc hl
 cp (hl)
 jr nc,NotBigger
 ld c,(hl)
 ld (hl),a
 ld a,c
 ld (de),a
NotBigger:
 djnz Loop
 inc de
 pop af
 dec a
 ld (addr),a
 jr nz,BigLoop
;find out differences
 pop hl
 ld de,Difference
 ld b,4
 ld a,(hl)
 inc hl
 ld c,(hl)
 sub c
 ld (de),a
 inc de
 djnz $-6
 ld a,(GamePointer)
 cp 14
 jr nz,MoreThan1Remaining
 ld hl,Points-1
 inc hl
 ld a,(hl)
 inc b
 cp -1
 jr nz,$-5
 ld a,b
 ld (Select),a
 jr MakeChoice
MoreThan1Remaining:
 call InvertSelect
ChoiceMenu:
 halt
 call _getky
 or a
 jr z,ChoiceMenu
 dec a
 jr z,Down
 dec a
 jr z,Left
 dec a
 jr z,Right
 dec a
 jr z,Up
 cp K_EXIT-4
 jp z,SaveGame
 cp K_SECOND-4
 jr z,MakeChoice
 jr ChoiceMenu
Up:
 ld a,(Select)
 cp 11
 jr z,ChoiceMenu
 dec a
 jr z,ChoiceMenu
MoveNow:
 push af
 call InvertSelect
 pop af
 ld (Select),a
 call InvertSelect
 jr ChoiceMenu
Down:
 ld a,(Select)
 cp 10
 jr z,ChoiceMenu
 cp 15
 jr nz,$+6
 ld a,6
 jr MoveNow
 inc a
 jr MoveNow
Left:
 ld a,(Select)
 cp 11
 jr c,ChoiceMenu
 sub 10
 jr MoveNow
Right:
 ld a,(Select)
 cp 11
 jr nc,ChoiceMenu
 add a,10
 cp 16
 jr c,MoveNow
 ld a,15
 jr MoveNow
MakeChoice:
 ld a,(Select)
 ld e,a
 ld hl,Points
 dec a
 ld c,a
 ld b,0
 add hl,bc
 ld a,(hl)
 inc a
 jr nz,ChoiceMenu
 ld a,e
 sub 7
 push hl
 jr nc,Pair
 ld b,5
 ld c,0
 ld hl,Dice
PointLoop:
 ld a,(hl)
 cp e
 jr nz,NoAdd
 ld a,c
 add a,e
 ld c,a
NoAdd:
 inc hl
 djnz PointLoop
 ld a,c
IncrGamePointer:
 pop hl
 ld (hl),a
 ld de,Points
 ld b,6
 ld l,0
 ld h,l
 ld a,(de)
 cp -1
 jr z,$+4
 add a,l
 ld l,a
 inc de
 djnz $-8
 ld a,l
 cp 63
 jr c,NoBonus
 ld a,50
 ld (Bonus),a
NoBonus: ;hl=number of points, de=pointer to points, c=free
 ld b,10
 ld a,(de)
 cp -1
 ld c,a
 jr z,$+7
 push bc
 ld b,0
 add hl,bc
 pop bc
 inc de
 djnz $-12
 ld bc,256*51+115
 ld (_penCol),bc
 ld (TotalPoints),hl
 call DispHL
 ld hl,GamePointer
 inc (hl)
 call InvertSelect
 jp GameLoop

Pair:
 jr nz,TwoPair
 ld hl,Difference-1
 ld b,4
 inc hl
 ld a,(hl)
 or a
 jr z,IsPair
 djnz $-5
ZeroScore:
 pop hl
 ld (hl),0
 jr IncrGamePointer+2
IsPair:
 ld de,-10
 add hl,de
 ld a,(hl)
 add a,a
 jr IncrGamePointer

TwoPair:
 dec a
 jr nz,ThreeOfKind
 ld b,5
 ld hl,TwoPairTable
TwoPairCheckLoop:
 push bc
 ld de,Difference
 ld b,4
TwoPairSmallLoop:
 ld c,(hl)
 ld a,(de)
 or a
 ld a,c
 jr z,CheckTableZero
 or a
 jr z,NotThisCase
 jr Continue
CheckTableZero:
 or a
 jr nz,NotThisCase
Continue:
 inc hl
 inc de
 djnz TwoPairSmallLoop
 pop bc
 dec hl
 dec de
 ld a,(hl)
 or a
 jr nz,$-4
 ex de,hl ;now hl=difference, de=twopairtable
 push hl
 ld de,-10
 add hl,de
 ld a,(hl)
 add a,a
 ld c,a
 pop hl
 dec hl
 dec hl
 ld a,(hl)
 or a
 jr z,$+3
 dec hl
 add hl,de
 ld a,(hl)
 add a,a
 add a,c
 jp IncrGamePointer
NotThisCase:
 ld c,b
 ld b,0
 add hl,bc
 pop bc
 djnz TwoPairCheckLoop
 jr ZeroScore

ThreeOfKind:
 dec a
 jr nz,FourOfKind
 ld hl,Difference
 ld b,3
FindZero:
 ld a,(hl)
 or a
 jr z,CheckAnotherZero
 inc hl
 djnz FindZero
 jr ZeroScore
CheckAnotherZero:
 inc hl
 ld a,(hl)
 or a
 jr z,Is3OfKind
 inc hl
 dec b
 ld a,b
 cp 2
 jr nc,FindZero
 jr ZeroScore
Is3OfKind:
 ld de,-10
 add hl,de
 ld a,(hl)
 ld b,a
 add a,a
 add a,b
 jp IncrGamePointer

FourOfKind:
 dec a
 jr nz,FullHouse
 ld a,2
 ld (CheckFourCase1+1),a
 ld hl,Difference
 ld a,(hl)
 or a
 jr z,CheckFourCase1
 ld a,3
 ld (CheckFourCase1+1),a
CheckFourCase1:
 ld b,2
 inc hl
 ld a,(hl)
 or a
 jp nz,ZeroScore
 djnz $-6
 ld de,-10
 add hl,de
 ld a,(hl)
 add a,a
 add a,a
 jp IncrGamePointer

FullHouse:
 dec a
 jr nz,SmallStraight
 ld hl,Difference
 ld a,(hl)
 or a
 jp nz,ZeroScore
 inc hl
 ld a,(hl)
 or a
 jr nz,FullCase2
 inc hl
 ld a,(hl)
 or a
 jp z,ZeroScore
 inc hl
 ld a,(hl)
 or a
 jp nz,ZeroScore
SumAll:
 ld c,0
 ld hl,Dice
 ld b,5
 ld a,(hl)
 add a,c
 ld c,a
 inc hl
 djnz $-4
 jp IncrGamePointer
FullCase2:
 ld b,2
 inc hl
 ld a,(hl)
 or a
 jp nz,ZeroScore
 djnz $-6
 jr SumAll

SmallStraight:
 dec a
 jr nz,BigStraight
 ld hl,Dice
 ld b,5
 ld a,(hl)
 cp b
 jp nz,ZeroScore
 inc hl
 djnz $-6
 jr SumAll

BigStraight:
 dec a
 jr nz,Coincidence
 ld hl,Dice
 ld b,5
 ld c,6
 ld a,(hl)
 cp c
 jp nz,ZeroScore
 inc hl
 dec c
 djnz $-7
 jr SumAll

Coincidence:
 dec a
 jr z,SumAll

Yatzy:
 ld hl,Difference
 ld b,4
 ld a,(hl)
 or a
 jp nz,ZeroScore
 inc hl
 djnz $-6
 pop hl
 ld (hl),50
 jp IncrGamePointer+2

DispA:
 ld l,a
 ld h,0
DispHL:
 xor a
 ld de,-1
 ld (_curRow),de
 call $4a33
DiscardSpaces:
 inc hl
 ld a,(hl)
 cp Lspace
 jr z,DiscardSpaces
 jp _vputs

vnewline:
 ld a,1
 ld (_penCol),a
NewRow:
 ld a,(_penRow)
 add a,6
 ld (_penRow),a
 ret

RandLFSR:
 ld hl,LFSRSeed+4
 ld e,(hl)
 inc hl
 ld d,(hl)
 inc hl
 ld c,(hl)
 inc hl
 ld a,(hl)
 ld b,a
 rl e \ rl d
 rl c \ rla
 rl e \ rl d
 rl c \ rla
 rl e \ rl d
 rl c \ rla
 ld h,a
 rl e \ rl d
 rl c \ rla
 xor b
 rl e \ rl d
 xor h
 xor c
 xor d
 ld hl,LFSRSeed+6
 ld de,LFSRSeed+7
 ld bc,7
 lddr
 ld (de),a
 and %00000111
 cp 7
 jr z,RandLFSR
 cp 6
 jr z,RandLFSR
 ret

InvertSelect:
 ld a,(Select)
 cp 11
 ld hl,$fc00-(16*6)
 jr c,StartInvert
 sub 10
 ld hl,$fc00-(16*6)+6
StartInvert:
 ld b,a
 ld de,16*6
 add hl,de
 djnz $-1
 ld b,7
 ld de,12
BigInvLoop:
 push bc
 ld b,4
InvLoop:
 ld a,(hl)
 cpl
 ld (hl),a
 inc hl
 djnz InvLoop
 add hl,de
 pop bc
 djnz BigInvLoop
 ret

Select: .db 0 ;menu selection
Dice: .db 1,2,3,4,5
Locks: .db 0,0,0,0,0
Difference: .db 0,0,0,0
GamePointer: .db 0 ;how many rounds have been played
TotalPoints: .dw 0
Round: .db 0  ;0,1,2 or 3
Points: .db -1,-1,-1,-1,-1,-1
 .db -1,-1,-1,-1,-1,-1,-1,-1,-1
Bonus: .db 0
SaveGameData:
Record: .dw 5
Games: .dw 0
Num300Games: .dw 0 ;how many 300 points games have been played
LFSRSeed: .db 154,155,201,36,6,37,50,45
SaveGameDataEnd:
TwoPairTable:
.db 1,0,1,0
.db 0,1,0,1
.db 0,1,1,0
.db 0,1,0,0 ;full house
.db 0,0,1,0 ;full house
Texts:
 .db "Pari",0
 .db "2 paria",0
 .db "3 samaa",0
 .db "4 samaa",0
 .db "Tayskasi",0
 .db "P. suora",0
 .db "Iso suora",0
 .db "Sattuma",0
 .db "Yatzy",0
 .db "Bonus",0
PointsText: .db "Pisteet:",0
EnnText: .db "Ennatys:",0
Pelit300Text: .db "300-Pelit:",0
.end