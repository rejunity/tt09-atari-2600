   LIST OFF
; ***  D O N K E Y  K O N G  ***
; Copyright 1982 Coleco Industries, Inc.
; Programmer: Garry Kitchen

; Analyzed, labeled and commented
;  by Dennis Debro
; Last Update: 12/28/2018
;
; *** 126 BYTES OF RAM USED 2 BYTES FREE
; ***   0 BYTES OF ROM FREE
;
; ==============================================================================
; = THIS REVERSE-ENGINEERING PROJECT IS BEING SUPPLIED TO THE PUBLIC DOMAIN    =
; = FOR EDUCATIONAL PURPOSES ONLY. THOUGH THE CODE WILL ASSEMBLE INTO THE      =
; = EXACT GAME ROM, THE LABELS AND COMMENTS ARE THE INTERPRETATION OF MY OWN   =
; = AND MAY NOT REPRESENT THE ORIGINAL VISION OF THE AUTHOR.                   =
; =                                                                            =
; = THE ASSEMBLED CODE IS © 1982, COLECO INDUSTRIES, INC.                      =
; =                                                                            =
; ==============================================================================
;
; Garry uses a horizontal position routine that *seems* to first appear in his
; Space Jockey game. This routine was modified over the years and has been seen
; in a number of games.
;
; To produce the PAL50 listing I used the CBS version. The PAL50 version adjusts
; the vertical blank time and overscan time to make the game produce 312 
; scanlines. The colors were also adjusted but it seems they missed the place in
; the kernel where Garry colors Mario directly. The speeds were not adjusted but
; the sound frequencies were.
;
; This game uses a lot overlays and a lot of offsets so I might have missed some
; variable meanings or table positions.

   processor 6502
      
;
; NOTE: You must compile this with vcs.h version 105 or greater.
;
TIA_BASE_READ_ADDRESS = $30         ; set the read address base so this runs on
                                    ; the real VCS and compiles to the exact
                                    ; ROM image

   include macro.h
   include tia_constants.h
   include vcs.h

;
; Make sure we are using vcs.h version 1.05 or greater.
;
   IF VERSION_VCS < 105
   
      echo ""
      echo "*** ERROR: vcs.h file *must* be version 1.05 or higher!"
      echo "*** Updates to this file, DASM, and associated tools are"
      echo "*** available at at https://github.com/munsie/dasm"
      echo ""
      err
      
   ENDIF
;
; Make sure we are using macro.h version 1.01 or greater.
;
   IF VERSION_MACRO < 101

      echo ""
      echo "*** ERROR: macro.h file *must* be version 1.01 or higher!"
      echo "*** Updates to this file, DASM, and associated tools are"
      echo "*** available at at https://github.com/munsie/dasm"
      echo ""
      err

   ENDIF

   LIST ON

;===============================================================================
; A S S E M B L E R - S W I T C H E S
;===============================================================================

NTSC                    = 0
PAL50                   = 1
PAL60                   = 2

TRUE                    = 1
FALSE                   = 0

   IFNCONST COMPILE_VERSION

COMPILE_VERSION         = NTSC      ; change to compile for different regions

   ENDIF

   IF !(COMPILE_VERSION = NTSC || COMPILE_VERSION = PAL50 || COMPILE_VERSION = PAL60)

      echo ""
      echo "*** ERROR: Invalid COMPILE_VERSION value"
      echo "*** Valid values: NTSC = 0, PAL50 = 1, PAL60 = 2"
      echo ""
      err

   ENDIF

   IFNCONST CHEAT_ENABLED
   
CHEAT_ENABLED           = FALSE     ; set to TRUE to enable no death collisions

   ENDIF

   IF !(CHEAT_ENABLED = TRUE || CHEAT_ENABLED = FALSE)

      echo ""
      echo "*** ERROR: Invalid CHEAT_ENABLED value"
      echo "*** Valid values: FALSE = 0, TRUE = 1"
      echo ""
      err

   ENDIF
   
;===============================================================================
; F R A M E - T I M I N G S
;===============================================================================

   IF COMPILE_VERSION = NTSC || COMPILE_VERSION = PAL60

VBLANK_TIME             = 45
OVERSCAN_TIME           = 34

   ELSE

VBLANK_TIME             = 75
OVERSCAN_TIME           = 64

   ENDIF
   
;===============================================================================
; C O L O R - C O N S T A N T S
;===============================================================================

BLACK                   =  $00
WHITE                   =  $0F

NTSC_COLOR_MARIO_SUIT   = $46       ; missed in PAL50 conversion

   IF COMPILE_VERSION = NTSC
   
YELLOW                  = $10
RED_ORANGE              = $20
BRICK_RED               = $30
RED                     = $40
COBALT_BLUE             = $60
BLUE                    = $80
CYAN                    = $A0
DK_GREEN                = $D0
   
COLOR_GIRLFRIEND_HAIR   = YELLOW + 14
COLOR_GIRLFRIEND_SHOES  = YELLOW + 14
COLOR_GIRLFRIEND_SASH   = RED + 6
COLOR_GIRLFRIEND_DRESS  = CYAN + 8
COLOR_MARIO_SUIT        = RED + 6
COLOR_MARIO_SHOES       = CYAN + 6
COLOR_SCORE             = BLUE + 10
COLOR_BONUS_TIMER       = DK_GREEN + 10
COLOR_FIREFOX_PLAYFIELD = BLUE + 10
COLOR_BARREL_PLAYFIELD  = COBALT_BLUE + 10
COLOR_OBSTACLES         = RED_ORANGE + 15
COLOR_DONKEY_KONG       = BRICK_RED + 4

   ELSE
   
YELLOW                  = $20
GREEN                   = $30
BRICK_RED               = $40
RED                     = $60
PURPLE                  = $80
BLUE                    = $B0
LT_BLUE                 = $C0

COLOR_GIRLFRIEND_HAIR   = YELLOW + 14
COLOR_GIRLFRIEND_SHOES  = YELLOW + 8
COLOR_GIRLFRIEND_SASH   = RED + 9
COLOR_GIRLFRIEND_DRESS  = BLUE + 7
COLOR_MARIO_SUIT        = BRICK_RED + 4
COLOR_MARIO_SHOES       = LT_BLUE + 8
COLOR_SCORE             = LT_BLUE + 8
COLOR_BONUS_TIMER       = GREEN + 8
COLOR_FIREFOX_PLAYFIELD = LT_BLUE + 8
COLOR_BARREL_PLAYFIELD  = PURPLE + 8
COLOR_OBSTACLES         = YELLOW + 11
COLOR_DONKEY_KONG       = BRICK_RED + 4

   ENDIF

;===============================================================================
; U S E R - C O N S T A N T S
;===============================================================================

ROM_BASE                = $F000
   
; game state values
GAME_IN_PROGRESS        = %10000000
GAME_PAUSED             = %00000000
START_NEW_LEVEL         = %00000001
LEVEL_COMPLETED         = %00000010


MAX_OBSTACLES           = 4

HAMMER_KERNEL_SECTION   = 4
NUM_WALKWAYS            = 5

STARTING_MARIOS         = 2         ; number of lives at the start of a game
MARIO_MOVE_RATE         = 2         ; decrement for faster mario -- increase for slower
MAX_HAMMER_TIME         = 3

JUMP_HANGTIME           = 31
INIT_MARIO_HORIZ_POS    = 49
INIT_MARIO_VERT_POS_BARREL = 154
INIT_MARIO_VERT_POS_FIREFOX = 133

INIT_HAMMER_HORIZ_POS_BARREL = 45
INIT_HAMMER_HORIZ_POS_FIREFOX = 84

BONUS_TIMER_DELAY       = $7F

H_DONKEY_KONG           = 20
MARIO_HEIGHT            = 17
H_DIGITS                = 8
H_HAMMER                = 14
H_KERNEL_SECTION        = 27

JUMPING_HEIGHT          = 7         ; increase this value for the high jump

LADDER_RANGE            = 3

FAIR_PIXEL_DELTA        = 9

OBSTACLE_HEIGHT         = 36
OBSTACLE_GRAPHIC_HEIGHT = 8

TOP_PLATFORM_VALUE      = 12

BARREL_SPRITE_NUMBER    = 0
FALLING_BARREL_SPRITE_NUMBER = 1
FIREFOX_SPRITE_NUMBER   = 2

; obstacle moving state
OBSTACLE_MOVING_RIGHT   = %01
OBSTACLE_MOVING_LEFT    = %00
OBSTACLE_MOVING_DOWN    = %11110000

; rivit constants
HORIZ_LEFT_RIVIT        = 54        ; horizontal position of left rivit
HORIZ_RIGHT_RIVIT       = 106       ; horizontal position of right rivit

COMPLETE_RIVIT_WALKWAY  = 18
LEFT_RIVIT_VALUE        = 6
RIGHT_RIVIT_VALUE       = 12

MAX_FIREFOX_LADDERS     = 16

XMIN_FIREFOX            = 36
XMAX_FIREFOX            = 124

; barrel constants
XMIN_BARREL_ODD         = 41
XMAX_BARREL_ODD         = 117

MAX_MARIO_BARREL_UP_LADDERS = 9
MAX_MARIO_BARREL_DOWN_LADDERS = 8        ; number of valid ladders Maio can use

YMIN_LEVEL0                   = 15
STARTING_BARREL_VERT          = TOP_PLATFORM_VALUE
STARTING_BARREL_HORIZ         = 37
BOTTOM_BARREL_PLATFORM_VALUE  = 145

; point value constants (BCD)
POINT_VALUE_JUMPING_OBSTACLE = $0100
POINT_VALUE_PULLING_RIVIT = $0100
POINT_VALUE_SMASHING_OBSTACLE = $0800
STARTING_BONUS                = $5000

JUMPING_SOUND_IDX       = 1
WALKING_SOUND_IDX       = 2
INCREMENT_SCORE_SOUND_IDX = 3
GAME_OVER_SOUND_IDX     = 3
LOSING_LIFE_SOUND_IDX   = 4
LEVEL_COMPLETED_SOUND_IDX = 5

;===============================================================================
; Z P - V A R I A B L E S
;===============================================================================
   SEG.U variables
   .org $80
   
obstacleVertPos         ds 4
marioHorizAnimationValue ds 1
jumpHangTime            ds 1
hammerTime              ds 1
playerScore             ds 2
marioFrameDelay         ds 1
colorCyclingTimer       ds 1
soundIndex              ds 1
gameState               ds 1
losingLifeFlag          ds 1
colorCyclingMode        ds 1
currentSoundPlaying     ds 1
currentGameBoard        ds 1
resetDebounce           ds 1
backgroundColor         ds 1
marioHorizPos           ds 1
marioDirection          ds 1
hammerHandleGraphicPtrs ds 2
hammerMalletGraphicPtrs ds 2
nextObstacleSlot        ds 1
playfieldColor          ds 1
marioVertPos            ds 1
hammerHorizPos          ds 1
firefoxPFIndexValues    ds 6
numberOfLives           ds 1
bonusTimer              ds 1
zpMarioGraphics         ds 28
obstacleHorizPositions  ds 4
obstacleDirections      ds 4
barrelLadderNumber      ds 4
obstacleCoarseHorizPosValue ds 6
obstacleFineHorizPosValue ds 6
rightPF1Pointer         ds 2
pf0Pointer              ds 2
digitPointer            ds 9
;-------------------------------------------
pf2Pointer              = digitPointer
leftPF1Pointer          = digitPointer + 2
obstaclePointer         = digitPointer + 4
marioGraphicPointer     = digitPointer + 6
;-------------------------------------------
marioColorPointer       = marioGraphicPointer
audioFrequecyPointer    = marioGraphicPointer
marioOffset             = marioGraphicPointer + 2
;-------------------------------------------
joystickValue           = marioOffset
;--------------------------------------
kernelSection           = joystickValue
;-------------------------------------------
obstacleOffset          = kernelSection
;-------------------------------------------
tmpLastObstacleToMove   ds 1
;--------------------------------------
tmpSixDigitLoopCount    = tmpLastObstacleToMove
;--------------------------------------
tmpKernelHeight         = tmpSixDigitLoopCount
randomSeed              ds 1
frameCount              ds 1
actionButtonDebounce    ds 1
ladderNumber            ds 1
jumpingDirection        ds 1
jumpingObstacle         ds 1
marioPlatform           ds 1
;-------------------------------------------
tmpObstacleIndex        = marioPlatform
;-------------------------------------------
hammerHandleNUSIZ       = tmpObstacleIndex
;-------------------------------------------
tmpGraphicIndex         = hammerHandleNUSIZ
;--------------------------------------
temp                    = tmpGraphicIndex
hammerKernelVector      ds 2
kernelVector            ds 2
obstaclePointerLSB      ds 6
marioColorPointerLSB    ds 6

   echo "***",(* - $80)d, "BYTES OF RAM USED", ($100 - *)d, "BYTES FREE"
   
;===============================================================================
; R O M - C O D E
;===============================================================================

   SEG Bank0
   .org ROM_BASE
   
Start
;
; Set up everything so the power up state is known.
;
   sei                              ; disable interrupts
   cld                              ; clear decimal mode
   ldx #$FF
   txs                              ; set the stack to the beginning
   inx                              ; x = 0
   txa
.clearLoop
   sta VSYNC,x
   inx
   bne .clearLoop
   jsr InitializeGame
   lda #STARTING_MARIOS
   sta numberOfLives                ; intialize number of Marios
   dec resetDebounce                ; set high to show RESET held
   dec colorCyclingMode             ; set hight to cycle colors
MainLoop
   lda backgroundColor              ; get background color
   sta COLUBK                       ; set background color
   ldy #$FF
   sty WSYNC                        ; wait for next scan line
   sty VBLANK                       ; disable TIA (i.e. D1 = 1)
   lda #OVERSCAN_TIME
   sta TIM64T                       ; set timer for overscan period
   inc randomSeed
   lda #<HorizontalColors
   ldy #<Blank
   ldx #NUM_WALKWAYS
.setLSBLoop
   sta marioColorPointerLSB,x       ; set the LSB value for Mario colors
   sty obstaclePointerLSB,x         ; set the LSB to clear obstacle
   dex
   bpl .setLSBLoop
   inc frameCount                   ; increment frame count
   lda frameCount                   ; get current frame count
   and #BONUS_TIMER_DELAY
   bne .checkIfJoystickMoved
   lda gameState                    ; get current game state
   bpl ProcessColorCycling          ; branch if game not in progress
   lda bonusTimer                   ; get bonus timer value
   sed                              ; set to decimal mode
   sec
   sbc #1                           ; reduce the timer by 1
   sta bonusTimer
   cld                              ; clear decimal mode
   bne ProcessColorCycling          ; branch if time not run out
   jsr PlayDeathSound
