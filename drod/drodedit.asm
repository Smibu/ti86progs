#include "ti86.inc"
.org _asm_exec_ram
_ldhlz = $437b
string =_plotSScreen
CurrentRoom =string+512

;.plugin lite86
    nop
    jp ProgStart
    .dw 0
    .dw ShellTitle+3

;if more data: use lddr
;if data deleted: use ldir

ProgStart:
 call ResetFlagsAll
 call _clrScrn
 call _runindicoff
 call _flushallmenus
 call _homeup
 ld hl,roomstart
 ld (hl),0
 ld de,roomstart+1
 ld bc,$fa70-roomstart
 ldir
 ld hl,ShellTitle
 call _putps
 call _newline
 call _newline
 ld hl,newleveltxt
 call _puts
 call _newline
 call _puts
 ld b,2
 call DoMenu
 cp K_EXIT-1
 jp z,quitnow
 dec a
 jp nz,LoadLevel

CreateNew:
 ld bc,4
 ld (_curRow),bc
 ld hl,filenametxt
 call _puts
 xor a
 ld (string),a
 ld a,8
 ld (length),a
 call GetString
 jr z,ProgStart
 ld hl,string
 ld de,filename
 ld bc,9
 ldir
EditStart:
 xor a
 ld (filenameinput),a
 call ResetFlagsAll
 call FindRoom
 call CopyRoom
editnow:
 call FindRoom
 jp c,waitaction
 call UpdateScreen
 call InvertSelect
WaitKey:
 ld b,15
HALT_LOOP:
 push bc
 call _getky
 pop bc
 cp 5
 jr nc,KeyWasPressed
 halt
 djnz HALT_LOOP
 ld a,%01111110
 out (1),a
 nop
 nop
 in a,(1)
 rrca
 push af
 call nc,down
 pop af
 rrca
 push af
 call nc,left
 pop af
 rrca
 push af
 call nc,right
 pop af
 rrca
 push af
 call nc,up
 pop af
KeyWasPressed:
 ld d,a
 ld a,%00111111
 out (1),a
 nop
 nop
 in a,(1)
 bit 5,a
 jp z,PlaceorChooseTile
 ld a,d
 cp K_EXIT
 jp z,CheckMenu
 cp K_PLUS
 call z,ContrastUp
 cp K_MINUS
 call z,ContrastDown
 ld a,(selectmode)
 or a
 jr nz,WaitKey
 ld a,d
 cp K_8
 jr z,roomup
 cp K_2
 jr z,roomdown
 cp K_4
 jr z,roomleft
 cp K_6
 jr z,roomright
 cp K_DEL
 jr z,deletetile
 sub K_F5
 jp z,SelectTile
 jr WaitKey

deletetile:
 call GetAddress
 dec a
 call z,deletemessage
 call GetAddress
 xor a
 jp placezero

roomup:
 call SaveCurrentRoom
 ld hl,roomcoords+1
 dec (hl)
 jr doneroomscroll

roomdown:
 call SaveCurrentRoom
 ld hl,roomcoords+1
 inc (hl)
 jr doneroomscroll

roomleft:
 call SaveCurrentRoom
 ld hl,roomcoords
 dec (hl)
 jr doneroomscroll

roomright:
 call SaveCurrentRoom
 ld hl,roomcoords
 inc (hl)
doneroomscroll:
 call FindRoom
 jr c,waitaction
 call CopyRoom
 call UpdateScreen
 call InvertSelect
 jp WaitKey

waitaction:
 call _clrLCD
 call _homeup
 ld hl,noroomtxt
 call _puts
 call _newline
 call _puts
waitactionkey:
 halt
 call _getky
 cp K_ENTER
 jr z,createroom
 cp K_EXIT
 jp z,menu
 cp K_8
 jr z,roomup+3
 cp K_2
 jr z,roomdown+3
 cp K_4
 jr z,roomleft+3
 cp K_6
 jr z,roomright+3
 jr waitactionkey

