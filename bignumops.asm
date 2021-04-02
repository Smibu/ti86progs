Addition:
;Check here the signs first
 ld a,(Arguments)
 cp 2
 jp nz,WaitKey
 call CheckBiggerNumber
 call RemoveSigns
 ld a,(Signs)
 or a
 jr z,NormalAddition
 cp 3
 jr z,NormalAddition
;So must subtract
 dec a
 jr nz,Number2IsMinus
 ld a,3
 ld (Signs),a
 jp GoToSubtraction
Number2IsMinus:
 xor a
 ld (Signs),a
 jp GoToSubtraction

NormalAddition:
;Normal addition if both numbers have same signs (+ and + or - and -)
;So answer's sign is going to be same as number 1's sign
 ld a,(Signs)
 and 1
 ld (AnswerSign),a
StartAddition:
 ld a,(BiggerNumber)
 cp 2
 jr c,AddToNumber1
 ld hl,(Number1End)
 inc hl
 inc hl
 ld de,NumberStart-1
 jr $+11
AddToNumber1:
 ld hl,(Number1End)
 inc hl
 inc hl
 ex de,hl
 ld hl,NumberStart-1
 ld ix,AdditionLoop
 ld b,20
 ld c,10
AdditionLoop:
 inc hl
 inc de
 ld a,(de)
 add a,(hl)
 cp b
 jp nc,EndAddition
 cp c
 jp nc,Over9
 ld (hl),a
 jp (ix)
Over9:
 push hl
 sub c
 ld (hl),a
 inc hl
 inc (hl)
 ld a,(hl)
 cp b
 jp c,NoSub
 sub b
 ld (hl),a
NoSub:
 sub c
 jp nc,Over9+2
 pop hl
 jp (ix)
EndAddition:
;Now delete the other number, update Number1End and put sign there if needed, and update views
 ld a,(BiggerNumber)
 cp 2
 jr z,RemoveFirstNumber
 call FindNumber1End
 ld a,(hl)
 cp 20
 jr nz,$+3
 inc hl
 call ClearNumberNow

UpdateSignAndPointers:  ;used by many operations
 ld a,1
 ld (Arguments),a
 call FindNumber1End
 dec hl
 ld a,(AnswerSign)
 ld (Signs),a
 or a
 jr z,$+6
 ld (hl),26
 jr $+3
 dec hl
 ld (Number1End),hl
 ld (Number1Ptr),hl
 call ClearLinesNotTempNumber
 call UpdateNumber1View
 jp WaitKey
RemoveFirstNumber:
 call FindNumber1End
 inc hl
 ld a,(hl)
 cp 20
 jr nz,$+3
 inc hl
 call CopyNumber2ToNumber1Place
 jr UpdateSignAndPointers

;DE-HL
Subtraction:
 ld a,(Arguments)
 cp 2
 jp nz,WaitKey
 call CheckBiggerNumber
 call RemoveSigns
GoToSubtraction:
 ld a,(Signs)
 cp 1
 jr nz,CheckOtherCases
 call SetAnswerSignMinus
GoToAddition:
 jp StartAddition
CheckOtherCases:
 cp 2
 jr nz,UseSubtraction
 call SetAnswerSignPlus
 jr GoToAddition
UseSubtraction:
 ld a,(BiggerNumber)
 cp 2
 jr c,SubtractFromNumber1
;Subtract Number1 from Number2
 ld de,(Number1End)
 inc de
 inc de
 ld hl,NumberStart-1
;Check the answersign here
 ld a,(Signs)
 or a
 push af
 call z,SetAnswerSignMinus
 pop af
 cp 3
 call z,SetAnswerSignPlus
 jr StartSubtraction
SubtractFromNumber1:
 ld de,NumberStart-1
 ld hl,(Number1End)
 inc hl
 inc hl
 ld a,(Signs)
 or a
 push af
 call z,SetAnswerSignPlus
 pop af
 cp 3
 call z,SetAnswerSignMinus
StartSubtraction:
 ld c,10
 ld b,20
 ld ix,SubtractionLoop
SubtractionLoop:
 inc hl
 inc de
 ld a,(hl)
 cp b
 jp nc,EndSubtraction
 ld a,(de)
 sub (hl)
 ld (hl),b
 cp c
 jp nc,Under0
 ld (de),a
 jp (ix)
