#include "ti86.inc"

.org _asm_exec_ram
 ld hl,SaveBoardname-1
 rst 20h
 rst 10h
 jp nc,_delvar
 ret

SaveBoardname: .db 4,0,"sud"
.end