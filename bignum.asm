#include "ti86.inc"
_dispAHL          equ	4a33h
.org _asm_exec_ram
 nop
 jp ProgStart
 .dw 0
 .dw ShellTitle
ShellTitle:
 .db "Bignum 86",0
;NOTES:
;Numbers are stored backwards into memory (except the number that user is typing)
;Sign is stored into the end of the number (like 932686-) which means -686239
;Sign's value: 26 = $1a
;Three points indicate that the number continues outside the screen (value: 206 = $ce)
;Decimal point is used only in short view mode (value: $2e)
;Exponent letter's value: $1b

;Things that should be done:
;Fast number scrolling
;Set TempNumber max length
;Memory check during math operations?
_putcDirect =$3fb6
_cphldeDirect =$0107

ProgStart:
 call _clrScrn
 call _homeup
 call _runindicoff
 call _flushallmenus

;Initialize number areas
 ld hl,$80ff
 ld de,$8100
 ld bc,$bff4-$80ff
 ld (hl),20
 ldir
 ld hl,TempNumber
 ld de,TempNumber+1
 ld bc,$fa70-TempNumber+1
 ld (hl),20
 ldir

;Initialize variables
 ld hl,VariableStart
 ld (hl),0
 ld de,VariableStart+1
 ld bc,VariableEnd-VariableStart-1
 ldir
 ld a,1
 ld (Select),a

 ld hl,Number1Txt
 call _puts
 call _newline
 call _puts
 ld bc,6
 ld (_curRow),bc
 call _put_colon
 jp ChangeSelect
WaitKey:
 halt
 call _getky
 or a
 jp z,WaitKey
 cp K_LEFT
 jp z,ScrollBackwards
 cp K_RIGHT
 jp z,ScrollForwards
 cp K_SIGN
 jp z,PutMinus
 cp K_DEL
 jp z,DeleteOneNumber
 cp K_CLEAR
 jp z,ClearNumber
 cp K_SECOND
 jp z,SwapNumbers
 cp K_EE
 jp z,ChangeView
 cp K_UP
 jp z,ChangeSelect
 cp K_DOWN
 jp z,ChangeSelect
 cp K_ENTER
 jp z,SaveNumber
 cp K_MORE
 jp z,ViewVars    ;Temporary
 cp K_EXIT
 jp z,Quit

;Operations
 cp K_SQUARE
 jp z,Square
 cp K_F1
 jp z,SquareRoot
 cp K_F2
 jp z,Factorial
 cp K_F5
 jp z,CheckPrimeNumber

;These operations need 2 arguments
 cp K_PLUS
 jp z,Addition
 cp K_MINUS
 jp z,Subtraction
 cp K_STAR
 jp z,Multiplication
 cp K_SLASH
 jp z,Division
 cp K_RAISE
 jp z,Raise
 cp K_F3
 jp z,Combination
 cp K_F4
 jp z,Variation
 cp $25
 jp nc,WaitKey
 ld hl,NumberTable-$12
 ld e,a
 ld d,0
 add hl,de
 ld a,(hl)
 cp 20
 jp z,WaitKey
 or a
 ld c,a
 call z,CheckOnlySign
 jp c,WaitKey
 call CheckOnlyZero
 jp c,WaitKey
 call ITNLandGetTempNumberAddress
;Perform memory check before saving the digit
 ld a,h
 cp $fa
 jr nz,SaveDigit
 ld a,l
 cp $6f
 jr nz,SaveDigit
 call MemoryError
 jp WaitKey
SaveDigit:
 ld (hl),c
 jr UpdateTempNumberView

ITNLandGetTempNumberAddress:
 call IncTempNumberLength
 ld hl,TempNumber
 add hl,de
ResCarry:
 or a
 ret

IncTempNumberLength:
 ld de,(TempNumberLength)
 inc de
 ld (TempNumberLength),de
 dec de
 ret

MemoryError:
 ld bc,7
 push bc
 ld (_curRow),bc
 ld hl,MemErrTxt
 call _puts
 call Wait2
 pop bc
 ld (_curRow),bc
 jp _eraseEOL

CheckOnlySign:
 ld hl,(TempNumberLength)
 ld de,1
 call _cphldeDirect
 jr nz,ResCarry
