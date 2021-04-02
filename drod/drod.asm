#include "ti86asm.inc"
#include "asm86.h"
.org _asm_exec_ram

_ldhlind =$4010
_RAM_Page_7     =$47f3
_PTEMP_END      =$d29a
_ex_ahl_bde     =$45f3
_ahl_plus_2_pg3     =$4c3f
_set_abs_dest_addr  =$5285
_set_abs_src_addr   =$4647
_set_mm_num_bytes   =$464f
_mm_ldir        =$52ed
_ldhlz = $437b
_createstrng = $472f
_Get_Word_ahl =$521d
_asapvar =$d6fc
CurrentRoom =_plotSScreen
background =_plotSScreen+144

Message =1
LeverDown =2
InvisPotion =3
MimicPotion =4
MimicCursor =5
TrapFloor =6
Guy =7
Arrow =15
Sword =23
ExitStairs =31
MimicGuy =32
;Solid sprites:
Wall1 =40
Wall2 =41
BreakableWall =42
EnemyWall =43
ExitWall =44
LeverWall =45
TrapWall =46
Lever =47

TarWall =48
StandingEye =49
Roach =57
TarEnemy =65
MovingEye =66
QueenRoach =74

;.plugin lite86
    .db 0
    jp ProgStart
    .dw 0 
    .dw ShellTitle
;These should be fixed:
;more space for the level by using $8100 area?
;more space for demo?
ProgStart:
;initialize variables:
 ld hl,_plotSScreen+302
 ld (MovePointer),hl
 ld hl,_plotSScreen
 ld (fileptr),hl
 xor a
 ld (temp),a
 ld (demo),a
 ld (savegame),a
 ld (demofilename),a
 inc a
 ld (choice),a
 call ClearLevelData
 ld hl,leveldata        ;clear CurrentRoom & background area
 ld de,CurrentRoom
 ld bc,1024
 ldir
 call _runindicoff
 call _flushallmenus
 call _clrLCD
 call _homeup
;Display title screen if exists
 ld hl,$fc00
 ld (Destination),hl
 ld hl,TitleScreenFile-1
 call LoadFile
 call nc,wait
NoTitleScreen:
 call ClearBottom
 ld a,2
 ld (sel),a
 ld hl,savegamedata
 ld (Destination),hl
 ld hl,savegamefile-1
 call LoadFile
 jr c,MainMenu
 ld a,1
 ld (sel),a
 ld (savegame),a
 ld hl,continuetxt
 ld bc,256*40+40
 call PrintText
MainMenu:
 ld hl,newgametxt
 ld bc,256*46+47
 call PrintText
 ld bc,256*52+43
 call PrintText
 ld bc,256*58+47
 call PrintText
 ld hl,$fe20
 ld (ToppestRow),hl
 ld b,4
 call DoMenu
 cp K_EXIT-1
 jp z,quitnow
 dec a
 push af
 ld a,1
 ld (savegame),a
 call z,ClearBottom
 pop af
 jp z,RestartRoom
 dec a
 jr z,NewGame
 dec a
 jr z,RecordDemo

PlayDemo:
;set up addresses
 ld bc,validatedemo
 ld de,nodemostxt
 ld hl,DispDemos
 ld ix,StartPlaying
 call SaveAddresses
 jr StartSearching
RecordDemo:
 ld a,2
 ld (demo),a
NewGame:
;set up addresses
 ld bc,validate
 ld de,notfoundtxt
 ld hl,DispNames
 ld ix,Startlevel
 call SaveAddresses
StartSearching:
 ld hl,$bfff
 push hl
SearchLoop:
 pop hl
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
 dec hl
 dec hl
 dec hl
 push hl
 ld de,filename-1
 ld b,10
CopyLoop:
 inc de
 dec hl
 ld a,(hl)
 ld (de),a
 djnz CopyLoop
Validateaddr =$+1
 call validate      ;;;;;;;;;;
 jr SearchLoop

notfound:
 call ClearBottom
NotFoundaddr =$+1
 ld hl,notfoundtxt  ;;;;;;;;;;;
 ld bc,256*48+37
 call PrintText
 call wait
 jp ProgStart
 
SearchReady:
 ld hl,(fileptr)
 ld (fileend),hl
 ld a,(temp)
 or a
 jr z,notfound
 ld a,1
 ld (sel),a
Displayaddr =$+1
 call DispNames     ;;;;;;;;;;;
 call InvertMenuSelect
waitlevelkey:
 halt
 call _getky
 cp K_EXIT
 jp z,ProgStart
 cp K_SECOND
Startaddr =$+1
 jp z,Startlevel   ;;;;;;;;;
 cp K_UP
 jr z,Scrolllevelsup
 cp K_DOWN
 jr z,Scrolllevelsdown
 jr waitlevelkey
