#include "ti86.inc"
.org _asm_exec_ram
_ldhlz = $437B

board = _plotSScreen
PermanentNumbers = board+81
gameready = PermanentNumbers+81
numbers = gameready+1
timer1 = numbers+1
timer2 = timer1+1
hintsenabled = timer2+2
level = hintsenabled+1
rec1 = level+1
rec2 = rec1+2
rec3 = rec2+2
rec4 = rec3+2
rec5 = rec4+2
rec6 = rec5+2
randseed = rec6+2
EndOfData = randseed+2

;.plugin lite86
 nop
 jp ProgStart
 .dw 0
 .dw ShellTitle+1
ShellTitle:
 .db 6,"Sudoku v2.2",0

ProgStart:
 ld hl,$d400
 ld de,$d401
 ld bc,$100
 ld (hl),$d3
 ldir
 ld hl,InterruptHandler
 ld de,$d3d3
 ld bc,InterruptHandlerEnd-InterruptHandler
 ldir
 ld a,$d4
 ld i,a
 im 2
 call _runindicoff
 call _flushallmenus
 call LoadGame
MenuStart:
 call _clrLCD
 call ResetFlags
 ld hl,256*7
 ld (_curRow),hl
 ld hl,ShellTitle
 call _putps
 ld bc,256*15
 ld (_penCol),bc
 ld hl,generateboardtext
 ld a,(gameready)
 inc a
 ld (sel),a
 dec a
 jr nz,SkipContinueText
 ld hl,continuetext
 call _vputs
SkipContinueText:
 ld b,5
ShowMenuTextsLoop:
 call vnewline
 call _vputs
 djnz ShowMenuTextsLoop
 call ViewLevel
 ld a,(hintsenabled)
 ld bc,256*36+18
 call ViewYesNo
 ld a,(highlight)
 ld bc,256*43+81
 call ViewYesNo
 set textInverse,(iy+textflags)
 call InvertMenuSelect
menuagain:
 ld b,6
 call DoMenu
CheckKeyPress:
 cp K_EXIT-1
 jp z,QuitGame
 dec a
 jp z,StartGame
 dec a
 jp z,GenerateRandomBoard
 dec a
 jr z,ChangeLevel
 dec a
 jr z,ChangeHints
 dec a
 jr z,ChangeHighlight
 jp ViewHighScores
ChangeHints:
 ld bc,256*36+18
 ld hl,hintsenabled
ChangeNow:
 ld a,1
 xor (hl)
 ld (hl),a
 jr DoneShow1

ChangeHighlight:
 ld bc,256*43+81
 ld hl,highlight
 jr ChangeNow

DoneShow1:
 call ViewYesNo
 jr menuagain

ViewYesNo:
 ld (_penCol),bc
 rrca
 jr c,enabled
 ld hl,notext
 jr showno
enabled:
 ld hl,yestext
showno:
 jp _vputs

ChangeLevel:
 ld a,(level)
 inc a
 cp 3
 jr c,checkeasy
 xor a
checkeasy:
 ld (level),a
 call ViewLevel
 jr menuagain

ViewLevel:
 ld a,(level)
 ld hl,256*29+21
 ld (_penCol),hl
 ld hl,easytext
 ld de,5
FindLevelTextLoop:
 or a
 jr z,EndLevelLoop
 add hl,de
 dec a
 jr FindLevelTextLoop
EndLevelLoop:
 jp _vputs

StartGame:
 call LoadGame
MakeGrid:
 call _clrLCD
 call ResetFlags
 ld hl,$fc00
 ld b,10
NewVerticalDotLine:
 push bc
 push hl
 ld de,$20
 ld b,32
 call DoVerticalLine
 pop hl
 inc hl
 pop bc
 djnz NewVerticalDotLine
 ld hl,$fc00
 ld de,$70
 ld b,10
NewHorizontalDotLine:
 push bc
 push hl
 ld b,9
