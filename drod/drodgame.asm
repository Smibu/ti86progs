;DROD game engine
WaitGameKey:
 halt
 call _getky
 ld d,a
 ld a,(demo)
 dec a
 jr z,skipwait
 ld a,d
 or a
 jr z,WaitGameKey
skipwait:
 ld a,d
 cp K_PLUS
 call z,ContrastUp
 cp K_MINUS
 call z,ContrastDown
 cp K_EXIT
 jp z,exitmenu
 ld a,(demo)
 dec a
 jr nz,NoPlaying
 ld b,20
HALT_LOOP:
 halt
 djnz HALT_LOOP
 call GetNextMove
NoPlaying:
 dec a
 call z,SaveMove
 ld a,d
 cp K_8
 jp z,up
 cp K_2
 jp z,down
 cp K_4
 jp z,left
 cp K_6
 jp z,right
 cp K_7
 jp z,upleft
 cp K_9
 jp z,upright
 cp K_1
 jp z,downleft
 cp K_3
 jp z,downright
 cp K_LEFT
 jr z,rotleft
 cp K_RIGHT
 jr z,rotright
 cp K_5
 jp z,CannotMove
 ld a,(demo)
 dec a
 jp z,ProgStart
 dec a
 jr nz,WaitGameKey
 ld hl,(MovePointer)
 dec hl
 ld (MovePointer),hl
 jr WaitGameKey

;rotates sword
rotright:
 ld b,1
 jr DoRotate

rotleft:
 ld b,-1
DoRotate:
 push bc
 call DeleteSword
 call GetAddress
 pop bc
 add a,b
 cp Guy-1
 call z,add8
 cp Guy+8
 call z,subtract8
DoneRot:
 ld (hl),a
 jp CannotMove

NewRoom:
 xor a
 ld (steps),a
 ld (mimic),a
 ld (invis),a
;check where direction the guy went (saved in (temp6))
 ld a,(temp6)
 or a
 jp z,Nothing        ;if zero, this must be the first room or room was restarted
 call CheckAnyEnemies
 jr nc,ThereIsEnemies
;remove enemies & walls from room and decr. number of enemy rooms IF there was enemies
 ld a,(anyenemies)
 dec a
 jr nz,ThereIsEnemies
 ld hl,enemyroomsleft
 dec (hl)
 call FindRoom
 ld b,144
EnemyRemoveLoop:
 ld a,(hl)
 cp EnemyWall
 jr z,Remove
 cp TarWall
 jr c,DontRemove
Remove:
 ld (hl),0
DontRemove:
 inc hl
 djnz EnemyRemoveLoop
ThereIsEnemies:
 ld a,(temp6)
 dec a
 jr nz,NotUp
 ld hl,roomcoords+1
 dec (hl)
 call GetAddress
 push af
 call CopyNewRoom    ;load new room
 ld a,8               ;copy guy to new room
 ld (coords+1),a
 call GetAddress
 pop af
 jr DoneRoomLoad

NotUp:
 dec a
 jr nz,NotDown
 ld hl,roomcoords+1
 inc (hl)
 call GetAddress
 push af
 call CopyNewRoom
 xor a
 ld (coords+1),a
 call GetAddress
 pop af
 jr DoneRoomLoad

NotDown:
 dec a
 jr nz,NotLeft
 ld hl,roomcoords
 dec (hl)
 call GetAddress
 push af
 call CopyNewRoom
 ld a,15
 ld (coords),a
 call GetAddress
 pop af
 jr DoneRoomLoad

NotLeft:
 ld hl,roomcoords
 inc (hl)
 call GetAddress
 push af
 call CopyNewRoom
 xor a
 ld (coords),a
 call GetAddress
 pop af
 jr DoneRoomLoad

Nothing:
;so room restarted or this is the starting room
 call CopyNewRoom
 ld hl,(lastentry)
 ld (coords),hl
 call GetAddress
 ld a,(lastentry+2)
DoneRoomLoad:
 ld (hl),a
;check if room wasn't found
 ld a,(noroomfound)
 dec a
 ret z
;save arrival coordinates
 ld hl,(coords)
 ld (lastentry),hl
 call GetAddress
 ld (lastentry+2),a
 xor a
 ld (anyenemies),a
 call CheckAnyEnemies
 jr c,noenemies
 ld a,1
 ld (anyenemies),a
