#include "ti86asm.inc"
#include "ti86math.inc"
#include "asm86.h"

.org _asm_exec_ram
_asapvar = $d6fc
_set_abs_src_addr = $4647
_set_abs_dest_addr = $5285
_set_mm_num_bytes = $464f
_mm_ldir = $52ed
level = _textShadow
x = _textShadow+1
y = _textShadow+2
dee = _textShadow+3
ee = _textShadow+4
lastk = _textShadow+5
sel = _textShadow+6
speed = _textShadow+7
spd = _textShadow+8
    nop
    jr ProgStart
    .dw 0
    .dw ShellTitle+1
ShellTitle:
    .db 12,"Tunnel Snake by Makee",0
ProgStart:
 res textInverse,(iy+textflags)
 call _runindicoff
 call _flushallmenus
 call _clrLCD
 ld hl,256*4+0
 ld (_curRow),hl
 ld hl,ShellTitle
 call _putps
 ld a,(maxlev)
 or a
 jr nz,noinit
 inc a
 ld (maxlev),a
noinit:
 ld bc,256*16+38
 ld (_penCol),bc
 ld hl,startlevtxt
 call _vputs
 ld bc,256*23+50
 ld (_penCol),bc
 call _vputs
 ld bc,256*44
 ld (_penCol),bc
 call _vputs
 ld a,49
 ld bc,256*16+90
 ld (_penCol),bc
 call _vputmap
 ld a,53
 ld bc,256*23+75
 ld (_penCol),bc
 call _vputmap
 ld bc,256*44+35
 ld (_penCol),bc
 ld hl,(hiscore)
 call DispHL
 xor a
 ld (sel),a
 inc a
 ld (level),a
 ld a,5
 ld (spd),a
 set textInverse,(iy+textflags)
 call invert
waitkey:
 call _getky
 cp K_DOWN
 jr z,scroll
 cp K_UP
 jr z,scroll
 cp K_ENTER
 jp z,startgame
 cp 54
 jp z,startgame
 cp K_LEFT
 jr z,left
 cp K_RIGHT
 jr z,right
 cp K_EXIT
 jp z,saveandquit
 jr waitkey
scroll:
 call invert
 ld a,(sel)
 xor 1
 ld (sel),a
 call invert
 jr waitkey
left:
 ld a,(sel)
 or a
 jr z,lvldown
 jr speedown
right:
 ld a,(sel)
 or a
 jr z,lvlup
 jr speedup
lvlup:
 ld a,(level)
 ld b,a
 ld a,(maxlev)
 cp b
 jr z,waitkey
 ld a,(level)
 inc a
 jr showlevel
lvldown:
 ld a,(level)
 dec a
 jr z,waitkey
showlevel:
 ld (level),a
 ld hl,256*16+86
 ld (_penCol),hl
 call DispA
 jr waitkey
speedown:
 ld a,(spd)
 dec a
 jr z,waitkey
 jr showspeed
speedup:
 ld a,(spd)
 cp 9
 jr z,waitkey
 inc a
showspeed:
 ld (spd),a
 ld hl,256*23+71
 ld (_penCol),hl
 call DispA
 jp waitkey

invert:
 ld hl,$fd00
 ld a,(sel)
 or a
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

startgame:
 res textInverse,(iy+textflags)
 ld hl,0
 ld (tscore),hl
 ld a,(level)
 dec a
 ld (level),a
 ld a,(spd)
 cp 1
 jr z,set1
 cp 2
 jr z,set2
 cp 3
 jr z,set3
 cp 4
 jr z,set4
 cp 5
 jr z,set5
 cp 6
 jr z,set6
 cp 7
 jr z,set7
 cp 8
 jr z,set8
 cp 9
 jr z,set9
set1:
 ld a,250
 jr donespeed
set2:
 ld a,210
 jr donespeed
set3:
 ld a,176
 jr donespeed
set4:
 ld a,148
 jr donespeed
set5:
 ld a,124
 jr donespeed
set6:
 ld a,105
 jr donespeed
set7:
 ld a,88
 jr donespeed
set8:
 ld a,74
 jr donespeed
set9:
 ld a,62
donespeed:
 ld (speed),a
newlevelbegin:
 call _clrLCD
 ld a,(level)
 inc a
 ld (level),a
 ld b,a
 ld a,(maxlev)
 cp b
 call c,newlevelrecord
 ld a,177
 ld (score),a
 ld a,34
 ld (y),a
 ld a,7
 ld (x),a
line1:
 ld hl,$fe20
 ld a,255
 ld (hl),a
line2:
 ld a,(level)
 ld b,a
 ld hl,$fd60
 ld de,$10
adding:
 add hl,de
 djnz adding
 ld a,255
 ld (hl),a
generateloop:
 call random
 or a
 jr z,noincreasex
increasex:
 ld a,(ee)
 or a
 jr nz,enotzero
 ld (dee),a
enotzero:
 xor a
 ld (ee),a
mustincreasex:
 ld a,(x)
 inc a
 ld (x),a
 jr randfory
noincreasex:
 ld a,1
 ld (ee),a
 ld a,(dee)
 inc a
 ld (dee),a
 ld a,(level)
 ld b,a
 ld a,9
 sub b
 push af
 ld a,(dee)
 ld b,a
 pop af
 sub b
 jr c,mustincreasex
randfory:
 call random
 or a
 jr z,decreasey
increasey:
 ld a,(y)
 inc a
 cp 63
 jr nz,ynottoomuch
 dec a
ynottoomuch:
 ld (y),a
 jr putpixels
decreasey:
 ld a,(level)
 ld b,a
 ld a,(y)
 dec a
 ld c,a
 add a,b
 sub 11
 jr nz,ynottoolow
 inc c
ynottoolow:
 ld a,c
 ld (y),a