DoHorizontalDotLineLoop:
 ld (hl),%10101010
 inc hl
 djnz DoHorizontalDotLineLoop
 pop hl
 add hl,de
 pop bc
 djnz NewHorizontalDotLine
 ld hl,$fc00
 ld b,4
NewVerticalLine:
 push bc
 push hl
 ld de,$10
 ld b,64
 call DoVerticalLine
 pop hl
 inc hl
 inc hl
 inc hl
 pop bc
 djnz NewVerticalLine
 ld hl,$fc00
 ld de,$150
 ld b,10
NewHorizontalLine:
 push bc
 push hl
 ld b,9
DoHorizontalLineLoop:
 ld (hl),255
 inc hl
 djnz DoHorizontalLineLoop
 pop hl
 add hl,de
 pop bc
 djnz NewHorizontalLine

PlaceAllNumbers:
 ld hl,256*8
 ld (x),hl
NumberPutLoop:
 call GetBoardAddress
 call nz,PutNumber
 ld a,(highlight)
 rrca
 jr nc,SkipHighlight
 call GetBoardAddress
 ld de,81
 add hl,de
 ld a,(hl)
 or a
 call nz,InvertCursorSelection
SkipHighlight:
 ld a,(x)
 inc a
 ld (x),a
 cp 9
 jr nz,NumberPutLoop
 xor a
 ld (x),a
 ld a,(y)
 dec a
 ld (y),a
 inc a
 jr nz,NumberPutLoop
 ld hl,256*4+4
 ld (x),hl
 call InvertCursorSelection
 ld bc,256*52+74
 ld hl,timetext
 call PrintText
 jr DisplayTime
WaitGameKey:
 ld a,(timer1)
 sub 80
 jr nz,checkkeys
 ld (timer1),a
 ld hl,(timer2)
 inc hl
 ld (timer2),hl
DisplayTime:
 ld hl,256*52+95
 ld (_penCol),hl
 ld hl,(timer2)
 call DispHL
checkkeys:
 halt
 call _getky
 or a
 jr z,WaitGameKey
 dec a
 jr z,Down
 dec a
 jp z,Left
 dec a
 jr z,Right
 dec a
 jr z,Up
 cp K_EXIT-4
 jp z,SaveAndQuit
 cp K_DEL-4
 push af
 call z,DeleteNumber
 pop af
 cp K_MORE-4
 call z,GetHints
 cp K_CLEAR-4
 jp z,RestartGame
 sub K_3-4
 jr z,Num3
 dec a
 jr z,Num6
 dec a
 jr z,Num9
 sub 6
 jr z,Num2
 dec a
 jr z,Num5
 dec a
 jr z,Num8
 sub 6
 jr z,Num1
 dec a
 jr z,Num4
 dec a
 jr z,Num7
WaitForKey:
 jr WaitGameKey
Num9:
 inc a
Num8:
 inc a
Num7:
 inc a
Num6:
 inc a
Num5:
 inc a
Num4:
 inc a
Num3:
 inc a
Num2:
 inc a
Num1:
 jr PlaceNumber
Right:
 ld a,(x)
 cp 8
 jr z,WaitGameKey
 call InvertCursorSelection
 ld hl,x
 inc (hl)
 jr EndCursorMove
Down:
 ld a,(y)
 cp 8
 jr z,WaitForKey
 call InvertCursorSelection
 ld hl,y
 inc (hl)
 jr EndCursorMove
Up:
 ld a,(y)
 or a
 jr z,WaitForKey
 call InvertCursorSelection
 ld hl,y
 dec (hl)
 jr EndCursorMove
Left:
 ld a,(x)
 or a
 jr z,WaitForKey
 call InvertCursorSelection
 ld hl,x
 dec (hl)
EndCursorMove:
 call InvertCursorSelection
WaitForKey2:
 jr WaitForKey

PlaceNumber:
 inc a
 ld b,a
 call GetBoardAddress
 ld de,81
 add hl,de
 ld a,(hl)
 or a
 jp nz,WaitGameKey
 ld a,b
 call CheckPossibility
 jp c,WaitGameKey
 call InvertCursorSelection
 call GetBoardAddress
 ld a,b
 ld (hl),a
 call PutNumber
 call InvertCursorSelection
 ld a,(numbers)
 inc a
 ld (numbers),a
 cp 81
 jr nz,WaitForKey2