;must do next to prevent enemies from moving when entering to new room
 ld hl,CurrentRoom
 ld b,144
PreventLoop:
 ld a,(hl)
 cp ExitStairs
 jr c,skiprev
 add a,100
 ld (hl),a
skiprev:
 inc hl
 djnz PreventLoop
noenemies:
 ld a,(enemyroomsleft)
 or a
 jr nz,notalldefeated
;remove exit walls
 ld hl,CurrentRoom
 ld b,144
exitwallremoveloop:
 ld a,(hl)
 cp ExitWall
 jr nz,noexitwall
 ld (hl),0
 push hl
 call GetbgAddress
 ld (hl),0
 pop hl
noexitwall:
 inc hl
 djnz exitwallremoveloop
notalldefeated:
 jp EndRotate

ReadMessage:
 call _clrLCD
 call _homeup
 call FindRoom
 call GetbgAddress
 call _putps
 jp wait

MakeInvisible:
 ld a,15
 ld (invis),a
 call GetAddress
 call GetbgAddress
 ld (hl),0
 ret

upleft:
 ld a,8
 jr Move
left:
 ld a,7
 jr Move
downleft:
 ld a,6
 jr Move
down:
 ld a,5
 jr Move
downright:
 ld a,4
 jr Move
right:
 ld a,3
 jr Move
upright:
 ld a,2
 jr Move
up:
 ld a,1
Move:
 ld (temp),a
 call GetAddress     ;address now also in (temp3)
 ld a,(temp)
 call CheckBorders
 jp c,NewRoom
 ld a,(temp)
 call CheckMovePossibilityGuy
 jp c,CannotMove
 call GetAddress
 push af
 call DeleteSword
 ld hl,(temp3)

;Check if guy was on the trap floor
 call GetbgAddress
 cp TrapFloor
 ld hl,(temp3)
 ld (hl),0
 jr nz,NoTrapFloor
 call GetbgAddress
 ld (hl),Wall1
 ld hl,(temp3)
NoTrapFloor:
 ld a,(temp)
 call FindPosition
 call ConvAddress
 ld hl,(tempcoords)
 ld (coords),hl
 call GetAddress
 pop af
 ld (hl),a
 call GetbgAddress
 ld a,(hl)
 cp ExitStairs
 jr nz,NotCompleted
 call _clrScrn
 ld hl,congratstxt
 ld bc,256*3+3
 ld (_curRow),bc
 call _puts
 call wait
 ld a,(demo)
 or a
 jp z,NormalComplete
 dec a
 jp z,ProgStart
 jp SaveDemo
NormalComplete:
 ld hl,savegamefile-1
 call DeleteFile
 jp ProgStart
NotCompleted:
 ld a,(mimic)
 or a
 ld a,(temp)
 call nz,MoveMimic

;check if the trap walls open:
 ld hl,background
 ld b,144
TrapCheckLoop:
 ld a,(hl)
 cp TrapFloor
 jr z,EndRotate     ;then there is trap floors
 inc hl
 djnz TrapCheckLoop

;no traps, so remove trap walls:
 ld hl,CurrentRoom
 ld b,144
WallRemoveLoop:
 ld a,(hl)
 cp TrapWall
 jr nz,NoTrapWall
 ld (hl),0
 call GetbgAddress
 ld (hl),0
 sbc hl,de
NoTrapWall:
 inc hl
 djnz WallRemoveLoop

EndRotate:
 call GetAddress
;check if guy got mimic potion, invisibility potion or message
 call GetbgAddress
 cp Message
 call z,ReadMessage
 cp InvisPotion
 call z,MakeInvisible
 cp MimicPotion
 call z,PlaceMimic

CannotMove:
 call GetAddress
 call CheckLeverHit
 call GetAddress
 call CheckSwordDraw
 jr c,DontShowSword2
 call GetSwordAddress
 ld (temp3),hl
;check if sword hit tar
 call CheckTarHit
;if mimic gets killed by the sword, don't draw it yet
 ld b,a
 xor a
 ld (MimicDies),a
 ld a,(hl)
 cp MimicGuy
 jr c,MimicDoesntDie
 cp MimicGuy+8
 jr nc,MimicDoesntDie
 ld a,1
 ld (MimicDies),a
