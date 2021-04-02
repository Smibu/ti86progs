#include "ti86asm.inc"
#include "ti86ops.inc"
#include "asm86.h"
.org _asm_exec_ram
_asapvar = $d6fc
_set_abs_src_addr = $4647
_set_abs_dest_addr = $5285
_set_mm_num_bytes = $464f
_mm_ldir = $52ed
.plugin lite86
    nop
    jp ProgStart
    .dw 0
    .dw ShellTitle
ShellTitle:
    .db "Calendar",0
ProgStart:
 res textInverse,(iy+textflags)
 call _runindicoff
 call _flushallmenus
 call _clrLCD
 xor a
 ld (leapyear),a
 ld a,(month)
 cp 0
 call z,init
;texts
 ld hl,256*6
 ld (_curRow),hl
 ld hl,titletxt
 call _puts
 ld hl,256*12+48
 ld (_penCol),hl
 ld hl,monthtxt
 call _vputs
 ld hl,256*19+43
 ld (_penCol),hl
 ld hl,centtxt
 call _vputs
 ld hl,256*26+48
 ld (_penCol),hl
 ld hl,yrtxt
 call _vputs
 ld hl,256*33+38
 ld (_penCol),hl
 ld hl,viewcaltxt
 call _vputs
 ld a,(month)
 ld hl,256*12+70
 ld (_penCol),hl
 call DispA
 ld a,(century)
 ld hl,256*19+76
 ld (_penCol),hl
 call DispA
 ld a,(yrs)
 ld hl,256*26+68
 ld (_penCol),hl
 call DispA
 set textInverse,(iy+textflags)
 ld a,1
 ld (sel),a
 call invert
waitkey:
 call _getky
 cp K_DOWN
 jr z,scrdown
 cp K_UP
 jr z,scrup
 cp K_ENTER
 jp z,go
 cp K_LEFT
 jr z,left
 cp K_RIGHT
 jr z,right
 cp K_EXIT
 jp z,quit
 jr waitkey
scrdown:
 ld a,(sel)
 cp 4
 jr z,waitkey
 call invert
 ld a,(sel)
 inc a
 ld (sel),a
 call invert
 jr waitkey
scrup:
 ld a,(sel)
 cp 1
 jr z,waitkey
 call invert
 ld a,(sel)
 dec a
 ld (sel),a
 call invert
 jr waitkey
left:
 ld a,(sel)
 cp 1
 jr z,monthdown
 cp 2
 jp z,centdown
 cp 3
 jp z,yrdown
 jr waitkey
right:
 ld a,(sel)
 cp 1
 jr z,monthup
 cp 2
 jp z,centup
 cp 3
 jp z,yrup
 jr waitkey
monthdown:
 ld a,(month)
 cp 1
 jp z,waitkey
 dec a
 ld (month),a
 cp 9
 jr nz,showmonth
 ld hl,256*12+77
 ld (_penCol),hl
 ld hl,emptysm
 call _vputs
 jr showmonth
monthup:
 ld a,(month)
 cp 12
 jp z,waitkey
 inc a
 ld (month),a
showmonth:
 ld a,(month)
 ld hl,256*12+70
 ld (_penCol),hl
 call DispA
 jp waitkey
centdown:
 ld a,(century)
 cp 0
 jp z,waitkey
 dec a
 ld (century),a
 cp 9
 jr nz,showcentury
 ld hl,256*19+83
 ld (_penCol),hl
 ld hl,emptysm
 call _vputs
 jr showcentury
centup:
 ld a,(century)
 cp 28
 jp z,waitkey
 inc a
 ld (century),a
showcentury:
 ld a,(century)
 ld hl,256*19+76
 ld (_penCol),hl
 call DispA
 jp waitkey
yrdown:
 ld a,(yrs)
 cp 0
 jp z,waitkey
 dec a
 ld (yrs),a
 cp 9
 jr nz,showyr
 ld hl,256*26+75
 ld (_penCol),hl
 ld hl,emptysm
 call _vputs
 jr showyr
yrup:
 ld a,(yrs)
 cp 99
 jp z,waitkey
 inc a
 ld (yrs),a
showyr:
 ld a,(yrs)
 ld hl,256*26+68
 ld (_penCol),hl
 call DispA
 jp waitkey
invert:
 ld hl,$fc50
 ld de,$70
 ld a,(sel)
 ld b,a
