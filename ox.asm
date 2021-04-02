#include "ti86asm.inc"
#include "asm86.h"
_ldhlz = $437b
field = $8100
.org _asm_exec_ram
 nop
 jp ProgStart
 .dw 0
 .dw ShellTitle
ShellTitle:
 .db "Noughts and Crosses",0

ProgStart:
 ld hl,256*3+8
 ld (screenx),hl
 ld hl,256*7+15
 ld (x),hl
 call _runindicoff
 call _flushallmenus
 call _clrLCD
 ld hl,field
 call _ldhlz
 ld hl,field+256
 call _ldhlz
 ld hl,256*1
 ld (_curRow),hl
 ld hl,ShellTitle
 call _puts
 ld hl,256*8+96
 ld (_penCol),hl
 ld hl,by
 call _vputs
 ld hl,256*16+40
 ld (_penCol),hl
 ld hl,playertext
 call _vputs
 call _vputs
 ld hl,256*23+40
 ld (_penCol),hl
 ld hl,playertext
 call _vputs
 call _vputs
 ld bc,256*23+64
 ld (_penCol),bc
 ld a,'O'
 call _vputmap
 xor a
 ld (sel),a
 call invert
waitkey:
 halt
 call _getky
 cp K_UP
 jr z,scroll
 cp K_DOWN
 jr z,scroll
 cp K_EXIT
 jp z,quit
 cp K_ENTER
 jr z,startgame
 jr waitkey
scroll:
 call invert
 ld a,(sel)
 xor 1
 ld (sel),a
 call invert
 jr waitkey
startgame:
 call _clrLCD
 ld hl,$fc70
 ld b,16
new_vertical_line:
 push bc
 push hl
 ld a,%10000000
 call do_vertical_line
 pop hl
 inc hl
 pop bc
 djnz new_vertical_line
 ld hl,$fc70
 ld de,$70
 ld b,9
new_horiz_line:
 push bc
 push hl
 call do_horiz_line
 pop hl
 add hl,de
 pop bc
 djnz new_horiz_line
 call invertselect
 ld hl,4
 ld (_penCol),hl
 ld hl,turntext
 call _vputs
 ld hl,0
 ld (_penCol),hl
 ld a,(sel)
 cp 0
 call z,xturn
 call nz,oturn
waitkey2:
 halt
 call _getky
 cp K_UP
 jr z,up
 cp K_DOWN
 jr z,down
 cp K_LEFT
 jr z,left
 cp K_RIGHT
 jp z,right
 cp K_EXIT
 jp z,ProgStart
 ld a,%00111111
 out (1),a
 in a,(1)
 bit 5,a
 jp z,place
 jr waitkey2
up:
 ld a,(y)
 cp 0
 jr z,waitkey2
 call invertselect
 ld a,(screeny)
 cp 0
 call z,scrollup
 ld a,(screeny)
 dec a
 ld (screeny),a
 ld a,(y)
 dec a
 ld (y),a
 call invertselect
 jr waitkey2
down:
 ld a,(y)
 cp 15
 jr z,waitkey2
 call invertselect
 ld a,(screeny)
 cp 7
 call z,scrolldown
 ld a,(screeny)
 inc a
 ld (screeny),a
 ld a,(y)
 inc a
 ld (y),a
 call invertselect
 jr waitkey2
left:
 ld a,(x)
 cp 0
 jr z,waitkey2
 call invertselect
 ld a,(screenx)
 cp 0
 call z,scrolleft
 ld a,(screenx)
 dec a
 ld (screenx),a
 ld a,(x)
 dec a
 ld (x),a
 call invertselect
 jp waitkey2
right:
 ld a,(x)
 cp 31
 jp z,waitkey2
 call invertselect
 ld a,(screenx)
 cp 15
 call z,scrollright
 ld a,(screenx)
 inc a
 ld (screenx),a
 ld a,(x)
 inc a
 ld (x),a
 call invertselect
 jp waitkey2
place:
 call findfield
 ld a,(hl)
 cp 0
 jp nz,waitkey2
 push hl
 call invertselect
 pop hl
 ld a,(sel)
 inc a
 ld (hl),a
 call findcoords
 ld de,$10
 add hl,de
 ld a,(sel)
 cp 1
 call z,viewonow
 call nz,viewxnow
 call invertselect
checkvictory:
horizontal_check:
 call initialize
hcheck1:
 ld a,(xcheck)
 cp 255
 jr z,hcheck2
 dec a
 ld (xcheck),a
 dec hl
 ld a,(hl)
 cp b
 jr z,hcheck1
hcheck2:
 ld a,(xcheck)
 inc a
 ld (xcheck),a
 inc hl
 ld a,(hl)
 cp b
 jr nz,hcheck_done
 ld a,(row)
 inc a
 ld (row),a
 ld a,(xcheck)
 cp 31
 jr nz,hcheck2