MimicDoesntDie:
; ld (hl),b     ;necessary?
DontShowSword2:
 ld a,(mimic)
 or a
 ld a,0              ;no flags update!
 call nz,MoveMimic   ;if there is mimic, update it too
;redraw guy's sword
 call GetAddress
 call CheckSwordDraw
 jr c,DontShowSword
 call GetSwordAddress
 ld (hl),a
;check if enemy walls open:
 call CheckAnyEnemies
 jr nc,DontShowSword

;no enemies, so remove enemy walls:
 ld hl,CurrentRoom
 ld b,144
EnemyWallRemoveLoop:
 ld a,(hl)
 cp EnemyWall
 jr nz,NoEnemyWall
 ld (hl),0
 call GetbgAddress
 ld (hl),0
 sbc hl,de
NoEnemyWall:
 inc hl
 djnz EnemyWallRemoveLoop

DontShowSword:
 call MoveEnemies
Backtogame:
 call UpdateScreen
CheckDeath:
 call GetAddress
 sub Guy
 cp 8
 jp c,WaitGameKey
 ld b,2
flashloop:
 push bc
 ld hl,$fc00
flashsubloop:
 ld a,(hl)
 cpl
 ld (hl),a
 inc hl
 or h
 jr nz,flashsubloop
 ld b,20
waitloop:
 halt
 djnz waitloop
 pop bc
 djnz flashloop
RestartRoom:
 xor a
 ld (temp6),a
 jp NewRoom

;moves all enemies in the room correctly
MoveEnemies:
 ld hl,steps
 inc (hl)
 ld a,(invis)
 or a
 jr z,MoveEnemiesNow
 dec a
 ld (invis),a
 jp DoNothing
MoveEnemiesNow:
 ld hl,CurrentRoom
 ld a,144
 ld (EnemyLoopCounter),a
MoveLoop:
 push hl
 ld a,(hl)
 cp StandingEye
 jp c,NoEnemy
 cp 100
 jp nc,NoEnemy
 cp Roach
 jr nc,CheckActualEnemies

;check if some eye has noticed the guy
CheckEyeChange:
 sub StandingEye-1
 ld (temp),a      ;save direction into (temp)
 ld (temp4),hl    ;save address into (temp4)
ChangeCheckLoop:
 push hl
 call ConvAddress
 ld a,(temp)
 call CheckBorders
 pop hl
 jp c,NoEnemy
 ld a,(temp)
 call FindPosition
 ld a,(hl)
 cp ExitStairs
 jp nc,NoEnemy
 call GetbgAddress
 cp ExitStairs
 jp nc,NoEnemy
 or a
 sbc hl,de
 ld a,(hl)
 sub Guy
 cp 8
 jr nc,ChangeCheckLoop
 ld a,(temp)
 add a,MovingEye-1
 ld hl,(temp4)
 ld (hl),a

CheckActualEnemies:
 cp QueenRoach
 jp nc,MoveQueenRoach
MoveNormalEnemy:
 push hl
 call ConvAddress
 pop hl
 ld a,(tempcoords)
 ld b,a
 ld a,(coords)
 cp b
 jr z,MoveUporDown
 jp c,MoveLeft

MoveRight:
 ld a,(tempcoords+1)
 ld b,a
 ld a,(coords+1)
 cp b
 jr c,MoveUpRight
 jr z,MoveStraightRight
MoveDownRight:
 ld a,4
 ld (temp4),a
 ld (temp5),a
 call CheckMovePossibility
 jr nc,MakeMove
 ld a,3
 ld (temp5),a
 call CheckMovePossibility
 jr nc,MakeMove
MoveDownNow:
 ld a,5
 ld (temp5),a
 call CheckMovePossibility
 jr nc,MakeMove
CantDo:
 ld a,(temp4)
 call GetCorrectSprite
DoneEnemyMove:
 add a,100
 ld (hl),a
 jp NoEnemy

MakeMove:
 ld a,(temp4)
 call GetCorrectSprite
 ld (hl),0
 push af
 ld a,(temp5)
 call FindPosition
 pop af
 jr DoneEnemyMove

MoveUpRight:
 ld a,2
 ld (temp4),a
 ld (temp5),a
 call CheckMovePossibility
 jr nc,MakeMove
 ld a,1
 ld (temp5),a
 call CheckMovePossibility
 jr nc,MakeMove