ProcessColorCycling
   lda colorCyclingMode             ; get color cycling mode value
   bpl .incrementColorCyclingTimer  ; branch if not in color cycling mode
   inc backgroundColor              ; increment the background color
   dec playfieldColor               ; decrement the playfield color
.incrementColorCyclingTimer
   inc colorCyclingTimer
   bne .checkIfJoystickMoved
   stx colorCyclingMode             ; set color cycle value
.checkIfJoystickMoved
   ldy #0
   cpx SWCHA                        ; compare x register value with joystick
   bne .endColorCycling             ; branch if joystick moved
   lda INPT4                        ; read left port action button
   bmi CheckConsoleSwitches         ; branch if button not pressed
.endColorCycling
   sty colorCyclingTimer            ; reset color cycling timer
   lda colorCyclingMode             ; get color cycling mode value
   bpl CheckConsoleSwitches
   sty colorCyclingMode             ; clear color cycling mode (y = 0)
   jsr InitializeGame
CheckConsoleSwitches
   lda SWCHB                        ; read the console switches
   lsr                              ; shift RESET to carry
   bcs .resetNotPressed             ; branch if RESET not pressed
   lda resetDebounce                ; get RESET debounce value
   bmi ClearGameRAM                 ; branch if RESET held
   dec resetDebounce                ; set high to show RESET held
ClearGameRAM
   ldx #<currentGameBoard - (PF1 + 64)
   lda #0
.clearGameRAM
   sta PF1 + 64,x                   ; clear RAM from PF2 to currentGameBoard
   dex
   bne .clearGameRAM
   jsr InitializeGame
   lda #STARTING_MARIOS             ; set the starting Mario lives
   sta numberOfLives
   bne .setMarioGraphicPointerInfo  ; unconditional branch
   
.resetNotPressed
   lda gameState                    ; get current game state
   bmi DetermineMarioMovement       ; branch if game in progress
   lda currentSoundPlaying          ; get the current sound being played
   bne .setMarioGraphicPointerInfo  ; branch if a sound is being played
   ldx INPT4                        ; read left port action button
   bmi .setMarioGraphicPointerInfo  ; branch if button not pressed
   lda gameState                    ; get current game state
   lsr                              ; shift START_NEW_LEVEL to carry
   bcs .resetBonusTimer             ; reset timer if starting a new level
   lda resetDebounce                ; get RESET debounce value
   bpl .setMarioGraphicPointerInfo  ; branch if RESET released       
.resetBonusTimer
   lda #STARTING_BONUS >> 8
   sta bonusTimer                   ; init bonus timer value
   ldx #GAME_IN_PROGRESS | LEVEL_COMPLETED | START_NEW_LEVEL | 124
   stx gameState                    ; set game state (i.e. x = 255)
   sty frameCount                   ; reset frame count (i.e. y = 0)
   sty resetDebounce                ; reset RESET debounce value (i.e. y = 0)
.setMarioGraphicPointerInfo
   jmp SetMarioGraphicPointerInfo

DetermineMarioMovement
   lda losingLifeFlag               ; get losing life value
   bmi .checkForJumpingMario        ; branch if Mario losing life       
   dec marioFrameDelay
   bmi .checkJoystickForMarioMovement
.checkForJumpingMario
   jmp CheckForJumpingMario

.checkJoystickForMarioMovement
   lda #MARIO_MOVE_RATE
   sta marioFrameDelay              ; reset Mario move frame rate
   lda SWCHA                        ; read joystick values
   ldx jumpHangTime                 ; get Mario jumping hang time value
   beq .setJoystickValue            ; branch if Mario not jumping
   lda jumpingDirection             ; get Mario jumping direction
.setJoystickValue
   sta joystickValue
   ldx marioDirection               ; get Mario direction value
   bpl DetermineMarioPlatform       ; branch if Mario moving horizontally
   jsr DetermineIfVerticalMovementAllowed
   bcc DetermineMarioPlatform       ; branch if vertical motion not allowed
   jmp CheckVerticalJoystickValues
       
DetermineMarioPlatform
   ldx #NUM_WALKWAYS
   lda marioVertPos                 ; get Mario vertical position
   sec
   sbc #H_KERNEL_SECTION - 5
   bcc .platformFound
.determineWalkwayLoop
   dex
   sbc #H_KERNEL_SECTION + 1
   bcs .determineWalkwayLoop
.platformFound
   stx marioPlatform                ; set Mario platform
   lda joystickValue                ; get current joystick value
   asl                              ; shift horizontal movements left
   bmi .checkRightMotion            ; branch if not moving left
   inc randomSeed
   lda #NO_REFLECT
   sta marioDirection               ; set Mario direction for MOVE_LEFT
   dec marioHorizPos                ; decrement Mario horizontal position
   dec marioHorizAnimationValue
   ldy #XMIN_FIREFOX                ; assume player on Firefox level
   lda currentGameBoard             ; get current game board
   bne .checkMinHorizPosition       ; branch if Firefox level
   lda marioPlatform                ; get Mario platform
   lsr                              ; shift D0 to carry
   bcs .checkMinHorizPosition       ; branch if an odd platform
   ldy #XMIN_BARREL_ODD
.checkMinHorizPosition
   cpy marioHorizPos
   bcc CheckRampValues              ; branch if Mario not reached left edge
   bcs .setMarioHorizPosition       ; unconditional branch
   
.checkRightMotion
   bcs CheckVerticalJoystickValues  ; branch if not moving right
   inc randomSeed
   lda #REFLECT
   sta marioDirection               ; set Mario direction for MOVE_RIGHT
   inc marioHorizPos                ; move Mario right
   inc marioHorizAnimationValue
   ldy #XMAX_FIREFOX
   lda currentGameBoard             ; get current game board
   bne .checkMaxHorizPosition       ; branch if Firefox level
   lda marioPlatform                ; get Mario platform
   lsr                              ; shift D0 to carry
   bcc .checkMaxHorizPosition       ; branch if an even platform
   ldy #XMAX_BARREL_ODD
.checkMaxHorizPosition
   cpy marioHorizPos
   bcs CheckRampValues              ; branch if Mario not reached right edge
.setMarioHorizPosition
   sty marioHorizPos
   sty marioHorizAnimationValue
.doneMarioHorizontalMovement
   jmp CheckForJumpingMario

CheckRampValues
   lda currentGameBoard             ; get current game board
   bne .doneMarioHorizMovement      ; branch if Firefox screen...no ramps
   lda marioPlatform                ; get Mario platform
   beq .doneMarioHorizMovement      ; branch if first platform...no ramp
   cmp #5                           ; determine if top platform
   beq .doneMarioHorizMovement      ; branch if top platform...no ramp   
   ldx #7
   lda marioHorizPos                ; get Mario horizontal position
   ldy marioDirection               ; get Mario direction value
   bne .determineMarioVertRampMovement; branch if Mario not moving left
   clc
   adc #1                           ; increment Mario horizontal position
.determineMarioVertRampMovement
   dex
   bmi .doneMarioHorizMovement
   cmp RampHorizValues,x            ; compare with Mario horizontal position
   bne .determineMarioVertRampMovement
   lda marioPlatform                ; get Mario platform
   lsr
   bcc .checkEvenNumberRamp         ; branch if even platform
   tya                              ; move Mario direction to the accumulator
   bne .moveUpRamp                  ; branch if Mario is moving left
   beq .moveDownRamp                ; unconditional branch
   
.checkEvenNumberRamp
   tya                              ; move Mario direction to the accumulator
   bne .moveDownRamp                ; branch if Mario is moving left
.moveUpRamp
   inc marioVertPos                 ; increment Mario vertical position
   bne .doneMarioHorizMovement      ; unconditional branch
   
.moveDownRamp
   dec marioVertPos                 ; decrement Mario vertical position
.doneMarioHorizMovement
   jmp CheckToRemoveRivits

CheckVerticalJoystickValues
   lda joystickValue                ; get the joystick value
   and #~MOVE_DOWN                  ; keep MOVE_DOWN value
   bne CheckForUpMotion             ; branch if joystick not pushed down
   dec randomSeed
   lda marioDirection               ; get Mario direction value
   bmi .marioMovingDown             ; branch if moving vertically
   lda hammerTime                   ; get Mario hammer time
   bne .doneMarioHorizontalMovement ; branch if Mario using hammer
   ldy #MAX_MARIO_BARREL_DOWN_LADDERS; offset for the down ladder table
   ldx #MAX_MARIO_BARREL_DOWN_LADDERS; maximum barrel ladders Mario can decend
   lda currentGameBoard             ; get current game board
   beq DetermineMarioDownLadder     ; branch if barrels
   ldy #<(FirefoxDownLadderTable - DownLadderTable + MAX_FIREFOX_LADDERS)
   ldx #MAX_FIREFOX_LADDERS         ; maximum number of ladders Mario can use
DetermineMarioDownLadder
   lda marioVertPos                 ; get Mario vertical position
.downLadderCheckLoop
   dey                              ; decrement down ladder table index
   dex                              ; decrement maximum number of ladders
   bmi .doneMarioHorizontalMovement
   cmp DownLadderTable,y
   bne .downLadderCheckLoop
   lda marioHorizPos                ; get Mario horizontal position
   sec
   sbc LadderHorizValues,y
   cmp #LADDER_RANGE
   bcs DetermineMarioDownLadder
   sty ladderNumber
.marioMovingDown
   lda #<-2
   sta marioDirection               ; set Mario direction value for MOVE_DOWN
   lda marioVertPos                 ; get Mario vertical position
   ldy ladderNumber
   cmp UpLadderTable,y
   bne .moveMarioDown
.doneMarioVerticalMovement
   jmp CheckForJumpingMario
   
.moveMarioDown
   inc marioVertPos                 ; increment Mario vertical position
   bne CheckToRemoveRivits          ; unconditional branch

CheckForUpMotion
   lda joystickValue                ; get the joystick value
   and #~MOVE_UP                    ; keep MOVE_UP value
   bne .doneMarioVerticalMovement   ; branch if joystick not pushed up
   dec randomSeed
   lda marioDirection               ; get Mario direction value
   bmi MarioMovingUp                ; branch if moving vertically
   lda hammerTime                   ; get Mario hammer time
   bne .doneMarioVerticalMovement   ; branch if Mario using hammer   
   ldx #MAX_MARIO_BARREL_UP_LADDERS ; maximum barrel ladders Mario can ascend
   ldy #MAX_MARIO_BARREL_UP_LADDERS ; offset for the up ladder table
   lda currentGameBoard             ; get current game board
   beq DetermineMarioUpLadder       ; branch if barrels   
   ldy #<(FirefoxUpLadderTable - UpLadderTable + MAX_FIREFOX_LADDERS)
   ldx #MAX_FIREFOX_LADDERS         ; maximum number of ladders Mario can use
DetermineMarioUpLadder
   lda marioVertPos                 ; get Mario vertical position
.upLadderCheckLoop
   dey                              ; decrement up ladder table index
   dex                              ; decrement maximum number of ladders
   bmi .doneMarioVerticalMovement
   cmp UpLadderTable,y
   bne .upLadderCheckLoop
   lda marioHorizPos                ; get Mario horizontal position
   sec
   sbc LadderHorizValues,y
   cmp #LADDER_RANGE
   bcs DetermineMarioUpLadder
   sty ladderNumber
MarioMovingUp
   lda #<-1
   sta marioDirection               ; set Mario direction value for MOVE_UP
   lda marioVertPos                 ; get Mario vertical position
   ldy ladderNumber
   cmp DownLadderTable,y
   beq CheckForJumpingMario
   dec marioVertPos
CheckToRemoveRivits
   lda currentGameBoard             ; get current game board
   beq PlayWalkingSound             ; branch if barrels
   ldx marioPlatform                ; get Mario platform
   cpx #1
   beq PlayWalkingSound             ; branch if Mario on last platform
   lda firefoxPFIndexValues,x       ; get platform rivit value
   ldy marioHorizPos                ; get Mario horizontal position
   cpy #HORIZ_LEFT_RIVIT
   beq .determineLeftRivitValue     ; branch if Mario at left rivit
   cpy #HORIZ_RIGHT_RIVIT
   bne PlayWalkingSound             ; branch if Mario not at right rivit
.determineRightRivitValue
   cmp #RIGHT_RIVIT_VALUE
   bcs .marioStandingInTheGap       ; branch if right rivit pulled
   adc #RIGHT_RIVIT_VALUE
   bpl .rivitPulled                 ; unconditional branch
   
.determineLeftRivitValue
   cmp #COMPLETE_RIVIT_WALKWAY
   bcs .marioStandingInTheGap       ; branch if all platform rivits removed
   cmp #LEFT_RIVIT_VALUE
   bcc .pullRivitFromPlatform
   cmp #RIGHT_RIVIT_VALUE
   bcc .marioStandingInTheGap
.pullRivitFromPlatform
   clc
   adc #LEFT_RIVIT_VALUE
.rivitPulled
   sta firefoxPFIndexValues,x
   jsr IncrementScoreForPullingRivit; increment points for removing rivit
   bne PlayWalkingSound             ; unconditional branch
   
.marioStandingInTheGap
   lda jumpHangTime                 ; get Mario jumping hang time value
   bne PlayWalkingSound             ; branch if Mario jumping over rivit gap
   jsr PlayDeathSound               ; Mario standing in rivit gap
PlayWalkingSound
   lda currentSoundPlaying          ; get the current sound being played
   bne CheckForJumpingMario         ; branch if a sound is being played
   lda marioHorizPos                ; get Mario horizontal position
   ldx marioDirection               ; get Mario direction value
   bpl .walkingSoundFrequencyIndex  ; branch if Mario not moving vertically
   lda marioVertPos                 ; get Mario vertical position
.walkingSoundFrequencyIndex
   and #3
   bne CheckForJumpingMario
   lda #5
   sta AUDC0
   lda #11
   sta AUDV0
   lda #WALKING_SOUND_IDX
   sta currentSoundPlaying          ; set to show walking sound playing
   sta soundIndex
   bne CheckActionButtonForJump     ; unconditional branch
   
CheckForJumpingMario
   lda jumpHangTime                 ; get Mario jumping hang time value
   beq CheckActionButtonForJump     ; branch if Mario not jumping
   ldx #MAX_OBSTACLES
.checkForJumpingOverObstacle
   dex
   bmi .doneCheckForJumpingOverObstacle
   lda marioHorizPos                ; get Mario horizontal position
   sec
   sbc obstacleHorizPositions,x     ; subtract obstacle horizontal position
   tay                              ; move difference to y register
   iny
   cpy #3                           ; compare with horizontal bounding box
   bcs .checkForJumpingOverObstacle ; branch if outside horizontal bounding box
   lda marioVertPos                 ; get Mario vertical position
   sec
   sbc obstacleVertPos,x            ; subtract obstacle vertical position
   cmp #4                           ; compare with vertical bounding box value
   bcs .checkForJumpingOverObstacle ; branch if outside vertical bounding box
   lda jumpingObstacle              ; get jumping obstacle value
   bmi .playMarioJumpingSound       ; branch if rewarded for jumping obstacle
   dec jumpingObstacle              ; set D7 high to show rewarded for jumping
   jsr IncrementScoreForJumpingObstacle       
   jmp .playMarioJumpingSound
   
