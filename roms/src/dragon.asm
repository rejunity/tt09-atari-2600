;;Sprite test program.
;;By Lawrie Griffiths

	processor 6502
	include "vcs.h"
	include "macro.h"
	
	seg.u vars
	org $80
	
DI  DS 1

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
    STA COLUP0
    LDA #0
    STA COLUBK

    LDA #7
    STA NUSIZ0
    LDA #8
    STA REFP0
    
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
	LDY #37           ; 37 VBLANK lines
Vblank0:
    STA WSYNC
	DEY
	BNE Vblank0
	LDA #0            ; Clear VBLANK
	STA VBLANK
	LDY #16           ; Count picture lines from 16 t0 208 (192 lines)
	STA DI

Picture:
    LDX DI            ; Get Index to Dragon sprite
    LDA Dragon,X
	STA GRP0
	CMP #0
	BEQ NoDrag	
	LDA DI
	CLC
	ADC #1
	STA DI
	
NoDrag:	
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
	
Dragon:
       .byte $06                  ;     XX
       .byte $0F                  ;    XXXX
       .byte $F3                  ;XXXX  XX
       .byte $FE                  ;XXXXXXX
       .byte $0E                  ;    XXX
       .byte $04                  ;     X
       .byte $04                  ;     X
       .byte $1E                  ;   XXXX
       .byte $3F                  ;  XXXXXX
       .byte $7F                  ; XXXXXXX
       .byte $E3                  ;XXX   XX
       .byte $C3                  ;XX    XX
       .byte $C3                  ;XX    XX
       .byte $C7                  ;XX   XXX
       .byte $FF                  ;XXXXXXXX
       .byte $3C                  ;  XXXX
       .byte $08                  ;    X
       .byte $8F                  ;X   XXXX
       .byte $E1                  ;XXX    X
       .byte $3F                  ;  XXXXXX
       .byte $00

	echo "----",($FFFC - *) ," bytes left"
	
	org $FFFC
	.word Start
	.word Start
