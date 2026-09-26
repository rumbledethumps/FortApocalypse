;
; FILE: FORT5.S
;
; MOVE SLAVES
; FUEL BASE
; SET SCANNER
; CHECK FORT
;
; LINE INTERUPTS
; SOUNDS
;
;
DO_CHECKSUM2:
         LDY #0
         STY TEMP1
         STY ADR1
         LDA #$90
         STA ADR1+1
         CLC
;
@1:      ADC (ADR1),Y
         BCC @2
         INC TEMP1
@2:      INY
         BNE @1
         INC ADR1+1
         LDX ADR1+1
         CPX #$B0
         BNE @1
         CMP #0
         BNE @4
         LDA TEMP1
         CMP #0
         BEQ @3
@4:      .byte $12
@3:      RTS
;
MOVE_SLAVES:
         LDX SLAVE_NUM
;
@1:      LDA SLAVE_STATUS,X
;
         CMP #OFF
         BEQ @3
;
         CMP #PICKUP
         BNE @2
         JSR S_COL2
         LDX #$00
         STX AUDC3
         LDY #$08
         JSR INC_SCORE
         INC SLAVES_SAVED
         JMP @3
;
@2:      JSR S_COL
         BCS @3
         JSR S_ERASE
         JSR S_MOVE
         JSR S_DRAW
         DEC S_MOVE         ; PROT
;
@3:      LDX SLAVE_NUM
         INX
         CPX #8
         BCC @4
@9:      LDX #0
@4:      STX SLAVE_NUM
         LDA PLAY_SCRN+5
         BEQ @5
         DEC TIM9_VAL
         BNE @5
         JSR CLEAR_INFO
@5:      RTS
;
GET_SLAVE_ADR:
         LDA SLAVE_X,X
         STA TEMP1
         LDA SLAVE_Y,X
         STA TEMP2
         JMP COMPUTE_MAP_ADR
;
S_COL:
         JSR GET_SLAVE_ADR
         LDY #0
         LDA (ADR1),Y
;        CMP #0
         BEQ @1
         CMP #EXP
         BEQ @1
         CMP #MISS_LEFT
         BEQ @1
         CMP #MISS_RIGHT
         BEQ @1
         DEC ADR1+1
         LDA (ADR1),Y
;        CMP #0
         BEQ @1
         CMP #EXP
         BEQ @1
         CMP #MISS_LEFT
         BEQ @1
         CMP #MISS_RIGHT
         BEQ @1
         CLC
         RTS
@1:
S_COL2:
         JSR S_ERASE
         LDA #OFF
         STA SLAVE_STATUS,X
         DEC SLAVES_LEFT
PRINT_SLAVES_LEFT:
         LDA #9
         STA TEMP1
         LDA #0
         STA TEMP2
         LDX #<SLAVE_PICKUP_MESS
         LDY #>SLAVE_PICKUP_MESS
         JSR PRINT
         LDA SLAVES_LEFT
         ORA #$10+128
         STA PLAY_SCRN+5
         CMP #$10+128
         BNE @1
         LDA #$A+128
@1:      AND #$8F
         STA PLAY_SCRN+6
         LDA #90
         STA TIM9_VAL
         SEC
         RTS
;
S_ERASE:
         JSR GET_SLAVE_ADR
         LDY #0
         LDA #$48    ; '^H'
         STA (ADR1),Y
         DEC ADR1+1
         LDA #$1F    ; '?'
         STA (ADR1),Y
         RTS
;
S_MOVE:
@0:      LDA SLAVE_DX,X
         BMI @2
         INC SLAVE_DX,X
         LDA SLAVE_DX,X
         AND #$01
         ORA #$10
         STA SLAVE_DX,X
         INC SLAVE_X,X
@1:      JMP @3
@2:      DEC SLAVE_DX,X
         LDA SLAVE_DX,X
         AND #$01
         ORA #$F0
         STA SLAVE_DX,X
         DEC SLAVE_X,X
@3:      JSR GET_SLAVE_ADR
         LDY #0
         LDA (ADR1),Y
         CMP #$48
         BEQ @4
         LDA SLAVE_DX,X
         EOR #$E0
         STA SLAVE_DX,X
         JMP @0