hcheck_done:
 ld a,(row)
 cp 5
 jp nc,gamedone
vertical_check:
 call initialize
 ld de,$20
vcheck1:
 ld a,(ycheck)
 cp 255
 jr z,vcheck2
 dec a
 ld (ycheck),a
 cp 0
 sbc hl,de
 ld a,(hl)
 cp b
 jr z,vcheck1
vcheck2:
 ld a,(ycheck)
 inc a
 ld (ycheck),a
 add hl,de
 ld a,(hl)
 cp b
 jr nz,vcheck_done
 ld a,(row)
 inc a
 ld (row),a
 ld a,(ycheck)
 cp 15
 jr nz,vcheck2
vcheck_done:
 ld a,(row)
 cp 5
 jp nc,gamedone
diagonal_check1:
 call initialize
 ld de,$21
d1check1:
 ld a,(ycheck)
 cp 255
 jr z,d1check2
 ld a,(xcheck)
 cp 255
 jr z,d1check2
 ld a,(xcheck)
 dec a
 ld (xcheck),a
 ld a,(ycheck)
 dec a
 ld (ycheck),a
 cp 0
 sbc hl,de
 ld a,(hl)
 cp b
 jr z,d1check1
d1check2:
 ld a,(ycheck)
 inc a
 ld (ycheck),a
 ld a,(xcheck)
 inc a
 ld (xcheck),a
 add hl,de
 ld a,(hl)
 cp b
 jr nz,d1check_done
 ld a,(row)
 inc a
 ld (row),a
 ld a,(xcheck)
 cp 31
 jr z,d1check_done
 ld a,(ycheck)
 cp 15
 jr nz,d1check2
d1check_done:
 ld a,(row)
 cp 5
 jp nc,gamedone
diagonal_check2:
 call initialize
 ld de,$1f
d2check1:
 ld a,(ycheck)
 cp 16
 jr z,d2check2
 ld a,(xcheck)
 cp 255
 jr z,d2check2
 ld a,(xcheck)
 dec a
 ld (xcheck),a
 ld a,(ycheck)
 inc a
 ld (ycheck),a
 add hl,de
 ld a,(hl)
 cp b
 jr z,d2check1
d2check2:
 ld a,(ycheck)
 dec a
 ld (ycheck),a
 ld a,(xcheck)
 inc a
 ld (xcheck),a
 cp 0
 sbc hl,de
 ld a,(hl)
 cp b
 jr nz,d2check_done
 ld a,(row)
 inc a
 ld (row),a
 ld a,(xcheck)
 cp 31
 jr z,d2check_done
 ld a,(ycheck)
 cp 0
 jr nz,d2check2
d2check_done:
 ld a,(row)
 cp 5
 jr nc,gamedone
 ld hl,0
 ld (_penCol),hl
 ld a,(sel)
 xor 1
 ld (sel),a
 cp 0
 call z,xturn
 call nz,oturn
 jp waitkey2

gamedone:
 ld hl,50
 ld (_penCol),hl
 ld hl,playertext
 call _vputs
 ld hl,xwintext
 call _vputs
 ld a,(sel)
 cp 0
 jr z,showwinner
owin:
 ld a,'O'
 ld bc,74
 ld (_penCol),bc
 call _vputmap
 jr showwinner
showwinner:
 call _getkey
 jp ProgStart

initialize:
 call findfield
 xor a
 ld (row),a
 ld a,(hl)
 ld b,a
 ld a,(y)
 ld (ycheck),a
 ld a,(x)
 ld (xcheck),a
 ret

invertselect:
 call findcoords
 ld de,$10
 add hl,de
 ld b,6
invertselectloop:
 ld a,(hl)
 xor %01111111
 ld (hl),a
 add hl,de
 djnz invertselectloop
 ret

viewonow:
 add hl,de
 ld (hl),%10011100
 add hl,de
 ld (hl),%10100010
 add hl,de
 ld (hl),%10100010
 add hl,de
 ld (hl),%10100010
 add hl,de
 ld (hl),%10011100
 ret

viewxnow:
 add hl,de
 ld (hl),%10100010
 add hl,de
 ld (hl),%10010100
 add hl,de
 ld (hl),%10001000
 add hl,de
 ld (hl),%10010100
 add hl,de
 ld (hl),%10100010
 ret

findfield:
 ld hl,field
 ld a,(x)
 ld d,0
 ld e,a
 add hl,de
 ld a,(y)
 ld b,a
 cp 0
 ret z
 ld de,32
findfieldloop:
 add hl,de
 djnz findfieldloop
 ret

findcoords:
 ld hl,$fc70
 ld a,(screenx)
 ld c,a
 ld b,0
 add hl,bc
 ld de,$70
 ld a,(screeny)
 ld b,a
 cp 0
 ret z
