;Here's the source code for that final digital clock programme.
;Feel free to employ and distribute this code however you may wish.
;Both the source code and the binary are public domain.
;
;This code is (c)1997 by Chris "Crackers" Cracknell
;and is placed in the Public Domain by the author.
;Anyone is free to employ and distribute this code
;as they see fit.
;
;-----------------------------------------------------------------------------

	processor 6502

VSYNC	=	$00
VBLANK	=	$01
WSYNC	=	$02
NUSIZ0	=	$04
NUSIZ1	=	$05
COLUPF 	=	$08
COLUBK	=	$09
PF0	=	$0D
PF1	=	$0E
PF2	=	$0F
SWCHA	=	$280
INTIM	=	$284
TIM64T	=	$296
CTRLPF	=	$0A
COLUP0	=	$06
COLUP1	=	$07
GP0	=	$1B
GP1	=	$1C
HMOVE	=	$2a
RESP0	=	$10
RESP1	=	$11

;RAM

TEMP	=	$80	;2 bytes for temporary data
SECS	=	$82	;seconds counter
MINS	=	$83	;minutes counter
HOURS	=	$84	;hours counter
JOYDEL	=	$85	;joystick delay variable
JOY1ST	=	$86	;joystick first move variable
SPRITEA	=	$87	;8 bytes for the first sprite
SPRITEB	=	$8F	;8 bytes for the second sprite
RMINS	=	$97	;real minutes
RHOURS	=	$98	;real hours
FRAMES	=	$99	;frames counter

	org  $F000

start	SEI            
	CLD
	LDX  #$FF
	TXS
	LDA  #$00

zero	STA  $00,X	;looks familiar, right?     
	DEX		;typical zeroing routine
	BNE  zero

	lda  #$01	;now we set up all our variables
	sta  CTRLPF	
	lda  #$0C	;set our starting time at 12:00
	sta  HOURS	;just like a VCR, eh? Except it doesn't blink
	lda  #$3C	;00 minutes
	sta  MINS
	lda  #$ca	;nice pretty green for our sprites
	sta  COLUP0
	sta  COLUP1
	lda  #$07	;make them good and fat
	sta  NUSIZ0
	sta  NUSIZ1
	lda  #$3C	;initialize the frame and seconds counters
	sta  FRAMES
	sta  SECS


main	JSR  vertb	;main loop
	JSR  time
	JSR  draw       
	JSR  clear
    	JMP  main       

vertb	LDX  #$00	;vertical blank, We all know what this is about         
	LDA  #$02           
	STA  WSYNC         
	STA  WSYNC        
	STA  WSYNC
	STA  VSYNC        
	STA  WSYNC         
	STA  WSYNC        
	LDA  #$2C
	STA  TIM64T        
	LDA  #$00        
	STA  WSYNC        
	STA  VSYNC
	RTS

time	ldy  #06	;just load Y ahead of time for #of sprite lines
	lda  #$3C	;60
	sec
	sbc  MINS	;subtract the clock minutes from 60 to get the
	sta  RMINS	;real minutes since clock counts down
	cmp  #$00	;see if it's 00 minutes
	beq  min0	
	cmp  #$32	;see if it's more than 50 minutes
	bpl  min5
	cmp  #$28	;see if it's more than 40 minutes
	bpl  min4
	cmp  #$1E	;see if it's more than 30 minutes
	bpl  min3
	cmp  #$14	;see if it's more than 20 minutes
	bpl  min2
	cmp  #$0A	;see if it's more than 10 minutes
	bpl  min1

min0	lda  zeros,y	;minutes must be less than 10 so load 00 sprite
	and  #$F0	;strip the first 4 bits
	sta  SPRITEA,y	;store it to sprite A memory
	dey		
	bpl  min0	;get next sprite line
	lda  #$00	;less than 10 minutes
	jmp  minload	;go to where we load the first 4 bits of sprite