.doneCheckForJumpingOverObstacle
   inx                              ; x = 0
   stx jumpingObstacle              ; set D7 low for not jumping obstacle
.playMarioJumpingSound
   lda currentSoundPlaying          ; get the current sound being played
   cmp #JUMPING_SOUND_IDX
   bne .reduceHangtime              ; branch if not playing jumping sound
   lda #12 
   sta AUDC0
   lda jumpHangTime                 ; get Mario jumping hang time value
   lsr                              ; divide by 2
   sta AUDV0                        ; set volume for jumping sound
.reduceHangtime
   dec jumpHangTime
   bne SetMarioGraphicPointerInfo
   lda marioVertPos                 ; get Mario vertical position
   clc
   adc #JUMPING_HEIGHT              ; increment by height of jump
   sta marioVertPos                 ; set Mario back to platform
   lda #0
   sta marioHorizAnimationValue
   beq SetMarioGraphicPointerInfo   ; unconditional branch
   
CheckActionButtonForJump
   lda INPT4                        ; read left port action button
   ora losingLifeFlag               ; combine with losing life value
   bmi .clearActionButtonDebounce   ; branch if losing life or button not pressed
   lda hammerTime                   ; get Mario hammer time
   bne .clearActionButtonDebounce   ; branch if Mario using hammer
   lda marioDirection               ; get Mario direction value
   bpl .setMarioJumpingStatus       ; branch if Mario moving horizontally
   jsr DetermineIfVerticalMovementAllowed
   bcs .clearActionButtonDebounce   ; branch if vertical motion allowed
   lda #NO_REFLECT
   sta marioDirection               ; set Mario direction to facing left
.setMarioJumpingStatus
   ldy actionButtonDebounce         ; get action button debounce value
   bne SetMarioGraphicPointerInfo   ; branch if action button held
   iny                              ; y = 1
   sty currentSoundPlaying
   dec actionButtonDebounce         ; D7 set high
   lda SWCHA                        ; read joystick values
   sta jumpingDirection             ; set Mario jumping direction
   lda marioVertPos                 ; get Mario vertical position
   sec
   sbc #JUMPING_HEIGHT              ; decrement by height of jump
   sta marioVertPos                 ; set Mario vertical position for jump
   lda #JUMP_HANGTIME
   sta jumpHangTime                 ; set Mario jumping hangtime
   sta soundIndex
   bne SetMarioGraphicPointerInfo   ; unconditional branch
   
.clearActionButtonDebounce
   lda #0
   sta actionButtonDebounce         ; set to show button not held
SetMarioGraphicPointerInfo
   ldx marioDirection               ; get Mario direction value
   bpl .setIndexForHorizontalMovingMario; branch if Mario moving horizontally
   ldx #5                           ; set index for ClimbingMario graphics
   jsr DetermineIfVerticalMovementAllowed
   bcs .setIndexForVerticalMovingMario; branch if vertical motion allowed
   inx                              ; increment for StationaryMario graphics
.setIndexForVerticalMovingMario
   txa                              ; move graphic index value to accumulator
   bne .determineMarioGraphicPointers; unconditional branch
   
.setIndexForHorizontalMovingMario
   lda marioHorizAnimationValue     ; get Mario horizontal animation value
   and #3 << 1
   lsr                              ; value now 0 <= a <= 3
   ldx jumpHangTime                 ; get Mario jumping hang time value
   beq .determineMarioGraphicPointers; branch if Mario not jumping
   lda #4                           ; set index to JumpingMario graphics
.determineMarioGraphicPointers
   tay
   lda marioVertPos                 ; get Mario vertical position
   ldx #NUM_WALKWAYS
.determineMarioPlatform
   cmp #46
   bcc .setMarioGraphicPointers     ; no need to calculate walkway number
   dex                              ; reduce the walkway value
   sbc #H_KERNEL_SECTION + 1        ; subtract by walkway height
   bcs .determineMarioPlatform
.setMarioGraphicPointers
   sty tmpGraphicIndex              ; not used again
   sta marioOffset
   adc MarioColorTable,y
   sta marioColorPointerLSB,x
   lda #>MarioGraphics
   sta marioGraphicPointer + 1      ; set Mario graphic pointer MSB value
   lda marioOffset
   clc
   adc MarioAnimationTable,y
   sta marioGraphicPointer
   jsr StoreMarioGraphics           ; store Mario graphics in RAM
   lda marioOffset                  ; get Mario offset value (i.e. div27 above)
   sec
   sbc #H_KERNEL_SECTION + 2
   bcc CheckMarioWithHammer         ; branch if standing on hammer platform
   sta temp
   cpx #1
   bcc CheckMarioWithHammer
   lda marioColorPointerLSB,x       ; get Mario color LSB value
   sbc #H_KERNEL_SECTION + 1
   sta marioColorPointerLSB - 1,x
   lda marioGraphicPointer          ; get Mario graphic pointer LSB value
   sec
   sbc #H_KERNEL_SECTION + 1
   sta marioGraphicPointer
   ldy #H_KERNEL_SECTION
.setMarioGraphicData
   dec temp
   bmi .clearMarioOffsetGraphicData
   lda (marioGraphicPointer),y
   sta zpMarioGraphics,y
   dey
   bpl .setMarioGraphicData
   
.clearMarioOffsetGraphicData
   lda #6
   sta temp
   lda #0
.setMarioClearGraphicBytes
   sta zpMarioGraphics,y
   dey
   dec temp
   bpl .setMarioClearGraphicBytes
CheckMarioWithHammer
   lda hammerTime                   ; get Mario hammer time
   bne .setHammerHorizPosition      ; branch if Mario using hammer   
   lda CXM1P                        ; check missile collisions (i.e. hammer handle)
   bpl SetCurrentSoundAudioFrequency; branch if Mario not touching hammer handle
   lda jumpHangTime                 ; get Mario jumping hang time value
   beq SetCurrentSoundAudioFrequency; branch if Mario not jumping
   lda #MAX_HAMMER_TIME             ; set the time for Mario to hold the hammer
   sta hammerTime
.setHammerHorizPosition
   lda #9                           ; Mario facing right hammer offset
   ldy marioDirection               ; get Mario direction value
   bne .offsetHammerPosition        ; branch if Mario facing right
   lda #<-2                         ; Mario facing left hammer offset
.offsetHammerPosition
   clc
   adc marioHorizPos                ; increment by Mario's horizontal position
   sta hammerHorizPos               ; set hammer horizontal position
   ldy #<HandleDownSwingAnimation - H_HAMMER
   ldx #<MalletDownSwingAnimation - H_HAMMER
   lda frameCount                   ; get current frame count
   and #8
   bne .setHammerGraphicPointerValues
   ldx #<MalletUpSwingAnimation - H_HAMMER
   ldy #<HandleUpSwingAnimation - H_HAMMER
.setHammerGraphicPointerValues
   sty hammerHandleGraphicPtrs
   stx hammerMalletGraphicPtrs
   lda frameCount                   ; get current frame count
   bne SetCurrentSoundAudioFrequency
   dec hammerTime                   ; decrement hammer time value
   bne SetCurrentSoundAudioFrequency
   lda #<NoHammerAnimation - H_HAMMER
   sta hammerHandleGraphicPtrs
   sta hammerMalletGraphicPtrs
SetCurrentSoundAudioFrequency
   lda currentSoundPlaying          ; get the current sound being played
   beq .setAudioVolume              ; branch if no sound is being played
   cmp #LOSING_LIFE_SOUND_IDX
   bcc .setCurrentSoundAudioFrequency
   lda frameCount                   ; get current frame count
   and #3
   bne NewFrame
.setCurrentSoundAudioFrequency
   dec soundIndex                   ; decrement sound index value
   bmi .turnOffSound                ; branch when donw playing current sound
   lda currentSoundPlaying          ; get the current sound being played
   asl                              ; multiply value by 2
   tay
   lda AudioFrequencyTable - 2,y    ; get audio frequency LSB value
   sta audioFrequecyPointer
   lda AudioFrequencyTable - 1,y    ; get audio frequency MSB value
   sta audioFrequecyPointer + 1
   ldy soundIndex                   ; get current sound index value
   lda (audioFrequecyPointer),y
   sta AUDF0                        ; set sound audio frequency
   bpl NewFrame                     ; unconditional branch

.turnOffSound
   lda #0
   sta currentSoundPlaying          ; set to show not playing a sound
.setAudioVolume
   sta AUDV0
NewFrame
.waitTime
   ldx INTIM
   bne .waitTime
   stx WSYNC                        ; wait for next scanline
   lda #START_VERT_SYNC
   sta VSYNC                        ; start VSYNC (i.e. D1 = 1)
   sta WSYNC
   sta WSYNC
   sta WSYNC
   stx VSYNC                        ; end VSYNC (i.e. D1 = 0)  
   lda #VBLANK_TIME
   sty WSYNC                        ; wait for next scanline
   sta TIM64T                       ; set timer for vertical blank period
   lda gameState                    ; get current game state
   cmp #LEVEL_COMPLETED
   beq .checkToSwitchToNewLevel     ; branch if LEVEL_COMPLETED
   lda currentGameBoard             ; get current game board
   beq .checkIfBarrelLevelComplete  ; branch if barrels   
CheckForLevelComplete
   ldx #3
.checkIfRivitLevelComplete
   lda firefoxPFIndexValues + 2,x   ; get value from rivit array
   cmp #COMPLETE_RIVIT_WALKWAY
   bcc CheckToSpawnNewObstacle      ; branch if less than competed rivit value
   dex
   bpl .checkIfRivitLevelComplete
   bmi .levelCompleted              ; unconditional branch

.checkIfBarrelLevelComplete
   lda marioVertPos                 ; get Mario vertical position
   cmp #YMIN_LEVEL0
   bne CheckToSpawnNewObstacle
.levelCompleted
   lda #LEVEL_COMPLETED
   sta gameState                    ; set game state to LEVEL_COMPLETED
   ldx #10
   lda #LEVEL_COMPLETED_SOUND_IDX
   jsr PlayMusic
.checkToSwitchToNewLevel
   lda currentSoundPlaying          ; get the current sound being played
   cmp #LEVEL_COMPLETED_SOUND_IDX
   beq CheckToSpawnNewObstacle      ; branch if playing level completed sound
   lda #START_NEW_LEVEL
   sta gameState                    ; set game state to START_NEW_LEVEL
   lda bonusTimer                   ; add bonus timer value to score
   jsr IncrementScore
   lda currentGameBoard             ; get current game board
   eor #1                           ; flip D0 value
   sta currentGameBoard             ; set new game board value
   jsr StartNewGameBoard
CheckToSpawnNewObstacle
   lda losingLifeFlag               ; get losing life value
   bmi .doneMovingObstacles         ; branch if Mario losing life
   lda gameState                    ; get current game state
   bpl .doneMovingObstacles         ; branch if GAME_LEVEL_NOT_IN_PROGRESS
   ldx nextObstacleSlot
   lda obstacleVertPos,x            ; get obstacle vertical position
   bne MoveObstacles                ; branch if obstacle present
   lda currentGameBoard             ; get current game board
   bne .spawnNewFirefox             ; branch to do firefox
   lda obstacleVertPos + 1,x        ; get vertical position of barrel above
   cpx #MAX_OBSTACLES - 1
   bne .determineToSpawnNewBarrel
   lda obstacleVertPos              ; get lower barrel vertical position
.determineToSpawnNewBarrel
   tay                              ; move barrel vertical position to y
   beq .spawnNewBarrel              ; branch if no barrel present
   cpy #35
   bcc MoveObstacles
.spawnNewBarrel
   lda #STARTING_BARREL_VERT
   sta obstacleVertPos,x            ; set barrel starting vertical position
   lda #STARTING_BARREL_HORIZ
   sta obstacleHorizPositions,x     ; set barrel starting horizontal position
   lda #OBSTACLE_MOVING_RIGHT
   sta obstacleDirections,x         ; set barrel moving right
   bne .doneSpawnNewObstacle        ; unconditional branch
   
.spawnNewFirefox
   lda randomSeed                   ; get current random seed value
   and #$1F                         ; value 0 <= a <= 31
   adc #XMIN_FIREFOX + 1            ; increment value by 37 (i.e. 37 <= a <= 68)
   sta obstacleHorizPositions,x     ; set Firefox horizontal position
   and #OBSTACLE_MOVING_RIGHT
   sta obstacleDirections,x         ; set Firefox direction
   lda FirefoxVerPos,x
   sta obstacleVertPos,x            ; set Firefox vertical position
.doneSpawnNewObstacle
   dex
   bpl .setNewSpawnObstacleNumber   ; branch to set next obstacle slot to spawn
   ldx #MAX_OBSTACLES - 1
.setNewSpawnObstacleNumber
   stx nextObstacleSlot
MoveObstacles
   ldx #MAX_OBSTACLES - 1
   ldy #1
   lda frameCount                   ; get current frame count
   lsr                              ; shift D0 to carry
   bcc .setLastObstacleToMove       ; branch on even frame   
   ldx #1
   ldy #<-1
.setLastObstacleToMove
   sty tmpLastObstacleToMove
MoveObstacleLoop
   ldy obstacleVertPos,x            ; get obstacle vertical position
   bne .moveObstacle                ; branch if obstacle present
   jmp MoveNextObstacle
   
.doneMovingObstacles
   jmp SetupObstaclesForKernel

.moveObstacle
   lda currentGameBoard             ; get current game board
   beq MoveBarrelObject             ; branch if moving barrels
   lda firefoxPFIndexValues + 2,x   ; get platform rivit value
   cmp #LEFT_RIVIT_VALUE
   bcc MoveFirefox                  ; branch if rivits not removed
   cmp #RIGHT_RIVIT_VALUE
   bcc .checkLeftRivitConstraint    ; branch if left rivit removed
   lda #HORIZ_RIGHT_RIVIT
   cmp obstacleHorizPositions,x
   beq ChangeFirefoxDirection       ; branch if Firefox at right rivit
   lda firefoxPFIndexValues + 2,x
   cmp #COMPLETE_RIVIT_WALKWAY
   bcc MoveFirefox   
.checkLeftRivitConstraint
   lda #HORIZ_LEFT_RIVIT
   cmp obstacleHorizPositions,x
   bne MoveFirefox                  ; branch if Firefox not at left rivit
ChangeFirefoxDirection
   lda obstacleDirections,x         ; get Firefox direction
   eor #1                           ; flip D0 value to change direction
   sta obstacleDirections,x         ; set Firefox new direction   