findy:
 add hl,de
 djnz findy
 ret

showrow:
 ld a,(screenx)
 ld (ycheck),a
 ld b,a
 ld a,(x)
 ld (xcheck),a
 sub b
 dec a
 ld (x),a
 ld a,255
 ld (screenx),a
 ld b,16
viewloop1:
 push bc
 ld a,(x)
 inc a
 ld (x),a
 ld a,(screenx)
 inc a
 ld (screenx),a
 call findcoords
 push hl
 call findfield
 ld a,(hl)
 cp 0
 pop hl
 ld de,$10
 add hl,de
 call z,clear
 cp 1
 call z,viewxnow
 cp 2
 call z,viewonow
 pop bc
 djnz viewloop1
 ld a,(xcheck)
 ld (x),a
 ld a,(ycheck)
 ld (screenx),a
 ret

showrow2:
 ld a,(screeny)
 ld (xcheck),a
 ld b,a
 ld a,(y)
 ld (ycheck),a
 sub b
 dec a
 ld (y),a
 ld a,255
 ld (screeny),a
 ld b,8
viewloop2:
 push bc
 ld a,(y)
 inc a
 ld (y),a
 ld a,(screeny)
 inc a
 ld (screeny),a
 call findcoords
 push hl
 call findfield
 ld a,(hl)
 cp 0
 pop hl
 ld de,$10
 add hl,de
 call z,clear
 cp 1
 call z,viewxnow
 cp 2
 call z,viewonow
 pop bc
 djnz viewloop2
 ld a,(ycheck)
 ld (y),a
 ld a,(xcheck)
 ld (screeny),a
 ret

scrollup:
 ld hl,$fc70
 ld de,_plotSScreen
 ld bc,896
 ldir
 ld de,$fce0
 ld hl,_plotSScreen
 ld bc,896
 ldir
 ld a,(y)
 dec a
 ld (y),a
 call showrow
 ld a,(y)
 inc a
 ld (y),a
 ld a,(screeny)
 inc a
 ld (screeny),a
 ret

scrolldown:
 ld hl,$fce0
 ld de,_plotSScreen
 ld bc,784
 ldir
 ld de,$fc70
 ld hl,_plotSScreen
 ld bc,784
 ldir
 ld a,(y)
 inc a
 ld (y),a
 call showrow
 ld a,(y)
 dec a
 ld (y),a
 ld a,(screeny)
 dec a
 ld (screeny),a
 ret

scrolleft:
 ld hl,$fffe
 ld de,$ffff
 ld b,56
scrolleftloop:
 push bc
 ld bc,15
 lddr
 pop bc
 dec hl
 dec de
 djnz scrolleftloop
 ld a,(x)
 dec a
 ld (x),a
 call showrow2
 ld a,(x)
 inc a
 ld (x),a
 ld a,(screenx)
 inc a
 ld (screenx),a
 ret

scrollright:
 ld hl,$fc71
 ld de,$fc70
 ld b,56
scrollrightloop:
 push bc
 ld bc,15
 ldir
 pop bc
 inc hl
 inc de
 djnz scrollrightloop
 ld a,(x)
 inc a
 ld (x),a
 call showrow2
 ld a,(x)
 dec a
 ld (x),a
 ld a,(screenx)
 dec a
 ld (screenx),a
 ret

xturn:
 ld a,'X'
 jp _vputmap

oturn:
 ld a,'O'
 jp _vputmap

clear:
 ld b,5
clearloop:
 add hl,de
 ld (hl),%10000000
 djnz clearloop
 ret

invert:
 ld hl,$fd00
 ld a,(sel)
 cp 0
 jr z,noadd
 ld hl,$fd70
noadd:
 ld b,112
invertloop:
 ld a,(hl)
 cpl
 ld (hl),a
 inc hl
 djnz invertloop
 ret

do_horiz_line:
 ld b,16
lineloop2:
 ld a,255
 ld (hl),a
 inc hl
 djnz lineloop2
 ret

do_vertical_line:
 ld de,$10
 ld b,56
lineloop:
 ld (hl),a
 add hl,de
 djnz lineloop
 ret

quit:
 res onInterrupt,(iy+onflags)
 set graphdraw,(iy+graphflags)
 jp _clrScrn

playertext: .db "Player ",0
playerxtext: .db "X starts",0
xwintext: .db "X won!",0
turntext: .db " turn",0
by: .db "by Makee",0
ProgramEnd:
sel = ProgramEnd
x = ProgramEnd+1
y = ProgramEnd+2
screenx = ProgramEnd+3
screeny = ProgramEnd+4
row = ProgramEnd+5
xcheck = ProgramEnd+6
ycheck = ProgramEnd+7
.end
