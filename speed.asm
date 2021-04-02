#include "ti86asm.inc"

.org _asm_exec_ram
_ldhlz = $437B
_asapvar        =$d6fc
_set_abs_src_addr   =$4647
_set_abs_dest_addr  =$5285
_set_mm_num_bytes   =$464f
_mm_ldir        =$52ed
;c9fa = 51706 (userdata)
;       52218 (numberdata)
    nop
    jp ProgStart
    .dw 0
    .dw ShellTitle

ShellTitle:
    .db "Speed game by Makee",0

ProgStart:
 ld hl,$D400
 ld de,$D401
 ld bc,$0100
 ld (hl),$D3
 ldir
 ld hl,int_handler
 ld de,$D3D3
 ld bc,int_end-int_handler
 ldir
 ld a,$D4
 ld i,a
 im 2
 call _clrLCD
 call _runindicoff
 call _flushallmenus
 xor a
 ld (level),a
 ld hl,_plotSScreen
 ld (hl),10
 ld de,_plotSScreen+1
 ld bc,1023
 ldir
 ld hl,ShellTitle
 ld bc,256
 ld (_curRow),bc
 call _puts
 ld bc,256*2+3
 ld (_curRow),bc
 ld hl,highscoretxt
 call _puts
 ld hl,(record)
 call disphl
 call _newline
 call _newline
 ld hl,anykeytxt
 call _puts
waitkey:
 halt
 call _getky
 or a
 jr z,waitkey
 cp K_EXIT
 jr nz,startgame
quit:
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
 im 1
 call _clrScrn
 jp _homeup
startgame:
 ld hl,0
 ld (timer),hl
 call _clrLCD
 call _homeup
 ld hl,scoretxt
 call _puts
waitgamekey:
 ld a,(level)
 ld b,a
 ld a,150
 sub b
 ld b,a
 ld a,(timer)
 sub b
; push af
; call dispa
; pop af
 jr nz,checkkeys
 ld (timer),a
 call Clear
again:
 call random
 push af
 ld a,(lastnum)
 ld b,a
 pop af
 cp b
 jr z,again
 ld hl,(numdataptr)
 ld (hl),a
 inc hl
 ld (numdataptr),hl
 ld (lastnum),a
 ld de,512
 or a
 sbc hl,de
 ex de,hl
 ld hl,(userdataptr)
 ld a,e
 sub l
 cp 5
 jr nc,tooslow
 call Invert

checkkeys:
 halt
 call _getky
 sub K_F4
 jr z,f4
 dec a
 jr z,f3
 dec a
 jr z,f2
 dec a
 jr z,f1
 cp K_EXIT-K_F4-3
 jp z,wrong
 jr waitgamekey
f4:
 inc a
f3:
 inc a
f2:
 inc a
f1:
 ld hl,(userdataptr)
 ld (hl),a
 inc hl
 ld (userdataptr),hl
 ld de,511
 add hl,de
 ld b,a
 ld a,(hl)
 cp b
 jp nz,wrong
 ld hl,(points)
 inc hl
 ld (points),hl
 ld a,(level)
 inc a
 ld (level),a
 ld bc,256*6
 ld (_curRow),bc
 call disphl
 jp waitgamekey

tooslow:
 ld bc,256*6+1
 ld (_curRow),bc
 ld hl,tooslowtxt
 call _puts
 jr gameover
wrong:
 ld bc,256*7+1
 ld (_curRow),bc
 ld hl,wrongtxt
 call _puts
gameover:
 ld hl,record+1
 ld a,(points+1)
 cp (hl)
 jr c,nonewhighscore
 jr z,checksmall
 jr newhighscore
checksmall:
 dec hl
 ld a,(points)
 cp (hl)
 jr c,nonewhighscore
 jr z,nonewhighscore
newhighscore:
 ld hl,(points)
 ld (record),hl
 ld bc,256*3+3
 ld (_curRow),bc
 ld hl,newhighscoretxt
 call _puts
nonewhighscore:
 halt
 call _getky
 or a
 jr z,nonewhighscore
 jp quit

Clear:
 ld hl,$fc00+(16*40)
 ld b,16*7
 call _ldhlz
 ret

Invert:
 ld hl,$fc00+(16*40)
 ld a,(lastnum)
 add a,a
 add a,a
 ld e,a
 ld d,0
 add hl,de
 ld b,7
 ld de,16
Invloop:
 ld (hl),255
 add hl,de
 djnz Invloop
 ret

random:
 push bc
 push hl
 ld b,4
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

int_handler:
 ex af,af'
 ld a,(timer)
 inc a
 ld (timer),a
 ld a,($C1B4)
 cp $1D
 jr c,int_ok
 cp $20
 jr nc,int_ok
 im 1
 jp $0039
int_ok:
 in a,($03)
 bit 3,a
 jp z,$0039
 res 0,a
 out ($03),a
 jp $0039
int_end:

dispa:
 ld l,a
 ld h,0
disphl:
 xor a
 jp $4a33

anykeytxt: .db "Press a key to start",0
wrongtxt: .db "Wrong!",0
tooslowtxt: .db "Too slow!",0
newhighscoretxt: .db "New high score!",0
highscoretxt: .db "High score:",0
scoretxt: .db "Score:",0

data_start:
randseed: .db 0,0
record: .db 0,0
data_end:

timer: .db 0
level: .db 0
lastnum: .db 0
points: .db 0,0

numdataptr: .dw numberdata
userdataptr: .dw userdata

userdata = _plotSScreen
numberdata = _plotSScreen+512

.end