MoveFirefox
   lda obstacleDirections,x         ; get Firefox direction
   beq .moveFirefoxLeft
.moveFireFoxRight   
   inc obstacleHorizPositions,x     ; increment Firefox horizontal position
   lda #XMAX_FIREFOX
   cmp obstacleHorizPositions,x
   bcc .changeFirefoxDirection      ; change direction if reached right max
   bcs .computeRandomDirection      ; unconditional branch
   
.moveFirefoxLeft
   dec obstacleHorizPositions,x     ; decrement Firefox horizontal position
   lda #XMIN_FIREFOX
   cmp obstacleHorizPositions,x
   bcs .changeFirefoxDirection      ; change direction if reached left min
.computeRandomDirection
   lda randomSeed                   ; get current random seed value
   cmp #2
   bcc .skipRandomDirection         ; no random Firefox direction if less than 2
   ldy playerScore                  ; get player score thousands value
   cmp RandomSeedTable,y            ; compare the random seed with number table
   bcs .doneMovingCurrentFirefox
   lda RandomSeedTable,y            ; get byte value from table
   sta randomSeed                   ; set new random seed value
.changeFirefoxDirection
   lda obstacleDirections,x         ; get Firefox direction value
   eor #1                           ; flip D0 value
   tay                              ; move new direction value to y register
   bpl .setFirefoxDirection         ; unconditional branch
   
.skipRandomDirection
   lda obstacleVertPos,x            ; get Firefox vertical position
   clc
   adc #FAIR_PIXEL_DELTA            ; increment by FAIR_PIXEL_DELTA
   cmp marioVertPos                 ; compare with Mario vertical position
   bne .doneMovingCurrentFirefox    ; branch if Mario not on platform under Firefox
   ldy #OBSTACLE_MOVING_LEFT        ; assume to move Firefox left
   lda obstacleHorizPositions,x     ; get Firefox horizontal position
   cmp marioHorizPos
   bcs .setFirefoxDirection         ; branch if Firefox on Mario's right
   ldy #OBSTACLE_MOVING_RIGHT
.setFirefoxDirection
   sty obstacleDirections,x
.doneMovingCurrentFirefox
   jmp MoveNextObstacle

MoveBarrelObject SUBROUTINE
   lda obstacleDirections,x         ; get barrel direction
   beq .moveBarrelLeft              ; branch if barrel moving left
   bmi .moveBarrelDown              ; branch if barrel falling down
.barrelMovingRight
   inc obstacleHorizPositions,x     ; increment barrel horizontal position
   bne BarrelRampMovement           ; unconditional branch
   
.moveBarrelLeft
   dec obstacleHorizPositions,x     ; decrement barrel horizontal position   
BarrelRampMovement
   cpy #TOP_PLATFORM_VALUE          ; y is barrel vertical position
   beq .doneBarrelRampMovement      ; branch if barrel on top platform
   cpy #BOTTOM_BARREL_PLATFORM_VALUE
   beq .checkBarrelDone             ; branch if barrel on bottom platform
   ldy obstacleHorizPositions,x     ; get barrel horizontal position
   asl                              ; shift barrel direction left
   bne .prepareToDetermineBarrelRampMovement; branch if barrel not moving left
   iny                              ; increment barrel horizontal position
.prepareToDetermineBarrelRampMovement
   tya                              ; accumulator holds barrel horizontal position
   ldy #7
.determineBarrelVertRampMovement
   dey
   bmi .doneBarrelRampMovement
   cmp RampHorizValues,y            ; compare with barrel horizontal position
   bcc .doneBarrelRampMovement
   bne .determineBarrelVertRampMovement
   inc obstacleVertPos,x            ; increment barrel vertical position
.doneBarrelRampMovement
   ldy playerScore                  ; get player score thousands value
   lda randomSeed                   ; get current random seed value
   cmp RandomSeedTable,y
   ldy #12
   bcs .initIndexForBarrelOffsetDiff
   ldy #<-1
.initIndexForBarrelOffsetDiff
   lda obstacleVertPos + 1,x        ; get next barrel vertical position
   cpx #3
   bne .setBarrelOffsetValue
   lda obstacleVertPos              ; get top barrel vertical position
.setBarrelOffsetValue
   sta obstacleOffset
.determineBarrelLadderNumber
   lda obstacleOffset               ; get barrel offset value
   sbc obstacleVertPos,x            ; subtract barrel vertical position
.determineBarrelOffsetDifference
   iny
   cpy #18
   bcs MoveNextObstacle
   cmp BarrelOffsetDiffTable,y
   bcc .determineBarrelOffsetDifference
   lda obstacleHorizPositions,x     ; get barrel horizontal position
   sbc #1                           ; subtract value by 1 (i.e. carry set)
   cmp LadderHorizValues,y
   bne .determineBarrelLadderNumber
   lda DownLadderTable,y
   sec
   sbc #FAIR_PIXEL_DELTA
   cmp obstacleVertPos,x
   bne .determineBarrelLadderNumber
   sty barrelLadderNumber,x
   lda obstacleDirections,x         ; get barrel direction
   ora #OBSTACLE_MOVING_DOWN
   bmi .setBarrelDirection
       
.moveBarrelDown
   inc obstacleVertPos,x
   inc obstacleVertPos,x
   ldy barrelLadderNumber,x         ; get barrel ladder number
   lda UpLadderTable,y
   sec
   sbc #FAIR_PIXEL_DELTA
   cmp obstacleVertPos,x
   beq .setBarrelVerticalPosition   ; branch if barrel on platform
   bcs MoveNextObstacle
.setBarrelVerticalPosition
   sta obstacleVertPos,x
   lda obstacleDirections,x         ; get barrel direction
   eor #OBSTACLE_MOVING_DOWN | OBSTACLE_MOVING_RIGHT;flip barrel direction value
.setBarrelDirection
   sta obstacleDirections,x
   jmp MoveNextObstacle
       
.checkBarrelDone
   lda obstacleHorizPositions,x     ; get barrel horizontal position
   cmp #XMIN_FIREFOX - 1
   bne MoveNextObstacle             ; branch if barrel not off the screen
   lda #0                           ; reset the vertical position of the barrel so
   sta obstacleVertPos,x            ; reset barrel vertical position
MoveNextObstacle
   dex
   cpx tmpLastObstacleToMove
   beq SetupObstaclesForKernel
   jmp MoveObstacleLoop
       
SetupObstaclesForKernel
   ldx #MAX_OBSTACLES - 1
.setupObstaclesForKernel
   ldy #FALLING_BARREL_SPRITE_NUMBER
   lda obstacleVertPos,x            ; get obstacle vertical position
   beq .beqNextObstacle             ; branch if obstacle not present
   lda obstacleDirections,x         ; get obstacle direction
   bpl .setRollingBarrelSprite      ; branch if not moving down
   lda barrelLadderNumber,x
   cmp #13
   bcc CheckForSmashingObstacle
   cmp marioVertPos
   bcs .removeObstacle              ; branch if barrel under Mario
.setRollingBarrelSprite
   dey                              ; y = 0 -or- BARREL_SPRITE_NUMBER
CheckForSmashingObstacle
   lda currentGameBoard             ; get current game board
   beq .checkForSmashingObstacle    ; branch if barrels
   ldy #FIREFOX_SPRITE_NUMBER
.checkForSmashingObstacle
   lda obstacleVertPos,x            ; get obstacle vertical position
   stx tmpObstacleIndex             ; save obstacle index for later
   ldx #NUM_WALKWAYS + 1
   sec
.determineObstaclePlatform
   dex
   sbc #H_KERNEL_SECTION + 1
   bcs .determineObstaclePlatform
   adc #H_KERNEL_SECTION + 1
   cpx #HAMMER_KERNEL_SECTION
   bne .calculateObstaclePointers   ; branch if not on a hammer platform
   asl CXP1FB                       ; check if the obstacle hit by hammer
   bpl .calculateObstaclePointers   ; branch if obstacle not smashed with hammer
   lda #POINT_VALUE_SMASHING_OBSTACLE >> 8
   jsr IncrementScore               ; increment score for smashing obstacle
   ldx tmpObstacleIndex             ; restore x register with obstacle index
.removeObstacle
   lda #0
   sta obstacleVertPos,x            ; clear obstacle vertical position
.beqNextObstacle
   beq .nextObstacle                ; unconditional branch
   
.calculateObstaclePointers
   sta obstacleOffset
   clc
   adc ObstacleTable,y
   sta obstaclePointerLSB,x
   lda obstacleOffset
   cmp #18
   bcc .determineObstacleKernelHorizPos
   ror obstacleCoarseHorizPosValue - 1,x
   cmp #19
   bcc .determineObstacleKernelHorizPos
   txa
   beq .determineObstacleKernelHorizPos
   lda obstaclePointerLSB,x
   sbc #H_KERNEL_SECTION + 1
   sta obstaclePointerLSB - 1,x
.determineObstacleKernelHorizPos
   ldy tmpObstacleIndex
   lda obstacleHorizPositions,y
   ldy #<-3
   sec
.coarseMoveLoop
   iny
   sbc #15                          ; divide position by 15
   bcs .coarseMoveLoop
   sty obstacleCoarseHorizPosValue,x; set coarse horizontal position value
   eor #15                          ; 4-bit 1's complement for fine motion
   asl                              ; shift remainder to upper nybbles
   asl
   asl
   asl
   adc #(8 + 1) << 4                ; increment 2's complement by 8 for full range
   sta obstacleFineHorizPosValue,x  ; set fine horizontal position value
   ldx tmpObstacleIndex
.nextObstacle
   dex
   bmi CheckToPlayDeathSound
   jmp .setupObstaclesForKernel
   
CheckToPlayDeathSound
   lda losingLifeFlag               ; get losing life value
   bmi .continueDeathSound          ; branch if Mario losing life
   
   IF CHEAT_ENABLED = TRUE
   
      lda #0
      
   ELSE

      lda CXPPMM                    ; read player and missile collision value
      
   ENDIF
   
   bpl .clearCollisions             ; branch if no player collisions
   jsr PlayDeathSound
.continueDeathSound
   lda currentSoundPlaying          ; get the current sound being played
   cmp #LOSING_LIFE_SOUND_IDX
   beq .clearCollisions             ; branch if playing losing life sound
   lda #0
   sta losingLifeFlag               ; clear losing life flag
   jsr StartNewGameBoard
   ldy #START_NEW_LEVEL
   dec numberOfLives                ; reduce number of lives
   bpl .setGameState                ; branch if player has lives left
   jsr PlayGameOverMusic            ; no lives left -- start GAME OVER routine
   ldy #0
   sty numberOfLives                ; set number of lives to 0 (i.e. y = 0)
.setGameState
   sty gameState
.clearCollisions
   lda #$FF
   sta CXCLR
   jsr SetupKernelPointers
   ldx #<HMM1 - HMP0
   lda hammerHorizPos               ; get hammer horizontal position
   jsr PositionHammerObject         ; horizontally position hammer handle
   ldy #MSBL_SIZE2                  ; ball size 2 clocks
   ldx #MSBL_SIZE4                  ; ball size 4 clocks
   lda hammerHandleGraphicPtrs
   cmp #<HandleDownSwingAnimation - H_HAMMER
   beq .setHammerHandleSwingDownValue; branch if hammer swinging down
   lda currentGameBoard             ; get current game board
   beq .setHammerHandleSwingUpValue ; branch if barrels
   inx                              ; reflect Firefox playfield (i.e. D0 = 1)
.setHammerHandleSwingUpValue
   stx CTRLPF                       ; set playfield REFLECT and mallot size
   sty hammerHandleNUSIZ            ; set hammer handle to MSBL_SIZE_2
   lda #<-1
   bne .horizontallyPositionHammerMallot; unconditional branch
   
.setHammerHandleSwingDownValue
   stx hammerHandleNUSIZ            ; set hammer handle to MSBL_SIZE_4
   lda currentGameBoard             ; get current game board
   beq .setSwingDownHammerMallotPosition; branch if barrels
   iny                              ; reflect Firefox playfield (i.e. D0 = 1)
.setSwingDownHammerMallotPosition
   sty CTRLPF                       ; set playfield REFLECT and mallot size
   lda #<-2
   ldy marioDirection               ; get Mario direction value
   beq .horizontallyPositionHammerMallot; branch if Mario facing left
   lda #4
.horizontallyPositionHammerMallot
   clc
   adc hammerHorizPos
   ldx #<HMBL - HMP0
   jsr PositionHammerObject         ; horizontally position hammer mallot
DisplayKernel SUBROUTINE
.waitTime
   ldx INTIM
   bne .waitTime
   stx WSYNC
;--------------------------------------
   stx VBLANK                 ; 3 = @03   enable TIA (i.e. D1 = 0)
   stx REFP0                  ; 3 = @06   set to NO_REFLECT (i.e. D3 = 0)
   stx REFP1                  ; 3 = @09
   inx                        ; 2         x = 1
   stx VDELP0                 ; 3 = @14   VDEL players (i.e. D0 = 1)
   stx VDELP1                 ; 3 = @17
   ldx #THREE_COPIES          ; 2
   stx NUSIZ0                 ; 3 = @22
   stx NUSIZ1                 ; 3 = @25
   SLEEP 2                    ; 2
   ldy #HMOVE_R7              ; 2
   sty HMP0                   ; 3 = @32   move GRP0 right 7 pixels
   ldy #H_DIGITS - 2          ; 2
   sta RESP0                  ; 3 = @37   coarse position GRP0 @ pixel 111
   ldx #COLOR_SCORE           ; 2
   sta RESP1                  ; 3 = @42   coarse position GRP1 @ pixel 126
   lda gameState              ; 3         get current game state
   asl                        ; 2         shift D7 to the carry bit
   bcc .colorDigits           ; 2³        carry clear -- game in progress
   ldx #COLOR_BONUS_TIMER     ; 2         bonus timer color
.colorDigits
   stx COLUP0                 ; 3 = @54
   stx COLUP1                 ; 3 = @57
   sta WSYNC
;--------------------------------------
   sta HMOVE                  ; 3
.drawDigits   
   lda NumberFonts,y          ; 4         read graphic value for zero
   sta digitPointer + 8       ; 3
   sta WSYNC
;--------------------------------------
   lda (digitPointer + 6),y   ; 5
   sta GRP0                   ; 3 = @08
   lda (digitPointer + 4),y   ; 5
   sta GRP1                   ; 3 = @16
   lda (digitPointer + 2),y   ; 5
   sta.w GRP0                 ; 4 = @25
   lda (digitPointer),y       ; 5
   tax                        ; 2
   lda NumberFonts,y          ; 4         read graphic value for zero
   sty tmpSixDigitLoopCount   ; 3
   ldy digitPointer + 8       ; 3
   stx GRP1                   ; 3 = @45
   sta GRP0                   ; 3 = @48
   sty GRP1                   ; 3 = @51
   sty GRP0                   ; 3 = @54
   ldy tmpSixDigitLoopCount   ; 3
   dey                        ; 2
   bpl .drawDigits            ; 2³
   stx WSYNC