@4:      RTS
;
S_DRAW:
         JSR GET_SLAVE_ADR
         LDY #0
         LDA SLAVE_DX,X
         PHA
         AND #$03
         TAX
         PLA
         BPL @1
;
         LDA SLAVE_CHR_B_L,X
         STA (ADR1),Y
         DEC ADR1+1
         LDA SLAVE_CHR_T_L,X
         STA (ADR1),Y
         RTS
;
@1:      LDA SLAVE_CHR_B_R,X
         STA (ADR1),Y
         DEC ADR1+1
         LDA SLAVE_CHR_T_R,X
         STA (ADR1),Y
         RTS
;
PICK_UP_SLAVE:
         LDX #8-0
@0:      DEX
         BPL @1
         CLC
         RTS
;
@1:      LDA SLAVE_STATUS,X
         CMP #OFF
         BEQ @0
         LDA SLAVE_X,X
         SEC
         SBC CHOP_X
         BPL @2
         EOR #<-2
@2:      CMP #4
         BCS @0
         LDA SLAVE_Y,X
         SEC
         SBC CHOP_Y
         BPL @3
         EOR #<-2
@3:      CMP #4
         BCS @0
         LDA #PICKUP
         STA SLAVE_STATUS,X
         LDA #$A8
         STA AUDC3
         LDA #32
         STA AUDF3
;
         SEC
         RTS
;
SLAVE_CHR_T_L:
 .byte $4A,$4A
SLAVE_CHR_T_R:
 .byte $49,$49
LAND_CHR:
SLAVE_CHR_B_L:
 .byte $3E,$3D
SLAVE_CHR_B_R:
 .byte $3B,$3C
 .byte $44
LAND_LEN = *-LAND_CHR-1
SLAVE_PICKUP_MESS:
 .byte $AD,$A5,$AE  ; -/MEN/
 .byte $00,$00  ; /  /
 .byte $B4,$AF  ; -/TO/
 .byte $00,$00  ; /  /
 .byte $B2,$A5,$B3,$A3,$B5,$A5  ; -/RESCUE/
 .byte $FF
;
CHECK_FUEL_BASE:
         LDA FUEL_STATUS
         CMP #REFUEL
         BNE @3
         JMP RE_FUEL
@3:      LDA CHOPPER_STATUS
         CMP #LAND
         BNE @9
         LDA CHOP_Y
         CMP #7+2
         BCC @9
         CMP #11+2
         BCS @9
         LDX CHOP_X
         LDA LEVEL
;        CMP #0
         BNE @1
         CPX #$15+2
         BCC @9
         CPX #$EC+2+6
         BCS @9
         JMP @2
@1:      CPX #$82
         BCC @9
         CPX #$82+6
         BCS @9
@2:      LDA #REFUEL
         STA FUEL_STATUS
         ASL COMPUTE_MAP_ADR ; PROT
         LDA #1
         STA TIM4_VAL
         LDA #4
         STA FUEL_TEMP
@9:
         LDA #0
         LDX FUEL_STATUS
         CPX #REFUEL
         BEQ @11
         LDA FUEL2
         BNE @20
;
         LDA FRAME
         AND #%00001000
         BNE @10
         LDA #9
         STA TEMP1
         LDA #0
         STA TEMP2
         LDA #$A4
         STA AUDC2
         STA AUDF2
         LDX #<WARNING
         LDY #>WARNING
         JSR PRINT
         JMP @20
@10:     LDA #$A4
@11:     STA AUDC2
         LDA #$88
         STA AUDF2
         JSR CLEAR_INFO
@20:     RTS
;
WARNING:
 .byte $AC,$AF,$B7  ; -/LOW/
 .byte $00,$00  ; /  /
 .byte $AF,$AE  ; -/ON/
 .byte $00,$00  ; /  /
 .byte $A6,$B5,$A5,$AC  ; -/FUEL/
 .byte $FF
;
RE_FUEL:
         DEC TIM4_VAL
         BNE FE
         LDA #1
         STA TIM4_VAL
         LDA FUEL_TEMP
         BMI F1
DF1:     LDA #9+2
         STA TEMP2
         LDA FUEL_TEMP
         STA TEMP3
         LDX LEVEL
         DEX         ; X=1?
         BEQ @1
         LDA #$15+2
         STA TEMP1
         JSR DRAW_BASE
         LDA #$EC+2
         BNE @2      ; FORCED