min5	lda  fives,y	;minutes must be 50+ so load 55 sprite
	and  #$F0	;strip 1st four bits
	sta  SPRITEA,y	;store it to sprite A memory
	dey
	bpl  min5	;get next sprite line
	lda  #$32	;50+ minutes - you'll need this number later to
	jmp  minload	;load the second half the sprite data

min4	lda  fours,y	;minutes must be 40+
	and  #$F0
	sta  SPRITEA,y
	dey
	bpl  min4
	lda  #$28	;40+ minutes
	jmp  minload

min3	lda  threes,y	;minutes must be 30+
	and  #$F0
	sta  SPRITEA,y
	dey
	bpl  min3
	lda  #$1E	;30+ minutes
	jmp  minload

min2	lda  twos,y	;minutes must be 20+
	and  #$F0
	sta  SPRITEA,y
	dey
	bpl  min2
	lda  #$14
	jmp  minload	;20+ minutes

min1	lda  ones,y	;minutes must be 10+
	and  #$F0
	sta  SPRITEA,y
	dey
	bpl  min1
	lda  #$0A	;10+ minutes

minload	STA  TEMP	;the accumulator had the 10s of minutes
	LDA  RMINS	;now we subtract the 10s minutes from the real
	sec		;minutes to get the 1s minutes to act as a pointer
	SBC  TEMP	;for the data tables for 2nd half of sprite
	ASL		;double the number
	TAX		
	LDA  numblk,x	;load the first half of the sprite data address
	sta  TEMP
	lda  numblk+1,x	;load the second half of the sprite table address
	sta  TEMP+1

	ldy  #$06	;number of lines in the sprite (-1)
msload	lda  (TEMP),y	;get the sprite data
	and  #$0F	;strip off the last 4 bits
	ora  SPRITEA,y	;combine the 1st half with the 2nd half
	sta  SPRITEA,y	;put it back in the sprite memory
	dey		
	bpl  msload	;get the next line of data

	ldy  #$06	;preload number of sprite lines (-1)
	lda  #$18	;24 hours
	sec
	SBC  HOURS	;subtract the counter hours to get 
	STA  RHOURS	;the real hours value
	cmp  #$00	;see if it's 12:00 am
	beq  hour0	
	cmp  #$14	;see if it's 20+ hours
	bpl  hour2
	cmp  #$0A	;see if it's 10+ hours
	bpl  hour1
	
hour0	lda  zeros,y	;load the zeros sprite data
	and   #$F0	;strip the 1st four bits
	sta  SPRITEB,y	;store to the 2nd sprite memory
	dey
	bpl  hour0
	lda  #$00	;same deal as with the minutes
	jmp  loadhrs	;but now we load the second half of the hours data

hour1	lda  ones,y
	and  #$F0
	sta  SPRITEB,y
	dey
	bpl  hour1
	lda  #$0A
	jmp  loadhrs

hour2	lda  twos,y
	and  #$F0
	sta  SPRITEB,y
	dey
	bpl  hour2
	lda  #$14
	jmp  loadhrs

loadhrs	STA  TEMP
	LDA  RHOURS
	sec
	SBC  TEMP
	asl
	tax
	lda  numblk,x
	sta  TEMP
	lda  numblk+1,x
	sta  TEMP+1

	ldy  #$06
hsload	lda  (TEMP),y
	and  #$0F
	ora  SPRITEB,y
	sta  SPRITEB,y
	dey
	bpl  hsload
	rts


numblk	.word  zeros	;where all the sprites are at
	.word  ones
	.word  twos
	.word  threes
	.word  fours
	.word  fives
	.word  sixes
	.word  sevens
	.word  eights
	.word  nines

draw	LDA  INTIM	;check to see if it's time to draw a frame	         
	BNE  draw
	sta  WSYNC
	sta  HMOVE
	sta  VBLANK	;turn the screen on!


;insert  display kernal

	ldx  #$3F	;okay, this display kernal sucks, but I'm not doing