MoveRightNow:
 ld a,3
 ld (temp5),a
 call CheckMovePossibility
 jr nc,MakeMove
 jr CantDo

MoveStraightRight:
 ld a,3
 ld (temp4),a
 jr MoveRightNow

MoveUporDown:
 ld a,(tempcoords+1)
 ld b,a
 ld a,(coords+1)
 cp b
 jr c,MoveUp

MoveDown:
 ld a,5
 ld (temp4),a
 jr MoveDownNow

MoveUp:
 ld a,1
 ld (temp4),a
 ld (temp5),a
 call CheckMovePossibility
 jr nc,MakeMove
 jr CantDo

MoveLeft:
 ld a,(tempcoords+1)
 ld b,a
 ld a,(coords+1)
 cp b
 jr c,MoveUpLeft
 jr z,MoveStraightLeft
MoveDownLeft:
 ld a,6
 ld (temp4),a
 ld (temp5),a
 call CheckMovePossibility
 jr nc,MakeMove
 ld a,7
 ld (temp5),a
 call CheckMovePossibility
 jr nc,MakeMove
 jp MoveDownNow

MoveUpLeft:
 ld a,8
 ld (temp4),a
 ld (temp5),a
 call CheckMovePossibility
 jp nc,MakeMove
 ld a,1
 ld (temp5),a
 call CheckMovePossibility
 jp nc,MakeMove
MoveLeftNow:
 ld a,7
 ld (temp5),a
 call CheckMovePossibility
 jp nc,MakeMove
 jp CantDo

MoveStraightLeft:
 ld a,7
 ld (temp4),a
 jr MoveLeftNow

MoveQueenRoach:
 push hl
 call ConvAddress
 pop hl
CheckBear:
 ld a,(steps)
 cp 15
 jr nz,DontBear
 xor a
Bearloop:
 push hl
 inc a
 push af
 call CheckMovePossibility
 jr c,End
 pop af
 call FindPosition
 ld (hl),Roach+100
 push af
End:
 pop af
 pop hl
 cp 8
 jr nz,Bearloop
 jr NoEnemy

DontBear:
 ld a,(tempcoords)
 ld b,a
 ld a,(coords)
 cp b
 jr z,MoveUporDownQueen
 jp c,MoveRightQueen
MoveLeftQueen:
 ld a,(tempcoords+1)
 ld b,a
 ld a,(coords+1)
 cp b
 jr z,MoveStraightLeft
 jr nc,MoveUpLeft
 jp MoveDownLeft

MoveRightQueen:
 ld a,(tempcoords+1)
 ld b,a
 ld a,(coords+1)
 cp b
 jp z,MoveStraightRight
 jp nc,MoveUpRight
 jp MoveDownRight

MoveUporDownQueen:
 ld a,(tempcoords+1)
 ld b,a
 ld a,(coords+1)
 cp b
 jp nc,MoveUp
 jp MoveDown

NoEnemy:
 pop hl
 inc hl
 ld a,(EnemyLoopCounter)
 dec a
 ld (EnemyLoopCounter),a
 or a
 jp nz,MoveLoop
DoNothing:
 ld hl,CurrentRoom
 ld b,144
subloop:
 ld a,(hl)
 sub 100
 jr c,skipsub
 ld (hl),a
skipsub:
 inc hl
 djnz subloop
 ld a,(steps)
 cp 15
 ret nz
 xor a
 ld (steps),a
 ret

;in - hl: address of enemy in CurrentRoom
;out - carry set if can't move
CheckMoveUpLeft:
 inc a
CheckMoveLeft:
 inc a
CheckMoveDownLeft:
 inc a
CheckMoveDown:
 inc a
CheckMoveDownRight:
 inc a
CheckMoveRight:
 inc a
CheckMoveUpRight:
 inc a
CheckMoveUp:
 inc a
 jp CheckMovePossibility

;in - address of guy / mimic coordinates in (temp3)
;out - hl: address where to draw the sword
;       a: sprite number of sword
GetSwordAddress:
 ld hl,(temp3)
 ld a,(hl)
 sub MimicGuy-1
 jr nc,noadd
 add a,MimicGuy-7
noadd:
 call FindPosition
; push af
; push hl
; call dispa
; call _getkey
; pop hl
; pop af
 add a,Sword-1
 ret