createroom:
;find the last room
 call FindLastByte
 ld hl,(temp3)
 ld (hl),255
 inc hl
 ex de,hl
 ld hl,roomcoords
 ld bc,2
 ldir
 jr doneroomscroll

SelectTile:
 inc a
 ld (selectmode),a
 ld hl,(x)
 ld (temp3),hl
 ld hl,0
 ld (x),hl
 ld hl,CurrentRoom
 ld de,_plotSScreen
 ld bc,144
 ldir
 ld hl,CurrentRoom
 ld b,144
 call _ldhlz
 ld hl,CurrentRoom
 ld a,-1
 ld b,49
tilesetloop:
 inc a
 cp 5
 jr z,tilesetloop
 cp 7
 jr c,go
 cp 15
 jr c,tilesetloop
 cp 23
 jr c,go
 cp 31
 jr c,tilesetloop
 cp 32
 jr c,go
 cp 40
 jr c,tilesetloop
 cp 66
 jr c,go
 cp 74
 jr c,tilesetloop
go:
 ld (hl),a
 inc hl
 djnz tilesetloop
 call UpdateScreen
 call InvertSelect
 jp WaitKey

PlaceorChooseTile:
 ld a,(selectmode)
 or a
 jr z,PlaceTile
 call GetAddress
 ld (currtile),a
 jp return

PlaceTile:
 call GetAddress
 ld a,(currtile)
 cp 1        ;message
 jr z,check
 cp 4           ;mimic potion
 jr z,check
 jr placenow
check:
 ld hl,CurrentRoom
 ld bc,145
 cpir
 ld a,c
 or a
 jp nz,WaitKey
placenow:
 call GetAddress
 dec a
 call z,deletemessage
 ld a,(currtile)
placezero:
 push af
 call GetAddress
 pop af
 ld (hl),a
 dec a
 jr nz,skipmessagetext
 call _clrScrn
 xor a
 ld (string),a
 ld a,146
 ld (length),a
 call _homeup
 ld hl,entertxt
 call _puts
 call _newline
 call GetString
 jr z,placezero
;save message text
 call FindLastByte
 push hl
 call FindByteAfterCurrent
 ex de,hl
 pop hl
 or a
 sbc hl,de
 ld a,h
 or l
 jr z,skipcopy2
 ld b,h
 ld c,l
 push bc
 call FindLastByte
 ld a,(string)
 ld e,a
 ld d,0
 add hl,de
 ex de,hl           ;de: new last byte
 push de
 call FindLastByte
 dec hl
 pop de
 pop bc
 lddr
skipcopy2:
 call FindByteAfterCurrent
 ex de,hl
 ld hl,string
 ld a,(string)
 inc a
 ld c,a
 ld b,0
 ldir
skipmessagetext:
 call InvertSelect
 call UpdateScreen
 call InvertSelect
 jp WaitKey

GetAddress:
 ld hl,CurrentRoom
 ld a,(x)
 ld e,a
 ld d,0
 add hl,de
 ld a,(x+1)
 add a,a
 add a,a
 add a,a
 add a,a
 ld e,a
 add hl,de
 ld a,(hl)
 ret

left:
 ld a,(x)
 or a
 ret z
 call InvertSelect
 ld a,(x)
 dec a
 jr doneleft

right:
 ld a,(x)
 cp 15
 ret z
 call InvertSelect
 ld a,(x)
 inc a
doneleft:
 ld (x),a
 jr doneall

down:
 ld a,(x+1)
 cp 8
 ret z
 call InvertSelect
 ld a,(x+1)
 inc a
 jr donedown

up:
 ld a,(x+1)
 or a
 ret z
 call InvertSelect
 ld a,(x+1)
 dec a
donedown:
 ld (x+1),a
doneall:
 jp InvertSelect

DoMenu:
 call InvertMenuSelect