blow1	sta  WSYNC	;much here so I didn't go for anything fancy since
	dex		;this is just a demo. This wouldn't be the way you 
	bpl  blow1	;do things in a game, but it works for this.
	sta  WSYNC
	nop		;See... you'd never do something weenie like this
	nop		;in a real programme
	nop		;
	nop		;
	nop		;but when I was experimenting with this programme
	nop		;I just had a whole bunch of ";nop" lines here
	nop		;and I removed the ";" until I got the spacing more
	nop		;or less where I wanted it
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	sta  RESP0
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	sta  RESP1

	ldy  #$06
sload	lda  SPRITEB,y
	sta  GP0
	lda  SPRITEA,y
	sta  GP1
	sta  WSYNC	;you wouldn't do something weenie like this
	sta  WSYNC	;either in a real programme, but it was an
	sta  WSYNC	;easy way to make each sprite 8 lines high
	sta  WSYNC	;and I was more concerned with making a working
	sta  WSYNC	;and accurate clock than a nice display.
	sta  WSYNC
	sta  WSYNC
	sta  WSYNC
	dey
	bpl  sload
	lda  #$00
	sta  GP0
	sta  GP1


	ldx  #$48
blow2	sta  WSYNC	;now we just blow the rest of the unused scanlines.
	dex
	bpl  blow2
	rts
	

clear   LDA  #$24	;set timer for overscan
	STA  TIM64T	
	LDA  #$02	;clear the screen and turn off the video
	STA  WSYNC  
	STA  VBLANK 
	LDA  #$00
 	STA  PF0
	STA  PF1
	STA  PF2
	sta  COLUPF
	sta  COLUBK


	LDA  #$3C	;this is the clock routine itself. it counts
	DEC  FRAMES	;down from 60 frames, and then decreases the
	bne  joy	;seconds, which count down the minutes and then
	lda  #$3C	;the hours.. etc. For whatever reason my 2600
	STA  FRAMES	;wasn't running at exactly 60 frames a second
	DEC  SECS	;so there were two lines inserted to correct
	bne  joy	;timing accuracy problems
	STA  SECS
	DEC  SECS	;here's one. Kept me from losing a second every
	DEC  MINS	;minute
	bne  joy
	STA  MINS
	LDA  #$18
	INC  SECS	;here's the other. It kept me from gaining a
	DEC  HOURS	;second every hour.
	bne  joy
	STA  HOURS
			;now my timing inaccuracies may have been caused
			;by either my V-blank, V-sync, Overscan, or
			;display being a few scanlines too long or short.
			;theoretically if all my lines were bang on,
			;I wouldn't have needed those two seconds counter
			;corrections. But with them inplace, it allows me
			;to be a little looser with my code which works for
			;me. It may still gain or lose a second every 60
			;hours, but I can live with that. And since I'll
			;be employing this clock in a virtual pet game and
			;not a swiss made olympic time piece, a little
			;inaccuracy won't matter.

joy	lda  SWCHA	;load joysticks
	ora  #$0f	;strip the data for player #2 joystick
	cmp  #$ef	;up
	beq  up
	cmp  #$df	;down
	beq  down
	cmp  #$bf	;left
	beq  left
	cmp  #$7f	;right
	beq  right
	lda  #$00	;no movement
	sta  JOYDEL	;reset the joystick delay variable
	lda  #$01	;reset the first move variable
	sta  JOY1ST
	jmp  oscan	;finish off the overscan

up	lda  HOURS	;check to see if we've run out our hours
	cmp  #$01
	beq  oscan	;yep, then ignore the movement
	inc  JOYDEL	;increase the joystick delay variable
	lda  JOY1ST	;check to see if this is the first move in this
	cmp  #$01	;direction.
	beq  now1	;if it is then change the variable now
	lda  #$1E	;nope then see if there's been enough of a delay
	cmp  JOYDEL	;to change the variable yet.
	bne  oscan
