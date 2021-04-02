;DROD sub routines
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
 cp K_SECOND-1
 jr z,CheckOption
 cp K_EXIT-1
 ret z
 jr WaitMenuKey
CheckOption:
 ld a,(sel)
 ret

vnewline:
 xor a
 ld (_penCol),a
newrow:
 ld a,(_penRow)
 add a,6
 ld (_penRow),a
 ret

ClearBottom:
 ld hl,$fe80
 ld de,$fe81
 ld bc,$ffff-$fe80
 ld (hl),0
 ldir
 ret

ClearLevelData:
 ld hl,leveldata
 ld de,leveldata+1
 ld bc,$fa70-leveldata-1
 ld (hl),0
 ldir
 ret

PrintText:
 ld (_penCol),bc
 jp _vputs

InvertMenuSelect:
ToppestRow =$+1
 ld hl,$fc00
 ld de,$60
 ld a,(sel)
FindBarPosition:
 add hl,de
 dec a
 jr nz,FindBarPosition
 ld c,16*7
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
 dec a
 jr nz,skipsavecheck
 ld a,(savegame)
 or a
 ret z
skipsavecheck:
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

subtract8:
 sub 8
 ret
add8:
 add a,8
 ret

;Displays register hl or a
dispa:
 ld l,a
 ld h,0
disphl:
 xor a
 push bc
 ld bc,-1
 ld (_curRow),bc
 call $4a33
 pop bc
 ld (_penCol),bc
 dec hl
 jp _vputs

;in - hl: address in CurrentRoom
;out - hl: address in background
;       a: byte in that address
GetbgAddress:
 ld de,144
 add hl,de
 ld a,(hl)
 ret

;in - a: direction to move to
;    hl: address in CurrentRoom
;out - hl: new address according to direction
FindPosition:
 ld b,a
 push hl
 push af
 ld hl,Positions-2
FindPositionLoop:
 inc hl
 inc hl
 djnz FindPositionLoop
 call _ldhlind
 ex de,hl
 pop af
 pop hl
 add hl,de
 ret

;in - a: direction to move to
;    hl: address of enemy in CurrentRoom
;out - a: correct sprite number
GetCorrectSprite:
 push af
 ld a,(hl)
 cp 65
 jr nc,NotRoach
 pop af
 add a,56
 ret
NotRoach:
 cp 66
 jr nc,NotTar
 pop af
 ld a,65
 ret
NotTar:
 cp 74
 jr nc,NotEye
 pop af
 add a,65
 ret
NotEye:    ;It must be Queen roach
 pop af
 add a,73
 ret

;in - hl: address in CurrentRoom
;out - coordinates in (tempcoords)
ConvAddress:
 ld de,CurrentRoom
 or a
 sbc hl,de
 ld a,l
 push af
 and %11110000
 rra
 rra
 rra
 rra
 ld (tempcoords+1),a
 pop af
 and %00001111
 ld (tempcoords),a
 ret

;in - guy coordinates in (coords)
;out - hl: address of guy (NOT mimic) in CurrentRoom
;          address stored into (temp3)
;          guy coordinates stored into (tempcoords)
;       a: byte in (hl)
GetAddress:
 ld hl,(coords)
 ld (tempcoords),hl
 ld a,(coords)
 ld b,a
 ld a,(coords+1)
EndGetAddress:
 add a,a
 add a,a
 add a,a
 add a,a
 add a,b
 ld e,a
 ld d,0
 ld hl,CurrentRoom
 add hl,de
 ld (temp3),hl
 ld a,(hl)
 ret

GetMimicAddress:
 ld hl,(mimiccoords)
 ld (tempcoords),hl
 ld a,(mimiccoords)
 ld b,a
 ld a,(mimiccoords+1)
 jr EndGetAddress

;Draws the screen again
UpdateScreen:
 call GetAddress
 ld (temp),a
 ld a,(invis)
 or a
 jr z,NotInvisible
 ld (hl),0
NotInvisible:
UpdateBg:
 ld de,CurrentRoom
 push de
 ld hl,background
 ld b,144
loop:
 ld a,(de)
 or a
 jr nz,skip
 ld a,(hl)
 ld (de),a
skip:
 inc hl
 inc de
 djnz loop
 di
 pop hl
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
 ld hl,(temp3)
 ld a,(temp)
 ld (hl),a
 ret

;check if there were any enemies left on this room
;out - carry set if no enemies
CheckAnyEnemies:
 ld hl,CurrentRoom
 ld b,144
EnemyCheckLoop:
 ld a,(hl)
 cp 48
 ret nc
 inc hl
 djnz EnemyCheckLoop
 scf
 ret

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
.end