Under0:
 push de
 add a,c
 ld (de),a
 inc de
 ex de,hl
 dec (hl)
 ex de,hl
 ld a,(de)
 add a,c
 jp c,Under0+2
 pop de
 jp (ix)
EndSubtraction:
;Discard the useless zeroes that there may be after subtraction
 ld hl,NumberStart-1
 ld c,20
SearchNumberStartLoop:
 inc hl
 ld a,(hl)
 cp c
 jp z,SearchNumberStartLoop
;HL is at the first byte of answer's number
;If HL=NumberStart, we don't have to move that number
 push hl
 call DiscardZeroes
 pop hl
 ld de,NumberStart
 call _cphlde
 call nz,CopyNumber2ToNumber1Place
 jp UpdateSignAndPointers

Multiplication:
 ld a,(Arguments)
 cp 2
 jp nz,WaitKey
 call CheckBiggerNumber
 call RemoveSigns
 call SetMultOrDivAnsSign
 call FindNumber2EndWithoutSign
 push hl
 ld bc,(TotalLength)
 inc hl
;Set answer area to zero
 call SetAnswerAreaZero
 jr nc,ContinueMult
 pop hl
 call MemoryError
 jp Quit
ContinueMult:
 ld hl,(Number1End)
 inc hl
 inc hl
 ld de,NumberStart-1
 ld a,(BiggerNumber)
 cp 2
 jr nz,$+3
 ex de,hl
 ld (Mult2),de
 pop bc
 call MultiplyNow
 ei
;Clear numbers that were multiplicated and copy answer to number1 place
 call FindNumber2EndWithoutSign
 inc hl
 push hl
 call DiscardZeroes
 call ClearNumber2
 call ClearNumber1
 pop hl
 call CopyNumber2ToNumber1Place  ;Actually copy answer to number1place
 jp UpdateSignAndPointers

;HL=Start of smaller number-1, BC=Answer's place-1
MultiplyNow:
 di
 ld ix,MultiplicationSubLoop
 exx
 ld e,10
 exx
MultiplicationLoop:
 inc bc
 inc hl
 ld a,(hl)
 or a
 jp z,MultiplicationLoop
 cp 20
 ret z
 ld (Mult1),a
 push bc
 exx
 pop hl
 exx
Mult2 =$+1
 ld de,0      ;Start of bigger number-1 (modified)
MultiplicationSubLoop:
 inc de
 ld a,(de)
 cp 20
 jp z,MultiplicationLoop
 exx
 ld c,a
 xor a
 ld d,a
Mult1 =$+1
 ld b,0  ;Modified
MultLoop: ;A+C->A, A+C->A... B times
 add a,c
 cp e
 jp nc,SubeIncd
 djnz MultLoop
 ld b,h
 ld c,l
 add a,(hl)
 cp e
 jp nc,Over93
 ld (hl),a
 ld a,d
 inc hl
 add a,(hl)
 cp e
 jp nc,Over92
 ld (hl),a
 ld h,b
 ld l,c
 inc hl
 exx
 jp (ix)

SubeIncd:
 sub e
 inc d
 djnz MultLoop
 ld b,h
 ld c,l
 add a,(hl)
 cp e
 jp nc,Over93
 ld (hl),a
 ld a,d
 inc hl
 add a,(hl)
 cp e
 jp nc,Over92
 ld (hl),a
 ld h,b
 ld l,c
 inc hl
 exx
 jp (ix)

Over93:
 sub e
 ld (hl),a
 ld a,d
 inc a
 inc hl
 add a,(hl)
 cp e
 jp nc,Over92
 ld (hl),a
 ld h,b
 ld l,c
 inc hl
 exx
 jp (ix)

Over92:
 sub e
 ld (hl),a
 inc hl
 inc (hl)
 ld a,(hl)
 cp e
 jp nc,Over92
 ld h,b
 ld l,c
 inc hl
 exx
 jp (ix)

Division:
 ld a,(Arguments)
 cp 2
 jp nz,WaitKey
 call CheckBiggerNumber
;Make sure that divisor isn't zero
 call FindNumber2EndWithoutSign
 dec hl
 ld a,(hl)
 or a
 jp z,WaitKey
;If number2 is bigger, the answer is zero
 ld a,(BiggerNumber)
 sub 2
 jr nz,Number2NotBigger
SetAnswerToZero:
 call SetAnswerSignPlus
 call ClearNumber2
 call ClearNumber1
 ld hl,NumberStart
 ld (hl),0
 jp UpdateSignAndPointers