now1	lda  #$00	;reset the joystick delay and set the first move
	sta  JOY1ST	;indicator to "no"
	sta  JOYDEL
	dec  HOURS	;decrease the hours counter
	jmp  oscan

down	lda  HOURS
	cmp  #$18
	beq  oscan
	inc  JOYDEL
	lda  JOY1ST
	cmp  #$01
	beq  now2
	lda  JOYDEL
	cmp  #$1E
	bne  oscan
now2	lda  #$00
	sta  JOY1ST
	sta  JOYDEL
	inc  HOURS	;increase the hours counter
	jmp  oscan

left	lda  MINS
	cmp  #$01
	beq  oscan
	inc  JOYDEL
	lda  JOY1ST
	cmp  #$01
	beq  now3
	lda  #$1E
	cmp  JOYDEL
	bne  oscan
now3	lda  #$00
	sta  JOY1ST
	sta  JOYDEL
	dec  MINS	;decrease the minutes counter
	jmp  oscan
	
right	lda  MINS
	cmp  #$3c
	beq  oscan
	inc  JOYDEL
	lda  JOY1ST
	cmp  #$01
	beq  now4
	lda  #$1E
	cmp  JOYDEL
	bne  oscan
now4	lda  #$00
	sta  JOY1ST
	sta  JOYDEL
	inc  MINS	;increase the minutes counter

oscan	lda  INTIM	;see if the timer has run out                
	BNE  oscan
	STA  WSYNC            
	RTS                

zeros	.byte %11100111	;sprites are stored upsidedown, and there
	.byte %10100101	;are two copies of each number in each sprite
	.byte %10100101	;location. The unwanted number is stripped
	.byte %10100101	;with the AND command (AND #$0F for the right
	.byte %10100101	;number stripped, AND #F0 for the left)
	.byte %10100101	;then any two numbers can be combined with an 
	.byte %11100111	;OR command. Neat huh?

ones	.byte %11100111
	.byte %01000010
	.byte %01000010
	.byte %01000010
	.byte %01000010
	.byte %11000110
	.byte %01000010

twos	.byte %11100111
	.byte %10000100
	.byte %10000100
	.byte %11100111
	.byte %00100001
	.byte %00100001
	.byte %11100111

threes	.byte %11100111
	.byte %00100001
	.byte %00100001
	.byte %11100111
	.byte %00100001
	.byte %00100001
	.byte %11100111

fours	.byte %00100001
	.byte %00100001
	.byte %00100001
	.byte %11100111
	.byte %10100101
	.byte %10100101
	.byte %10000100

fives	.byte %11100111
	.byte %00100001
	.byte %00100001
	.byte %11100111
	.byte %10000100
	.byte %10000100
	.byte %11100111

sixes	.byte %11100111
	.byte %10100101
	.byte %10100101
	.byte %11100111
	.byte %10000100
	.byte %10000100
	.byte %11000110

sevens	.byte %10000100
	.byte %10000100
	.byte %10000100
	.byte %01000010
	.byte %00100001
	.byte %00100001
	.byte %11100111

eights	.byte %11100111	;This code is (c)1997 by Chris "Crackers" Cracknell
	.byte %10100101	;and is placed in the Public Domain by the author.
	.byte %10100101	;Anyone is free to employ and distribute this code
	.byte %11100111	;as they see fit.
	.byte %10100101	;
	.byte %10100101	;
	.byte %11100111	;
			;
nines	.byte %00100001	;Well... if you're going to use this code in a
	.byte %00100001	;"Doomsday Machine" to destroy the world, then
	.byte %00100001	;I would rather you didn't. But otherwise, knock
	.byte %11100111	;yourself out with it.
	.byte %10100101	;
	.byte %10100101	;Actually... if the "Doomsday Machine" is just in 
	.byte %11100111	;a game, then it's okay to use the code.
			;
	org $FFFC	;Unless it's like the movie "War Games" where the
	.word start	;computer running the game is hooked up to a real
	.word start	;"Doomsday Machine" then it wouldn't be a good idea.