;If only one character, it must not be -
 ld a,(TempNumber)
 cp 26
 jp z,SetCarry
 or a
 ret

CheckOnlyZero:
 ld a,(TempNumber)
 or a
 jp z,SetCarry
 ret

UpdateTempNumberView:
;Check how long TempNumber is (if >19: Show "..." and last digits, if <=19: Show all numbers)
 ld bc,256*1+6
 ld (_curRow),bc
 ld hl,(TempNumberLength)
 ld de,20
 call _cphldeDirect
 jr nc,ShowLast18
ShowAll:
 ld hl,TempNumber
 jr StartTempNumberDisplay
ShowLast18:
 ld a,$ce
 call _putcDirect
 ld a,20
 ld hl,TempNumber-18
 ld de,(TempNumberLength)
 add hl,de
StartTempNumberDisplay:
 ld b,'0'
 ld c,20+'0'
 ld e,26
 ld ix,TempNumberDisplayLoop
TempNumberDisplayLoop:
 ld a,(hl)
 cp e
 jp z,SkipAdd
 add a,b
 cp c
 jp z,EndTempNumberDisplay
SkipAdd:
 call _putcDirect
 inc hl
 jp (ix)
EndTempNumberDisplay:
 call _eraseEOL
 jp WaitKey

SwapNumbers:
;Swap signs
 ld a,(Signs)
 dec a
 jr z,Set2
 dec a
 jr nz,NoSignsChange
Set1:
 inc a
 jr SetSigns
Set2:
 ld a,2
SetSigns:
 ld (Signs),a
NoSignsChange:
;If + and + or - and -, don't have to do anything
;Now swap the actual numbers. 3 different reverses are needed.
;Make sure first that there are 2 numbers
 ld a,(Arguments)
 cp 2
 jp nz,WaitKey
 call FindNumber2End
;HL is at the last digit of Number2 (can be sign too)
 ld de,NumberStart
 call ReverseDEHL
;Now reverse the numbers separately, the result is: numbers swapped!
 call FindNumber1End
 push hl
 dec hl
 dec hl
 ld de,NumberStart
 call ReverseDEHL
 pop hl
 inc hl
 ex de,hl
 call FindNumber2End
 call ReverseDEHL
;Done! Now reset the number view pointer and update view
 call FindNumber1End
 dec hl
 dec hl
 ld (Number1End),hl
 ld (Number1Ptr),hl
 call FindNumber2End
 ld (Number2End),hl
 ld (Number2Ptr),hl
 call ClearLinesNotTempNumber
 call UpdateNumber1View
 call UpdateNumber2View
 jp WaitKey

;OUT: HL is two bytes after the end of Number1
FindNumber1End:
 ld b,-1
 ld hl,NumberStart
 ld a,20
 cpir
 ret

;OUT: HL is at the last byte of Number2
FindNumber2End:
 ld b,-1
 call FindNumber1End
 inc hl
 cpir
 dec hl
 dec hl
 ret

;OUT - HL is at the last byte of TempNumber
FindTempNumberEnd:
 ld b,-1
 ld hl,TempNumber
 ld a,20
 cpir
 dec hl
 dec hl
 ret

;Reverses the data string between DE and HL, always DE<HL
ReverseDEHL:
 or a
 ld ix,ReverseLoop
 ld c,3
ReverseLoop:
 ld a,(de)
 ld b,a
 ld a,(hl)
 ld (de),a
 ld (hl),b
 push hl
 sbc hl,de
 ld a,h
 or a
 jp nz,Continue
 ld a,l
 cp c
 jp c,EndReverse
Continue:
 pop hl
 inc de
 dec hl
 jp (ix)
EndReverse:
 pop hl
 ret

SaveNumber:
;Check if the TempNumber is valid
 ld hl,(TempNumberLength)
 ld de,0
 call _cphldeDirect
 jp z,WaitKey
 inc de
 call _cphldeDirect
 jr nz,SkipOnlySignCheck
;If length is 1, must check that it's not sign
 ld a,(TempNumber)
 cp 26
 jp z,WaitKey