WaitMenuKey:
 halt
 push bc
 call _getky
 pop bc
 dec a
 push af
 call z,ScrollMenuDown
 pop af
 push af
 cp 3
 call z,ScrollMenuUp
 pop af
 cp K_ENTER-1
 jr z,CheckOption
 cp 53             ;2nd
 jr z,CheckOption
 cp K_EXIT-1
 ret z
 jr WaitMenuKey

CheckOption:
 ld a,(sel)
 ret

InvertMenuSelect:
 ld hl,$fc80
 ld de,$80
 ld a,(sel)
FindBarPosition:
 add hl,de
 dec a
 jr nz,FindBarPosition
 ld c,16*8
InvertMenuSelectLoop:
 ld a,(hl)
 cpl
 ld (hl),a
 inc hl
 dec c
 jr nz,InvertMenuSelectLoop
 ret

ScrollMenuUp:
 ld a,(sel)
 dec a
 ret z
 call InvertMenuSelect
 ld hl,sel
 dec (hl)
 jr donemenuscroll

ScrollMenuDown:
 ld a,(sel)
 cp b
 ret z
 call InvertMenuSelect
 ld hl,sel
 inc (hl)
donemenuscroll:
 call InvertMenuSelect
 ret

CheckMenu:
 ld a,(selectmode)
 or a
 jr z,menu
return:
 xor a
 ld (selectmode),a
 ld hl,(temp3)
 ld (x),hl
 ld hl,_plotSScreen
 ld de,CurrentRoom
 ld bc,144
 ldir
 call UpdateScreen
 call InvertSelect
 jp WaitKey
menu:
 ld a,1
 ld (sel),a
 call _clrLCD
 call GetNumEnemyRooms
 ld bc,256*14
 ld a,(roomcoords)
 call dispa
 ld a,Lcomma
 call _putc
 ld bc,256*18
 ld a,(roomcoords+1)
 call dispa
 ld bc,256*12+1
 ld a,(numenemyrooms)
 call dispa
 call _homeup
 ld a,-1
 ld (_curRow),a
 ld hl,roomcoordstxt
 ld b,7
textloop:
 call _newline
 call _puts
 djnz textloop
 ld b,5
 call DoMenu
 cp K_EXIT-1
 jp z,saveandquit
 dec a
 jp z,editnow
 dec a
 jp z,deleteroom
 dec a
 jp z,setlevelname
 dec a
 jp z,doneroomscroll     ;undo room changes

setstartposition:
 call SaveCurrentRoom
 ld hl,256*150+150
 ld (roomcoords),hl
 call FindRoom
 call CopyRoom
 ld hl,(coords)
 ld (x),hl
 call GetAddress
 ld (temp2),a
 ld a,(coords+2)
 ld (hl),a       ;put guy into it
again:
 call UpdateScreen
waitguykey:
 halt
 call _getky
 cp K_2
 jr z,guydown
 cp K_4
 jr z,guyleft
 cp K_6
 jr z,guyright
 cp K_8
 jr z,guyup
 cp 54
 jp z,putguy
 cp K_LEFT
 jr z,rotleft
 cp K_RIGHT
 jr z,rotright
 jr waitguykey
rotleft:
 ld a,(coords+2)
 sub 7
 jr nz,donerot
 ld a,8
 jr donerot

rotright:
 ld a,(coords+2)
 sub 5
 cp 9
 jr nz,donerot
 ld a,1
donerot:
 add a,6
 ld (coords+2),a
 jr endrot

guyup:
 ld a,(x+1)
 or a
 jr z,waitguykey
 call GetAddress
 ld a,(temp2)
 ld (hl),a
 ld hl,x+1
 dec (hl)
 jr endguymove

guydown:
 ld a,(x+1)
 cp 8
 jr z,waitguykey
 call GetAddress
 ld a,(temp2)
 ld (hl),a
 ld hl,x+1
 inc (hl)
 jr endguymove

guyleft:
 ld a,(x)
 or a
 jr z,waitguykey
 call GetAddress
 ld a,(temp2)
 ld (hl),a
 ld hl,x
 dec (hl)
 jr endguymove