GameCompleted:
 ld bc,256*38+74
 ld hl,solvetext
 call PrintText
 ld hl,rec4
 ld a,(hintsenabled)
 or a
 jr z,NoHints
 ld hl,rec1
NoHints:
 ld a,(level)
 add a,a
 ld e,a
 ld d,0
 add hl,de
 push hl
 call _ldhlind
 ld a,(timer2+1)
 cp h
 pop hl
 jr z,CheckSmall
 jr nc,NoHighScore
 jr NewHighScore
CheckSmall:
 push hl
 call _ldhlind
 ld a,(timer2)
 cp l
 pop hl
 jr nc,NoHighScore
 jr z,NoHighScore
NewHighScore:
 ld a,(timer2)
 ld (hl),a
 inc hl
 ld a,(timer2+1)
 ld (hl),a
 ld bc,256*45+74
 ld hl,newhighscoretext
 call PrintText
NoHighScore:
 call Wait
 ld a,1
 ld (gameready),a

SaveAndQuit:
 call SaveGame
 jp MenuStart

DeleteNumber:
 call GetBoardAddress
 ret z
 ld de,81
 push hl
 add hl,de
 ld a,(hl)
 or a
 pop hl
 ret nz
 ld (hl),0
 call InvertCursorSelection
 ld a,10
 call PutNumber
 call InvertCursorSelection
 ld hl,numbers
 dec (hl)
 ret

GetHints:
 ld a,(hintsenabled)
 or a
 ret z
 ld hl,256*15+1
 ld (_curRow),hl
 xor a
CheckNumberLoop:
 inc a
 push af
 cp 4
 jr z,IncreaseRow
 cp 7
 jr nz,NoIncreaseRow
IncreaseRow:
 ld hl,(_curRow)
 inc l
 dec h
 dec h
 dec h
 ld (_curRow),hl
NoIncreaseRow:
 call CheckPossibility
 jr c,NotPossible
 pop af
 push af
 add a,48
 call _putc
 jr SkipNotPossible
NotPossible:
 ld a,Lspace
 call _putc
SkipNotPossible:
 call RestoreCursorCoordinates
 pop af
 cp 9
 jr nz,CheckNumberLoop
 ret

SaveGame:
 ld hl,SaveBoardname-1
 rst 20h
 rst 10h
 call nc,_delvar
 ld hl,EndOfData-board
 call _createstrng
 call _ex_ahl_bde
 call _ahl_plus_2_pg3
 call _set_abs_dest_addr
 xor a
 ld hl,board
 call _set_abs_src_addr
 xor a
 ld hl,EndOfData-board
 call _set_mm_num_bytes
 jp _mm_ldir

RestartGame:
 call _clrLCD
 ld bc,256*8
 ld (_penCol),bc
 ld hl,restarttext
 call _vputs
 ld b,2
RestartTextShowLoop:
 call vnewline
 call _vputs
 djnz RestartTextShowLoop
 ld a,2
 ld (sel),a
 call InvertMenuSelect
 ld b,2
 call DoMenu
 dec a
 jr nz,DontRestart
RestartNow:
 ld de,board
 ld hl,PermanentNumbers
 ld bc,81
 ldir
 call SetPermanentNumbers
DontRestart:
 jp MakeGrid

InvertCursorSelection:
 call GetSpriteCoordinates
 ld de,$10
 add hl,de
 ld c,6
InvertCursorSelectionLoop:
 ld a,(hl)
 xor %01111111
 ld (hl),a
 add hl,de
 dec c
 jr nz,InvertCursorSelectionLoop
 ret

GetBoxStartCoordinate:
 or a
 ret z
 cp 3
 ret z
 cp 6
 ret z
 dec a
 jr GetBoxStartCoordinate