SkipOnlySignCheck:
;Now check if TempNumber becomes Number1 or Number2
 ld a,(Arguments)
 or a
 jr z,SaveAsNumber1
 call ClearNumber2
 ld a,(TempNumberSign)
 add a,a
 ld b,a
 ld a,(Signs)
 add a,b
 ld (Signs),a
 ld a,2
 ld (Arguments),a
 call FindNumber1End
 inc hl  ;Leave 2 bytes between numbers
 ex de,hl
 jr SaveAsNumber2
SaveAsNumber1:
 inc a
 ld (Arguments),a
 ld a,(TempNumberSign)
 ld (Signs),a
 ld de,NumberStart
SaveAsNumber2:
;Copy number backwards to NumberStart area
 call FindTempNumberEnd
 ld b,d
 ld c,e
 ld de,TempNumber-1
NumberCopyBackwardsLoop:
 ld a,(hl)
 ld (bc),a
 dec hl
 inc bc
 ld a,b
;Perform memory check
 cp $bf
 jp nz,ContinueCopying
 ld a,c
 cp $f4
 jp z,ErrorDuringCopy
ContinueCopying:
 push hl
 or a
 sbc hl,de
 pop hl
 jp nz,NumberCopyBackwardsLoop
 jr NoErrorDuringCopy
ErrorDuringCopy:
 call MemoryError
 jp Quit
NoErrorDuringCopy:
;Copy done, clear TempNumber and update views
 call ClearTempNumber
 call ClearLines
 call FindNumber1End
 dec hl
 dec hl
 ld (Number1End),hl
 ld (Number1Ptr),hl
 call UpdateNumber1View
 ld a,(Arguments)
 dec a
 jp z,UpdateTempNumberView
 call FindNumber2End
 ld (Number2End),hl
 ld (Number2Ptr),hl
 call UpdateNumber2View
 jp UpdateTempNumberView

ClearLines:
 ld bc,256*1+6
 ld (_curRow),bc
 call _eraseEOL
ClearLinesNotTempNumber:
 ld bc,256*2
 ld (_curRow),bc
 call _eraseEOL
ClearNumber2Line:
 ld bc,256*2+1
 ld (_curRow),bc
 jp _eraseEOL

PutMinus:
;TempNumberLength must be 0 if you want to type the sign
 ld hl,(TempNumberLength)
 ld a,h
 or l
 jp nz,WaitKey
 call ITNLandGetTempNumberAddress
 ld (hl),26
 ld a,1
 ld (TempNumberSign),a
 jp UpdateTempNumberView

ClearTempNumber:
 xor a
 ld (TempNumberSign),a
 ld h,a
 ld l,a
 ld (TempNumberLength),hl
 ld hl,TempNumber
ClearNumberNow:
 ld a,20
ClearNumberLoop:
 ld (hl),a
 inc hl
 cp (hl)
 jp nz,ClearNumberLoop
 ret

ClearNumber2:
 ld a,(Signs)
 bit 1,a
 jr z,Number2IsPlus
 sub 2
 ld (Signs),a
Number2IsPlus:
 call FindNumber1End
 inc hl   ;If there are 3 bytes between numbers (after addition/subtraction), this is necessary
 jr ClearNumberNow

ClearNumber1:
 xor a
 ld (Signs),a
Number1IsPlus:
 ld hl,NumberStart
 jr ClearNumberNow


DeleteOneNumber:
;Length must not be 0
 ld hl,(TempNumberLength)
 ld a,h
 or l
 jp z,WaitKey
 call FindTempNumberEnd
 ld (hl),20
 ld hl,(TempNumberLength)
 dec hl
 ld (TempNumberLength),hl
;If length is now zero, there must be no sign
 ld a,h
 or l
 jr nz,LengthNot0
 xor a
 ld (TempNumberSign),a
LengthNot0:
 jp UpdateTempNumberView

ChangeSelect:
 ld hl,Inv1+3
 ld ix,Inv2+3
 ld b,$c6+(8*textInverse)
 ld c,$86+(8*textInverse)
 ld a,(Select)
 xor 1
 ld (Select),a
 jr z,SetSelect1
 ld b,$86+(8*textInverse)
 ld c,$c6+(8*textInverse)
