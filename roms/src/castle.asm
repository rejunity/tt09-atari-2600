;;Test program.
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
	LDA #1            ; Set reflection
	STA CTRLPF
	LDA #$46          ; Set colours
	STA COLUPF
	LDA #0
	STA COLUBK
;	LDA #$E0          ; Move Ball 2 right, gets done 37 times
;	STA HMBL           ; So ball X position becomes 74
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
;	STA HMOVE          ; Move ball and missiles
	DEY
	BNE Vblank0
	LDA #0            ; Clear VBLANK
	STA VBLANK
;	STA HMCLR          ; Clear Ball and mossile movement
	LDY #16           ; Count picture lines from 16 t0 208 (192 lines)
Picture:
;    LDA #0
;    CPY #100           ; Ball Y position
;    BNE NoBall
;	LDA #2
;NoBall:
;    STA ENABL
	TYA               ; Divide by line number by 32
	STA $81
	LSR
	LSR
	LSR
	LSR
	LSR
	STA $80           ; Multiply by 3
	ASL
	CLC
	ADC $80           ; $80 is temp
	TAX
;	LDX #0            ; Temporary test to use only first value
	LDA CastleDef,X   ; Set PF to one of 7 values
	STA PF0
	INX
	LDA CastleDef,X
	STA PF1
	INX
	LDA CastleDef,X
	STA PF2
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
	
CastleDef:
    .byte $F0,$FE,$15          ;XXXXXXXXXXX X X X      R R R RRRRRRRRRRR                                      
    .byte $30,$03,$1F          ;XX        XXXXXXX      RRRRRRR        RR                                      
    .byte $30,$03,$FF          ;XX        XXXXXXXXXXRRRRRRRRRR        RR                                      
    .byte $30,$00,$FF          ;XX          XXXXXXXXRRRRRRRR          RR                                      
    .byte $30,$00,$3F          ;XX          XXXXXX    RRRRRR          RR                                      
    .byte $30,$00,$00          ;XX                                    RR                                      
    .byte $F0,$FF,$0F          ;XXXXXXXXXXXXXX            RRRRRRRRRRRRRR
	

	echo "----",($FFFC - *) ," bytes left"
	
	org $FFFC
	.word Start
	.word Start
	
