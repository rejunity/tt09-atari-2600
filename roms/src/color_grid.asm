;; Color Grid: 8 intesity columns x 16 luma rows
;; By ReJ aka Renaldas Zioma
;; Coded with amazing https://8bitworkshop.com

    processor 6502
    include "vcs.h"
    include "macro.h"

    org  $f000

    ; The CLEAN_START macro zeroes RAM and registers
Start
    CLEAN_START

NextFrame
    lda #2
    sta VBLANK  ; Enable VBLANK (disable output)
    lda #2
    sta VSYNC   ; At the beginning of the frame we set the VSYNC bit...
    sta WSYNC   ; And hold it on for 3 scanlines...
    sta WSYNC
    sta WSYNC
    lda #0      ; Now we turn VSYNC off.
    sta VSYNC 

                ; Put color grid (128 scanlines) in the center of the screen:
    ldx #67     ; 3 + 67 + 128 + 64 = 262 total scanlines
LVBlank
    sta WSYNC   ; accessing WSYNC stops the CPU until next scanline
    dex         ; decrement X
    bne LVBlank ; loop until X == 0

    lda #0
    sta VBLANK  ; Re-enable output (disable VBLANK)
    sta COLUBK

    ldx #129
    ldy $0
    lda $0
        
    clc
    jmp ScanLoopEntree

ScanLoop
    sta COLUBK  ; Set the background color
    adc #2      ; add 2 to the current background color in A
    sta COLUBK  ; set the background color
    adc #2      ; add 2 to the current background color in A
    sta COLUBK  ; set the background color
    adc #2      ; add 2 to the current background color in A
    sta COLUBK  ; set the background color

    adc #2      ; add 2 to the current background color in A
    sta COLUBK  ; set the background color
    adc #2      ; add 2 to the current background color in A
    sta COLUBK  ; set the background color
    adc #2      ; add 2 to the current background color in A
    sta COLUBK  ; set the background color
    adc #2      ; add 2 to the current background color in A
    sta COLUBK  ; set the background color

    lda #0
    sta COLUBK  ; set the background color to BLACK

ScanLoopEntree
    sta WSYNC
    tya         ; A = (Y / 8) * 16
    lsr
    lsr
    lsr
    asl
    asl
    asl
    asl
    bit $0      ; Align right
    iny
    dex
    bne ScanLoop

    lda #2
    sta VBLANK  ; Enable VBLANK again
    
    ldx #64     ; 64 lines of overscan to complete the frame
LVOver
    sta WSYNC
    dex
    bne LVOver

    jmp NextFrame   ; Go back and do another frame
    
    org $fffc
    .word Start
    .word Start