;--------------------------------------
   sta HMCLR                  ; 3 = @03   clear all horizontal movements
   ldx #0                     ; 2
   stx VDELP0                 ; 3 = @08   turn off vertical delay of players
   stx VDELP1                 ; 3 = @11
   stx GRP0                   ; 3 = @14
   stx GRP1                   ; 3 = @17
   stx NUSIZ1                 ; 3 = @20   set to ONE_COPY
   ldx #H_DONKEY_KONG         ; 2
   lda playfieldColor         ; 3
   sta COLUPF                 ; 3 = @28   color the playfield
   sta RESP0 - H_DONKEY_KONG,x; 4 = @32   wastes a cycle but saves a byte
   lda marioDirection         ; 3         get Mario direction value
   bpl .setMarioReflectState  ; 2³        branch if Mario moving horizontally
   lda marioVertPos           ; 3         get Mario vertical position
   and #REFLECT >> 1          ; 2
   asl                        ; 2
.setMarioReflectState
   sta REFP0                  ; 3 = @47
   lda #DOUBLE_SIZE           ; 2
   sta NUSIZ0                 ; 3 = @52   make Donkey Kong double size
   lda #COLOR_DONKEY_KONG     ; 2
   sta COLUP0                 ; 3 = @57   color Donkey Kong
   lda #>ObstacleSprites      ; 2         set the MSB for the obstacles
   sta obstaclePointer + 1    ; 3
   ldy numberOfLives          ; 3
.drawDonkeyKongLoop
   lda DonkeyKong - 1,x       ; 4
   sta WSYNC
;--------------------------------------
   sta GRP0                   ; 3 = @03   draw Donkey Kong character
   lda #0                     ; 2
   sta PF1                    ; 3 = @08   clear the PF1 register
   lda Girlfriend - 1,x       ; 4
   sta GRP1                   ; 3 = @15   draw girlfriend character
   lda GirlfriendColors - 2,x ; 4
   sta COLUP1                 ; 3 = @22   color girfriend character
   cpx #H_DONKEY_KONG - 7     ; 2
   bcs .nextDonkeyKongLoop    ; 2³
   cpx #H_DONKEY_KONG - 15    ; 2
   bcc .nextDonkeyKongLoop    ; 2³
   lda TopBarrelSectionPFDataTable - 5,x;4
   sta rightPF1Pointer - 5,x  ; 4
   lda LivesPFPattern,y       ; 4
   sta PF1                    ; 3 = @45   draw lives indicators
.nextDonkeyKongLoop
   dex                        ; 2
   bne .drawDonkeyKongLoop    ; 2³
   stx NUSIZ0                 ; 3         set to ONE_COPY (i.e. x = 0)
   lda hammerHandleNUSIZ      ; 3         get hammer handle NUSIZ value
   sta NUSIZ1                 ; 3
   lda frameCount             ; 3         get current frame count
   sta REFP1                  ; 3
   ldy #1                     ; 2
.drawDonkeyKongPlatform
   stx PF1                    ; 3         clear the playfield registers
   stx PF2                    ; 3
   sta WSYNC
;--------------------------------------
   lda #$0F                   ; 2
   sta PF1                    ; 3 = @05
   lda #$FF                   ; 2
   sta PF2                    ; 3 = @10
   ldx #6                     ; 2         wait 35 cycles for barrel board
   lda currentGameBoard       ; 3         get current game board
   beq .donkeyKongPlatformWaitLoop;2³     branch if barrels
   ldx firefoxPFIndexValues + 5;3 = @20   get top section playfield index value
   lda FireFoxLeftPF1Table,x  ; 4
   sta leftPF1Pointer         ; 3
   lda FireFoxPF2Table,x      ; 4
   sta pf2Pointer             ; 3
   lda FireFoxPF0Table,x      ; 4
   sta pf0Pointer             ; 3
   lda #>FirefoxPlayfieldData ; 2
   sta leftPF1Pointer + 1     ; 3
   sta pf2Pointer + 1         ; 3
   sta pf0Pointer + 1         ; 3
   ldx #1                     ; 2         wait 4 cycles for Firefox board
   stx REFP1                  ; 3 = @57
.donkeyKongPlatformWaitLoop
   dex                        ; 2
   bne .donkeyKongPlatformWaitLoop;2³
   dey                        ; 2 = @49
   bpl .drawDonkeyKongPlatform; 2³
   stx PF1                    ; 3 = @68   clear the playfield registers
   stx PF2                    ; 3 = @71
   sec                        ; 2
   sta WSYNC
;--------------------------------------
   lda marioHorizPos          ; 3         get Mario horizontal position
.coarseMoveMario
   sbc #15                    ; 2         divide position by 15
   bcs .coarseMoveMario       ; 2³
   eor #15                    ; 2         4-bit 1's complement for fine motion
   asl                        ; 2
   asl                        ; 2
   asl                        ; 2
   asl                        ; 2
   adc #(8 + 1) << 4          ; 2         increment 2's complement by 8 for full range
   sta RESP0                  ; 3
   sta HMP0                   ; 3
   lda #NTSC_COLOR_MARIO_SUIT ; 2         missed in the PAL50 version
   sta COLUP0                 ; 3
   lda marioVertPos           ; 3         get Mario vertical position
   sta WSYNC
;--------------------------------------
   sta HMOVE                  ; 3
   cmp #YMIN_LEVEL0           ; 2
   bcs .skipMarioDraw         ; 2³
   ldy #$1C                   ; 2         first byte of Mario sprite
   bne .drawMario             ; 3         unconditional branch
   
.skipMarioDraw
   ldy #0                     ; 2
   SLEEP 2                    ; 2
.drawMario
   sty GRP0                   ; 3 = @15
   lda obstacleFineHorizPosValue + 5;3    get top obstacle fine horiz position
   ldy obstacleCoarseHorizPosValue + 5;3  get top obstacle coarse position value
.coarsePositionTopObstacle
   dey                        ; 2
   bpl .coarsePositionTopObstacle;2³
   ldy #<GRP0                 ; 2
   SLEEP 2                    ; 2
   sta RESP1                  ; 3
   sta HMP1                   ; 3
   stx HMP0                   ; 3         clear player 0 movement (i.e. x = 0)
   lda #>MarioColors          ; 2
   sta marioColorPointer + 1  ; 3
   sta WSYNC
;--------------------------------------
   sta HMOVE                  ; 3
   bcc .drawMario_a           ; 2³
   bcs .skipMarioDraw_a       ; 3         unconditional branch
   
.drawMario_a
   ldx #$7E                   ; 2         second byte of Mario sprite
.skipMarioDraw_a
   stx $00,y                  ; 4 = @12   write to GRP0 in 4 cycles and 3 bytes
   ldx #NUM_WALKWAYS + 1      ; 2
   jmp EnterKernel            ; 3

   IF COMPILE_VERSION = PAL50
   
      .byte $00                     ; not used
      
   ELSE

      .byte $9D                     ; not used
   
   ENDIF

EndKernel
   jmp MainLoop

BarrelHammerKernel SUBROUTINE
   stx PF2                    ; 3 = @58
   lda (marioColorPointer),y  ; 5
   stx PF1                    ; 3 = @66   clear the playfield registers (x = 0)
   beq .skipMarioDraw         ; 2³
   ldx zpMarioGraphics,y      ; 4
.skipMarioDraw
   sta WSYNC
;--------------------------------------
   sta COLUP0                 ; 3 = @03
   lda (hammerHandleGraphicPtrs),y;5
   sta ENAM1                  ; 3 = @11
   lda (hammerMalletGraphicPtrs),y;5
   sta ENABL                  ; 3 = @19
   lda (obstaclePointer),y    ; 5
   sta GRP1                   ; 3 = @27
   stx GRP0                   ; 3 = @30
   lda (pf2Pointer),y         ; 5
   sta PF2                    ; 3 = @38
   lda (rightPF1Pointer),y    ; 5
   ldx #0                     ; 2
   sta PF1                    ; 3 = @48
   dey                        ; 2
   cpy #H_KERNEL_SECTION - H_HAMMER + 1;2
   bcs BarrelHammerKernel     ; 2³
BarrelKernel SUBROUTINE
   stx PF2                    ; 3 = @57
   lda (marioColorPointer),y  ; 5
   stx PF0                    ; 3 = @65
   beq .skipMarioDraw         ; 2³
   ldx zpMarioGraphics,y      ; 4
.skipMarioDraw
   sta WSYNC
;--------------------------------------
   sta COLUP0                 ; 3 = @03
   stx GRP0                   ; 3 = @06
   ldx #0                     ; 2
   lda (obstaclePointer),y    ; 5
   sta GRP1                   ; 3 = @16
   lda (leftPF1Pointer),y     ; 5
   sta PF1                    ; 3 = @24
   lda (pf2Pointer),y         ; 5
   sta PF2                    ; 3 = @32
   lda (pf0Pointer),y         ; 5
   sta PF0                    ; 3 = @40
   lda (rightPF1Pointer),y    ; 5
   sta PF1                    ; 3 = @48
   dey                        ; 2
   cpy tmpKernelHeight        ; 3
   bne BarrelKernel           ; 2³
ContinueKernel SUBROUTINE
   lda (marioColorPointer),y  ; 5
   stx PF2                    ; 3 = @63
   sta COLUP0,x               ; 4 = @67
   bne .drawMario             ; 2³
   sta GRP0,x                 ; 4 = @73
   beq .skipMarioDraw         ; 3 = @76   unconditional branch
   
.drawMario
   lda zpMarioGraphics + 2    ; 3
   sta GRP0                   ; 3 = @76
;--------------------------------------
.skipMarioDraw
   stx PF1                    ; 3 = @03
   stx PF0                    ; 3 = @06
   lda (obstaclePointer),y    ; 5
   sta GRP1                   ; 3 = @14
   ldx kernelSection          ; 3
   beq EndKernel              ; 2³ + 1    branch crosses a page boundary
   ldy obstacleCoarseHorizPosValue - 1,x;4 get obstacle coarse position value
   bmi SkipObstacleMove       ; 2³
.coarseMoveObstacle
   dey                        ; 2
   bpl .coarseMoveObstacle    ; 2³
   sta RESP1                  ; 3
   lda obstacleFineHorizPosValue - 1,x;4  get obstacle fine horizontal position
   sta HMP1                   ; 3
SkipObstacleMove SUBROUTINE
   ldy #1                     ; 2
   sta WSYNC
;--------------------------------------
   sta HMOVE                  ; 3
   lda (obstaclePointer),y    ; 5
   sta GRP1                   ; 3 = @11
   lda (marioColorPointer),y  ; 5
   sta.w COLUP0               ; 4 = @20
   bne .drawMario             ; 2³
   sta.w GRP0                 ; 4 = @26
   beq .skipMarioDraw         ; 3         unconditional branch
   
.drawMario
   lda zpMarioGraphics + 1    ; 3
   sta GRP0                   ; 3 = @29
.skipMarioDraw
   lda currentGameBoard       ; 3         get current game board
   beq .loadBarrelPFPointers  ; 2³        branch if barrels
   ldy firefoxPFIndexValues - 1,x;4 = @38
   lda FireFoxLeftPF1Table,y  ; 4
   sta leftPF1Pointer         ; 3
   lda FireFoxPF2Table,y      ; 4
   sta pf2Pointer             ; 3
   lda FireFoxPF0Table,y      ; 4
   ldy #0                     ; 2
   sta pf0Pointer,y           ; 5 = @63
   beq .skipBarrelPFPointers  ; 3         unconditional branch
   
.loadBarrelPFPointers
   lda BarrelLeftPF1Table - 1,x;4 = @39
   sta leftPF1Pointer         ; 3
   lda BarrelPF2Table - 1,x   ; 4
   sta pf2Pointer             ; 3
   lda BarrelPF0Table - 1,x   ; 4
   sta pf0Pointer             ; 3
   lda BarrelRightPF1Table - 1,x;4
   sta rightPF1Pointer        ; 3
   dey                        ; 2 = @65
.skipBarrelPFPointers
   lda (obstaclePointer),y    ; 5
   sta GRP1                   ; 3 = @73 (barrels) @74(firefox)
   lda (marioColorPointer),y  ; 5
;--------------------------------------
   sta.w COLUP0               ; 4 = @5 (barrles) @6(firefox)
   bne .drawMario_a           ; 2³
   sta.w GRP0                 ; 4 = @11 (barrels) @12 (firefox)
   beq .skipDrawMario_a       ; 3
.drawMario_a
   lda zpMarioGraphics        ; 3
   sta GRP0                   ; 3 = @14 (barrels) @15 (firefox)
.skipDrawMario_a
   ldy #H_KERNEL_SECTION      ; 2
EnterKernel
   lda obstaclePointerLSB - 1,x;4
   sta obstaclePointer        ; 3         set obstacle graphic pointer LSB value
   lda marioColorPointerLSB - 1,x;4
   sta marioColorPointer      ; 3         set Mario color pointer LSB value
   sta HMCLR                  ; 3         clear horizontal movement
   dex                        ; 2
   SLEEP 2                    ; 2
   stx kernelSection          ; 3
   cpx #HAMMER_KERNEL_SECTION ; 2
   bne .skipHammerKernel      ; 2³
   ldx #0                     ; 2
   jmp (hammerKernelVector)   ; 5
   
.skipHammerKernel
   lda KernelSectionHeight,x  ; 4
   sta tmpKernelHeight        ; 3
   ldx #0                     ; 2
   lda (marioColorPointer),y  ; 5
   jmp (kernelVector)         ; 5
       
FirefoxHammerKernel SUBROUTINE
   SLEEP 2                    ; 2 = @54
   lda (marioColorPointer),y  ; 5
   bne .drawMario             ; 2³
   SLEEP 2                    ; 2
   beq .skipMarioDraw         ; 3         unconditional branch
   
.drawMario
   ldx zpMarioGraphics,y      ; 4
.skipMarioDraw
   sta COLUP0                 ; 3 = @69
   lda FireFoxPF2Data_01 - 3,y; 4
   sta PF2                    ; 3
;--------------------------------------
   stx GRP0                   ; 3 = @03
   lda (hammerHandleGraphicPtrs),y;5
   sta ENAM1                  ; 3 = @11
   lda (obstaclePointer),y    ; 5
   sta GRP1                   ; 3 = @19
   lda (hammerMalletGraphicPtrs),y;5
   sta ENABL                  ; 3 = @27
   lda FireFoxPF1Data_01 - 3,y; 4
   sta PF1                    ; 3 = @34
   lda (marioColorPointer),y  ; 5
   lda marioColorPointer,y    ; 4
   ldx #0                     ; 2
   dey                        ; 2
   cpy #H_KERNEL_SECTION - H_HAMMER + 1;2
   bcs FirefoxHammerKernel    ; 2³