Number2NotBigger:
 call RemoveSigns
 call SetMultOrDivAnsSign
 call FindNumber2EndWithoutSign
;Perform memory check
 ld de,(Difference)
 push hl
 add hl,de
 inc hl
 ld de,$bff4
 call _cphldeDirect
 pop hl
 jr c,ContinueDivision
 call MemoryError
 jp Quit
ContinueDivision:
 ld (Div1),hl
 ld (Div3),hl
 push hl
 inc hl
 push hl
 pop ix
 ld hl,(Number1End)
 inc hl
 inc hl
 inc hl
 ld (Div4),hl
 ex de,hl
 pop hl
 or a
 sbc hl,de
 ld b,h
 ld c,l
 call FindNumber1EndWithoutSign
 call DivideNow
 call FindNumber2EndWithoutSign
 ld a,20
Number2BackwardClearLoop:
 ld (hl),a
 dec hl
 cp (hl)
 jp nz,Number2BackwardClearLoop
 call ClearNumber1
;Copy quotient to number1's place (ix points to end of quotient)
 ld de,NumberStart-1
 ld c,20
 push ix
 pop hl
 ld ix,QCopyLoop
QCopyLoop:
 dec hl
 inc de
 ld a,(hl)
 cp c
 jp z,UpdateSignAndPointers
 ld (hl),c
 ld (de),a
 jp (ix)

;BC=Length of divisor, HL=end of dividend+1, answer is NOT stored backwards!
DivideNow:
 xor a
 ld (DivNum),a
 push hl
 ld (Div2),bc
 ld (Div5),bc
 or a
 sbc hl,bc
 ld (DivPointer),hl
 pop de
Div1 =$+1
 ld hl,0 ;end of divisor+1
Loop2:
 dec de
 dec hl
 ld a,(de)
 cp (hl)
 jp c,Plus1Num
 jp nz,NextSubtraction
 push hl
DivPointer =$+1
 ld hl,0
 sbc hl,de
 pop hl
 jp nz,Loop2
SubtractAgain:
 dec hl
 dec de
 ld c,10
 ld b,20
SubtractionLoop2:
 inc hl
 inc de
 ld a,(hl)
 cp b
 jp nc,EndSubtraction2
 ld a,(de)
 sub (hl)
 cp c
 jp nc,Under02
 ld (de),a
 jp SubtractionLoop2
Under02:
 push de
 add a,c
 ld (de),a
 inc de
 ex de,hl
 dec (hl)
 ex de,hl
 ld a,(de)
 add a,c
 jp c,Under02+2
 pop de
 jp SubtractionLoop2
EndSubtraction2:
 ld a,(DivNum)
 inc a
 ld (DivNum),a
 ld a,(de)
 or a
 jp nz,CheckOther
 ld a,20
 ld (de),a
 jp Loop3
CheckOther:
 cp 20
 jp nz,NextSubtraction+4
Loop3:
 dec de
 dec hl
 ld a,(de)
 cp (hl)
 jp c,EndDiv
 jp nz,NextSubtraction+4
 ld b,h
 ld c,l
 ld hl,(DivPointer)
 sbc hl,de
 ld h,b
 ld l,c
 jp nz,Loop3
 jp SubtractAgain
EndDiv:
 ld a,(DivNum)
 ld (ix),a
 inc ix
;Remove zeroes
 ex de,hl
 ld a,20
 ld b,-1
 cpir
 dec hl
 dec hl
Div5 =$+1
 ld bc,0 ;Length of divisor
 ld e,20
ZeroRemoveLoop:
 ld a,(hl)
 or a
 jp nz,DoneRemoving
 ld (hl),e
 dec hl
 dec bc
 ld a,b
 or c
 jp nz,ZeroRemoveLoop
DoneRemoving:
Plus1Num:
 ld de,(DivPointer)
 dec de
 ld (DivPointer),de
 ld l,20
 ld a,(de)
 cp l
 ret z
Div2 =$+1
 ld bc,0 ;Length of divisor
Loop4:
 ld a,(de)
 cp l
 jp z,AddZero
 dec bc
 inc de
 ld a,b
 or c
 jp nz,Loop4
 ld a,(de)
 cp l
 jp nz,NextSubtraction
Div3 =$+1
 ld hl,0 ;end of divisor+1
