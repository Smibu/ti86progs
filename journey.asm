#include "ti86asm.inc"
;#include "ti86math.inc"
;#include "asm86.h"
.org _asm_exec_ram
level = _textShadow
xcoord = _textShadow+1
ycoord = _textShadow+2
sxcoord = _textShadow+3
sycoord = _textShadow+4
_ConvOP = $5577
_random = $55da
_setXXop1 = $4613
_setXXop2 = $4617
_asapvar = $d6fc
lastk = _textShadow+5
 nop
 jp ProgStart
 .dw 0
 .dw ShellTitle

ShellTitle:
 .db "Journey",0

ProgStart:
 call _clrLCD
 call _runindicoff
 xor a
 ld (sxcoord),a
 ld a,32
 ld (sycoord),a
 ld a,K_RIGHT
 ld (lastk),a
 ld a,1
 ld (level),a
 ld a,34
 ld (ycoord),a
 ld a,10
 ld (xcoord),a
 ld a,255
lines:
 inc a
 ld b,a
 ld c,34
 push af
 call pixel_on
 pop af
 cp 10
 jr nz,lines
 ld a,255
line2:
 inc a
 ld c,22
 push af
 ld a,(level)
 add a,22
 ld c,a
 pop af
 ld b,a
 push af
 call pixel_on
 pop af
 cp 10
 jr nz,line2
generateloop:
 ld a,(xcoord)
 inc a
 ld (xcoord),a
rand:
 xor a
 call _setXXop1
 call _random
 ld a,10
 call _setXXop2
 call _FPMULT
 call _FPMULT
 call _ConvOP
 and 1
 cp 0
 jr z,cond1
 jr cond2
cond1:
 ld a,(ycoord)
 inc a
 cp 63
 call z,atoomuch
 ld (ycoord),a
 jr putpixels
cond2:
 ld a,(level)
 ld b,a
 ld a,(ycoord)
 dec a
 ld c,a
 add a,b
 sub 11
 call z,atoolow
 ld a,c
 ld (ycoord),a
putpixels:
 ld a,(xcoord)
 ld b,a
 ld a,(ycoord)
 ld c,a
 call pixel_on
 ld a,(level)
 ld b,a
 ld a,(ycoord)
 sub 12
 add a,b
 ld c,a
 ld a,(xcoord)
 ld b,a
 call pixel_on
 ld a,(xcoord)
 cp 127
 jr z,getcmd
 jr generateloop
atoomuch:
 dec a
 ret
atoolow:
 inc c
 ret
getcmd:
 call _getky
keypress:
 cp K_UP
 jr z,moveup
 cp K_DOWN
 jr z,movedown
 cp K_LEFT
 jr z,moveleft
 cp K_RIGHT
 jr z,moveright
 cp K_EXIT
 ret z
 ld a,(lastk)
 jr keypress
moveup:
 ld (lastk),a
 ld a,(sycoord)
 dec a
 ld (sycoord),a
 jr move
moveleft:
 ld (lastk),a
 ld a,(sxcoord)
 dec a
 ld (sxcoord),a
 jr move
moveright:
 ld (lastk),a
 ld a,(sxcoord)
 inc a
 ld (sxcoord),a
 jr move
movedown:
 ld (lastk),a
 ld a,(sycoord)
 inc a
 ld (sycoord),a
move:
 ld a,(sxcoord)
 ld b,a
 ld a,(sycoord)
 ld c,a
 push bc
 call pixeltest
 pop bc
 jp nz,_clrLCD
 push bc
 call pixel_on
 pop bc
 ld a,b
 cp 60
 jr nc,scrollleft
delay:
 ld a,65
 ld e,a
dela:
 dec e
 jr nz,dela
 dec a
 jr nz,dela
 jp getcmd
pixeltest:
 call FindPixel
 and (hl)
 ret
pixel_on:
 call FindPixel
 or (hl)
 ld (hl),a
 ret
#include "findpixel.asm"
scrollleft:
 di
 ld hl,0
 ld bc,1024
loopleft:
 dec hl
 ex af,af'
 rl (hl)
 ex af,af'
 dec c
 jp nz,loopleft
 dec b
 jp nz,loopleft
 ei
clean:
 ld hl,$fc0f-16
 ld b,64
loop:
 ld a,%11111110
 ld de,16
 add hl,de
 and (hl)
 ld (hl),a
 djnz loop
 ld a,(xcoord)
 dec a
 ld (xcoord),a
 ld a,(sxcoord)
 dec a
 ld (sxcoord),a
 jp generateloop
.end