;in - a: direction to move to
;    hl: address of enemy in CurrentRoom
;out - carry set if enemy can't move
;      address stored into (temp3)
;      direction stored into (temp)
CheckMovePossibility:
 ld (temp),a
 ld (temp3),hl
 call CheckBorders
 jp c,CantMove
 ld a,(temp)
 call FindPosition
 ld a,(hl)
 cp 23
 jp nc,CantMove
 call GetbgAddress
 cp 23
 jp nc,CantMove
 ld hl,(temp3)
 call GetbgAddress
 cp 23
 jp nc,CantMove

 ld a,(temp)
 ld hl,(temp3)
 call FindPosition
 call GetbgAddress
 sub Arrow
 cp 8
 jr c,CheckArrowEnemy

 ld hl,(temp3)
 call GetbgAddress
 sub Arrow
 cp 8
 jp nc,CanMove
CheckArrowEnemy:
 ld hl,(temp3)
 ld a,(temp)
 call FindPosition
 call CheckArrow
 ret c

;check now if the enemy is standing on an arrow
 ld hl,(temp3)
 jp CheckArrow

;in - a: direction to move to
;        address of guy / mimic in (temp3)
;out - carry set if can't move
;      direction stored into (temp)
;      address stored into (temp3)
CheckMovePossibilityGuy:
 ld (temp),a     ;save direction
 ld hl,(temp3)
 call FindPosition  ;find new address
 ld a,(hl)
 cp 32
 jp nc,CantMove  ;if there is any obstacle, can't move then
 call GetbgAddress
 cp 32
 jp nc,CantMove  ;check also background (in case sword is on the wall)

 ld hl,(temp3)
 ld a,(temp)
 call FindPosition
 call GetbgAddress
 sub Arrow
 cp 8
 jr c,CheckArrowGuy  ;jump if guy is going to an arrow

 ld hl,(temp3)
 call GetbgAddress
 sub Arrow
 cp 8
 jr nc,CanMove  ;if guy is NOT standing on an arrow, he can move

CheckArrowGuy:
 ld hl,(temp3)
 ld a,(temp)
 call FindPosition
 call CheckArrow
 ret c

;check now if the guy is standing on an arrow
 ld hl,(temp3)

;in - direction in (temp)
;     hl: address of guy/enemy in CurrentRoom
CheckArrow:
 call GetbgAddress
 ld b,a
 ld a,(temp)
 sub 4
 call c,add8
 add a,15
 cp b
 jr z,CantMove
 dec a
 cp 14
 call z,add8
 cp b
 jr z,CantMove
 dec a
 cp 14
 call z,add8
 cp b
 jr z,CantMove
CanMove:
 or a
 jr DoneCheckArrow
CantMove:
 scf
DoneCheckArrow:
 ld hl,(temp3)
 ret

;checks if the sword can be drawn
;in - address of guy / mimic in (temp3)
;     coordinates in (tempcoords)
;out - carry set if can't draw sword
CheckSwordDraw:
 ld hl,(temp3)
 ld a,(hl)
 sub MimicGuy-1
 jr nc,noadd2
 add a,25
noadd2:
 ld (temp5),a
 ld a,(tempcoords+1)
 or a
 jr nz,SkipFirst2
 ld a,(temp5)
 dec a
 jp z,CantMove
 dec a
 jp z,CantMove
 cp 8-2
 jp z,CantMove
SkipFirst2:
 ld a,(tempcoords+1)
 cp 8
 jr nz,SkipSecond2
 ld a,(temp5)
 sub 4
 jp z,CantMove
 dec a
 jp z,CantMove
 dec a
 jp z,CantMove
SkipSecond2:
 ld a,(tempcoords)
 or a
 jr nz,SkipThird2
 ld a,(temp5)
 sub 6
 jp z,CantMove
 dec a
 jp z,CantMove
 dec a
 jp z,CantMove
SkipThird2:
 ld a,(tempcoords)
 cp 15
 jp nz,CanMove
 ld a,(temp5)
 sub 2
 jp z,CantMove
 dec a
 jp z,CantMove
 dec a
 jp z,CantMove
 jp CanMove