@1:      LDA #$82
@2:      STA TEMP1
         JSR DRAW_BASE
         DEC FUEL_TEMP
FE:      RTS
;
F1:      LDX #1
         LDA CHOP_Y
         CMP #11+2
         BCS @1
         LDX #0
         STX AUDC2
@1:      STX S4_VAL
         LDA CHOP_Y
         CMP #8+2
         BCS FE
         LDA #FULL
         STA FUEL_STATUS
         LDA #4
         STA FUEL_TEMP
         JSR DF1
         JMP SAVE_POS
;
DRAW_BASE:
         JSR COMPUTE_MAP_ADR
         LDA #4
         STA TEMP4
         LDA TEMP3
         ASL
         CLC
         ADC TEMP3
         ASL
         TAX
@1:      LDY #0
@2:      LDA BASE_SHAPE,X
         STA (ADR1),Y
         INX
         INY
         CPY #6
         BNE @2
         INC ADR1+1
         DEC TEMP4
         BPL @1
         RTS
;
BASE_SHAPE:
 .byte $00,$00,$00,$00,$00,$00  ; 0
 .byte $00,$00,$00,$00,$00,$00  ; 1
 .byte $00,$00,$00,$00,$00,$00  ; 2
 .byte $00,$00,$00,$00,$00,$00  ; 3
 .byte $44,$44,$44,$44,$44,$44  ; 4
 .byte $55,$58,$58,$58,$58,$56  ; 5
 .byte $55,$26,$35,$25,$2C,$56  ; 6
 .byte $55,$58,$58,$58,$58,$56  ; 7
 .byte $54,$00,$00,$00,$00,$54  ; 8
;
SET_SCANNER:
         LDA #0
         STA TEMP1
         STA TEMP2
         INC DRAW_MAP       ; PROT
         LDA SY
         BEQ @2
         BMI @2
         CMP #17
         BCC @1
         LDA #16
@1:      JSR MULT_BY_40
@2:      LDA SX
         LSR
         LSR
         LSR
         CLC
         ADC #<SCANNER
         ADC TEMP1
         STA ADR1
         LDA #>SCANNER
         ADC TEMP2
         STA ADR1+1
         LDA ADR1
         STA SCAN_ADR1
         LDA ADR1+1
         STA SCAN_ADR1+1
         LDA #<S_LINE1
         STA SCAN_ADR2
         STA ADR2
         LDA #>S_LINE1
         STA SCAN_ADR2+1
         STA ADR2+1
         JSR DO_LINE
         LDA #<S_LINE2
         STA SCAN_ADR2
         STA ADR2
         LDA #>S_LINE2
         STA SCAN_ADR2+1
         STA ADR2+1
         JSR DO_LINE
         LDA #<S_LINE3
         STA SCAN_ADR2
         STA ADR2
         LDA #>S_LINE3
         STA SCAN_ADR2+1
         STA ADR2+1
         JMP DO_LINE
@3:      RTS
;
POS_IT:
         STX TEMP3
         LDX TEMP1
         LDA TEMP2
         JSR MULT_BY_40
         TXA
         LSR
         LSR
         LSR
         CLC
         ADC #<(SCANNER+3)
         ADC TEMP1
         STA ADR2
         LDA #>SCANNER
         ADC TEMP2
         STA ADR2+1
         TXA
         AND #7
         TAX
         LDY #0
         LDA (ADR2),Y
         EOR POS_MASK1,X
         STA (ADR2),Y
         LDX TEMP3
         RTS
;
MULT_BY_40:
         STA TEMP1
         ASL
         ASL
         ADC TEMP1
;
         LDY #0
         STY TEMP2
         ASL
         ROL TEMP2
         ASL
         ROL TEMP2
         ASL
         ROL TEMP2
         STA TEMP1
         RTS
;
DO_LINE:
         LDA #7
         STA TEMP1
@0:      LDX #12
         LDY #0
@1:      LDA (ADR1),Y
         STA (ADR2),Y
         INC ADR1
         BNE @2
         INC ADR1+1
