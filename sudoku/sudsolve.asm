#include "ti86.inc"
.org _asm_exec_ram
_ldhlz = $437B

board = _plotSScreen+81

;.plugin lite86
 nop
 jp ProgStart
 .dw 0
 .dw ShellTitle
ShellTitle:
 .db "Sudoku solver v1.0",0

ProgStart:
 call _runindicoff
 call _flushallmenus
 call _clrLCD
 ld bc,34
 ld hl,ShellTitle
 call PrintText
 call vnewline
 call vnewline
 ld hl,newboardtxt
 call _vputs
 call vnewline
 call _vputs
WaitMenuKey:
 halt
 call _getky
 cp K_EXIT
 jp z,Quit
 cp K_F1
 jr z,NewBoard
 cp K_F2
 jr nz,WaitMenuKey
OpenBoard:
 ld hl,SaveBoardname-1
 rst 20h
 rst 10h
 jr c,NewBoard
 call _ex_ahl_bde
 call _ahl_plus_2_pg3
 call _set_abs_src_addr
 xor a
 ld hl,_plotSScreen
 call _set_abs_dest_addr
 xor a
 ld hl,162
 call _set_mm_num_bytes
 call _mm_ldir
 jr MakeGrid
NewBoard:
 call ClearBoard
MakeGrid:
 call _clrLCD
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
 ld a,(hl)
 or a
 call nz,PutNumber
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
 ld hl,entertosolvetxt
 ld bc,256*57+78
 call PrintText
WaitGameKey:
 halt
 call _getky
 dec a
 jr z,Down
 dec a
 jp z,Left
 dec a
 jr z,Right
 dec a
 jr z,Up
 cp K_EXIT-4
 jp z,ProgStart
 cp K_DEL-4
 push af
 call z,DeleteNumber
 pop af
 cp K_CLEAR-4
 jp z,NewBoard
 cp K_ENTER-4
 jp z,SolveBoard
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
 inc a
 call PlaceNumber
 jr WaitGameKey
Right:
 ld a,(x)
 cp 8
 jr z,WaitGameKey
 call InvertCursorSelection
 ld hl,x
 inc (hl)
 call InvertCursorSelection
WaitForKey:
 jr WaitGameKey
Down:
 ld a,(y)
 cp 8
 jr z,WaitForKey
 call InvertCursorSelection
 ld hl,y
 inc (hl)
 call InvertCursorSelection
 jr WaitForKey
Up:
 ld a,(y)
 or a
 jr z,WaitForKey
 call InvertCursorSelection
 ld hl,y
 dec (hl)
 call InvertCursorSelection
 jr WaitForKey
Left:
 ld a,(x)
 or a
 jr z,WaitForKey
 call InvertCursorSelection
 ld hl,x
 dec (hl)
 call InvertCursorSelection
 jr WaitForKey

PlaceNumber:
 ld b,a
 call GetBoardAddress
 ld a,b
 call CheckPossibility
 ret c
 call GetBoardAddress
 ld a,b
 ld (hl),a
 call PutNumber
 call InvertCursorSelection
 ld hl,numbers
 inc (hl)
 ret

DeleteNumber:
 call GetBoardAddress
 ld a,(hl)
 or a
 ret z
 ld (hl),0
 call InvertCursorSelection
 ld a,10
 call PutNumber
 call InvertCursorSelection
 ld hl,numbers
 dec (hl)
 ret

CheckPossibleMoves:
 xor a
 ld (numpossibles),a
 ld (onlypossible),a
CheckNumberLoop:
 inc a
 push af
 call CheckPossibility
 jr c,Done
 pop af
 push af
 ld a,(numpossibles)
 inc a
 ld (numpossibles),a
 dec a
 jr z,OnlyPoss
 xor a
 ld (onlypossible),a
 jr Done
OnlyPoss:
 pop af
 ld (onlypossible),a
 push af
Done:
 call RestoreCursorCoordinates
 pop af
 cp 9
 jr nz,CheckNumberLoop
 ret

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
checky:
 ld a,(y)
 or a
 ret z
 ld de,9
yloop:
 add hl,de
 dec a
 jr nz,yloop
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
 ld a,(hl)
 or a
 jr nz,CantPlaceHere
HorizontalCheck:
 xor a
 ld (x),a
 call GetBoardAddress
 ld a,b
 ld d,a
 ld bc,10
 cpir
 ld a,c
 or a
 ld b,d
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
 jp nz,VerticalCheckLoop        ;for speed
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
 jp nz,BoxCheckLoop        ;for speed
 add hl,de
 djnz StartBoxCheckLoop
 ld b,a