;checks if enemy/mimic is at the edge of the room
;in - direction in (temp)
;     coordinates of enemy / mimic in (tempcoords)
;out - carry set if can't move
CheckBorders:
 ld a,(tempcoords+1)
 or a
 jr nz,SkipFirst
 ld a,1
 ld (temp6),a
 ld a,(temp)
 dec a
 jp z,CantMove
 dec a
 jp z,CantMove
 cp 8-2
 jp z,CantMove
SkipFirst:
 ld a,(tempcoords+1)
 cp 8
 jr nz,SkipSecond
 ld a,2
 ld (temp6),a
 ld a,(temp)
 sub 4
 jp z,CantMove
 dec a
 jp z,CantMove
 dec a
 jp z,CantMove
SkipSecond:
 ld a,(tempcoords)
 or a
 jr nz,SkipThird
 ld a,3
 ld (temp6),a
 ld a,(temp)
 sub 6
 jp z,CantMove
 dec a
 jp z,CantMove
 dec a
 jp z,CantMove
SkipThird:
 ld a,(tempcoords)
 cp 15
 jp nz,CanMove
 ld a,4
 ld (temp6),a
 ld a,(temp)
 sub 2
 jp z,CantMove
 dec a
 jp z,CantMove
 dec a
 jp z,CantMove
 xor a
 ld (temp6),a
 jp CanMove

;removes sword if necessary
;in - address of guy / mimic in (temp3)
;out - sword deleted or nothing done
DeleteSword:
 call CheckSwordDraw
 ret c
 call GetSwordAddress
 ld (hl),0
 ret

;checks if the lever was toggled
;in - coordinates of guy/mimic in (temp3)
;out - levers toggled possibly
CheckLeverHit:
 call GetSwordAddress
 call GetbgAddress
 cp Lever
 ret nz
 ld hl,background
 ld b,144
WallChangeLoop:
 ld a,(hl)
 cp LeverWall
 jr nz,NotWallUp
 ld (hl),LeverDown
 push hl
 sbc hl,de
 ld (hl),LeverDown
 pop hl
 jr EndWallChangeLoop
NotWallUp:
 cp LeverDown
 jr nz,EndWallChangeLoop
 ld (hl),LeverWall
 push hl
 sbc hl,de
 ld (hl),LeverWall
 pop hl
EndWallChangeLoop:
 inc hl
 djnz WallChangeLoop
 ret

PlaceMimic:
 call GetAddress
 call GetbgAddress
 ld (hl),0        ;remove mimic potion
 ld hl,256*4+7
 ld (mimiccoords),hl
 ld hl,CurrentRoom+(4*16+7)    ;center of CurrentRoom
 ld a,(hl)
 ld (temp5),a
 ld (hl),MimicCursor       ;put cursor into it
again:
 call UpdateScreen
waitmimickey:
 halt
 call _getky
 ld d,a
 ld a,(demo)
 dec a
 jr z,skipwait2
 ld a,d
 or a
 jr z,waitmimickey
skipwait2:
 ld a,d
 cp K_PLUS
 call z,ContrastUp
 cp K_MINUS
 call z,ContrastDown
 cp K_EXIT
 jp z,exitmenu
 ld a,(demo)
 dec a
 jr nz,NoPlaying2
 ld b,20
HALT_LOOP2:
 halt
 djnz HALT_LOOP2
 call GetNextMove
NoPlaying2:
 dec a
 call z,SaveMove
 ld a,d
 cp K_8
 jp z,mimicup
 cp K_2
 jp z,mimicdown
 cp K_4
 jp z,mimicleft
 cp K_6
 jp z,mimicright
 cp K_5
 jp z,putmimic
 ld a,(demo)
 dec a
 jp z,ProgStart
 dec a
 jr nz,waitmimickey
 ld hl,(MovePointer)
 dec hl
 ld (MovePointer),hl
 jr waitmimickey
mimicup:
 ld a,(mimiccoords+1)
 or a
 jr z,waitmimickey
 call GetMimicAddress
 ld a,(temp5)
 ld (hl),a
 ld hl,mimiccoords+1
 dec (hl)
 jr endmimicmove
mimicdown:
 ld a,(mimiccoords+1)
 cp 8
 jr z,waitmimickey
 call GetMimicAddress
 ld a,(temp5)
 ld (hl),a
 ld hl,mimiccoords+1
 inc (hl)
 jr endmimicmove
