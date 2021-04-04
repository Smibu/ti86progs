#include "ti86.inc"
.org _asm_exec_ram
 call _runindicoff
 call _clrLCD
 call _homeup
 ld hl,Text1
 call _puts
 call _newline
 call _puts
ChoiceLoop:
 halt
 call _getky
 cp K_EXIT
 jp z,_clrScrn
 cp K_2
 jr z,PixelChangeMode
 cp K_1
 jr nz,ChoiceLoop
PixelOnMode:
 ld a,$b6
 jr Start
PixelChangeMode:
 ld a,$ae
Start:
 ld (Mode),a
 call _clrLCD
 ld b,64
 ld c,32
 push bc
 ld ix,Loop
 ld d,0
Loop:
Random:
 ld b,8
randseed =$+1
 ld hl,12345
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
 ld h,d
 ld l,d
 ld e,a
RMul:
 add hl,de
 djnz RMul
 ld a,h
MakeMove:
 add a,a
 ld hl,Positions
 ld e,a
 add hl,de
 ld a,(hl)
 pop bc
 add a,b
 and %01111111
 ld b,a
 inc hl
 ld a,(hl)
 add a,c
 and %00111111
 ld c,a
 push bc
 call FindPixel
PixelPut:
; halt
Mode:
 xor (hl) ;xor (hl)=$ae, or (hl)=$b6
 ld (hl),a
 ld a,%11111110
 out (1),a
 in a,(1)
 rrca
 jp c,Loop
 pop bc
 ret

#include "findpixel.asm"

Positions: .db 255,255,0,255,1,255,255,0,1,0,255,1,0,1,1,1
Text1: .db "1-Pixel On",0
Text2: .db "2-Pixel Change",0
.end