GetBoardAddress:
 ld hl,board
 ld a,(x)
 ld e,a
 ld d,0
 add hl,de
 ld a,(y)
 ld e,a
 add a,a
 add a,a
 add a,a
 add a,e
 ld e,a
 add hl,de
 ld a,(hl)
 or a
 ret

GetSpriteCoordinates:
 ld hl,$fc00
 ld a,(x)
 ld e,a
 ld d,0
 add hl,de
 ld de,$70
 ld a,(y)
 or a
 ret z
FindYCoordinate:
 add hl,de
 dec a
 jr nz,FindYCoordinate
 ret

CheckPossibility:
 ld hl,(x)
 ld (temp),hl
 ld b,a
 call GetBoardAddress
 jr nz,CantPlaceHere
HorizontalCheck:
 xor a
 ld (x),a
 call GetBoardAddress
 ld a,b
 push bc
 ld bc,10
 cpir
 ld a,c
 or a
 pop bc
 jr nz,CantPlaceHere
EndOfHorizontalCheck:
 call RestoreCursorCoordinates
VerticalCheck:
 xor a
 ld (y),a
 call GetBoardAddress
 ld de,9
 ld a,b
 ld c,9
VerticalCheckLoop:
 cp (hl)
 jr z,CantPlaceHere
 add hl,de
 dec c
 jr nz,VerticalCheckLoop
EndOfVerticalCheck:
 call RestoreCursorCoordinates
 jr BoxCheck
CantPlaceHere2:
 ld b,a
CantPlaceHere:
 call RestoreCursorCoordinates
 scf
 ret
BoxCheck:
 ld a,(x)
 call GetBoxStartCoordinate
 ld (x),a
 ld a,(y)
 call GetBoxStartCoordinate
 ld (y),a
 call GetBoardAddress
 ld de,6
 ld a,b
 ld b,3
StartBoxCheckLoop:
 ld c,3
BoxCheckLoop:
 cp (hl)
 jr z,CantPlaceHere2
 inc hl
 dec c
 jr nz,BoxCheckLoop
 add hl,de
 djnz StartBoxCheckLoop
 ld b,a
RestoreCursorCoordinates:
 ld hl,(temp)
 ld (x),hl
 ret

DoVerticalLine:
 ld a,(hl)
 or %10000000
 ld (hl),a
 add hl,de
 djnz DoVerticalLine
 ret

PutNumber:
 ld b,a
 ld hl,NumberSprites-6
 ld de,6
FindNumberLoop:
 add hl,de
 djnz FindNumberLoop
 ex de,hl
 push de
 call GetSpriteCoordinates
 pop de
 ld b,6
NumberViewLoop:
 push bc
 ld bc,$10
 add hl,bc
 ld a,(de)
 ld c,a
 res 7,c
 and (hl)
 or c
 ld (hl),a
 inc de
 pop bc
 djnz NumberViewLoop
 ret

GenerateRandomBoard:
 xor a
 ld (y),a
 ld hl,board
 ld b,162
 call _ldhlz
 ld hl,256*14+3
 ld (_curRow),hl
GenerateLoop:
 inc b
 xor a
 ld (err),a
TryAgain:
 call Random
 ld (x),a
 ld a,b
 call CheckPossibility
 jr c,cantdo
 call GetBoardAddress
 ld a,b
 ld (hl),a
 cp 9
 jr nz,GenerateLoop
 ld a,(y)
 inc a
 ld (y),a
 cp 9
 jr z,EndGen
ResetRow:
 call _getky
 or a
 jr z,NoKeyPressed
 call GetWantedKey
 jp CheckKeyPress
NoKeyPressed:
 xor a
 ld (x),a
 call GetBoardAddress
 ld b,9
 call _ldhlz
 jr GenerateLoop

cantdo:
 ld a,(err)
 inc a
 ld (err),a
 cp 30
 jr nz,TryAgain
 jr ResetRow

EndGen:
 ld a,(level)
 ld b,a
 ld a,4
 add a,b
 ld b,a
 jr JumpLoop