mimicleft:
 ld a,(mimiccoords)
 or a
 jp z,waitmimickey
 call GetMimicAddress
 ld a,(temp5)
 ld (hl),a
 ld hl,mimiccoords
 dec (hl)
 jr endmimicmove
mimicright:
 ld a,(mimiccoords)
 cp 15
 jp z,waitmimickey
 call GetMimicAddress
 ld a,(temp5)
 ld (hl),a
 ld hl,mimiccoords
 inc (hl)
endmimicmove:
 call GetMimicAddress
 ld (temp5),a
 ld (hl),MimicCursor
 jp again
putmimic:
 call GetMimicAddress
 call GetbgAddress
 cp 31
 jp nc,waitmimickey
 ld a,1
 ld (mimic),a
 call GetAddress
 push af
 call GetMimicAddress
 pop af
 add a,25
 ld (hl),a
 ret

;moves the mimic
;in - a: direction to move to
MoveMimic:
 ld (temp),a
 ld a,(MimicDies)
 or a
 jr z,NotKilledMimic
 xor a
 ld (mimic),a
 call DeleteSword
 ret
NotKilledMimic:
 call GetMimicAddress
 call DeleteSword
 ld a,(temp)
 or a
 jr z,SkipMimicMoves
 call GetMimicAddress     ;address now also in (temp3)
 ld a,(temp)
 call CheckBorders
 ret c
 ld a,(temp)
 call CheckMovePossibilityGuy
 ret c
 ld hl,(temp3)
 ld a,(hl)
 push af
 ld hl,(temp3)
 ld (hl),0
 ld a,(temp)
 call FindPosition
 call ConvAddress
 ld hl,(tempcoords)
 ld (mimiccoords),hl
 call GetMimicAddress
 pop af
 ld (hl),a
 call ConvAddress
 ld hl,(tempcoords)
 ld (mimiccoords),hl
SkipMimicMoves:
 call GetMimicAddress
 push hl
 call GetAddress
 add a,25
 pop hl
 ld (hl),a
 call GetMimicAddress
 call CheckSwordDraw
 ret c
 call GetSwordAddress
 ld (temp3),hl
 call CheckTarHit
 ld (hl),a
 ld a,(temp)
 or a
 ret nz          ;so the lever won't be toggled twice
 call GetMimicAddress
 jp CheckLeverHit

CheckTarHit:
 push af
 push hl
 ld a,(hl)
 sub TarWall
 jr nz,NoTarWall
;so sword hit tar, change all surrounding tar walls into enemies
TarWallChangeLoop:
 inc a
 push af
 ld hl,(temp3)
 call FindPosition
 ld a,(hl)
 cp TarWall
 jr nz,NoWallHere
 ld (hl),TarEnemy+100
NoWallHere:
 pop af
 cp 8
 jr nz,TarWallChangeLoop
NoTarWall:
 pop hl
 pop af
 ret

CopyNewRoom:
 call FindRoom
 ld de,CurrentRoom
 ld bc,144
 ldir
;now copy some parts of it to background too
 ld hl,background
 ld b,144
 call _ldhlz
 ld hl,CurrentRoom
 ld de,background
 ld b,144
bgcopyloop:
 ld a,(hl)
 cp 42
 jr c,Copy
 jr z,DontCopy
 cp 48
 jr nc,DontCopy
Copy:
 ld (de),a
DontCopy:
 inc hl
 inc de
 djnz bgcopyloop
 ret

;in - room coordinates in (roomcoords)
;out - hl: pointer to room in leveldata area
FindRoom:
 ld hl,leveldata
 ld (temp3),hl
 ld bc,$fa70-roomstart
 xor a
 ld (noroomfound),a
LevelSearchLoop:
 ld hl,(temp3)
 ld a,255
 cpir
 ld (temp3),hl
 jp po,roomnotfound
 ld a,(roomcoords)
 cp (hl)
 jr nz,LevelSearchLoop
 inc hl
 ld a,(roomcoords+1)
 cp (hl)
 jr nz,LevelSearchLoop
 inc hl
 ret
roomnotfound:
 ld a,1
 ld (noroomfound),a
 call _clrScrn
 call _homeup
 ld hl,roomnotexisttxt
 jp _puts

Positions:
 .db 240,255,241,255,1,0,17,0,16,0,15,0,255,255,239,255

.end