FirefoxKernel SUBROUTINE
   lda (marioColorPointer),y  ; 5
JumpFirefoxKernel
   beq .skipMarioDraw         ; 2³
   ldx zpMarioGraphics,y      ; 4
.skipMarioDraw
   sta WSYNC
;--------------------------------------
   sta COLUP0                 ; 3 = @03
   stx GRP0                   ; 3 = @06
   lda (obstaclePointer),y    ; 5
   sta GRP1                   ; 3 = @14
   lda (leftPF1Pointer),y     ; 5
   sta PF1                    ; 3 = @22
   lda (pf2Pointer),y         ; 5
   sta PF2                    ; 3 = @30
   ldx #0                     ; 2
   lda (pf0Pointer),y         ; 5
   lda (pf0Pointer),y         ; 5
   dey                        ; 2
   cpy tmpKernelHeight        ; 3
   sta PF2                    ; 3 = @50
   bne FirefoxKernel          ; 2³
   jmp ContinueKernel         ; 3
       
RandomSeedTable
   .byte $30,$50,$70,$90,$B0,$D0,$D0,$D0,$FF,$FF

DetermineIfVerticalMovementAllowed
   ldy ladderNumber
   lda marioVertPos                 ; get Mario vertical position
   cmp UpLadderTable,y
   beq .verticalMovementNotAllowed
   cmp DownLadderTable,y
   beq .verticalMovementNotAllowed
   sec
   rts
.verticalMovementNotAllowed
   clc
   rts

SetupKernelPointers
   lda currentGameBoard             ; get current game board
   asl                              ; multiply value by 4
   asl
   adc #3                           ; a = 3 for barrels and 7 for firefox
   tax
   ldy #3
.vectorLoadLoop
   lda KernelVectorTable,x
   sta hammerKernelVector,y
   dex
   dey
   bpl .vectorLoadLoop
   ldx #10
   ldy #0
   lda gameState                    ; get current game state
   bpl .bcd2DigitLoop               ; branch if showing player score
   ldy #<bonusTimer - playerScore - 1; set display bonus timer value
.bcd2DigitLoop
   lda playerScore,y                ; get number value (BCD)
   and #$F0                         ; keep upper nybbles
   lsr                              ; divide by 2 (i.e. value * 8)
   adc #0                           ; not needed...carry clear
   sta digitPointer - 4,x           ; set digit pointer LSB value
   lda #>NumberFonts
   sta digitPointer - 3,x           ; set digit pointer MSB value
   dex
   dex
   lda playerScore,y                ; get number value (BCD)
   and #$0F                         ; keep lower nybbles
   asl                              ; multiply value by 8 (i.e. H_DIGITS)
   asl
   asl
   adc #0                           ; not needed...carry clear
   sta digitPointer - 4,x           ; set digit pointer LSB value
   lda #>NumberFonts
   sta digitPointer - 3,x           ; set digit pointer MSB value
   iny
   dex
   dex
   bpl .bcd2DigitLoop
   lda gameState                    ; get current game state
   bpl .doneSetupKernelPointers     ; branch if showing player score
   lda #<Blank
   sta digitPointer + 6             ; suppress thousands values for timer
   sta digitPointer + 4
.doneSetupKernelPointers
   rts

MarioGraphics
StationaryMarioSprite
   .byte $00 ; |........|
   .byte $3F ; |..XXXXXX|
   .byte $1B ; |...XX.XX|
   .byte $1B ; |...XX.XX|
   .byte $3F ; |..XXXXXX|
   .byte $7B ; |.XXXX.XX|
   .byte $75 ; |.XXX.X.X|
   .byte $76 ; |.XXX.XX.|
   .byte $7B ; |.XXXX.XX|
   .byte $3F ; |..XXXXXX|
   .byte $1F ; |...XXXXX|
   .byte $3E ; |..XXXXX.|
   .byte $0F ; |....XXXX|
   .byte $DB ; |XX.XX.XX|
   .byte $6B ; |.XX.X.XX|
   .byte $1A ; |...XX.X.|
   .byte $7E ; |.XXXXXX.|
   .byte $1C ; |...XXX..|
RunningMarioSprite_00
   .byte $00 ; |........|
   .byte $06 ; |.....XX.|
   .byte $02 ; |......X.|
   .byte $02 ; |......X.|
   .byte $EE ; |XXX.XXX.|
   .byte $FC ; |XXXXXX..|
   .byte $BD ; |X.XXXX.X|
   .byte $BD ; |X.XXXX.X|
   .byte $7F ; |.XXXXXXX|
   .byte $F7 ; |XXXX.XXX|
   .byte $FE ; |XXXXXXX.|
   .byte $9E ; |X..XXXX.|
   .byte $0F ; |....XXXX|
   .byte $DB ; |XX.XX.XX|
   .byte $6B ; |.XX.X.XX|
   .byte $1A ; |...XX.X.|
   .byte $7E ; |.XXXXXX.|
   .byte $1C ; |...XXX..|
   .byte $00 ; |........|
RunningMarioSprite_01
   .byte $00 ; |........|
   .byte $1C ; |...XXX..|
   .byte $0C ; |....XX..|
   .byte $0D ; |....XX.X|
   .byte $1F ; |...XXXXX|
   .byte $1F ; |...XXXXX|
   .byte $0E ; |....XXX.|
   .byte $7E ; |.XXXXXX.|
   .byte $7E ; |.XXXXXX.|
   .byte $3E ; |..XXXXX.|
   .byte $1C ; |...XXX..|
   .byte $0F ; |....XXXX|
   .byte $DB ; |XX.XX.XX|
   .byte $6B ; |.XX.X.XX|
   .byte $1A ; |...XX.X.|
   .byte $7E ; |.XXXXXX.|
   .byte $1C ; |...XXX..|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
JumpingMarioSprite
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $07 ; |.....XXX|
   .byte $FF ; |XXXXXXXX|
   .byte $FE ; |XXXXXXX.|
   .byte $BC ; |X.XXXX..|
   .byte $3F ; |..XXXXXX|
   .byte $FF ; |XXXXXXXX|
   .byte $FE ; |XXXXXXX.|
   .byte $3E ; |..XXXXX.|
   .byte $0F ; |....XXXX|
   .byte $DB ; |XX.XX.XX|
   .byte $6B ; |.XX.X.XX|
   .byte $1A ; |...XX.X.|
   .byte $7E ; |.XXXXXX.|
   .byte $1C ; |...XXX..|
ClimbingMarioSprite
   .byte $00 ; |........|
   .byte $1C ; |...XXX..|
   .byte $1C ; |...XXX..|
   .byte $0E ; |....XXX.|
   .byte $7E ; |.XXXXXX.|
   .byte $7E ; |.XXXXXX.|
   .byte $FE ; |XXXXXXX.|
   .byte $FE ; |XXXXXXX.|
   .byte $7F ; |.XXXXXXX|
   .byte $7F ; |.XXXXXXX|
   .byte $7F ; |.XXXXXXX|
   .byte $FF ; |XXXXXXXX|
   .byte $FE ; |XXXXXXX.|
   .byte $FC ; |XXXXXX..|
   .byte $7C ; |.XXXXX..|
   .byte $60 ; |.XX.....|
   .byte $00 ; |........|
       
JumpingSoundFrequencyValues
   .byte 15, 15, 15, 15, 15, 15, 14, 13, 13, 13, 14, 15, 15, 15, 15, 15
   .byte 14, 13, 13, 14;, 15, 15, 15, 15, 14, 13, 14, 15, 15, 15, 14
;
; last 11 bytes shared with table below
;
LevelCompletedSoundFrequencyValues
   .byte 15, 15, 15, 15, 14, 13, 14, 15, 15, 15, 14, 15; last byte not read
       
ObstacleColor
   .byte COLOR_OBSTACLES            ; color of hammer handle and obstacles
       
GirlfriendColors
   .byte COLOR_GIRLFRIEND_SHOES
   .byte COLOR_GIRLFRIEND_SHOES
   .byte COLOR_GIRLFRIEND_DRESS
   .byte COLOR_GIRLFRIEND_DRESS
   .byte COLOR_GIRLFRIEND_DRESS
   .byte COLOR_GIRLFRIEND_DRESS
   .byte COLOR_GIRLFRIEND_DRESS
   .byte COLOR_GIRLFRIEND_SASH
   .byte COLOR_GIRLFRIEND_DRESS
   .byte COLOR_GIRLFRIEND_DRESS
   .byte COLOR_GIRLFRIEND_HAIR
   .byte COLOR_GIRLFRIEND_HAIR
   .byte COLOR_GIRLFRIEND_HAIR
   .byte COLOR_GIRLFRIEND_HAIR
   .byte COLOR_GIRLFRIEND_HAIR
   .byte COLOR_GIRLFRIEND_HAIR
       
StoreMarioGraphics SUBROUTINE
   ldy #H_KERNEL_SECTION
.storeMarioGraphicLoop
   lda (marioGraphicPointer),y
   sta zpMarioGraphics,y
   dey
   bpl .storeMarioGraphicLoop
   rts

InitializationTable
   .byte BLACK                      ; backgroundColor
   .byte INIT_MARIO_HORIZ_POS       ; marioHorizPos
   .byte REFLECT                    ; marioDirection
   .word HandleUpSwingAnimation - H_HAMMER; hammerHandleGraphicPtrs
   .word MalletUpSwingAnimation - H_HAMMER; hammerMalletGraphicPtrs
   .byte MAX_OBSTACLES - 1          ; nextObstacleSlot
   .byte COLOR_BARREL_PLAYFIELD     ; playfieldColor
   .byte INIT_MARIO_VERT_POS_BARREL ; marioVertPos
   .byte INIT_HAMMER_HORIZ_POS_BARREL; hammerHorizPos
;
; following values are used for Firefox board
;
   .byte COLOR_FIREFOX_PLAYFIELD    ; playfieldColor
   .byte INIT_MARIO_VERT_POS_FIREFOX; marioVertPos
   .byte INIT_HAMMER_HORIZ_POS_FIREFOX; hammerHorizPos
   .byte 0                          ; firefoxPFIndexValues
   .byte 1                          ; firefoxPFIndexValues + 1
   .byte 2                          ; firefoxPFIndexValues + 2
   .byte 3                          ; firefoxPFIndexValues + 3
   .byte 4                          ; firefoxPFIndexValues + 4
   .byte 5                          ; firefoxPFIndexValues + 5
   
FirefoxPlayfieldData
FireFoxPF1Data_01
   .byte $0F ; |....XXXX|
   .byte $0A ; |....X.X.|
   .byte $0F ; |....XXXX|
   .byte $0A ; |....X.X.|
   .byte $0F ; |....XXXX|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $02 ; |......X.|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $02 ; |......X.|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $02 ; |......X.|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $02 ; |......X.|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $02 ; |......X.|
FireFoxPF2Data_01
   .byte $FD ; |XXXXXX.X|
   .byte $55 ; |.X.X.X.X|
   .byte $FD ; |XXXXXX.X|
   .byte $55 ; |.X.X.X.X|
   .byte $FF ; |XXXXXXXX|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $08 ; |....X...|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $08 ; |....X...|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $08 ; |....X...|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $08 ; |....X...|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $08 ; |....X...|
FireFoxPF2Data_00
   .byte $FF ; |XXXXXXXX|
   .byte $54 ; |.X.X.X..|
   .byte $FF ; |XXXXXXXX|
   .byte $54 ; |.X.X.X..|
   .byte $FF ; |XXXXXXXX|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $08 ; |....X...|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $08 ; |....X...|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $08 ; |....X...|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $08 ; |....X...|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $08 ; |....X...|
   .byte $00 ; |........|
FireFoxPF1Data_00
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
FireFoxPF2Data_02
   .byte $FD ; |XXXXXX.X|
   .byte $55 ; |.X.X.X.X|
   .byte $FD ; |XXXXXX.X|
   .byte $55 ; |.X.X.X.X|
   .byte $FD ; |XXXXXX.X|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $08 ; |....X...|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $08 ; |....X...|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $08 ; |....X...|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $08 ; |....X...|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $08 ; |....X...|
       
InitializeGame
   ldx #<hammerHorizPos - backgroundColor
.initBarrelLevel
   lda InitializationTable,x
   sta backgroundColor,x
   dex
   bpl .initBarrelLevel
   lda currentGameBoard             ; get current game board
   beq .leaveInitialization         ; branch if barrels
   ldx #8
.initFireFoxLevel
   lda InitializationTable + 11,x
   sta playfieldColor,x
   dex 
   bpl .initFireFoxLevel
.leaveInitialization
   rts

PlayDeathSound
   lda #$FF
   sta losingLifeFlag               ; set value to show player losing life
   
   IF COMPILE_VERSION = PAL50
   
   ldx #14
   
   ELSE
   
   ldx #17
   
   ENDIF
   
   lda #LOSING_LIFE_SOUND_IDX
   bne PlayMusic                    ; unconditional branch
       
IncrementScoreForJumpingObstacle
IncrementScoreForPullingRivit
   lda #(POINT_VALUE_JUMPING_OBSTACLE | POINT_VALUE_PULLING_RIVIT) >> 8
IncrementScore
   sed                              ; set to decimal mode
   clc
   adc playerScore + 1              ; increment score hundreds value
   sta playerScore + 1              ; set score hundreds value
   lda #1 - 1
   adc playerScore                  ; increment score thousands value
   sta playerScore                  ; set score thousands value
   cld                              ; clear decimal mode
PlayIncrementScoreMusic
PlayGameOverMusic

   IF COMPILE_VERSION = PAL50
   
   ldx #26
   
   ELSE
   
   ldx #32
   
   ENDIF
   
   lda #INCREMENT_SCORE_SOUND_IDX | GAME_OVER_SOUND_IDX
PlayMusic
   sta currentSoundPlaying
   stx soundIndex
   lda #12
   sta AUDC0
   lda #15
   sta AUDV0
   rts

DownLadderTable
BarrelDownLadderTable
   .byte 132, 101, 104, 74, 76, 46, 48, 21, 5
   .byte 21, 44, 72, 129, 21, 49, 77, 105, 133

FirefoxDownLadderTable   
   .byte 21, 21, 21, 21, 49, 49, 49, 49
   .byte 77, 77, 77, 77, 105, 105, 105, 105
       
KernelVectorTable
   .word BarrelHammerKernel + 2
   .word BarrelKernel + 6   
   .word FirefoxHammerKernel
   .word JumpFirefoxKernel

