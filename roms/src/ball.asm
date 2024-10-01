;;Ball test program.
;;By Lawrie Griffiths

	processor 6502
	include "vcs.h"
	include "macro.h"
	
	seg.u vars
	org $80

	seg Code
	org $F000		
	
Start:
    LDX #0            ; Clear RAM and TIA and set Stack Pointer
    TXA    
Clear:
    DEX
    TXS
    PHA
    BNE Clear
    LDA #$46          ; Set colours
	STA COLUPF
    LDA #0
	STA COLUBK
    LDA #$E0          ; Move Ball 2 right, gets done 37 times
	STA HMBL          ; So ball X position becomes 74
	LDA #2            ; Start VBLANK
	STA VBLANK
Frame:
    LDA #2
Vsync0:
	STA VSYNC         ; 3 VSYNC lines
	STA WSYNC
	STA WSYNC
	STA WSYNC
	LDA #0
	STA VSYNC
	LDY #37          ; 37 VBLANK lines
Vblank0:
    STA WSYNC
	STA HMOVE         ; Move ball and missiles
	DEY
	BNE Vblank0
	LDA #0            ; Clear VBLANK
	STA VBLANK
	STA HMCLR         ; Clear Ball and mossile movement
	LDY #16           ; Count picture lines from 16 t0 208 (192 lines)
Picture:
    LDA #0
    CPY #100          ; Ball Y position
    BNE NoBall
	LDA #2
NoBall:
    STA ENABL
	INY
	STA WSYNC
	CPY #208
    BNE Picture
	LDA #2            ; Set VBLANK
	STA VBLANK
	LDY #30           ; 30 Overscan lines
Overscan:
    DEY
	STA WSYNC
	BNE Overscan
	JMP Frame
		
	echo "----",($FFFC - *) ," bytes left"
	
	org $FFFC
	.word Start
	.word Start