Scrolllevelsup:
 ld a,(choice)
 dec a
 jr z,waitlevelkey
 ld a,(sel)
 dec a
 jr nz,skip1
 ld hl,choice
 dec (hl)
Displayaddr2 =$+1
 call DispNames      ;;;;;;;;;
Label:
 call InvertMenuSelect
 jr waitlevelkey
skip1:
 call InvertMenuSelect
 ld hl,sel
 dec (hl)
 ld hl,choice
 dec (hl)
 jr Label

Scrolllevelsdown:
 ld a,(choice)
 ld b,a
 ld a,(temp)
 cp b
 jr z,waitlevelkey
 ld a,(sel)
 cp 4
 jr nz,skip2
 ld a,(choice)
 inc a
 push af
 sub 3
 ld (choice),a
Displayaddr3 =$+1
 call DispNames     ;;;;;;;;;
 pop af
 ld (choice),a
 jr Label
skip2:
 call InvertMenuSelect
 ld hl,sel
 inc (hl)
 ld hl,choice
 inc (hl)
 jr Label

StartPlaying:
;Load demo file
 ld hl,_plotSScreen+288
 ld (Destination),hl
 call FindDemoPointer
 dec hl
 call LoadFile
;Load level file
 ld hl,leveldata
 ld (Destination),hl
 ld hl,_plotSScreen+292
 call LoadFile
 jr nc,levelexists
 call ClearBottom
 ld bc,256*48+30
 ld hl,notfoundleveltxt
 call PrintText
 call wait
 jp ProgStart
levelexists:
 ld a,1
 ld (demo),a
 jr StartNow
Startlevel:
 ld hl,leveldata
 ld (Destination),hl
 call FindLevelPointer
;Copy filename to filename area
 push hl
 ld de,filename
 call _mov9b
 pop hl
 dec hl
 call LoadFile
;Find guy's starting coordinates and number of enemy rooms
StartNow:
 ld a,(numenemyrooms)
 ld (enemyroomsleft),a
 ld hl,256*150+150
 ld (roomcoords),hl      ;Coordinates of first room
 xor a
 ld (temp6),a
 ld hl,(startpos)
 ld (lastentry),hl
 ld a,(startpos+2)
 ld (lastentry+2),a
 call _clrLCD
 jp NewRoom

exitmenu:
 ld a,(demo)
 or a
 jp z,NoDemo
 dec a
 jp z,ProgStart
SaveDemo:
 ld hl,DemoFileid
 ld de,_plotSScreen+288
 call _mov5b
 ld hl,filename
 ld de,_plotSScreen+293
 call _mov9b
 call _clrScrn
 call _homeup
 ld hl,filenametxt
 call _puts
GetString:
 call SetFlags
waitletter:
 halt
 call _getky
 cp K_DEL
 jr nz,checkothers
 ld a,(demofilename)
 or a
 jr z,waitletter
 dec a
 ld (demofilename),a
 ld a,Lspace
 call _putmap
 ld hl,_curCol
 dec (hl)
 ld a,Lspace
 call _putmap
 jr waitletter
checkothers:
 cp K_SECOND
 jr nz,notalphapressed
 bit shiftLwrAlph,(iy+shiftflags)
 jr z,setlwr
 call ResetFlags
 jr waitletter
setlwr:
 call SetFlags
 jr waitletter
notalphapressed:
 ld c,a
 cp K_EXIT
 jr nz,notexit
 call ResetFlagsAll
 jp ProgStart
notexit:
 cp K_ENTER
 jr z,Ready
 ld a,(demofilename)
 cp 8
 jr z,waitletter
 ld a,c
 or a
 jr z,waitletter
 ld hl,lettertable-1
 ld e,a
 ld d,0
 add hl,de
 ld a,(hl)
 cp Lspace
 jp z,waitletter
 ld a,(demofilename)
 or a
 jr nz,skipnumbercheck
 ld a,(hl)
 cp 58
 jp c,waitletter
skipnumbercheck:
 ld a,c
 cp 47
 jp nc,waitletter
skipchecks:
 bit shiftLwrAlph,(iy+shiftflags)
 jr nz,lower
 ld a,(hl)
 cp 97
 jp c,waitletter
 cp 123
 jp nc,waitletter
 jr lower+1
lower:
 ld a,(hl)
 call _putc
 ld hl,demofilename
 inc (hl)
 ld c,a
 ld a,(hl)
 ld e,a
 ld d,0
 add hl,de
 ld (hl),c
 jp waitletter
Ready:
 ld a,(demofilename)
 or a
 jp z,waitletter
 call ResetFlagsAll
 call SaveDemoNow
 jp ProgStart