guyright:
 ld a,(x)
 cp 15
 jp z,waitguykey
 call GetAddress
 ld a,(temp2)
 ld (hl),a
 ld hl,x
 inc (hl)
endguymove:
 call GetAddress
 ld (temp2),a
endrot:
 call GetAddress
 ld a,(coords+2)
 ld (hl),a
 jp again

putguy:
 ld a,(temp2)
 cp 31
 jp nc,waitguykey
 ld hl,(x)
 ld (coords),hl
 call GetAddress
 ld a,(temp2)
 ld (hl),a
 jp menu

setlevelname:
 ld hl,string
 ld b,0
 call _ldhlz
 xor a
 ld (length),a
 call _clrScrn
 call _homeup
 ld hl,levnametxt
 call _puts
 call _newline
 ld hl,leveldata+9
 ld de,string+1
findendloop:
 ld a,(hl)
 or a
 jr z,donefind
 call _putc
 ld (de),a
 push hl
 ld hl,length
 inc (hl)
 pop hl
 inc hl
 inc de
 jr findendloop
donefind:
 ld a,(length)
 ld (string),a
 ld a,20
 ld (length),a
 call GetString
 jr z,gotomenu
 ld hl,leveldata+9
 ld b,20
 call _ldhlz
 ld hl,string+1
 ld de,leveldata+9
 ld b,0
 ld a,(string)
 ld c,a
 ldir
gotomenu:
 jp menu

startingroom:
 call _clrLCD
 call _homeup
 ld hl,cantdeletetxt
 call _puts
wait:
 halt
 call _getky
 or a
 jr z,wait
 jp doneroomscroll

deleteroom:
 ld hl,roomcoords
 ld a,150
 cp (hl)
 jr nz,skipanother
 inc hl
 cp (hl)
 jr z,startingroom
skipanother:
 call FindLastByte
 ld (length),hl
 call FindRoom
 jp c,menu
 dec hl
 dec hl
 push hl           ;hl=room to be deleted+1
 call FindByteAfterCurrent
 ld (temp3),hl     ;hl=pointer to next room
 ex de,hl          ;de=pointer to next room
 ld hl,(length)    ;hl=pointer to end of all rooms
 or a
 sbc hl,de         ;hl=number of bytes to save
 ld b,h
 ld c,l         ;bc=number of bytes to save
 pop hl
 ld a,b
 or c
 jr z,skipcopy  ;if bc=0, don't copy anything
 dec hl
 ex de,hl         ;de=pointer to room to be deleted
 ld hl,(temp3)    ;hl=pointer to next room
 ldir
skipcopy:
 ld hl,(length)
 ld a,255
 ld bc,1000
 cpdr
 inc hl
 ld b,0
 call _ldhlz
 jp doneroomscroll

CheckAnyEnemies:
 ld b,144
checkloop:
 ld a,(hl)
 cp 48
 ret nc
 inc hl
 djnz checkloop
 scf
 ret

GetNumEnemyRooms:
 xor a
 ld (numenemyrooms),a
 ld hl,leveldata+30
levelloop:
 inc hl
 inc hl
 inc hl
 push hl
 call CheckAnyEnemies
 jr c,noenemies
 ld hl,numenemyrooms
 inc (hl)
noenemies:
 pop hl
 call FindByteAfterCurrent+3
 ld a,(hl)
 or a
 jr nz,levelloop
 ret

saveandquit:
 call SaveCurrentRoom
;find all enemy rooms
 call GetNumEnemyRooms
 call FindLastByte
 ld de,leveldata-1
 sbc hl,de
 ld (length),hl
 ld hl,filename-1
 rst 20h
 rst 10h
 call nc,_delvar
 ld hl,(length)
 call _createstrng
 call _ex_ahl_bde
 call _ahl_plus_2_pg3
 call _set_abs_dest_addr
 xor a
 ld hl,leveldata
 call _set_abs_src_addr
 xor a
 ld hl,(length)
 call _set_mm_num_bytes
 call _mm_ldir