putpixels:
 ld a,(x)
 cp 128
 jr z,snakestart
 ld b,a
 ld a,(y)
 ld c,a
 call FindPixel
 or (hl)
 ld (hl),a
 ld a,(level)
 ld b,a
 ld a,(y)
 sub 12
 add a,b
 ld c,a
 ld a,(x)
 ld b,a
 call FindPixel
 or (hl)
 ld (hl),a
 jp generateloop
snakestart:
 res onInterrupt,(iy+onflags)
 ld hl,0
 ld (_penCol),hl
 ld hl,readytxt
 call _vputs
 call _getkey
 ld hl,0
 ld (_penCol),hl
 ld hl,empty
 call _vputs
 xor a
 ld (x),a
 ld a,32
 ld (y),a
 ld a,K_RIGHT
 ld (lastk),a
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
 jp z,ProgStart
 ld a,(lastk)
 jr keypress
moveup:
 ld (lastk),a
 ld a,(y)
 dec a
 ld (y),a
 jr move
moveleft:
 ld (lastk),a
 ld a,(x)
 dec a
 ld (x),a
 jr move
moveright:
 ld (lastk),a
 ld a,(x)
 inc a
 ld (x),a
 jr move
movedown:
 ld (lastk),a
 ld a,(y)
 inc a
 ld (y),a
move:
 ld a,(x)
 cp 128
 jr z,levdone
 ld b,a
 ld a,(y)
 ld c,a
 push bc
 ld a,(score)
 or a
 jr z,scoreiszero
 dec a
 ld (score),a
scoreiszero:
 call pixeltest
 pop bc
 jp nz,died
 call pixel_on
delay:
 ld a,(speed)
 ld e,a
dela:
 dec e
 jr nz,dela
 dec a
 jr nz,dela
 jp getcmd

pixel_on:
 call FindPixel
 or (hl)
 ld (hl),a
 ret

pixeltest:
 call FindPixel
 and (hl)
 ret

levdone:
 call box
 ld hl,0
 ld (_penCol),hl
 ld hl,completetxt
 call _vputs
 ld a,(level)
 ld hl,67
 ld (_penCol),hl
 call DispA
 ld hl,256*6
 ld (_penCol),hl
 ld hl,levscoretxt
 call _vputs
 ld hl,256*12
 ld (_penCol),hl
 ld hl,tscoretxt
 call _vputs
incscore:
 ld a,(spd)
 ld b,a
 add a,a
 add a,a
 add a,a
 add a,b
 add a,b
 ld c,a
 ld b,0
 ld hl,(score)
 add hl,bc
 ld (score),hl
 ld hl,256*6+40
 ld (_penCol),hl
 ld hl,(score)
 call DispHL
 ld hl,256*12+40
 ld (_penCol),hl
addscores:
 ld hl,(tscore)
 ld de,(score)
 add hl,de
 ld (tscore),hl
 call DispHL
 call _getkey
 jp newlevelbegin
died:
 call box
 ld hl,0
 ld (_penCol),hl
 ld hl,dietxt
 call _vputs
 ld hl,64
 ld (_penCol),hl
 ld hl,(tscore)
 call DispHL
 ld hl,(hiscore)
 ld b,h
 ld hl,(tscore)
 ld a,h
 cp b
 jr z,checksmall
 jr nc,newscore
 jr wait
checksmall:
 ld a,l
 ld hl,(hiscore)
 ld b,l
 cp b
 jr z,wait
 jr nc,newscore
 jr wait
newscore:
 ld hl,256*6
 ld (_penCol),hl
 ld hl,newhiscoretxt
 call _vputs
 ld hl,(tscore)
 ld (hiscore),hl
 jr wait

saveandquit:
 ld hl,_asapvar
 rst 20h
 rst 10h
 ld a,b
 ld hl,data_start-_asm_exec_ram+4
 add hl,de
 adc a,0
 call _set_abs_dest_addr
 xor a
 ld hl,data_start
 call _set_abs_src_addr
 ld hl,data_end-data_start
 call _set_mm_num_bytes
 call _mm_ldir
 call _clrScrn
 res onInterrupt,(iy+onflags)
 res textInverse,(iy+textflags)
 jp _homeup
wait:
 call _getky
 cp K_ENTER
 jr nz,wait
 jp ProgStart

#include "findpixel.asm"

DispA:
 ld l,a
 ld h,0
DispHL:
 xor a
 ld de,-1
 ld (_curRow),de
 call 4A33h
 dec hl
 jp _vputs

newlevelrecord:
 ld a,(level)
 ld (maxlev),a
 ret
box:
 ld hl,$fbff
 ld de,6
 ld b,10
boxloop:
 inc hl
 ld a,0
 ld (hl),a
 djnz boxloop
 ld a,1
 ld (hl),a
 add hl,de
 ld b,10
 ld a,h
 cp 254
 jr nz,boxloop
 inc hl
drawline:
 ld a,255
 ld (hl),a
 inc hl
 djnz drawline
 ret

random:        ; Creates a pseudorandom number 0 <= x < A
    push bc
    push hl
    ld b,2
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
    pop hl
    pop bc
    ret

startlevtxt: .db "Starting level:",0
speedtxt: .db "Speed:",0
hiscoretxt: .db "High score:",0
completetxt: .db "You completed level",0
levscoretxt: .db "Level score:",0
readytxt: .db "Ready!",0
empty: .db "                     ",0
newhiscoretxt: .db "New high score!",0
dietxt: .db "You crashed, score:",0
tscoretxt: .db "Total score:",0
pausetxt: .db "Paused",0
score: .db 0,0
tscore: .db 0,0
data_start:
hiscore: .db 0,0
maxlev: .db 0
randseed: .dw $d2a2
data_end:
.end