Loop5:
 dec hl
 dec de
 ld a,(de)
 cp (hl)
 jp c,AddZero
 jp nz,NextSubtraction
 ld b,h
 ld c,l
 ld hl,(DivPointer)
 sbc hl,de
 ld h,b
 ld l,c
 jp nz,Loop5
NextSubtraction:
 xor a
 ld (DivNum),a
 ld de,(DivPointer)
Div4 =$+1
 ld hl,0 ;start of divisor
 jp SubtractAgain
AddZero:
 xor a
 ld (ix),a
 inc ix
 ex de,hl
 ld a,20
 ld b,-1
 cpir
 dec hl
 dec hl
 ld bc,1
 jp ZeroRemoveLoop-2

Raise:
 ld a,(Arguments)
 cp 2
 jp nz,WaitKey
 call CheckBiggerNumber
;If number2 is negative, answer will be 0 UNLESS number1=1 or number1=0 (error)
 ld a,(Signs)
 cp 2
 jr c,Number2NotNegative
;Check if number1=0
 call CheckNumber1Zero
 jp z,WaitKey
;Check if number1=1
 dec a
 jp nz,SetAnswerToZero
;Make sure number 1 is only 1 digit long
 dec hl
 ld a,(hl)
 cp 20
 jp nz,SetAnswerToZero
;Set answer to -1 or 1
 call SetAnswerSignPlus
 ld a,(Signs)
 bit 0,a
 call nz,Number2ParityCheck
 call c,SetAnswerSignMinus
SetAnswerTo1:
 call ClearNumber2
 call ClearNumber1
 ld hl,NumberStart
 ld (hl),1
 jp UpdateSignAndPointers

Number2NotNegative:
;Check if number2 is zero (if it is, answer will be 1 unless number1=0)
 call FindNumber2EndWithoutSign
 dec hl
 ld a,(hl)
 or a
 jr nz,Number2NotZero
;Make sure number1 isn't zero too
 call CheckNumber1Zero
 jp z,WaitKey
 call SetAnswerSignPlus
 jr SetAnswerTo1
Number2NotZero:
;Check sign (if number1 is +, answer is +, if number1 is -, check if number2 is even or odd)
 call SetAnswerSignPlus
 ld a,(Signs)
 or a
 call nz,Number2ParityCheck
 call c,SetAnswerSignMinus
;If number2=1, answer is same as number1
 call FindNumber2EndWithoutSign
 dec hl
 ld a,(hl)
 dec a
 jr nz,Number2Not1
 dec hl
 ld a,(hl)
 cp 20
 jr nz,Number2Not1
;So it is 1, just clear number 2 and done!
 call ClearNumber2
 call RemoveSigns
 jp UpdateSignAndPointers
Number2Not1:
;The power must not be more than 5 digits long (2^100000 would cause overflow)
 call FindNumber1End
 inc hl
 push hl
 ex de,hl
 call FindNumber2EndWithoutSign
 or a
 sbc hl,de
 ld de,6
 sbc hl,de
 pop hl
 jp nc,WaitKey
 push hl
 call RemoveSigns
 pop hl
;Copy number2 to power's place (still backwards) and then clear number2
 ld de,Power
 ld bc,6
 ldir
 call ClearNumber2
;Copy number1 to plotSScreen area (used in multiplications)
;Make sure first that number1 isn't too long (if it is, can't perform operation!)
 call FindNumber1EndWithoutSign
 ld de,NumberStart
 or a
 sbc hl,de
 ld de,1024
 sbc hl,de
 jr c,Number1NotTooLong
 call MemoryError
 jp Quit
Number1NotTooLong:
 ld hl,NumberStart
 ld de,_plotSScreen
 ld bc,1024
 ldir
;Now start multiplying number1 by number1, number2 times
 ld de,NumberStart-1  ;Bigger number is always at NumberStart
 ld (Mult2),de
;Decrease power by 1 (then it multiplies correctly)
 ld hl,Power
DecAgain2:
 ld a,(hl)
 dec a
 cp 9
 jp c,StartRaising
 ld (hl),9
 inc hl
 jp DecAgain2
StartRaising:
 ld (hl),a
 ld hl,(Number1Length)
 add hl,hl
 ld (TotalLength),hl
MultiplyAgain:
 call FindNumber1End
 push hl
 push hl
 ld bc,(TotalLength)
 call SetAnswerAreaZero
 pop hl
 dec hl
 ld b,h
 ld c,l
 ld hl,_plotSScreen-1
 call MultiplyNow
 ei