quitnow:
 call _clrScrn
 call ResetFlagsAll
 xor a
 ld (_asapvar+2),a
 jp _homeup

LoadLevel:
 ld bc,5
 ld (_curRow),bc
 ld hl,filenametxt
 call _puts
SearchAgain:
 ld hl,(temp3)
 ld a,$0c
 call _RAM_Page_7
 ld bc,(_PTEMP_END+1)
 push hl
 or a
 sbc hl,bc
 ld b,h
 ld c,l
 pop hl
 cpdr
 jp po,SearchReady
good_found_one:
 dec hl
 dec hl
 dec hl
 dec hl
 ld (temp3),hl
 call copy_to_op1
 call validate
 jr nz,SearchAgain
waitsrchkey:
 halt
 call _getky
 cp K_ENTER
 jr z,LoadNow
 cp 54
 jr z,LoadNow
 cp K_EXIT
 jp z,ProgStart
 cp K_RIGHT
 jr nz,waitsrchkey
 jr SearchAgain

SearchReady:
 ld a,(temp)
 or a
 jr z,notfound
 ld hl,$bfff
 ld (temp3),hl
 jr SearchAgain
notfound:
 call _clrScrn
 call _homeup
 ld hl,notfoundtxt
 call _puts
 jr quitnow+3

copy_to_op1:
 ld de,filename
 push de
 ld b,10
copy_to_op1_loop:
 ld a,(hl)
 ld (de),a
 inc de
 dec hl
 djnz copy_to_op1_loop
 pop de
 ret

LoadNow:
 ld hl,filename-1
 rst 20h
 rst 10h
 call _ex_ahl_bde
 push af
 push hl
 call _Get_Word_ahl
 ld (leveldata),de
 pop hl
 pop af
 call _ahl_plus_2_pg3
 call _set_abs_src_addr
 xor a
 ld hl,leveldata        ;where to copy string
 call _set_abs_dest_addr
 xor a
 ld hl,(leveldata)          ;number of bytes to copy
 call _set_mm_num_bytes
 call _mm_ldir
 jp EditStart

validate:
 ld hl,filename-1
 rst 20h
 rst 10h
 call _ex_ahl_bde
 call _ahl_plus_2_pg3
 call _set_abs_src_addr
 xor a
 ld hl,leveldata        ;where to copy string
 call _set_abs_dest_addr
 xor a
 ld hl,30              ;number of bytes to copy
 call _set_mm_num_bytes
 call _mm_ldir
 ld hl,leveldata
 ld a,(hl)
 or a
 ret nz
 inc hl
 ld a,(hl)
 cp 'd'
 ret nz
 inc hl
 ld a,(hl)
 cp 'r'
 ret nz
 inc hl
 ld a,(hl)
 cp 'o'
 ret nz
 inc hl
 ld a,(hl)
 cp 'd'
 ret nz
;so it is a drod level, show filename and level name
 ld hl,filename
 ld bc,256*9+5
 ld (_curRow),bc
 call _putps
 ld b,7
 ld a,Lspace
spaceloop:
 call _putc
 djnz spaceloop
 ld bc,6
 ld (_curRow),bc
 ld hl,leveldata+9
 call _puts
 ld b,19
 ld a,Lspace
spaceloop2:
 call _putc
 djnz spaceloop2
 ld (temp),a
 ret

CopyRoom:
 ld de,CurrentRoom
 ld bc,144
 ldir
 ret

;in - room coordinates in (roomcoords)
;out - hl: pointer to room in leveldata area
FindRoom:
 ld hl,leveldata
 ld (temp3),hl
 ld bc,$fa70-roomstart
LevelSearchLoop:
 ld hl,(temp3)
 ld a,255
 cpir
 ld (temp3),hl
 ld a,b
 or c
 jr z,nonefound
 ld a,(roomcoords)
 cp (hl)
 jr nz,LevelSearchLoop
 inc hl
 ld a,(roomcoords+1)
 cp (hl)
 jr nz,LevelSearchLoop
 inc hl
 ret
