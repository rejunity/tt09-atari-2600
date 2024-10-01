;///////////////////////////////////////////////////////////////
;//	3 Bars Background Effect Demo by Christian Bogey      //
;//                  Friday, April 30, 2004                   //
;///////////////////////////////////////////////////////////////


    	processor 6502 
        include "vcs.h" 
        include "macro.h" 

	SEG CODE
	ORG $F000	; Start Adress

Start		; Standard init code

	SEI	; Clear Interrups. The 6507 doesn't use interrupts but
		; the program can run on a 7800 (6502) which use it.
		; Prevent from interferences too : interrupt capabilities
		; are included in the 6507 but the pins aren't linked.
	CLD	
	LDX #$FF
	TXS
	LDA #0

Clear_Mem
	STA 0,X
	DEX
	BNE Clear_Mem	; Clear mem countdown from $FF to $01 
			; >>>>>>>>> VBLANK Set to 0 Later

New_Frame 
        ; Start of Vertical Sync

        LDA #2 
        STA VSYNC 	; Turn VSYNC On
            
        ; Count 3 Scanlines 

        STA WSYNC 
        STA WSYNC 
        STA WSYNC 

        LDA #0 		; 			// 2 cycles
        STA VSYNC	; Turn VSYNC Off 	// 3 cycles

  	;>>>>>>>>>>>>> Start of Vertival Blank <<<<<<<<<<<<<<<<<<<
  	; Count 37 Scanlines

	LDA  #43	;			// 2 cycles
	STA  TIM64T	;			// 4 cycles
	
	;>>>>>>>>>>>>>>>> Free space for code starts here 
        
        
	;>>>>>>>>>>>>>>>> Free space for code ends here

Wait_VBLANK_End
	LDA INTIM	;			// 4 cycles
	BPL Wait_VBLANK_End	;		// 3 cycles

	STA WSYNC	;       		// 3 cycles  Total Amount = 21 cycles
			;			2812-21 = 2791; 2791/64 = 43.60
        LDA #0 
        STA VBLANK 	; Enable TIA Output
			
	;>>>>>>>>>>>>>>>> End of Vertival Blank <<<<<<<<<<<<<<<<<<<
	
	
	;>>>>>>>>>>>>>>>> KERNAL starts here <<<<<<<<<<<<<<<<<<<<<<

        ; 192 scanlines of picture 
        LDX #0
        LDY #191
        STA WSYNC     	; 191 + 1 = 192 Scanlines
        NOP		; 2 Cycles
        JMP Loop1	; + 3 Cycles // 5 Cycles are necessary for 2nd colour
        		;            // bar alignment (Next frame build)
Loop1
        INX
        STX COLUBK 
        
        REPEAT 12
        NOP
        REPEND
        STY COLUBK
        REPEAT 10
        NOP
        REPEND
        STX COLUBK 
        INX
        STA WSYNC 
        DEY
        BNE Loop1
	LDX #0
	STX COLUBK
	
	;>>>>>>>>>>>>>>>> KERNAL ends here <<<<<<<<<<<<<<<<<<<<<<<<
	
;////////////// End Of Display ////////////////////////////////////////      	
    
	LDA #%00000010 		; Disable VIA Output
        STA VBLANK      
        
	; 30 Scanlines Overscan
	LDY #29
Loop2
	STA WSYNC
	DEY
	BNE Loop2
	STA WSYNC	; 29+1 = 30
	
	
        ; Build New Frame 
       	JMP New_Frame 		

	ORG $FFFA 

        .word Start 	; NMI - Not used by the 2600 but exists on a 7800
        .word Start     ; RESET 
        .word Start    	; IRQ - Not used by the 2600 but exists on a 7800

        END 