DeleteNumbersLoop:
 call Random
 ld (x),a
 call GetBoardAddress
 jr z,DeleteNumbersLoop
 ld (hl),0
 ld a,(numbers)
 inc a
 ld (numbers),a
 cp b
 jr nz,DeleteNumbersLoop
JumpLoop:
 xor a
 ld (numbers),a
 ld a,(y)
 dec a
 ld (y),a
 inc a
 jr nz,DeleteNumbersLoop
EndDelete:
 xor a
 ld (gameready),a
 call SetPermanentNumbers
 ld hl,0
 ld (timer2),hl
 xor a
 ld (timer1),a
 jp MakeGrid

Random:        ; Creates a pseudorandom number 0 <= x < 9
 push bc
 ld b,9
 ld hl,(randseed)
 ld a,l
 xor h
 ld l,a
 ld a,h
 xor l
 ld h,a
 ld a,r
 add a,h
 ld h,a
 ld (randseed),hl
 ld hl,0
 ld d,0
 ld e,a
RMul:
 add hl,de
 djnz RMul
 ld a,h
 pop bc
 ret

SetPermanentNumbers:
 xor a
 ld (numbers),a
 ld hl,board
 ld de,PermanentNumbers
 ld bc,81
 ldir
 ld b,81
SetPermanentNumbersLoop:
 dec de
 ld a,(de)
 or a
 jr z,NoNumber
 ld hl,numbers
 inc (hl)
NoNumber:
 djnz SetPermanentNumbersLoop
 ret

ResetFlags:
 res textInverse,(iy+textflags)
 res onInterrupt,(iy+onflags)
 ret

QuitGame:
 call ResetFlags
 call _homeup
 im 1
 set graphdraw,(iy+graphflags)
 jp _clrScrn

InterruptHandler:
 ex af,af'
 ld a,(timer1)
 dec a
 ld (timer1),a
 ld a,($c1b4)
 cp $1d
 jr c,int_ok
 cp $20
 jr nc,int_ok
 im 1
 jp $39
int_ok:
 in a,(3)
 bit 3,a
 jp z,$39
 res 0,a
 out (3),a
 jp $39
InterruptHandlerEnd:

DoMenu:
WaitMenuKey:
 push bc
 halt
 call _getky
 pop bc
GetWantedKey:
 dec a
 call z,ScrollMenuDown
 cp 3
 call z,ScrollMenuUp
 cp K_ENTER-1
 jr z,CheckOption
 cp K_SECOND-1
 jr z,CheckOption
 cp K_EXIT-1
 ret z
 jr WaitMenuKey

CheckOption:
 ld a,(sel)
 ret

InvertMenuSelect:
 ld hl,$fc80
 ld de,$70
 ld a,(sel)
FindBarPosition:
 add hl,de
 dec a
 jr nz,FindBarPosition
 ld c,112
InvertMenuSelectLoop:
 ld a,(hl)
 cpl
 ld (hl),a
 inc hl
 dec c
 jr nz,InvertMenuSelectLoop
 ret

ScrollMenuUp:
 ld a,(gameready)
 ld c,a
 ld a,(sel)
 sub c
 dec a
 ret z
 call InvertMenuSelect
 ld hl,sel
 dec (hl)
 jr EndScroll

ScrollMenuDown:
 ld a,(sel)
 cp b
 ret z
 call InvertMenuSelect
 ld hl,sel
 inc (hl)
EndScroll:
 jp InvertMenuSelect

Wait:
 halt
 call _getky
 or a
 jr z,Wait
 ret

vnewline:
 xor a
 ld (_penCol),a
NewRow:
 ld a,(_penRow)
 add a,7
 ld (_penRow),a
 ret

ViewHighScores:
 call ResetFlags
 call _clrLCD
 ld hl,leveltext
 call PrintText
 ld a,87
 ld (_penCol),a
 ld hl,timetext
 call _vputs
 ld hl,easytext
 ld b,6