addloop:
 add hl,de
 djnz addloop
 ld b,112
invertloop:
 ld a,(hl)
 cpl
 ld (hl),a
 inc hl
 djnz invertloop
 ret
go:
 ld a,(sel)
 cp 4
 jr z,viewcalendar
 cp 5
 jp z,quit
 jp waitkey
viewcalendar:
 call _clrLCD
 res textInverse,(iy+textflags)
 ld a,(month)
 cp 1
 jr z,t1set1
 cp 10
 jr z,t1set1
 cp 5
 jr z,t1set2
 cp 8
 jr z,t1set3
 cp 6
 jr z,t1set5
 cp 9
 jr z,t1set6
 cp 12
 jr z,t1set6
 cp 4
 jr z,t1set7
 cp 7
 jr z,t1set7
t1set4:
 ld a,4
 ld (t1),a
 jr checkcentury
t1set1:
 ld a,1
 ld (t1),a
 jr checkcentury
t1set2:
 ld a,2
 ld (t1),a
 jr checkcentury
t1set3:
 ld a,3
 ld (t1),a
 jr checkcentury
t1set5:
 ld a,5
 ld (t1),a
 jr checkcentury
t1set6:
 ld a,6
 ld (t1),a
 jr checkcentury
t1set7:
 ld a,7
 ld (t1),a
checkcentury:
 ld a,(century)
 cp 1
 jp z,t2set6
 cp 8
 jr z,t2set6
 cp 15
 jr z,t2set6
 cp 2
 jr z,t2set5
 cp 9
 jr z,t2set5
 cp 18
 jr z,t2set5
 cp 22
 jr z,t2set5
 cp 26
 jr z,t2set5
 cp 3
 jr z,t2set4
 cp 10
 jr z,t2set4
 cp 4
 jr z,t2set3
 cp 11
 jr z,t2set3
 cp 19
 jr z,t2set3
 cp 23
 jr z,t2set3
 cp 27
 jr z,t2set3
 cp 5
 jr z,t2set2
 cp 12
 jr z,t2set2
 cp 16
 jr z,t2set2
 cp 20
 jr z,t2set2
 cp 24
 jr z,t2set2
 cp 28
 jr z,t2set2
 cp 6
 jr z,t2set1
 cp 13
 jr z,t2set1
t2set7:
 ld a,7
 ld (t2),a
 jr checkyr
t2set1:
 ld a,1
 ld (t2),a
 jr checkyr
t2set2:
 ld a,2
 ld (t2),a
 jr checkyr
t2set3:
 ld a,3
 ld (t2),a
 jr checkyr
t2set4:
 ld a,4
 ld (t2),a
 jr checkyr
t2set5:
 ld a,5
 ld (t2),a
 jr checkyr
t2set6:
 ld a,6
 ld (t2),a