SetSelect1:
 ld (hl),b
 ld (ix),c
 ld bc,(_curRow)
 push bc
 ld bc,256
 ld (_curRow),bc
 ld a,':'
Inv1:
 res textInverse,(iy+textflags)
 call _putmap
Inv2:
 set textInverse,(iy+textflags)
 ld bc,256+1
 ld (_curRow),bc
 call _putmap
 pop bc
 ld (_curRow),bc
 res textInverse,(iy+textflags)
 jp WaitKey

ScrollCheck:
 ld a,(View) ;If view mode is 1 (short), scrolling isn't necessary
 dec a
 jr nz,CheckOthers
SetCarry:
 scf
 ret
CheckOthers:
 ld a,(Select)
 or a
 jr nz,ScrollNumber2Check
 ld a,(Arguments) ;If no numbers, can't scroll
 cp 1
 ret
ScrollNumber2Check:
 ld a,(Arguments) ;If number 2 is selected but there's no number 2, can't scroll
 cp 2
 ret

ScrollBackwards:
 call ScrollCheck
 jp c,WaitKey
 ld a,(Select)
 or a
 jr nz,ScrollBackwardsNumber2
;Check if number1's pointer is already in the end
 ld hl,(Number1End)
 ld de,(Number1Ptr)
 call _cphldeDirect
 jp z,WaitKey
 ld hl,(Number1Ptr)
 inc hl   ;inc because because numbers are stored backwards!
 ld (Number1Ptr),hl
 call UpdateNumber1View
 jp WaitKey
ScrollBackwardsNumber2:
 ld hl,(Number2End)
 ld de,(Number2Ptr)
 call _cphldeDirect
 jp z,WaitKey
 ld hl,(Number2Ptr)
 inc hl
 ld (Number2Ptr),hl
 call UpdateNumber2View
 jp WaitKey

ScrollForwards:
 call ScrollCheck
 jp c,WaitKey
 ld a,(Select)
 or a
 jr nz,ScrollForwardsNumber2
 ld hl,(Number1Ptr)
 ld de,NumberStart
 sbc hl,de
 ld de,18
 call _cphldeDirect
 jp c,WaitKey
 ld hl,(Number1Ptr)
 dec hl
 ld (Number1Ptr),hl
 call UpdateNumber1View
 jp WaitKey
ScrollForwardsNumber2:
 call FindNumber1End
 inc hl
 ex de,hl   ;DE is start of number 2
 ld hl,(Number2Ptr)
 or a
 sbc hl,de
 ld de,18
 call _cphldeDirect
 jp c,WaitKey
 ld hl,(Number2Ptr)
 dec hl
 ld (Number2Ptr),hl
 call UpdateNumber2View
 jp WaitKey

UpdateNumber1Short:
;View number 1
 ld a,(Arguments)
 or a
 ret z
 call ClearLinesNotTempNumber
 ld bc,256*3
 ld (_curRow),bc
 ld hl,NumberStart
 ld (DS2+1),hl
 inc hl
 inc hl
 ld (DS1+1),hl
 ld hl,FindNumber1EndWithoutSign
 ld (DS3+2),hl
 ld (DS4+1),hl
 ld hl,(Number1End)
 jr ViewNumberShortNow

UpdateNumber2Short:
;View number 2
 ld a,(Arguments)
 cp 2
 ret nz
 ld bc,256*3+1
 ld (_curRow),bc
 call FindNumber1End
 inc hl
 ld (DS2+1),hl
 inc hl
 inc hl
 ld (DS1+1),hl
 ld hl,FindNumber2EndWithoutSign
 ld (DS3+2),hl
 ld (DS4+1),hl
 ld hl,(Number2End)

ViewNumberShortNow: ;Displays number1 or number2 in short
 inc hl
DisplayOneMore:
 dec hl
 ld a,(hl)
 cp 10
 jr nc,$+4
 add a,'0'
 call _putcDirect
 cp 26
 jr z,DisplayOneMore
DS3:
 push hl
 call FindNumber1EndWithoutSign ;Modified
DS1:
 ld de,NumberStart  ;Modified
 or a
 sbc hl,de
 pop hl
 jr c,DisplayExponent
 ld a,'.'
 call _putcDirect
 dec hl
 ld c,'0'