nonefound:
 scf
 ret

UpdateScreen:
 di
 ld hl,CurrentRoom
 ld ix,$fc00
 ld b,9
loop_row:
 push bc
columns:
 ld b,16
loop_columns:
 push hl
 ld e,(hl)
 ld l,(hl)
 ld d,0
 ld h,0
 add hl,hl
 add hl,hl
 add hl,hl
 sbc hl,de
 ld de,Empty
 add hl,de
draw_tile:
 ld de,$10
 ld c,b
 ld b,7
 push ix
draw_tile_loop:
 ld a,(hl)
 ld (ix),a
 add ix,de
 inc hl
 djnz draw_tile_loop
 pop ix
 ld b,c
 pop hl
 inc hl
 inc ix
 djnz loop_columns
 ld de,$10*6
 add ix,de
 pop bc
 djnz loop_row
 ei
 ret

InvertSelect:
 ld hl,$fc00
 ld a,(x)
 ld e,a
 ld d,0
 add hl,de
 ld a,(x+1)
 or a
 jr z,skipadd
 ld e,112
addloop:
 add hl,de
 dec a
 jr nz,addloop
skipadd:
 ld b,7
 ld e,$10
invloop:
 ld a,(hl)
 cpl
 ld (hl),a
 add hl,de
 djnz invloop
 ret

;CurrentRoom->leveldata
SaveCurrentRoom:
 call FindRoom
 ret c
 ex de,hl
 ld hl,CurrentRoom
 ld bc,144
 ldir
 ret

;finds the byte after all rooms
FindLastByte:
 ld hl,leveldata
 ld bc,$fa70-roomstart
lookagain:
 ld a,255
 cpir
 ld a,b
 or c
 jr z,readysearch
 ld (temp3),hl
 jr lookagain
readysearch:
;check if there's a message
 ld hl,(temp3)
 ld de,146
 add hl,de
 ld (temp3),hl
 ld a,(hl)
 or a
 ret z
 ld e,a
 ld d,0
 add hl,de
 inc hl
 ld (temp3),hl
 ret

FindByteAfterCurrent:
 call FindRoom
 ld de,144
 add hl,de
 ld a,(hl)
 or a
 ret z
 cp 255
 ret z
 ld e,a
 ld d,0
 add hl,de
 inc hl
 ret

;in - max number of letters in (length)
;     length already in (string)
GetString:
 call SetFlags
waitletter:
 halt
 push bc
 call _getky
 pop bc
 cp K_DEL
 jr nz,checkothers
 ld a,(string)
 or a
 jr z,waitletter
 dec a
 ld (string),a
 ld a,Lspace
 call _putmap
 ld a,(_curCol)
 or a
 jr nz,donedelete
 ld hl,_curRow
 dec (hl)
 ld a,21
donedelete:
 dec a
 ld (_curCol),a
 ld a,Lspace
 call _putmap
 jr waitletter
checkothers:
 cp 54        ;2nd
 jr nz,notalphapressed
 bit shiftLwrAlph,(iy+shiftflags)
 jr z,setlwr
 call ResetFlags
 jr waitletter
setlwr:
 call SetFlags
 jr waitletter
notalphapressed:
 ld d,a
 sub K_EXIT
 jr nz,notexit
 jp ResetFlagsAll
notexit:
 ld a,d
 cp K_ENTER
 jr z,Ready
 ld a,(length)
 ld b,a
 ld a,(string)
 cp b
 jr z,waitletter
 ld a,d
 or a
 jr z,waitletter
 push de
 ld hl,lettertable-1
 ld e,a
 ld d,0
 add hl,de
 pop de
 ld a,(filenameinput)
 or a
 ld a,(hl)
 jr z,skipchecks
 cp Lspace
 jp z,waitletter
 ld a,(string)
 or a
 jr nz,skipnumbercheck
 ld a,(hl)
 sub 48
 cp 10
 jp c,waitletter
skipnumbercheck:
 ld a,d
 cp 47
 jp nc,waitletter
