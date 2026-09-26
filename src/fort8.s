;
; FILE: FORT8.S
;
; DISPLAY LIST RAM BASED STUFF
;
DSP_LST1 = RAM1_STUFF
Z1:
         .byte $70,$70,$80,$70
         .byte $44
         .word PANEL
         .byte $04,$04,$04,$04
         .byte $44
         .word NAVA_PANEL
         .byte $44+$80
         .word PLAY_SCRN
         .byte $50,$20,$80
DSP_MAP  = *-Z1+RAM1_STUFF
MAP_LINES = 17
         .byte $74
         .word 0
         .byte $74
         .word 0
         .byte $74
         .word 0
         .byte $74
         .word 0
         .byte $74
         .word 0
         .byte $74
         .word 0
         .byte $74
         .word 0
         .byte $74
         .word 0
         .byte $74
         .word 0
         .byte $74
         .word 0
         .byte $74
         .word 0
         .byte $74
         .word 0
         .byte $74
         .word 0
         .byte $74
         .word 0
         .byte $74
         .word 0
         .byte $74
         .word 0
         .byte $54+$80
         .word 0
         .byte $41
         .word DSP_LST1
Z1_LEN   = *-Z1-1
;
NAVA_PANEL:
 .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; /           /
 .byte $AE,$CE,$A1,$C1,$B6,$D6,$A1,$C1  ; NAVA
 .byte $B4,$D4,$B2,$D2,$AF,$CF,$AE,$CE  ; TRON
 .byte $00,$00,$00,$00,$00,$00  ; /      /
;
Z2:
PANEL    = RAM2_STUFF
 .byte $00,$00,$00,$00,$00,$00,$00  ; /       /
 .byte $B3,$D3,$A3,$C3,$AF,$CF,$B2,$D2,$A5,$C5  ; SCORE
 .byte $00,$00  ; /  /
SCORE_DIG = *-Z2+RAM2_STUFF
 .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; /            /
 .byte $00,$00,$00,$00,$00,$00,$00,$00,$00  ; /         /
 .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; /                    /
 .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; /                    /
 .byte $00,$00  ; /  /
 .byte $A6,$C6,$B5,$D5,$A5,$C5,$AC,$CC  ; FUEL
 .byte $00,$00,$1A  ; /  :/
 .byte $5C,$5D,$5E,$5F,$60,$61,$62,$63,$64,$65,$66,$67
 .byte $1D,$00,$00  ; /=  /
 .byte $A2,$C2,$AF,$CF,$AE,$CE,$B5,$D5,$B3,$D3  ; BONUS
 .byte $00,$00,$00,$00  ; /    /
FUEL_DIG = *-Z2+RAM2_STUFF
 .byte $00,$00,$00,$00,$00,$00,$00,$00  ; /        /
 .byte $00,$00,$1B  ; /  ;/
 .byte $68,$69,$6A,$6B,$6C,$6D,$6E,$6F,$70,$71,$72,$73
 .byte $1E,$00,$00,$00  ; />   /
BONUS_DIG = *-Z2+RAM2_STUFF
 .byte $00,$00,$00,$00,$00,$00,$00,$00  ; /        /
 .byte $00,$00,$00  ; /   /
 .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$1C  ; /            </
 .byte $74,$75,$76,$77,$78,$79,$7A,$7B,$7C,$7D,$7E,$7F
 .byte $1F,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; /?              /
Z2_LEN   = *-Z2-1
;
; EOF
;