;Save demo, name in demofilename
SaveDemoNow:
 ld hl,(MovePointer)
 ld de,_plotSScreen+288
 or a
 sbc hl,de
 push hl
 ex de,hl
 ld hl,_plotSScreen+288
 push hl
 push de
 ld hl,demofilename-1
 jp SaveFile

NoDemo:
 ld a,1
 ld (sel),a
 ld hl,$fcc0
 ld (ToppestRow),hl
 call _clrLCD
 ld bc,47
 ld a,(roomcoords)
 call dispa
 ld a,Lcomma
 call _vputmap
 ld bc,63
 ld a,(roomcoords+1)
 call dispa
 ld bc,256*6+57
 ld a,(enemyroomsleft)
 call dispa
 ld bc,0
 ld hl,roomcoordstxt
 call PrintText
 call vnewline
 call _vputs
 call vnewline
 call vnewline
 call _vputs
 call vnewline
 call _vputs
 call vnewline
 call _vputs
 ld b,3
 call DoMenu
 cp K_EXIT-1
 jr z,saveandquit
 dec a
 jp z,Backtogame
 dec a
 jp z,RestartRoom
 call SaveGame
 jp ProgStart

saveandquit:
 call SaveGame
quitnow:
 call _clrScrn
 xor a
 ld (_asapvar+2),a
 jp _homeup

DeleteFile:
 rst 20h
 rst 10h
 jp nc,_delvar
 ret

SaveGame:
 ld hl,(length)
 ld de,8
 add hl,de
 push hl
 ex de,hl
 ld hl,savegamedata
 push hl
 push de
 ld hl,savegamefile-1
 jp SaveFile

wait:
 halt
 call _getky
 or a
 jr z,wait
 xor a
 ret

;this routine must be jumped to
SaveFile:
 call DeleteFile
 pop hl
 call _createstrng
 call _ex_ahl_bde
 call _ahl_plus_2_pg3
 call _set_abs_dest_addr
 xor a
 pop hl
 call _set_abs_src_addr
 xor a
 pop hl
 call _set_mm_num_bytes
 jp _mm_ldir

;Sprite numbers:

;0 - Empty
;1 - Message
;2 - Lever wall down
;3 - Invisibility potion
;4 - Mimic potion
;5 - Mimic cursor
;6 - Trap floor
;7 - 8 Guys
;15 - 8 Arrows
;23 - 8 Swords
;31 - Exit stairs (level completed when touched)
;32 - 8 Mimic guys

;Start of sprites that can't be walked through:

;40 - Wall type 1 (black)
;41 - Wall type 2
;42 - Breakable wall
;43 - "Enemy" wall  (green)
;44 - Exit wall    (blue)
;45 - Lever wall (yellow)
;46 - Trap wall (red)
;47 - Lever (orb)

;Start of enemies:

;48 - Tar as a wall
;49 - 8 Eyes (standing still)
;57 - 8 Roaches
;65 - Tar as an enemy
;66 - 8 Moving Eyes
;74 - 8 Queen Roaches (moves away from the guy)

LevelFileid =$+1
savegamefile: .db 8,"drodsave"
TitleScreenFile: .db 7,"drodtit"
DemoFileid: .db 0,"demo"
demofilename: .db 0,"xxxxxxxx"
filename: .db 0,0,0,0,0,0,0,0,0
savegame: .db 0   ;is there a save game
fileptr: .dw _plotSScreen
fileend: .db 0,0      ;pointer to end of files (levels/demos)
choice: .db 1
sel: .db 1          ;menu selection

;variables used while playing
coords: .db 0,0      ;guy coordinates in room
EnemyLoopCounter: .db 0
tempcoords: .db 0,0  ;temporary coordinates
temp: .db 0      ;to save direction temporarily (and other things)
temp3: .db 0,0
temp4: .db 0   ;to save original direction (where the enemy tries to go)
temp5: .db 0   ;to save direction (where the enemy actually goes)
temp6: .db 0   ;which side did the guy enter to the room
steps: .db 0   ;number of steps (to make Queen Roach bear)
mimic: .db 0   ;is there mimic guy?
MimicDies: .db 0 ;to remember if mimic guy died
invis: .db 0   ;how much invisibility left
mimiccoords: .db 0,0   ;mimic guy coordinates
anyenemies: .db 0    ;0-1 - to remember if current room had any enemies when entering
noroomfound: .db 0   ;0-1 - to remember if a room wasn't found
demo: .db 0 ;0-no demo playing/recording, 1-demo playing, 2-demo recording
MovePointer: .dw _plotSScreen+302 ;pointer to demo's move area