skipchecks:
 bit shiftLwrAlph,(iy+shiftflags)
 jr nz,lower
 ld a,(hl)
 sub 32
 cp 65
 jp c,waitletter
 cp 91
 jp nc,waitletter
 jr lower+1
lower:
 ld a,(hl)
 call _putc
 ld hl,string
 inc (hl)
 push af
 ld a,(hl)
 ld e,a
 ld d,0
 add hl,de
 pop af
 ld (hl),a
 jp waitletter
Ready:
 ld a,(string)
 or a
 jp z,waitletter
 jp ResetFlagsAll

deletemessage:
 call FindLastByte
 ld (length),hl
 call FindRoom
 ld de,144
 add hl,de
 push hl           ;hl=message to be deleted
 call FindByteAfterCurrent
 ld (temp3),hl     ;hl=pointer to next room
 ex de,hl          ;de=pointer to next room
 ld hl,(length)    ;hl=pointer to end of all rooms
 or a
 sbc hl,de         ;hl=number of bytes to save
 ld b,h
 ld c,l         ;bc=number of bytes to save
 pop hl
 ld a,b
 or c
 ex de,hl         ;de=pointer to message to be deleted
 ld hl,(temp3)    ;hl=pointer to next room
 jr z,skipcopy3  ;if bc=0, don't copy anything
 ldir
skipcopy3:
 or a
 sbc hl,de
 ex de,hl
 ld hl,(length)
 or a
 sbc hl,de
 ld b,0
 call _ldhlz
 ret

ResetFlagsAll:
 res shiftAlpha,(iy+shiftflags)
 res curAble,(iy+curflags)
 set graphdraw,(iy+graphflags)
 res onInterrupt,(iy+onflags)
ResetFlags:
 res shiftLwrAlph,(iy+shiftflags)
 ret

SetFlags:
 set curAble,(iy+curflags)
 set shiftAlpha,(iy+shiftflags)
 set shiftLwrAlph,(iy+shiftflags)
 ret

#include "drodsprites.asm"

dispa:
 ld l,a
 ld h,0
disphl:
 push bc
 xor a
 ld bc,-1
 ld (_curRow),bc
 call $4a33
 pop bc
 ld (_curRow),bc
 inc hl
 jp _puts

ContrastUp:
 ld b,1
ChangeContrast:
 ld a,($c008)
 add a,b
 and %00011111
 ld ($c008),a
 out (2),a
 xor a
 ret
ContrastDown:
 ld b,-1
 jr ChangeContrast

ShellTitle: .db 19,"  DROD Level Editor",0
newleveltxt: .db "Create new level",0
opentxt: .db "Open level",0
filenametxt: .db "Filename:",0
levnametxt: .db "Level name:",0
cantdeletetxt: .db "Can't delete startingroom!",0
roomcoordstxt: .db "Current room:",0
enemyroomstxt: .db "Enemy rooms:",0
returntxt: .db "Return to editor",0
deleteroomtxt: .db "Delete current room",0
setlevelnametxt: .db "Set level name",0
undochangestxt: .db "Undo room changes",0
setpositiontxt: .db "Set starting position",0
noroomtxt: .db "No room here",0
createroomtxt: .db "Press ENTER to create",0
notfoundtxt: .db "No levels found!",0
entertxt: .db "Enter text:",0

sel: .db 1
roomcoords: .db 150,150
temp3: .dw $bfff
x: .db 7,4
currtile: .db 0
selectmode: .db 0
filename: .db 0,"        "
length: .db 8,0
temp: .db 0
filenameinput: .db 1
temp2: .db 0,0

lettertable:
.db "2469     xtoje1  wsnid3 zvrmhc5 yuqlgb78 0pkfa.?!,-/:  &"

leveldata:
.db 0,"drod",0,7,4,7,"My level",0,0,0,0,0,0,0,0,0,0,0,0,0
.db 255,150,150
roomstart:
coords =leveldata+6
numenemyrooms =leveldata+5
.end