RestoreCursorCoordinates:
 ld hl,(temp)
 ld (x),hl
 ret

DoVerticalLine:
DoVerticalLineLoop:
 ld a,(hl)
 or %10000000
 ld (hl),a
 add hl,de
 djnz DoVerticalLineLoop
 ret

PutNumber:
 ld b,a
 ld hl,number1-6
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

SolveBoard:
CheckOnlyPossibles:
 ld hl,0
 ld (x),hl
 xor a
 ld (numssolved),a
CheckOnlyPossiblesLoop:
 call CheckPossibleMoves
 ld a,(onlypossible)
 or a
 jr z,SkipPlaceNumber
 call PlaceNumber
 ld hl,numssolved
 inc (hl)
SkipPlaceNumber:
 ld a,(x)
 inc a
 ld (x),a
 sub 9
 jr c,CheckOnlyPossiblesLoop
 ld (x),a
 ld a,(y)
 inc a
 ld (y),a
 cp 9
 jr c,CheckOnlyPossiblesLoop
 ld a,(numssolved)
 or a
 jr nz,CheckOnlyPossibles

CheckOnlyRowPlaces:
 xor a
 ld (numssolved),a
 ld (numtosolve),a
 ld (y),a
CheckOnlyPlacesRowloop:
 ld hl,numtosolve
 inc (hl)
 call CheckHorizontalPlaces
 ld a,(numpossibles)
 dec a
 jp nz,NotOnlyPlace
 ld hl,(onlypossiblecoords)
 ld (x),hl
 ld a,(numtosolve)
 call PlaceNumber
 ld hl,numssolved
 inc (hl)
NotOnlyPlace:
 ld a,(numtosolve)
 cp 9
 jr c,CheckOnlyPlacesRowloop
 xor a
 ld (numtosolve),a
 ld a,(y)
 inc a
 ld (y),a
 cp 9
 jr c,CheckOnlyPlacesRowloop
 ld a,(numssolved)
 or a
 jp nz,CheckOnlyPossibles

CheckOnlyVertPlaces:
 xor a
 ld (numssolved),a
 ld (numtosolve),a
 ld (x),a
CheckOnlyPlacesVertloop:
 ld hl,numtosolve
 inc (hl)
 call CheckVerticalPlaces
 ld a,(numpossibles)
 dec a
 jp nz,NotOnlyPlace2
 ld hl,(onlypossiblecoords)
 ld (x),hl
 ld a,(numtosolve)
 call PlaceNumber
 ld hl,numssolved
 inc (hl)
NotOnlyPlace2:
 ld a,(numtosolve)
 cp 9
 jr c,CheckOnlyPlacesVertloop
 xor a
 ld (numtosolve),a
 ld a,(x)
 inc a
 ld (x),a
 cp 9
 jr c,CheckOnlyPlacesVertloop
 ld a,(numssolved)
 or a
 jp nz,CheckOnlyPossibles

CheckOnlyBoxPlaces:
 xor a
 ld (numssolved),a
 ld (numtosolve),a
 ld (x),a
 ld (y),a
CheckOnlyBoxPlacesloop:
 ld hl,numtosolve
 inc (hl)
 call CheckBoxPlaces
 ld a,(numpossibles)
 dec a
 jp nz,NotOnlyPlace3
 ld hl,(onlypossiblecoords)
 ld (x),hl
 ld a,(numtosolve)
 call PlaceNumber
 ld hl,numssolved
 inc (hl)
NotOnlyPlace3:
 ld hl,(err)
 ld (x),hl
 ld a,(numtosolve)
 cp 9
 jr c,CheckOnlyBoxPlacesloop
 xor a
 ld (numtosolve),a
 ld a,(x)
 add a,3
 ld (x),a
 sub 9
 jr nz,CheckOnlyBoxPlacesloop
 ld (x),a
 ld a,(y)
 add a,3
 ld (y),a
 cp 9
 jr nz,CheckOnlyBoxPlacesloop
 ld a,(numssolved)
 or a
 jp nz,CheckOnlyPossibles
 jp MakeGrid

CheckBoxPlaces:
 xor a
 ld (numpossibles),a
 ld hl,(x)
 ld (err),hl
 ld b,3
rowloop:
 push bc
 ld b,3