@2:      LDA ADR2
         CLC
         ADC #8
         STA ADR2
         LDA ADR2+1
         ADC #0
         STA ADR2+1
         DEX
         BNE @1
         LDA SCAN_ADR1
         CLC
         ADC #40
         STA SCAN_ADR1
         STA ADR1
         LDA SCAN_ADR1+1
         ADC #0
         STA SCAN_ADR1+1
         STA ADR1+1
         INC SCAN_ADR2
         BNE @3
         INC SCAN_ADR2+1
@3:      LDA SCAN_ADR2
         STA ADR2
         LDA SCAN_ADR2+1
         STA ADR2+1
         DEC TEMP1
         BPL @0
         RTS
;
CHECK_FORT:
         LDA FORT_STATUS
         CMP #EXPLODE
         BEQ @1
         RTS
;
@1:
DO_CHECKSUM1:
         LDY #0
         STY TEMP1
         STY ADR1
         LDA #$90
         STA ADR1+1
         CLC
;
@1:      ADC (ADR1),Y
         BCC @2
         INC TEMP1
@2:      INY
         BNE @1
         INC ADR1+1
         LDX ADR1+1
         CPX #$B0
         BNE @1
         CMP #0
         BNE @4
         LDA TEMP1
         CMP #0
         BEQ @3
@4:      .byte $12
@3:
;
NEXT_PART1:
         LDX #$00
         LDY #$50
         JSR INC_SCORE
         JSR GIVE_BONUS
         LDA #STOP_MODE
         STA MODE
         LDA #$99
         STA BONUS1
         STA BONUS2
         LDA #$76
         STA LAND_CHOP_X
         LDA #$A0
         STA LAND_CHOP_Y
         LDA #$6E
         STA LAND_X
         LDA #$11
         STA LAND_Y
         LDA #$07
         STA LAND_FX
         LDA #$96
         STA LAND_FY
         LDA #8
         STA LAND_CHOP_ANGLE
         LDX #16-1
         LDA #0
@90:     STA WINDOW_1,X
         DEX
         BPL @90
         LDA #0
         STA TEMP3
         STA TEMP4
         STA TEMP6
@2:      LDA #121
         STA TEMP1
         LDA #20
         STA TEMP2
         JSR COMPUTE_MAP_ADR
         LDA TEMP3
         ASL
         TAX
         LDA FORT_EXP,X
         STA ADR2
         LDA FORT_EXP+1,X
         STA ADR2+1
@3:      LDY TEMP4
         LDA (ADR2),Y
         STA TEMP5
         LDY #7+8+8
@4:      LDX #2
         LDA #0
         ROR TEMP5
         BCC @5
         LDA #EXP
@5:      STA (ADR1),Y
         DEY
         DEX
         BPL @5
         TYA
         BPL @4
         INC ADR1+1
         INC TEMP6
         LDA TEMP6
         CMP #3
         BNE @3
         LDA #0
         STA TEMP6
         INC TEMP4
         LDA TEMP4
         CMP #6
         BNE @3
         LDA #0
         STA TEMP4
         LDA #$10
         STA BAK2_COLOR
         LDA #$CF
         STA AUDC4
         LDY #15
@6:      LDX #2
         JSR WAIT_FRAME
         INC BAK2_COLOR
         LDA #1
         STA S3_VAL
         LDA RANDOM
         STA AUDF4
         DEY
         BPL @6
         LDA #0
         STA BAK2_COLOR
         INC TEMP3
         LDA TEMP3
         CMP #4
         BNE @2
         LDA #GO_MODE
         STA MODE
         LDA #OFF
         STA FORT_STATUS
         STA LASER_STATUS
;
         JMP CLEAR_SOUNDS
;
FORT_EXP:
 .word FORT_EX1,FORT_EX2
 .word FORT_EX3,FORT_EX4
;
LINE1:   PHA
         TXA
         PHA
         LDA #<LINE2
         STA VDSLST
         LDA #>LINE2
         STA VDSLST+1
;
         LDX #0
@1:      TXA
         STA WSYNC
         ASL
         ORA #$E0
         STA COLBK
         INX
         CPX #8
         BNE @1
;
         BEQ LINEC   ; FORCED
;
LINE2:
         PHA
         TXA
         PHA
         LDA #<LINE3
         STA VDSLST
         LDA #>LINE3
         STA VDSLST+1
         LDX #2
@0:      LDA ROCKET_X,X
         STA HPOSM0,X
         DEX
         BPL @0