TopBarrelSectionPFDataTable
   .word RightPF1DataTopBarrelSection - 3
   .word PF0DataTopBarrelSection - 3
   .word PF2DataTopBarrelSection - 3
   .word LeftPF1DataTopBarrelSection - 3

   IF COMPILE_VERSION = PAL50
   
      .byte $00                     ; not used
   
   ELSE
   
      .byte $2A                     ; not used
   
   ENDIF
   
UpLadderTable
BarrelUpLadderTable
   .byte 154, 130, 127, 101, 99, 73, 71, 43, 21
   .byte 46, 75, 103, 154, 42, 70, 98, 126, 154
   
FirefoxUpLadderTable
   .byte 49, 49, 49, 49, 77, 77, 77, 77
   .byte 105, 105, 105, 105, 133, 133, 133, 133

MarioColors
HorizontalColors

   REPEAT H_KERNEL_SECTION + 2
   .byte BLACK
   REPEND
   
   .byte COLOR_MARIO_SHOES
   .byte COLOR_MARIO_SHOES
   .byte COLOR_MARIO_SUIT
   .byte COLOR_MARIO_SUIT
   .byte COLOR_MARIO_SUIT   
   .byte COLOR_MARIO_SUIT   
   .byte COLOR_MARIO_SUIT
   .byte COLOR_MARIO_SUIT
   .byte COLOR_MARIO_SUIT
   .byte COLOR_MARIO_SUIT
   .byte WHITE
   .byte WHITE
   .byte WHITE   
   .byte WHITE   
   .byte WHITE
   .byte COLOR_MARIO_SUIT
   .byte COLOR_MARIO_SUIT

VerticalColors
   REPEAT H_KERNEL_SECTION + 2
   .byte BLACK
   REPEND
   
   .byte COLOR_MARIO_SHOES
   .byte COLOR_MARIO_SHOES
   .byte COLOR_MARIO_SHOES
   .byte COLOR_MARIO_SUIT
   .byte COLOR_MARIO_SUIT   
   .byte COLOR_MARIO_SUIT   
   .byte COLOR_MARIO_SUIT   
   .byte COLOR_MARIO_SUIT   
   .byte COLOR_MARIO_SUIT   
   .byte COLOR_MARIO_SUIT   
   .byte COLOR_MARIO_SUIT   
   .byte COLOR_MARIO_SUIT   
   .byte COLOR_MARIO_SUIT   
   .byte COLOR_MARIO_SUIT
   .byte COLOR_MARIO_SUIT
   
   REPEAT H_KERNEL_SECTION + 1
   .byte BLACK
   REPEND
   
DonkeyKong
   .byte $00 ; |........|
   .byte $E0 ; |XXX.....|
   .byte $E0 ; |XXX.....|
   .byte $67 ; |.XX..XXX|
   .byte $67 ; |.XX..XXX|
   .byte $7E ; |.XXXXXX.|
   .byte $7E ; |.XXXXXX.|
   .byte $3E ; |..XXXXX.|
   .byte $5E ; |.X.XXXX.|
   .byte $DC ; |XX.XXX..|
   .byte $BC ; |X.XXXX..|
   .byte $FE ; |XXXXXXX.|
   .byte $FF ; |XXXXXXXX|
   .byte $7F ; |.XXXXXXX|
   .byte $39 ; |..XXX..X|
   .byte $45 ; |.X...X.X|
   .byte $7D ; |.XXXXX.X|
   .byte $55 ; |.X.X.X.X|
   .byte $7C ; |.XXXXX..|
   .byte $38 ; |..XXX...|
       
ObstacleTable
   .byte <HorizontalBarrelSprite + OBSTACLE_HEIGHT - H_KERNEL_SECTION
   .byte <FallingBarrelSprite + OBSTACLE_HEIGHT - H_KERNEL_SECTION
   .byte <FirefoxSprite + OBSTACLE_HEIGHT - H_KERNEL_SECTION

FireFoxLeftPF1Table
;
; no rivits removed
;
   .byte <FireFoxPF1Data_00 - 13
   .byte <FireFoxPF1Data_01 - 3
   .byte <FireFoxPF1Data_01 - 3
   .byte <FireFoxPF1Data_01 - 3
   .byte <FireFoxPF1Data_01 - 3
   .byte <FireFoxPF1Data_01 - 3
;
; left rivit removed
;
   .byte <FireFoxPF1Data_00 - 13
   .byte <FireFoxPF1Data_01 - 3
   .byte <FireFoxPF1Data_01 - 3
   .byte <FireFoxPF1Data_01 - 3
   .byte <FireFoxPF1Data_01 - 3
   .byte <FireFoxPF1Data_01 - 3
;
; right rivit removed
;
   .byte <FireFoxPF1Data_00 - 13
   .byte <FireFoxPF1Data_01 - 3
   .byte <FireFoxPF1Data_01 - 3
   .byte <FireFoxPF1Data_01 - 3
   .byte <FireFoxPF1Data_01 - 3
   .byte <FireFoxPF1Data_01 - 3
;
; all rivits removed
;
   .byte <FireFoxPF1Data_00 - 13
   .byte <FireFoxPF1Data_01 - 3
   .byte <FireFoxPF1Data_01 - 3
   .byte <FireFoxPF1Data_01 - 3
   .byte <FireFoxPF1Data_01 - 3
   .byte <FireFoxPF1Data_01 - 3
   
FireFoxPF2Table
;
; no rivits removed
;
   .byte <FireFoxPF1Data_00 - 13
   .byte <FireFoxPF2Data_00 - 3
   .byte <FireFoxPF2Data_01 - 3
   .byte <FireFoxPF2Data_01 - 3
   .byte <FireFoxPF2Data_01 - 3
   .byte <FireFoxPF2Data_01 - 3
;
; left rivit removed
;
   .byte <FireFoxPF1Data_00 - 13
   .byte <FireFoxPF2Data_00 - 3
   .byte <FireFoxPF2Data_02 - 3
   .byte <FireFoxPF2Data_02 - 3
   .byte <FireFoxPF2Data_02 - 3
   .byte <FireFoxPF2Data_02 - 3
;
; right rivit removed
;
   .byte <FireFoxPF1Data_00 - 13
   .byte <FireFoxPF2Data_00 - 3
   .byte <FireFoxPF2Data_01 - 3
   .byte <FireFoxPF2Data_01 - 3
   .byte <FireFoxPF2Data_01 - 3
   .byte <FireFoxPF2Data_01 - 3
;
; all rivits removed
;
   .byte <FireFoxPF1Data_00 - 13
   .byte <FireFoxPF2Data_00 - 3
   .byte <FireFoxPF2Data_02 - 3
   .byte <FireFoxPF2Data_02 - 3
   .byte <FireFoxPF2Data_02 - 3
   .byte <FireFoxPF2Data_02 - 3
   
FireFoxPF0Table
;
; no rivits removed
;
   .byte <FireFoxPF1Data_00 - 13
   .byte <FireFoxPF2Data_00 - 3
   .byte <FireFoxPF2Data_01 - 3
   .byte <FireFoxPF2Data_01 - 3
   .byte <FireFoxPF2Data_01 - 3
   .byte <FireFoxPF2Data_01 - 3
;
; left rivit removed
;
   .byte <FireFoxPF1Data_00 - 13
   .byte <FireFoxPF2Data_00 - 3
   .byte <FireFoxPF2Data_01 - 3
   .byte <FireFoxPF2Data_01 - 3
   .byte <FireFoxPF2Data_01 - 3
   .byte <FireFoxPF2Data_01 - 3
;
; right rivit removed
;
   .byte <FireFoxPF1Data_00 - 13
   .byte <FireFoxPF2Data_00 - 3
   .byte <FireFoxPF2Data_02 - 3
   .byte <FireFoxPF2Data_02 - 3
   .byte <FireFoxPF2Data_02 - 3
   .byte <FireFoxPF2Data_02 - 3
;
; all rivits removed
;
   .byte <FireFoxPF1Data_00 - 13
   .byte <FireFoxPF2Data_00 - 3
   .byte <FireFoxPF2Data_02 - 3
   .byte <FireFoxPF2Data_02 - 3
   .byte <FireFoxPF2Data_02 - 3
   .byte <FireFoxPF2Data_02 - 3
       
LivesPFPattern
   .byte $00 ; |........|           no lives remaining
   .byte $01 ; |.......X|           one life
   .byte $05 ; |.....X.X|           two lives
   .byte $15 ; |...X.X.X|           three lives
   
   IF COMPILE_VERSION = PAL50
   
      .byte $00, $FF, $FF, $00, $00 ; not used
      
   ELSE
   
      .byte $89, $A5, $0D, $E9, $00 ; not used
   
   ENDIF

   BOUNDARY 0
   
NumberFonts
zero
   .byte $3C ; |..XXXX..|
   .byte $66 ; |.XX..XX.|
   .byte $66 ; |.XX..XX.|
   .byte $66 ; |.XX..XX.|
   .byte $66 ; |.XX..XX.|
   .byte $66 ; |.XX..XX.|
   .byte $3C ; |..XXXX..|
   .byte $00 ; |........|
one
   .byte $7E ; |.XXXXXX.|
   .byte $18 ; |...XX...|
   .byte $18 ; |...XX...|
   .byte $18 ; |...XX...|
   .byte $38 ; |..XXX...|
   .byte $18 ; |...XX...|
   .byte $08 ; |....X...|
   .byte $00 ; |........|
two
   .byte $7E ; |.XXXXXX.|
   .byte $62 ; |.XX...X.|
   .byte $60 ; |.XX.....|
   .byte $3C ; |..XXXX..|
   .byte $06 ; |.....XX.|
   .byte $46 ; |.X...XX.|
   .byte $3C ; |..XXXX..|
   .byte $00 ; |........|
three
   .byte $3C ; |..XXXX..|
   .byte $46 ; |.X...XX.|
   .byte $06 ; |.....XX.|
   .byte $1C ; |...XXX..|
   .byte $06 ; |.....XX.|
   .byte $46 ; |.X...XX.|
   .byte $3C ; |..XXXX..|
   .byte $00 ; |........|
four
   .byte $0C ; |....XX..|
   .byte $0C ; |....XX..|
   .byte $7E ; |.XXXXXX.|
   .byte $4C ; |.X..XX..|
   .byte $2C ; |..X.XX..|
   .byte $1C ; |...XXX..|
   .byte $0C ; |....XX..|
   .byte $00 ; |........|
five
   .byte $3C ; |..XXXX..|
   .byte $46 ; |.X...XX.|
   .byte $06 ; |.....XX.|
   .byte $7C ; |.XXXXX..|
   .byte $60 ; |.XX.....|
   .byte $60 ; |.XX.....|
   .byte $7E ; |.XXXXXX.|
   .byte $00 ; |........|
six
   .byte $3C ; |..XXXX..|
   .byte $66 ; |.XX..XX.|
   .byte $66 ; |.XX..XX.|
   .byte $7C ; |.XXXXX..|
   .byte $60 ; |.XX.....|
   .byte $62 ; |.XX...X.|
   .byte $3C ; |..XXXX..|
   .byte $00 ; |........|
seven
   .byte $30 ; |..XX....|
   .byte $30 ; |..XX....|
   .byte $18 ; |...XX...|
   .byte $0C ; |....XX..|
   .byte $06 ; |.....XX.|
   .byte $42 ; |.X....X.|
   .byte $7E ; |.XXXXXX.|
   .byte $00 ; |........|
eight
   .byte $3C ; |..XXXX..|
   .byte $66 ; |.XX..XX.|
   .byte $66 ; |.XX..XX.|
   .byte $3C ; |..XXXX..|
   .byte $66 ; |.XX..XX.|
   .byte $66 ; |.XX..XX.|
   .byte $3C ; |..XXXX..|
   .byte $00 ; |........|
nine
   .byte $3C ; |..XXXX..|
   .byte $46 ; |.X...XX.|
   .byte $06 ; |.....XX.|
   .byte $3E ; |..XXXXX.|
   .byte $66 ; |.XX..XX.|
   .byte $66 ; |.XX..XX.|
   .byte $3C ; |..XXXX..|
   .byte $00 ; |........|
   
BarrelOffsetDiffTable
   .byte 128, 144, 50, 54, 54, 58, 50, 49, 255, 52, 58, 58, 128

ObstacleSprites
Blank
HorizontalBarrelSprite
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $3C ; |..XXXX..|
   .byte $6E ; |.XX.XXX.|
   .byte $FB ; |XXXXX.XX|
   .byte $BF ; |X.XXXXXX|
   .byte $FD ; |XXXXXX.X|
   .byte $DF ; |XX.XXXXX|
   .byte $76 ; |.XXX.XX.|
   .byte $3C ; |..XXXX..|
   
FallingBarrelSprite
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $7E ; |.XXXXXX.|
   .byte $99 ; |X..XX..X|
   .byte $BD ; |X.XXXX.X|
   .byte $81 ; |X......X|
   .byte $BD ; |X.XXXX.X|
   .byte $99 ; |X..XX..X|
   .byte $7E ; |.XXXXXX.|
   .byte $00 ; |........|
   
FirefoxSprite
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $38 ; |..XXX...|
   .byte $7E ; |.XXXXXX.|
   .byte $FF ; |XXXXXXXX|
   .byte $FF ; |XXXXXXXX|
   .byte $71 ; |.XXX...X|
   .byte $AA ; |X.X.X.X.|
   .byte $AA ; |X.X.X.X.|
   .byte $71 ; |.XXX...X|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
       
FirefoxVerPos
   .byte 96, 68, 40, TOP_PLATFORM_VALUE
   
StartNewGameBoard
   lda #0
   ldx #<hammerTime - obstacleVertPos
   ldy #<HorizontalColors
.startNewGameBoard
   sta obstacleVertPos,x
   dex
   bmi .doneStartNewGameBoard
   sty marioColorPointerLSB,x
   bpl .startNewGameBoard           ; unconditional branch
   
.doneStartNewGameBoard
   jmp InitializeGame

   IF COMPILE_VERSION = PAL50

      .byte $00                     ; not used
   
   ELSE
   
      .byte $98                     ; not used
   
   ENDIF

AudioFrequencyTable
   .word JumpingSoundFrequencyValues
   .word WalkingSoundFrequencyValues
   .word ScoringSoundFrequencyValues
   .word DeathSoundFrequencyValues
   .word LevelCompletedSoundFrequencyValues
   .word RandomSeedTable                  ; not used
   
DeathSoundFrequencyValues

   IF COMPILE_VERSION = PAL50

   .byte 12, 12, 12, 17, 17, 8, 8, 11, 10, 9, 8, 7, 6, 5, 0, 0, 0
   
   ELSE
   
   .byte 12, 12, 12, 12, 17, 17, 17, 8, 8, 8, 11, 10, 9, 8, 7, 6, 5
   
   ENDIF