ShellTitle: .db "DROD by Makee",0
continuetxt: .db "Continue game",0
newgametxt: .db "New game",0
recorddemotxt: .db "Record demo",0
playdemotxt: .db "Play demo",0
notfoundtxt: .db "No levels found!",0
nodemostxt: .db "No demos found!",0
roomcoordstxt: .db "Current room:",0
enemyroomstxt: .db "Enemy rooms left:",0
resumetxt: .db "Resume game",0
restarttxt: .db "Restart room",0
backtxt: .db "Back to main menu",0
roomnotexisttxt: .db "No room here",0
congratstxt: .db "Congratulations!",0
notfoundleveltxt: .db "Level file not found!",0
filenametxt: .db "Filename:",0

lettertable:
.db "2469     xtoje1  wsnid3 zvrmhc5 yuqlgb78 0pkfa"

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

GetNextMove:
 ld hl,(MovePointer)
 ld a,(hl)
 ld d,a
 inc hl
 ld (MovePointer),hl
 xor a
 ret

SaveMove:
 ld hl,(MovePointer)
 ld a,d
 ld (hl),a
 inc hl
 ld (MovePointer),hl
 ret
;in - hl:filename to load
;        destination in Destination
LoadFile:
 rst 20h
 rst 10h
 ret c
 call _ex_ahl_bde
 call _Get_Word_ahl
 push de
 call _set_abs_src_addr
 xor a
Destination =$+1
 ld hl,0
 call _set_abs_dest_addr
 xor a
 pop hl
 ld (length),hl
 call _set_mm_num_bytes
 jp _mm_ldir

validatedemo:
 ld de,DemoFileid+1
 call ValidateNow
 ret nz
;Save demo's file name to file table
 ld hl,filename
 ld de,(fileptr)
 call _mov9b
 ld (fileptr),de
 ld hl,temp
 inc (hl)
 ret

ValidateNow:
 push de
 call LoadFilePart
 pop de
 ld hl,leveldata
 ld a,(hl)
 or a
 ret nz
 inc hl
 ld b,4
ValidateLoop:
 ld a,(de)
 cp (hl)
 ret nz
 inc hl
 inc de
 djnz ValidateLoop
 ret

LoadFilePart:
 ld hl,filename-1
 rst 20h
 rst 10h
 call _ex_ahl_bde
 call _ahl_plus_2_pg3
 call _set_abs_src_addr
 xor a
 ld hl,leveldata
 call _set_abs_dest_addr
 xor a
 ld hl,30
 call _set_mm_num_bytes
 jp _mm_ldir

;validates string that was found
validate:
 ld de,LevelFileid
 call ValidateNow
 ret nz
;so it is a drod level, save it to file table
 ld hl,filename
 ld de,(fileptr)
 call _mov9b
 ld hl,leveldata+9
 ld bc,21
 ldir
 ld (fileptr),de
 ld hl,temp
 inc (hl)
 ret

SubDisp:
 ld bc,256*40
 ld (_penCol),bc
 jp ClearBottom

DispDemos:
 call SubDisp
 call FindDemoPointer
DispDemosLoop:
 push hl
 ld a,(hl)
 ld b,a
 inc hl
 call _vputsn
 call vnewline
 ld a,(_penRow)
 cp 64
 pop hl
 ret z
 ld de,9
 add hl,de
 call CheckEnd
 jr nz,DispDemosLoop
 ret

CheckEnd:
 ld de,(fileend)
 ld a,d
 cp h
 ret nz
 ld a,e
 cp l
 ret

DispNames:
 call SubDisp
 call FindLevelPointer
disploop:
 ld de,9
 add hl,de
 push hl
 call _vputs
 call vnewline
 ld a,(_penRow)
 cp 64
 pop hl
 ret z
 ld de,21
 add hl,de
 call CheckEnd
 jr nz,disploop
 ret

FindDemoPointer:
 ld hl,_plotSScreen-9
 ld de,9
 jr FindPointerLoop

FindLevelPointer:
 ld hl,_plotSScreen-30
 ld de,30
FindPointerLoop:
 ld a,(choice)
ptrloop:
 add hl,de
 dec a
 jr nz,ptrloop
 ret

SaveAddresses:
 ld (Validateaddr),bc
 ld (NotFoundaddr),de
 ld (Displayaddr),hl
 ld (Displayaddr2),hl
 ld (Displayaddr3),hl
 ld (Startaddr),ix
 ret

#include "drodsub.asm"
#include "drodsprites.asm"
#include "drodgame.asm"

;variables that will be saved:
savegamedata:
enemyroomsleft: .db 0      ;number of enemy rooms left
roomcoords: .db 0,0    ;room coordinates in the level
lastentry: .db 0,0,0   ;where the guy entered the room and which direction
length: .db 0,0        ;level data length (starts from "leveldata")

leveldata:
numenemyrooms =leveldata+5
startpos =leveldata+6
roomstart =leveldata+33
.end