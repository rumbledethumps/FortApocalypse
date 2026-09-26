;
; FILE: FORT6.S
;
; DATA, SHAPES, DISPLAY LISTS
;
;
DSP_LST2:
         .byte $70,$70,$80,$70
         .byte $44
         .word PANEL
         .byte $04,$04,$04,$04,$70
         .byte $70
         .byte $80,$50,$20
         .byte $44
         .word PLAY_SCRN
         .byte $04,$04,$04,$04,$04,$04,$04
         .byte $04,$04,$04,$04,$04,$04,$04
         .byte $80,$70,$80
         .byte $41
         .word DSP_LST2
;
DSP_LST3:
         .byte $70,$70,$70,$70,$70,$70
         .byte $44
         .word PLAY_SCRN
         .byte $04,$04,$04,$04,$04,$04,$04,$04,$04
         .byte $04,$04,$04,$04,$04,$04,$04,$04
         .byte $44
         .word PLAY_SCRN
         .byte $41
         .word DSP_LST3
;
CART_START:
         SEI
         LDX #$FF
         TXS
         PHA
         PHA
         LDA #$B3
         PHA
         LDX #0
         TXA
@1:      STA 0,X
         STA $D000,X
         STA $D400,X
         STA $D200,X
         STA $D300,X
         INX
         BNE @1
;
         LDY #1
         STY ADR1+1
         DEY         ; Y=0
         STY ADR1
;
@2:      STA (ADR1),Y
         INY
         BNE @2
         INC ADR1+1
         LDX ADR1+1
         CPX #$50
         BNE @2
         LDA #$34
         PHA
;
         LDX #0
@3:      LDA BOOT_STUFF,X
         STA $180+$40,X
         INX
         BPL @3
;
;        CLI
         RTS
;
CHOPPER_SHAPES:
 .word CL3_1,CL3_2   ; 0   ANGLE
 .word CL2_1,CL2_2   ; 2
 .word CL1_1,CL1_2   ; 4
 .word CM1_1,CM1_2   ; 6
 .word CM1_1,CM1_2   ; 8
 .word CM1_1,CM1_2   ; 10
 .word CR1_1,CR1_2   ; 12
 .word CR2_1,CR2_2   ; 14
 .word CR3_1,CR3_2   ; 16
;
CL1_1:
 .byte $00,$00,$FF,$01,$01,$0F,$11
 .byte $21,$31,$7F,$70,$3F,$1F,$10
 .byte $A0,$7F,$00,$00
;
 .byte $00,$00,$C0,$00,$02,$02,$82
 .byte $FE,$0F,$79,$61,$C1,$C0,$40
 .byte $20,$FC
;.HS 0000
CL1_2:
 .byte $00,$00,$07,$01,$01,$0F,$11
 .byte $21,$31,$7F,$70,$3F,$1F,$10
 .byte $A0,$7F,$00,$00
;
 .byte $00,$00,$FE,$00,$01,$01,$81
 .byte $FF,$0E,$7A,$62,$C2,$C0,$40
 .byte $20,$FC
;.HS 0000
CL2_1:
 .byte $00,$00,$07,$F9,$01,$07,$09
 .byte $11,$21,$37,$7C,$73,$3F,$18
 .byte $10,$A7,$78,$00
;
 .byte $00,$00,$C0,$02,$02,$02,$9E
 .byte $FF,$19,$71,$61,$C0,$C0,$60
 .byte $3C,$C0
;.HS 0000
CL2_2:
 .byte $00,$00,$07,$01,$01,$07,$09
 .byte $11,$21,$37,$7C,$73,$3F,$18
 .byte $10,$A7,$78,$00
;
 .byte $00,$3E,$C0,$01,$01,$01,$9F
 .byte $FE,$1A,$72,$62,$C0,$C0,$60
 .byte $3C,$C0
;.HS 0000
CL3_1:
 .byte $00,$00,$03,$3D,$C1,$03,$0D
 .byte $11,$21,$23,$6E,$79,$67,$3E
 .byte $10,$11,$9E,$60
;
 .byte $00,$00,$80,$02,$02,$02,$8E
 .byte $FF,$39,$61,$61,$C0,$C0,$60
 .byte $3C,$E0
;.HS 0000
CL3_2:
 .byte $00,$00,$03,$01,$01,$03,$0D
 .byte $11,$21,$23,$6E,$79,$67,$3E
 .byte $10,$11,$9E,$60