columnloop:
 push bc
 ld a,(numtosolve)
 call CheckPossibility
 jp c,NotPossible3
 ld a,(numpossibles)
 inc a
 ld (numpossibles),a
 cp 2
 jr z,done2
 call RestoreCursorCoordinates
 ld hl,(x)
 ld (onlypossiblecoords),hl
NotPossible3:
 call RestoreCursorCoordinates
 ld hl,x
 inc (hl)
 pop bc
 djnz columnloop
 ld a,(x)
 sub 3
 ld (x),a
 ld hl,y
 inc (hl)
 pop bc
 djnz rowloop
 ret
done2:
 pop bc
 pop bc
 ret

CheckHorizontalPlaces:
 xor a
 ld (x),a
 ld (numpossibles),a
CheckHorizontalPlacesloop:
 ld a,(numtosolve)
 call CheckPossibility
 jp c,NotPossible
 ld a,(numpossibles)
 inc a
 ld (numpossibles),a
 cp 2
 ret z
 call RestoreCursorCoordinates
 ld hl,(x)
 ld (onlypossiblecoords),hl
NotPossible:
 call RestoreCursorCoordinates
 ld a,(x)
 inc a
 ld (x),a
 cp 9
 jp c,CheckHorizontalPlacesloop
 ret

CheckVerticalPlaces:
 xor a
 ld (y),a
 ld (numpossibles),a
CheckVerticalPlacesloop:
 ld a,(numtosolve)
 call CheckPossibility
 jp c,NotPossible2
 ld a,(numpossibles)
 inc a
 ld (numpossibles),a
 cp 2
 ret z
 call RestoreCursorCoordinates
 ld hl,(x)
 ld (onlypossiblecoords),hl
NotPossible2:
 call RestoreCursorCoordinates
 ld a,(y)
 inc a
 ld (y),a
 cp 9
 jp c,CheckVerticalPlacesloop
 ret

QuitGame:
 res textInverse,(iy+textflags)
 res onInterrupt,(iy+onflags)
 set graphdraw,(iy+graphflags)
 call _homeup
 jp _clrScrn

vnewline:
 xor a
 ld (_penCol),a
NewRow:
 ld a,(_penRow)
 add a,7
 ld (_penRow),a
 ret

PrintText:
 ld (_penCol),bc
 jp _vputs

Quit:
 call _homeup
 jp _clrScrn

ClearBoard:
 ld hl,board
 ld b,81
 call _ldhlz
 ret

number1:
 .db %10001000
 .db %10011000
 .db %10001000
 .db %10001000
 .db %10001000
 .db %10011100

number2:
 .db %10011000
 .db %10100100
 .db %10001000
 .db %10010000
 .db %10100000
 .db %10111100

number3:
 .db %10011000
 .db %10000100
 .db %10001000
 .db %10000100
 .db %10011000
 .db %10000000

number4:
 .db %10100000
 .db %10100100
 .db %10111100
 .db %10000100
 .db %10000100
 .db %10000100

number5:
 .db %10111100
 .db %10100000
 .db %10111000
 .db %10000100
 .db %10000100
 .db %10111000

number6:
 .db %10011100
 .db %10100000
 .db %10111000
 .db %10100100
 .db %10100100
 .db %10011000

number7:
 .db %10111100
 .db %10000100
 .db %10000100
 .db %10001000
 .db %10001000
 .db %10010000

number8:
 .db %10111100
 .db %10100100
 .db %10111100
 .db %10100100
 .db %10100100
 .db %10111100

number9:
 .db %10011000
 .db %10100100
 .db %10100100
 .db %10011100
 .db %10000100
 .db %10111000

empty:
 .db %10000000
 .db %10000000
 .db %10000000
 .db %10000000
 .db %10000000
 .db %10000000

SaveBoardname: .db 4,0,"sud"

;dispa:
; ld l,a
; ld h,0
; xor a
; ld bc,100
; ld (_penCol),bc
; jp $4a33

newboardtxt: .db "F1 - New board",0
openboardtxt: .db "F2 - Get board from Sudoku",0
entertosolvetxt: .db "ENTER - solve",0
ProgramEnd:
err = ProgramEnd
sel = ProgramEnd+1
temp = ProgramEnd+2
x = ProgramEnd+4
y = ProgramEnd+5
numbers = ProgramEnd+7
numpossibles = ProgramEnd+8
onlypossible = ProgramEnd+9
numssolved = ProgramEnd+10
numtosolve = ProgramEnd+11
onlypossiblecoords = ProgramEnd+12
 .end