checkyr:
 ld a,(yrs)
 cp 1
 jp z,plus1
 cp 7
 jp z,plus1
 cp 12
 jp z,plus1
 cp 18
 jp z,plus1
 cp 29
 jp z,plus1
 cp 35
 jp z,plus1
 cp 40
 jp z,plus1
 cp 46
 jp z,plus1
 cp 57
 jp z,plus1
 cp 63
 jp z,plus1
 cp 68
 jp z,plus1
 cp 74
 jp z,plus1
 cp 85
 jp z,plus1
 cp 91
 jp z,plus1
 cp 96
 jp z,plus1
 cp 2
 jp z,plus2
 cp 13
 jp z,plus2
 cp 19
 jp z,plus2
 cp 24
 jp z,plus2
 cp 30
 jp z,plus2
 cp 41
 jp z,plus2
 cp 47
 jp z,plus2
 cp 52
 jp z,plus2
 cp 58
 jp z,plus2
 cp 69
 jp z,plus2
 cp 75
 jp z,plus2
 cp 80
 jp z,plus2
 cp 86
 jp z,plus2
 cp 97
 jp z,plus2
 cp 3
 jp z,plus3
 cp 8
 jp z,plus3
 cp 14
 jp z,plus3
 cp 25
 jp z,plus3
 cp 31
 jp z,plus3
 cp 36
 jp z,plus3
 cp 42
 jp z,plus3
 cp 53
 jp z,plus3
 cp 59
 jp z,plus3
 cp 64
 jp z,plus3
 cp 70
 jp z,plus3
 cp 81
 jp z,plus3
 cp 87
 jp z,plus3
 cp 92
 jp z,plus3
 cp 98
 jp z,plus3
 cp 9
 jp z,plus4
 cp 15
 jp z,plus4
 cp 20
 jp z,plus4
 cp 26
 jp z,plus4
 cp 37
 jp z,plus4
 cp 43
 jp z,plus4
 cp 48
 jp z,plus4
 cp 54
 jp z,plus4
 cp 65
 jp z,plus4
 cp 71
 jp z,plus4
 cp 76
 jp z,plus4
 cp 82
 jp z,plus4
 cp 93
 jp z,plus4
 cp 99
 jp z,plus4
 cp 4
 jp z,plus5
 cp 10
 jp z,plus5
 cp 21
 jp z,plus5
 cp 27
 jp z,plus5
 cp 32
 jp z,plus5
 cp 38
 jp z,plus5
 cp 49
 jp z,plus5
 cp 55
 jp z,plus5
 cp 60
 jp z,plus5
 cp 66
 jp z,plus5
 cp 77
 jp z,plus5
 cp 83
 jp z,plus5
 cp 88
 jp z,plus5
 cp 94
 jp z,plus5
 cp 5
 jp z,plus6
 cp 11
 jp z,plus6
 cp 16
 jp z,plus6
 cp 22
 jp z,plus6
 cp 33
 jp z,plus6
 cp 39
 jp z,plus6
 cp 44
 jp z,plus6
 cp 50
 jp z,plus6
 cp 61
 jp z,plus6
 cp 67
 jp z,plus6
 cp 72
 jp z,plus6
 cp 78
 jp z,plus6
 cp 89
 jp z,plus6
 cp 95
 jp z,plus6
 jr checkleapyear
plus1:
 ld a,(t2)
 inc a
 ld (t2),a
 jr checkleapyear
plus2:
 ld a,(t2)
 add a,2
 ld (t2),a
 jr checkleapyear
plus3:
 ld a,(t2)
 add a,3
 ld (t2),a
 jr checkleapyear
plus4:
 ld a,(t2)
 add a,4
 ld (t2),a
 jr checkleapyear
plus5:
 ld a,(t2)
 add a,5
 ld (t2),a
 jr checkleapyear
plus6:
 ld a,(t2)
 add a,6
 ld (t2),a
checkleapyear:
 ld a,(t2)
 cp 8
 jr c,nosub
 sub 7
 ld (t2),a
nosub:
 ld a,(t1)
 ld b,a
 ld a,(t2)
 add a,b
 ld (t3),a
 cp 8
 jr c,convwholeyear
 sub 7
 ld (t3),a
convwholeyear:
 ld d,0
 ld a,(century)
 ld e,a
 ld h,0
 ld a,(century)
 ld l,a
 ld b,99
multloop:
 add hl,de
 djnz multloop
 ld b,0
 ld a,(yrs)
 ld c,a
 add hl,bc
 ld (years),hl
 ld a,(month)
 cp 3
 jr nc,noleapyear
 ld hl,(years)
checkloop:
 dec hl
 dec hl
 dec hl
 dec hl
 ld a,h
 cp 0
 jr nz,checkloop
checkloop2:
 dec hl
 dec hl
 dec hl
 dec hl
 ld a,l
 cp 0
 jr z,isleapyear
 cp 1
 jr z,noleapyear
 cp 2
 jr z,noleapyear
 cp 3
 jr z,noleapyear
 jr checkloop2
isleapyear:
 ld a,1
 ld (leapyear),a
 ld a,(t3)
 dec a
 cp 0
 jr nz,not0
 ld a,7
not0:
 ld (t3),a
noleapyear:
 ld a,(t3)
 ld b,a
 ld a,55
columnloop:
 add a,18
 cp 127
 jr nz,not1
 ld a,1
not1:
 djnz columnloop
 ld (x),a
 ld hl,256*2+73
 ld (_penCol),hl
 ld a,(month)
 cp 2
 jr z,feb
 cp 3
 jr z,mar
 cp 4
 jr z,apr
 cp 5
 jr z,may
 cp 6
 jr z,jun
 cp 7
 jr z,jul
 cp 8
 jr z,aug
 cp 9
 jr z,sep
 cp 10
 jr z,oct
 cp 11
 jr z,nov
 cp 12
 jr z,dece