ShortViewLoop:
 ld a,(hl)
 cp 20
 jp z,DisplayExponent
 add a,c
 call _putcDirect
 ld a,(_curCol)
 cp 15
 jp z,DisplayExponent
 dec hl
 jp ShortViewLoop
DisplayExponent:
 ld a,$1b
 call _putcDirect
 ld bc,(_curRow)
DS4:
 call FindNumber1EndWithoutSign ;Modified
DS2:
 ld de,NumberStart  ;Modified
 sub a
 sbc hl,de
 dec hl
 ld de,-1
 ld (_curRow),de
 call _dispAHL
 dec hl
DiscardSpaces:
 ld a,(hl)
 cp Lspace
 jr nz,$+5
 inc hl
 jr DiscardSpaces
 ld (_curRow),bc
 jp _puts

UpdateNumber2View:
 ld bc,256*3+1
 ld (_curRow),bc
 ld a,(View)
 or a
 jp nz,UpdateNumber2Short
 ld hl,Number2Ptr
 ld (NumberXPtr+1),hl
 ld (NoStartDotsNeeded+1),hl
 call FindNumber1End
 inc hl
 inc hl
 inc hl
 ld (NumStart),hl ;Start of number2+2
 ld de,(Number2End)
 jr UpdateNumberView

UpdateNumber1View:
 ld bc,256*3
 ld (_curRow),bc
 ld a,(View)
 or a
 jp nz,UpdateNumber1Short
 ld hl,Number1Ptr
 ld (NumberXPtr+1),hl
 ld (NoStartDotsNeeded+1),hl
 ld hl,NumberStart+2
 ld (NumStart),hl
 ld de,(Number1End)

UpdateNumberView:
 ld hl,_curCol
 dec (hl)
 ld a,Lspace
 call _putcDirect
NumberXPtr:
 ld hl,(Number1Ptr) ;Modified (Number1Ptr or Number2Ptr)
 call _cphldeDirect
 jr z,NoStartDotsNeeded
 ld hl,_curCol
 dec (hl)
 ld a,$ce
 call _putcDirect
NoStartDotsNeeded:
 ld hl,(Number1Ptr) ;Modified (Number1Ptr or Number2Ptr)
 ld c,'0'
 ld b,20
NumberDisplayLoop:
 ld a,(hl)
 cp b
 ret z
 jr nc,SkipAdd2
 add a,c
SkipAdd2:
 call _putcDirect
 ld a,(_curCol)
 cp b
 jp nz,SkipPoints
NumStart =$+1
 ld de,0 ;Modified (Start of Number 1 or Number 2)
 push hl
 sbc hl,de
 pop hl
 jr c,SkipPoints
 ld a,$ce
 jp _putmap
SkipPoints:
 dec hl
 jr NumberDisplayLoop

ChangeView:
 ld a,(Arguments)
 or a
 jp z,WaitKey
 ld a,(View)
 xor 1
 ld (View),a
 jr nz,$+5   ;Don't clear 2 times, it takes useless time!
 call ClearLinesNotTempNumber
 call UpdateNumber1View
 ld a,(Arguments)
 dec a
 jr z,$+5
 call UpdateNumber2View
 jp WaitKey

wait:
 push hl
 push de
 push bc
 push af
 xor a
 call _dispAHL
 call _runindicon
 call _getkey
 call _runindicoff
 pop af
 pop bc
 pop de
 pop hl
 ret

;Clear TempNumber if exists, if not, clear Number2 if exists, if not, clear Number1 if exists
ClearNumber:
 ld hl,(TempNumberLength)
 ld a,h
 or l
 jr z,CheckToClearOthers
 call ClearTempNumber
 jp UpdateTempNumberView
CheckToClearOthers:
 ld a,(Arguments)
 or a
 jp z,WaitKey
 dec a
 jr nz,MustClearNumber2
 ld (Arguments),a
 call ClearNumber1
 call ClearLinesNotTempNumber
 jp WaitKey
MustClearNumber2:
 call ClearNumber2
 ld a,1
 ld (Arguments),a
 call ClearNumber2Line
 jp WaitKey