;There can be extra zeroes, remove it if it exists
 ld h,b
 ld l,c
 call DiscardZeroes
 pop hl
 call CopyNumber2ToNumber1Place
;Find new total length, DE=end of number1+1
 ld hl,NumberStart
 ex de,hl
 or a
 sbc hl,de
 ld de,(Number1Length)
 add hl,de
 ld (TotalLength),hl
;Decrease power by 1, if then not zero, multiply again
 ld c,9
 ld hl,Power
 push hl
DecAgain:
 ld a,(hl)
 dec a
 cp c
 jp c,NotUnder0
 ld (hl),c
 inc hl
 jp DecAgain
NotUnder0:
 ld (hl),a
 pop hl
 ld a,(hl)
 or a
 jp nz,MultiplyAgain
PowerCheck:
 inc hl
 ld a,(hl)
 or a
 jp z,PowerCheck
 cp 20
 jp nz,MultiplyAgain
;All done!
 jp UpdateSignAndPointers

SquareRoot:
 ret

Factorial:
 ret

Combination:
 ret

Variation:
 ret

CheckPrimeNumber:
 ret

CheckNumber1Zero:
 call FindNumber1EndWithoutSign
 dec hl
 ld a,(hl)
 or a
 ret

Number2ParityCheck:
 ld hl,(Number1End)
 inc hl
 inc hl
 inc hl
 ld a,(hl)
 bit 0,a
 ret z
 scf
 ret

;Only 1 argument allowed for squaring!
Square:
 ld a,(Arguments)
 dec a
 jp nz,WaitKey
 call SetAnswerSignPlus
 call RemoveSigns
 call FindNumber1EndWithoutSign
 push hl
 ld de,NumberStart
 or a
 sbc hl,de
 add hl,hl
 ld b,h
 ld c,l
 pop hl
 push hl
 inc hl
 call SetAnswerAreaZero
 jr nc,ContinueSquaring
 pop hl
 call MemoryError
 jp Quit
ContinueSquaring:
 ld de,NumberStart-1
 ld (Mult2),de
 pop bc
 ld hl,NumberStart-1
 call MultiplyNow
 ei
 call FindNumber1EndWithoutSign
 inc hl
 push hl
 call DiscardZeroes
 pop hl
 call CopyNumber2ToNumber1Place  ;Actually copy answer to number1place
 jp UpdateSignAndPointers

CopyNumber2ToNumber1Place:
;HL is at the first byte of the last number, deletes it
 ld c,20
 ld de,NumberStart
 ld ix,CopyLoop
CopyLoop:
 ld a,(hl)
 cp c
 ret z
 ld (de),a
 ld (hl),c
 inc hl
 inc de
 jp (ix)

RemoveSigns:
;Removes signs in the memory ("Signs"-variable is unaffected)
 ld hl,(Number1End)
 ld a,(hl)
 cp 26
 jr nz,$+4
 ld (hl),20
 ld hl,(Number2End)
 ld a,(hl)
 cp 26
 ret nz
 ld (hl),20
 ret

;Doesn't modify AF
SetAnswerSignMinus:
 ld c,a
 ld a,1
 jr $+4
SetAnswerSignPlus:
 ld c,a
 ld a,0
 ld (AnswerSign),a
 ld a,c
 ret

;HL=start of the number whose zeroes we want to discard (HL can be in the middle of number too)
DiscardZeroes:
 ld a,20
 ld b,-1
 cpir
 dec hl
 ld c,a
DiscardZeroesLoop:
 dec hl
 ld a,(hl)
 cp c
 jp z,PutZero
 or a
 ret nz
 ld (hl),c
 jp DiscardZeroesLoop
PutZero:
 inc hl  ;Make sure it didn't discard too much
 xor a
 ld (hl),a
 ld (AnswerSign),a  ;Minus sign in front of 0 is unnecessary
 ret

SetAnswerAreaZero:
 push hl
 push de
 add hl,bc
 ld de,$bff3
 call _cphldeDirect
 pop de
 pop hl
 jp nc,SetCarry
 ld (hl),0
 ld e,l
 ld d,h
 inc de
 dec bc
 ldir
 or a
 ret

SetMultOrDivAnsSign:
 ld a,(Signs)
 dec a
 jp z,SetAnswerSignMinus
 dec a
 jp z,SetAnswerSignMinus
 jp SetAnswerSignPlus

DivNum: .db 0
.end