ViewSkillLevels:
 call vnewline
 call _vputs
 ld a,Lcomma
 call _vputmap
 push hl
 ld a,b
 cp 4
 jr nz,noagain
 pop hl
 ld hl,easytext
 push hl
noagain:
 cp 4
 jr nc,skipno
 ld hl,notext
 call _vputs
skipno:
 ld hl,hintsenabledtext
 call _vputs
 pop hl
 djnz ViewSkillLevels
 ld bc,256*7+87
 ld (_penCol),bc
 ld b,6
 ld hl,rec1
ShowTimes:
 push hl
 call _ldhlind
 inc hl
 ld a,h
 or l
 jr nz,DisplayTimeNow
 ld hl,nonetext
 call _vputs
 jr DoneDisplaying
DisplayTimeNow:
 dec hl
 call DispHL
DoneDisplaying:
 pop hl
 inc hl
 inc hl
 call NewRow
 ld a,87
 ld (_penCol),a
 djnz ShowTimes
 call Wait
 jp MenuStart

PrintText:
 ld (_penCol),bc
 jp _vputs

LoadGame:
 ld hl,SaveBoardname-1
 rst 20h
 rst 10h
 jr c,Initialize
 call _ex_ahl_bde
 call _ahl_plus_2_pg3
 call _set_abs_src_addr
 xor a
 ld hl,board
 call _set_abs_dest_addr
 xor a
 ld hl,EndOfData-board
 call _set_mm_num_bytes
 jp _mm_ldir

Initialize:
 ld hl,board
 ld b,rec1-board
 call _ldhlz
 ld a,1
 ld (gameready),a
 ld b,12
 ld hl,rec1
ScoreResetLoop:
 ld (hl),255
 inc hl
 djnz ScoreResetLoop
 ld hl,$d2a2
 ld (randseed),hl
 ret

NumberSprites:
 .db %10001000
 .db %10011000
 .db %10001000
 .db %10001000
 .db %10001000
 .db %10011100

 .db %10011000
 .db %10100100
 .db %10001000
 .db %10010000
 .db %10100000
 .db %10111100

 .db %10011000
 .db %10000100
 .db %10001000
 .db %10000100
 .db %10011000
 .db %10000000

 .db %10100000
 .db %10100100
 .db %10111100
 .db %10000100
 .db %10000100
 .db %10000100

 .db %10111100
 .db %10100000
 .db %10111000
 .db %10000100
 .db %10000100
 .db %10111000

 .db %10011100
 .db %10100000
 .db %10111000
 .db %10100100
 .db %10100100
 .db %10011000

 .db %10111100
 .db %10000100
 .db %10000100
 .db %10001000
 .db %10001000
 .db %10010000

 .db %10111100
 .db %10100100
 .db %10111100
 .db %10100100
 .db %10100100
 .db %10111100

 .db %10011000
 .db %10100100
 .db %10100100
 .db %10011100
 .db %10000100
 .db %10111000

 .db %10000000
 .db %10000000
 .db %10000000
 .db %10000000
 .db %10000000
 .db %10000000

SaveBoardname: .db 4,0,"sud"

DispHL:
 xor a
 ld de,-1
 ld (_curRow),de
 call $4a33
 dec hl
 jp _vputs

continuetext: .db "Continue",0
generateboardtext: .db "New game",0
leveltext: .db "Level:",0
hintsenabledtext: .db "Hints:",0
highlighttext: .db "Highlight given numbers:",0
besttimestext: .db "Best times",0
restarttext: .db "Restart game?",0
yestext: .db "Yes",0
notext: .db "No ",0
easytext: .db "Easy",0
normaltext: .db "Med.",0
hardtext: .db "Hard",0
nonetext: .db "None",0
timetext: .db "Time:",0
solvetext: .db "Solved!",0
newhighscoretext: .db "Best time!",0
ProgramEnd:
err = ProgramEnd
sel = ProgramEnd+1
temp = ProgramEnd+2
x = ProgramEnd+4
y = ProgramEnd+5
highlight = ProgramEnd+6
.end