FindNumber1EndWithoutSign:
 ld hl,(Number1End)
 ld a,(Signs)
 bit 0,a
 ret nz
 inc hl
 ret

FindNumber2EndWithoutSign:
 ld hl,(Number2End)
 ld a,(Signs)
 bit 1,a
 ret nz
 inc hl
 ret

CheckBiggerNumber:
;Checks which of the numbers is bigger (absolute value)
;Actually same as cp number2,number1
;Carry flag set if number 1 is bigger, zero flag if they equal
;Necessary for addition and subtraction
;Check first which number is longer (ignore sign!)
 call FindNumber1EndWithoutSign
 ld de,NumberStart
 or a
 sbc hl,de
 push hl    ;Length of number1 saved
 ld (Number1Length),hl
 ld hl,(Number1End)
 inc hl
 inc hl
 inc hl
 ex de,hl
 call FindNumber2EndWithoutSign
 or a
 sbc hl,de
 pop de   ;Load length of number1
 push hl
 add hl,de
 ld (TotalLength),hl ;Save total length
 pop hl
 or a
 ex de,hl
 sbc hl,de ;Number1 length - Number2 length
 ld (Difference),hl ;Save difference (needed in memory check in division)
 jr nz,ReadyBiggerCheck       ;If numbers had different length, this is done
;Now must check the values of the numbers
 call FindNumber2EndWithoutSign
 ex de,hl
 call FindNumber1EndWithoutSign
 ld c,20
BiggerCheckLoop:
 dec hl
 dec de
 ld a,(de)
 cp c
 jp z,Equal
 cp (hl)
 jp c,Number1Bigger
 jp z,BiggerCheckLoop
 jp Number2Bigger
Equal:
 xor a
SaveBiggerNumber:
 ld (BiggerNumber),a
 ret
ReadyBiggerCheck:
 jr c,Number2Bigger
Number1Bigger:
 ld a,1
 jr SaveBiggerNumber
Number2Bigger:
 ld a,2
 jr SaveBiggerNumber

ViewVars:
 call _clrLCD
 call _homeup
 ld hl,Arguments
 ld b,7
ViewLoop:
 push hl
 ld a,(hl)
 ld l,a
 xor a
 ld h,a
 call _dispAHL
 call _newline
 pop hl
 inc hl
 djnz ViewLoop
 call _ldhlind
 xor a
 call _dispAHL
 call Wait2
Quit:
 call _clrScrn
 res onInterrupt,(iy+onflags)
 jp _homeup

Wait2:
 halt
 call _getky
 jp z,Wait
 ret

#include "bignumops.asm"

NumberTable:
 .db 3,6,9,20,20,20,20,20,2,5,8,20,20,20,20,0,1,4,7

VariableStart:
Arguments: .db 0 ;0-Both numbers missing, 1-Number 1 there, 2-Both numbers there
Signs: .db 0 ;0-Both have +, 1-Number 1 has -, 2-Number 2 has -, 3-Both numbers have -
Select: .db 0 ;0-Number 1 selected, 1-Number 2 selected
View: .db 0 ;0-Normal number view mode (839187398...), 1-Short view mode (1.234E78)
TempNumberSign: .db 0 ;0-TempNumber doesn't have -, 1-TempNumber has -
AnswerSign: .db 0 ;What is going to be answer's sign
BiggerNumber: .db 0 ;0-They equal, 1-Number1 bigger, 2-Number2 bigger
TempNumberLength: .db 0,0 ;How many characters are there in the number that user is typing
Difference: .db 0,0 ;Number1 length - Number2 length
Number1Length: .db 0,0 ;Length of Number1
TotalLength: .db 0,0 ;Total length of number1 and number2
Number1End: .db 0,0 ;End of Number1 (address!)
Number2End: .db 0,0 ;End of Number2 (address!)

Number1Ptr: .db 0,0 ;At which point Number 1 is being scrolled
Number2Ptr: .db 0,0 ;At which point Number 2 is being scrolled
VariableEnd:

Power: .db 20,20,20,20,20,20

MemErrTxt: .db "ERR:MEM",0
Number1Txt: .db "1:",0
Number2Txt: .db "2:",0

NumberStart =$8100
TempNumber:
.end