;
 .byte $06,$78,$80,$01,$01,$01,$8F
 .byte $FE,$3A,$62,$62,$C0,$C0,$60
 .byte $3C,$E0
;.HS 0000
CM1_1:
 .byte $00,$00,$07,$00,$00,$01,$03
 .byte $06,$04,$08,$0D,$07,$03,$04
 .byte $08,$1C,$00,$00
;
 .byte $00,$00,$FF,$80,$80,$C0,$E0
 .byte $30,$10,$08,$D8,$F0,$E0,$10
 .byte $08,$1C
;.HS 0000
CM1_2:
 .byte $00,$00,$7F,$00,$00,$01,$03
 .byte $06,$04,$08,$0D,$07,$03,$04
 .byte $08,$1C,$00,$00
;
 .byte $00,$00,$E0,$80,$80,$C0,$E0
 .byte $30,$10,$08,$D8,$F0,$E0,$10
 .byte $08,$1C
;.HS 0000
CR1_1:
 .byte $00,$00,$03,$00,$40,$40,$41
 .byte $7F,$F0,$9E,$86,$83,$03,$02
 .byte $04,$3F,$00,$00
;
 .byte $00,$00,$FF,$80,$80,$F0,$88
 .byte $84,$8C,$FE,$0E,$FC,$F8,$08
 .byte $05,$FE
;.HS 0000
CR1_2:
 .byte $00,$00,$7F,$00,$80,$80,$81
 .byte $FF,$70,$5E,$46,$43,$03,$02
 .byte $04,$3F,$00,$00
;
 .byte $00,$00,$E0,$80,$80,$F0,$88
 .byte $84,$8C,$FE,$0E,$FC,$F8,$08
 .byte $05,$FE
;.HS 0000
CR2_1:
 .byte $00,$00,$03,$40,$40,$40,$79
 .byte $FF,$98,$8E,$86,$03,$03,$06
 .byte $3C,$03,$00,$00
;
 .byte $00,$00,$E0,$9F,$80,$E0,$90
 .byte $88,$84,$EC,$3E,$CE,$FC,$18
 .byte $08,$E5,$1E
;.HS 00
CR2_2:
 .byte $00,$7C,$03,$80,$80,$80,$F9
 .byte $7F,$58,$4E,$46,$03,$03,$06
 .byte $3C,$03,$00,$00
;
 .byte $00,$00,$E0,$80,$80,$E0,$90
 .byte $88,$84,$EC,$3E,$CE,$FC,$18
 .byte $08,$E5,$1E
;.HS 00
CR3_1:
 .byte $00,$00,$01,$40,$40,$40,$71
 .byte $FF,$9C,$86,$86,$03,$03,$06
 .byte $3C,$07,$00,$00
;
 .byte $00,$00,$C0,$BC,$83,$C0,$B0
 .byte $88,$84,$C4,$76,$9E,$E6,$7C
 .byte $08,$88,$79,$06
CR3_2:
 .byte $60,$1E,$01,$80,$80,$80,$F1
 .byte $7F,$5C,$46,$46,$03,$03,$06
 .byte $3C,$07,$00,$00
;
 .byte $00,$00,$C0,$80,$80,$C0,$B0
 .byte $88
BOOT_STUFF:
 .byte $84,$C4,$76,$9E,$E6,$7C
 .byte $08,$88,$79,$06
;
INIT_OS:
         LDA $E463
         STA $224
         LDA $E464
         STA $225
         LDA $E460
         STA $222
         LDA $E461
         STA $223
         RTS
;
         .byte "f3DSdsIaApPLa;"
         .byte "Steve Hales"
;
         .word INIT_OS-1
         .word START-1
;
LASER_SHAPES:
 .byte %11000000
 .byte %11000000
 .byte %00110000
 .byte %00110000
 .byte %00001100
 .byte %00001100
 .byte %00000011
 .byte %00000011
;
 .byte %00000011
 .byte %00000011
 .byte %00001100
 .byte %00001100
 .byte %00110000
 .byte %00110000
 .byte %11000000
 .byte %11000000
;
 .byte %00000000
 .byte %00000000
 .byte %00000000
 .byte %11111111
 .byte %11111111
 .byte %00000000
 .byte %00000000
 .byte %00000000
;
 .byte %00110000
 .byte %00110000
 .byte %00110000
 .byte %00110000
 .byte %00110000
 .byte %00110000
 .byte %00110000
 .byte %00110000
;
; EOF
;
