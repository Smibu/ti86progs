#include "ti86.inc"
;Source code for ASM to HEX - editable
;Size on calculator: 323 bytes

OutputProgram =$8100
.org _asm_exec_ram
 call _clrScrn
 call _runindicoff
 call _homeup
 ld hl,HexStart
 ld de,OutputProgram
 call _mov9b
 call _puts
SearchAgain:
 ld hl,$bfff
 push hl
SearchLoop:
 pop hl
 ld a,18
 call _RAM_Page_7
 ld bc,(_PTEMP_END+1)
 or a
 push hl
 sbc hl,bc
 ld b,h
 ld c,l
 pop hl
 cpdr
 jp po,SearchAgain
 dec hl
 dec hl
 push hl
 ld de,_OP1-1
 ld b,10
CopyToOP1Loop:
 inc de
 dec hl
 ld a,(hl)
 ld (de),a
 djnz CopyToOP1Loop
 rst 10h
 call _ex_ahl_bde
 call _ahl_plus_2_pg3
 call _Get_Word_ahl
 ld hl,$288e
 call _cphlde
 jr nz,SearchLoop
 ld hl,_OP1+1
 ld bc,256*9+1
 ld (_curRow),bc
 call _putps
 call _eraseEOL
Waitkey:
 halt
 call _getky
 cp K_EXIT
 jp z,Quit
 cp K_RIGHT
 jr z,SearchLoop
 cp K_ENTER
 jr nz,Waitkey
 rst 10h
 call _ex_ahl_bde
 call _Get_Word_ahl
 dec de
 dec de
 ld c,a
 ld a,d
 cp 31
 jr c,NotTooBig
 ld bc,256*7+1
 ld (_curRow),bc
 ld hl,TooBigTxt
 pop af
 jp _puts
NotTooBig:
 ld a,c
 ld ix,OutputProgram+9
 call _Inc_Ptr_ahl
ConvertLoop:
 call _Inc_Ptr_ahl
 ld b,a
 push hl
 call _GetB_AHL
 call _RAM_Page_1
 call ConvertAToHex
 dec de
 ld a,d
 or e
 pop hl
 ld a,b
 jr nz,ConvertLoop
CreateProgram:
 ld hl,OutputName-1
 rst 20h
 rst 10h
 call nc,_delvar
 push ix
 pop hl
 or a
 ld de,OutputProgram
 sbc hl,de
 push hl
 call _createprog
 call _ex_ahl_bde
 call _ahl_plus_2_pg3
 call _set_abs_dest_addr
 ld hl,$100
 ld a,h
 call _set_abs_src_addr
 xor a
 pop hl
 call _set_mm_num_bytes
 call _mm_ldir
Quit:
 pop af
 jp _clrScrn
ConvertAToHex:
 ld c,a
 rrca
 rrca
 rrca
 rrca
 call ConvertNibble
 ld a,c
ConvertNibble:
 and $0f
 add a,'0'
 cp '9'+1
 jr c,ConvertNibbleNow
 sub '9'+1-'A'
ConvertNibbleNow:
 ld (ix),a
 inc ix
 ret
OutputName: .db 7,"hexprgm"
HexStart: .db 0,"AsmPrgm",$d6
.db "ASM to HEX- converter"
ProgramTxt: .db "Program:",0
TooBigTxt: .db " is too big!  ",0
.end