jan:
 ld hl,jantxt
 jr printmonth
feb:
 ld hl,febtxt
 jr printmonth
mar:
 ld hl,martxt
 jr printmonth
apr:
 ld hl,aprtxt
 jr printmonth
may:
 ld hl,maytxt
 jr printmonth
jun:
 ld hl,juntxt
 jr printmonth
jul:
 ld hl,jultxt
 jr printmonth
aug:
 ld hl,augtxt
 jr printmonth
sep:
 ld hl,septxt
 jr printmonth
oct:
 ld hl,octtxt
 jr printmonth
nov:
 ld hl,novtxt
 jr printmonth
dece:
 ld hl,dectxt
printmonth:
 call _vputs
 ld hl,256*2+110
 ld (_penCol),hl
 ld hl,(years)
 call DispHL
printdays:
 ld hl,256*8+4
 ld (_penCol),hl
 ld hl,montxt
 call _vputs
 ld hl,256*8+22
 ld (_penCol),hl
 ld hl,tuetxt
 call _vputs
 ld hl,256*8+40
 ld (_penCol),hl
 ld hl,wedtxt
 call _vputs
 ld hl,256*8+58
 ld (_penCol),hl
 ld hl,thutxt
 call _vputs
 ld hl,256*8+76
 ld (_penCol),hl
 ld hl,fritxt
 call _vputs
 ld hl,256*8+94
 ld (_penCol),hl
 ld hl,sattxt
 call _vputs
 ld hl,256*8+112
 ld (_penCol),hl
 ld hl,suntxt
 call _vputs
 ld a,14
 ld (y),a
 ld a,(month)
 cp 4
 jr z,set30
 cp 6
 jr z,set30
 cp 9
 jr z,set30
 cp 11
 jr z,set30
 cp 2
 jr z,checkleap
 jr set31
set30:
 ld b,30
 jr nochanges
checkleap:
 ld a,(leapyear)
 cp 1
 jr z,set29
 ld b,28
 jr nochanges
set31:
 ld b,31
 jr nochanges
set29:
 ld b,29
nochanges:
 ld c,1
viewdaysloop:
 ld a,(y)
 ld h,a
 ld a,(x)
 ld l,a
 ld (_penCol),hl
 ld a,c
 call DispA
 ld a,(x)
 add a,18
 ld (x),a
 cp 110
 jr c,nonewline
 ld a,1
 ld (x),a
 ld a,(y)
 add a,8
 ld (y),a
nonewline:
 inc c
 djnz viewdaysloop
 res onInterrupt,(iy+onflags)
 call _getkey
 jp ProgStart
quit:
 ld hl,_asapvar
 rst 20h
 rst 10h
 ld a,b
 ld hl,data_start-_asm_exec_ram+4
 add hl,de
 adc a,$00
 call _set_abs_dest_addr
 xor a
 ld hl,data_start
 call _set_abs_src_addr
 ld hl,data_end-data_start
 call _set_mm_num_bytes
 call _mm_ldir
 call _homeup
 res onInterrupt,(iy+onflags)
 res textInverse,(iy+textflags)
 jp _clrScrn
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
init:
 ld a,8
 ld (month),a
 ld (sel),a
 ld a,20
 ld (century),a
 ld a,6
 ld (yrs),a
 ret
titletxt: .db "Calendar",0
monthtxt: .db "Month:",0
centtxt: .db "Centuries:",0
yrtxt: .db "Years:",0
emptysm: .db "   ",0
viewcaltxt: .db "View calendar",0
jantxt: .db "January",0
febtxt: .db "February",0
martxt: .db "March",0
aprtxt: .db "April",0
maytxt: .db "May",0
juntxt: .db "June",0
jultxt: .db "July",0
augtxt: .db "August",0
septxt: .db "September",0
octtxt: .db "October",0
novtxt: .db "November",0
dectxt: .db "December",0
montxt: .db "MO",0
tuetxt: .db "TU",0
wedtxt: .db "WE",0
thutxt: .db "TH",0
fritxt: .db "FR",0
sattxt: .db "SA",0
suntxt: .db "SU",0
years: .db 0,0
sel: .db 0
t1: .db 0
t2: .db 0
t3: .db 0
x: .db 0
y: .db 0
leapyear: .db 0
data_start:
month: .db 0
century: .db 0
yrs: .db 0
data_end:
.end