;
         LDX #7
@1:      TXA
         STA WSYNC
         ASL
         ORA #$E0
         STA COLBK
         DEX
         BPL @1
;
LINEC:   LDA #0
         STA COLBK
         PLA
         TAX
         PLA
         RTI
;
LINE3:
         PHA
         PHP
         CLD
         LDA #<LINE4
         STA VDSLST
         LDA #>LINE4
         STA VDSLST+1
         LDA ROBOT_X
         STA HPOSP2
         CLC
         ADC #8
         STA HPOSP3
         LDA #>CHR_SET2
         STA WSYNC
         STA CHBASE
         LDA BAK_COLOR
         STA COLPF0
         LDA #$0A
         STA COLPF1
         LDA #$93
         STA COLPF2
         LDA FRAME
         STA COLPF3
         STA WSYNC
         LDA BAK2_COLOR
         STA COLBK
         PLP
         PLA
         RTI
;
LINE4:
         PHA
         TXA
         PHA
         TYA
         PHA
         PHP
;
         CLD
         LDA #<LINE1
         STA VDSLST
         LDA #>LINE1
         STA VDSLST+1
         LDX #7
         LDA #0
@0:      STA HPOSP0,X
         DEX
         BPL @0
         STA WSYNC
         STA COLBK
         LDA MODE
         CMP #STOP_MODE
         BEQ @1
         CMP #GO_MODE
         BNE @2
@1:      JSR DO_SOUNDS
;
@2:      PLP
         PLA
         TAY
         PLA
         TAX
         PLA
         RTI
;
DO_CHECKSUM3:
         LDX #0
         TXA
         CLC
@1:      ADC $B980,X
         INX
         BNE @1
         CMP #$0
         BEQ @2
         .byte $12
@2:      RTS
;
DO_SOUNDS:
;
; CHOPPER SOUND
S1:
         LDA CHOPPER_STATUS
         CMP #OFF
         BEQ @2
         LDA FRAME
         AND #2
         BNE @2
         LDA #$83
         STA AUDC1
         LDA S1_1_VAL
         BPL @1
         LDA S1_2_VAL
@1:      SEC
         SBC #4
         STA S1_1_VAL
         STA AUDF1
@2:
; MISSILE SOUND
S2:
         LDA S2_VAL
         BMI @2
         EOR #$3F
         CLC
         ADC #16
         STA AUDF2
         LDX #$86
         CMP #$3F+16
         BNE @1
         LDX #0
@1:      STX AUDC2
         DEC S2_VAL
@2:
; EXPLOSION
S3:
         LDA S3_VAL
         BEQ @3
         LDA RANDOM
         AND #3
         ORA S3_VAL
         ADC #$10
         STA AUDF3
         INC S3_VAL
         LDA S3_VAL
         CMP #$31
         BNE @1
         LDA #0
         STA S3_VAL
@1:      LDX #$48
         CMP #0
         BNE @2
         TAX         ; X=0
@2:      STX AUDC3
@3:
; RE-FUEL
S4:
         LDA S4_VAL
         BEQ @3
         LDX #0
         LDA FRAME
         AND #7
         BEQ @1
         LDX #$18
@1:
;
         LDY #$00
         LDA FUEL1
         CMP #<MAX_FUEL
         LDA FUEL2
         SBC #>MAX_FUEL
         BCS @2
         LDY #$A6
         SED
         LDA FUEL1
         CLC
         ADC #4
         STA FUEL1
         LDA FUEL2
         ADC #0
         STA FUEL2
         CLD
@2:      STX AUDF2
         STY AUDC2
@3:
;
; HYPER CHAMBER SOUND
;
S5:      LDA S5_VAL
         BEQ @2
         INC S5_VAL
         CMP #$50
         BNE @1
         LDA #0
         STA S5_VAL
@1:      STA AUDF2
         LDA #$A8
         STA AUDC2
@2:
;
; CRUISE MISSILE SOUND
;
S6:      LDA FRAME
         AND #1
         BNE @2
         LDA S6_VAL
         BEQ @2
         INC S6_VAL
         CMP #$20
         BCC @1
         LDX #0
         STX S6_VAL
@1:      STA AUDF4
         LDA #$07
         STA AUDC4
@2:      RTS
; EOF
;
;