BarrelRightPF1Data_05
   .byte $FF ; |XXXXXXXX|
   .byte $FF ; |XXXXXXXX|
   .byte $10 ; |...X....|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $10 ; |...X....|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $10 ; |...X....|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $10 ; |...X....|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
BarrelRightPF1Data_04
   .byte $14 ; |...X.X..|
   .byte $3C ; |..XXXX..|
   .byte $E8 ; |XXX.X...|
   .byte $54 ; |.X.X.X..|
   .byte $AC ; |X.X.XX..|
   .byte $78 ; |.XXXX...|
   .byte $C0 ; |XX......|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
BarrelRightPF1Data_03
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $C0 ; |XX......|
   .byte $78 ; |.XXXX...|
   .byte $AF ; |X.X.XXXX|
   .byte $55 ; |.X.X.X.X|
   .byte $EA ; |XXX.X.X.|
   .byte $3D ; |..XXXX.X|
   .byte $07 ; |.....XXX|
   .byte $10 ; |...X....|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $10 ; |...X....|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $10 ; |...X....|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $10 ; |...X....|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
BarrelRightPF1Data_02
   .byte $14 ; |...X.X..|
   .byte $3C ; |..XXXX..|
   .byte $E8 ; |XXX.X...|
   .byte $54 ; |.X.X.X..|
   .byte $AC ; |X.X.XX..|
   .byte $78 ; |.XXXX...|
   .byte $C0 ; |XX......|
   .byte $00 ; |........|
   .byte $40 ; |.X......|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $40 ; |.X......|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $40 ; |.X......|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
BarrelRightPF1Data_01
   .byte $40 ; |.X......|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $40 ; |.X......|
   .byte $C0 ; |XX......|
   .byte $78 ; |.XXXX...|
   .byte $AF ; |X.X.XXXX|
   .byte $55 ; |.X.X.X.X|
   .byte $EA ; |XXX.X.X.|
   .byte $3D ; |..XXXX.X|
   .byte $07 ; |.....XXX|
   .byte $10 ; |...X....|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $10 ; |...X....|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $10 ; |...X....|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $10 ; |...X....|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
RightPF1DataTopBarrelSection
   .byte $FC ; |XXXXXX..|
   .byte $6C ; |.XX.XX..|
   .byte $90 ; |X..X....|
   .byte $6C ; |.XX.XX..|
   .byte $FC ; |XXXXXX..|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
;
; last byte shared so don't cross a page boundary
;
Girlfriend
   .byte $00 ; |........|
   .byte $43 ; |.X....XX|
   .byte $82 ; |X.....X.|
   .byte $7E ; |.XXXXXX.|
   .byte $7F ; |.XXXXXXX|
   .byte $FF ; |XXXXXXXX|
   .byte $7E ; |.XXXXXX.|
   .byte $3C ; |..XXXX..|
   .byte $18 ; |...XX...|
   .byte $7E ; |.XXXXXX.|
   .byte $38 ; |..XXX...|
   .byte $9C ; |X..XXX..|
   .byte $7E ; |.XXXXXX.|
   .byte $BF ; |X.XXXXXX|
   .byte $3A ; |..XXX.X.|
   .byte $1F ; |...XXXXX|
   .byte $07 ; |.....XXX|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|   

LadderHorizValues
   .byte 109, 81, 49, 89, 109, 69, 49, 109, 77
   .byte 77, 101,65, 73, 123, 35, 123, 35, 123

.firefoxLadderHorizValues
   .byte 41, 61, 97, 117, 41, 61, 97, 117
   .byte 41, 61, 97, 117, 41, 61, 97, 117
       
PositionHammerObject
   sta WSYNC                        ; wait for next scan line
   sec
.coarseMoveHammerObject
   sbc #15                          ; divide position by 15
   bcs .coarseMoveHammerObject
   eor #15                          ; 4-bit 1's complement for fine motion
   asl                              ; shift remainder to upper nybbles
   asl
   asl
   asl
   adc #(8 + 1) << 4                ; increment 2's complement by 8 for full range
   sta RESP0,x                      ; set coarse position value
   sta WSYNC                        ; wait for next scan line
   sta HMP0,x                       ; set fine motion value
   rts

RampHorizValues
   .byte 117, 105, 93, 81, 69, 58, 45

   IF COMPILE_VERSION = PAL50
   
      .byte $00                     ; not used
   
   ELSE
   
      .byte $88                     ; not used
   
   ENDIF

MarioColorTable
   .byte <HorizontalColors, <HorizontalColors, <HorizontalColors
   .byte <HorizontalColors + 1, <HorizontalColors + 2, <VerticalColors
   .byte <HorizontalColors

WalkingSoundFrequencyValues
   .byte 26, 28
   
BarrelRightPF1Table
   .byte <BarrelRightPF1Data_05 - 13
   .byte <BarrelRightPF1Data_04 - 3
   .byte <BarrelRightPF1Data_03 - 3
   .byte <BarrelRightPF1Data_02 - 3
   .byte <BarrelRightPF1Data_01 - 3
   
   .byte $91                        ; not used
   
BarrelLeftPF1Data_05
   .byte $0F ; |....XXXX|
   .byte $0F ; |....XXXX|
   .byte $00 ; |........|
   .byte $06 ; |.....XX.|
   .byte $00 ; |........|
   .byte $06 ; |.....XX.|
   .byte $00 ; |........|
   .byte $06 ; |.....XX.|
   .byte $00 ; |........|
   .byte $06 ; |.....XX.|
   .byte $00 ; |........|
   .byte $06 ; |.....XX.|
   .byte $00 ; |........|
   .byte $06 ; |.....XX.|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
BarrelLeftPF1Data_02
BarrelLeftPF1Data_04
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $01 ; |.......X|
   .byte $0F ; |....XXXX|
   .byte $0A ; |....X.X.|
   .byte $05 ; |.....X.X|
   .byte $0B ; |....X.XX|
   .byte $0E ; |....XXX.|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
BarrelLeftPF1Data_01
BarrelLeftPF1Data_03
   .byte $02 ; |......X.|
   .byte $03 ; |......XX|
   .byte $01 ; |.......X|
   .byte $02 ; |......X.|
   .byte $03 ; |......XX|
   .byte $01 ; |.......X|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
LeftPF1DataTopBarrelSection
   .byte $0F ; |....XXXX|
   .byte $0B ; |....X.XX|
   .byte $04 ; |.....X..|
   .byte $0B ; |....X.XX|
   .byte $0F ; |....XXXX|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $08 ; |....X...|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $08 ; |....X...|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $08 ; |....X...|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $08 ; |....X...|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $08 ; |....X...|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
BarrelPF2Data_04
   .byte $40 ; |.X......|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $E0 ; |XXX.....|
   .byte $BC ; |X.XXXX..|
   .byte $57 ; |.X.X.XXX|
   .byte $AA ; |X.X.X.X.|
   .byte $F5 ; |XXXX.X.X|
   .byte $1E ; |...XXXX.|
   .byte $03 ; |......XX|
   .byte $00 ; |........|
   .byte $01 ; |.......X|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
BarrelPF0Data_05
   .byte $01 ; |.......X|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $01 ; |.......X|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $01 ; |.......X|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
BarrelPF2Data_03
   .byte $01 ; |.......X|
   .byte $03 ; |......XX|
   .byte $1E ; |...XXXX.|
   .byte $F5 ; |XXXX.X.X|
   .byte $AA ; |X.X.X.X.|
   .byte $57 ; |.X.X.XXX|
   .byte $BC ; |X.XXXX..|
   .byte $E0 ; |XXX.....|
   .byte $10 ; |...X....|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $10 ; |...X....|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $10 ; |...X....|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
BarrelPF2Data_02
   .byte $10 ; |...X....|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $F0 ; |XXXX....|
   .byte $BC ; |X.XXXX..|
   .byte $57 ; |.X.X.XXX|
   .byte $AA ; |X.X.X.X.|
   .byte $F5 ; |XXXX.X.X|
   .byte $1E ; |...XXXX.|
   .byte $03 ; |......XX|
   .byte $00 ; |........|
   .byte $21 ; |..X....X|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $21 ; |..X....X|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $21 ; |..X....X|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
BarrelPF2Data_01
   .byte $21 ; |..X....X|
   .byte $03 ; |......XX|
   .byte $1E ; |...XXXX.|
   .byte $F5 ; |XXXX.X.X|
   .byte $AA ; |X.X.X.X.|
   .byte $57 ; |.X.X.XXX|
   .byte $BC ; |X.XXXX..|
   .byte $E0 ; |XXX.....|
   .byte $80 ; |X.......|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $80 ; |X.......|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $80 ; |X.......|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
PF2DataTopBarrelSection
   .byte $FF ; |XXXXXXXX|
   .byte $B6 ; |X.XX.XX.|
   .byte $49 ; |.X..X..X|
   .byte $B6 ; |X.XX.XX.|
   .byte $FF ; |XXXXXXXX|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $80 ; |X.......|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $80 ; |X.......|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $80 ; |X.......|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $80 ; |X.......|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $80 ; |X.......|
BarrelPF2Data_05
   .byte $FF ; |XXXXXXXX|
   .byte $FF ; |XXXXXXXX|
   .byte $40 ; |.X......|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $40 ; |.X......|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   
   IF COMPILE_VERSION = PAL50
   
      .byte $00                     ; not used
   
   ELSE
   
      .byte $A0                     ; not used
   
   ENDIF
   
MarioAnimationTable
   .byte <StationaryMarioSprite - H_KERNEL_SECTION - 1
   .byte <RunningMarioSprite_00 - H_KERNEL_SECTION - 1
   .byte <StationaryMarioSprite - H_KERNEL_SECTION - 1
   .byte <RunningMarioSprite_01 - H_KERNEL_SECTION - 1
   .byte <JumpingMarioSprite - H_KERNEL_SECTION - 1
   .byte <ClimbingMarioSprite - H_KERNEL_SECTION - 1
   .byte <StationaryMarioSprite - H_KERNEL_SECTION - 1

BarrelPF0Data_04
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $80 ; |X.......|
   .byte $F0 ; |XXXX....|
   .byte $50 ; |.X.X....|
   .byte $A0 ; |X.X.....|
   .byte $D0 ; |XX.X....|
   .byte $70 ; |.XXX....|
   .byte $10 ; |...X....|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $10 ; |...X....|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $10 ; |...X....|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $10 ; |...X....|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
BarrelPF0Data_03
   .byte $10 ; |...X....|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $70 ; |.XXX....|
   .byte $D0 ; |XX.X....|
   .byte $A0 ; |X.X.....|
   .byte $50 ; |.X.X....|
   .byte $F0 ; |XXXX....|
   .byte $80 ; |X.......|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $40 ; |.X......|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $40 ; |.X......|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $40 ; |.X......|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
BarrelPF0Data_02
   .byte $40 ; |.X......|
   .byte $00 ; |........|
   .byte $80 ; |X.......|
   .byte $F0 ; |XXXX....|
   .byte $50 ; |.X.X....|
   .byte $A0 ; |X.X.....|
   .byte $D0 ; |XX.X....|
   .byte $70 ; |.XXX....|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
;
; last 3 bytes shared with table below
;
BarrelPF0Data_01
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $70 ; |.XXX....|
   .byte $D0 ; |XX.X....|
   .byte $A0 ; |X.X.....|
   .byte $50 ; |.X.X....|
   .byte $F0 ; |XXXX....|
   .byte $80 ; |X.......|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
PF0DataTopBarrelSection
   .byte $F0 ; |XXXX....|
   .byte $D0 ; |XX.X....|
   .byte $20 ; |..X.....|
   .byte $D0 ; |XX.X....|
   .byte $F0 ; |XXXX....|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   .byte $00 ; |........|
   
NoHammerAnimation
   .byte $F0 | DISABLE_BM, $F0 | DISABLE_BM, DISABLE_BM, DISABLE_BM, DISABLE_BM
   .byte DISABLE_BM, DISABLE_BM, DISABLE_BM, DISABLE_BM, DISABLE_BM, DISABLE_BM
   .byte DISABLE_BM, DISABLE_BM, DISABLE_BM, DISABLE_BM
   
HandleUpSwingAnimation
   .byte DISABLE_BM, DISABLE_BM, DISABLE_BM, DISABLE_BM, DISABLE_BM, DISABLE_BM
   .byte DISABLE_BM, $FF,$FF,$FF, DISABLE_BM, DISABLE_BM, DISABLE_BM, $FF

MalletUpSwingAnimation
   .byte DISABLE_BM, DISABLE_BM, DISABLE_BM, DISABLE_BM, DISABLE_BM, DISABLE_BM
   .byte DISABLE_BM, DISABLE_BM, DISABLE_BM, DISABLE_BM, $FF, $FF, $FF
;
; last byte shared with table below
;
MalletDownSwingAnimation
   .byte DISABLE_BM, $FF, $FF, $FF, $FF, $FF, $FF, DISABLE_BM, DISABLE_BM
   .byte DISABLE_BM, DISABLE_BM, DISABLE_BM, DISABLE_BM
;
; last byte shared with table below
;
HandleDownSwingAnimation
   .byte DISABLE_BM, DISABLE_BM, DISABLE_BM, $FF, $FF, DISABLE_BM, DISABLE_BM
   .byte DISABLE_BM, DISABLE_BM, DISABLE_BM, DISABLE_BM, DISABLE_BM, DISABLE_BM
   .byte DISABLE_BM
       
ScoringSoundFrequencyValues
   .byte 10, 10, 10, 10, 10, 10, 10, 6, 6, 6, 6, 6, 6, 6, 6, 6
   .byte 6, 6, 7, 7, 7, 7, 7, 8, 8, 8, 8, 8, 10, 10, 10, 10, 10 ; last byte not read
       
BarrelLeftPF1Table
   .byte <BarrelLeftPF1Data_05 - 13
   .byte <BarrelLeftPF1Data_04 - 3
   .byte <BarrelLeftPF1Data_03 - 3
   .byte <BarrelLeftPF1Data_02 - 3
   .byte <BarrelLeftPF1Data_01 - 3

   .byte $4F                        ; not used

BarrelPF2Table
   .byte <BarrelPF2Data_05 - 13
   .byte <BarrelPF2Data_04 - 3
   .byte <BarrelPF2Data_03 - 3
   .byte <BarrelPF2Data_02 - 3
   .byte <BarrelPF2Data_01 - 3
   
   .byte $D4                        ; not used
   
BarrelPF0Table
   .byte <BarrelPF0Data_05 - 13
   .byte <BarrelPF0Data_04 - 3
   .byte <BarrelPF0Data_03 - 3
   .byte <BarrelPF0Data_02 - 3
   .byte <BarrelPF0Data_01 - 3
   
   .byte $62                        ; not used

KernelSectionHeight
   .byte 12, 2, 2, 2, 2, 2

   .org ROM_BASE + 4096 - 4, 0      ; 4K ROM
   .word Start
   .word Start
