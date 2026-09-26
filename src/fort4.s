;
; FILE: FORT4.S
;
; MAIN INTERUPT DRIVER
;        PART (II)
; POSITION THINGS
; READ.STICK
; READ.TRIG
; DO.LASER.1
; DO.LASER.2
; DO.BLOCKS
; DO.ELEVATOR
; DO.EXP
; DO.NUMBERS
; DRAW.MAP
;
POS_CHOPPER:
         LDA CHOP_X
         STA TEMP1_I
         LDA CHOP_Y
         STA TEMP2_I
         JMP POS_IT_I
;
POS_ROBOT:
         LDA R_X
         STA TEMP1_I
         LDA R_Y
         STA TEMP2_I
;        JMP POS.IT.I
;
POS_IT_I:
         LDX TEMP1_I
         LDA TEMP2_I
;
         ASL
         ASL
         ADC TEMP2_I
         LDY #0
         STY TEMP3_I
         ASL
         ROL TEMP3_I
         ASL
         ROL TEMP3_I
         ASL
         ROL TEMP3_I
         STA TEMP2_I
;
         TXA
         LSR
         LSR
         LSR
         CLC
         ADC #<(SCANNER+3)
         ADC TEMP2_I
         STA ADR1_I
         LDA #>SCANNER
         ADC TEMP3_I
         STA ADR1_I+1
         TXA
         AND #7
         TAX
         LDY #0
         LDA (ADR1_I),Y
         EOR POS_MASK1,X
         STA (ADR1_I),Y
         RTS
;
READ_STICK:
         LDA CHOPPER_STATUS
         CMP #OFF
         BEQ @1
         CMP #CRASH
         BNE DO_STICK
@1:      RTS
DO_STICK:
         LDA CHOPPER_ANGLE
         AND #1
         STA TEMP1_I
         LDA CHOPPER_ANGLE
         AND #$FE
         STA CHOPPER_ANGLE
         LDA DEMO_STATUS
;        CMP #0      ON
         BNE @20
         LDX DEMO_COUNT
         LDA DEMO_STICK,X
         STA STICK
         LDA FRAME
         AND #$F
         BNE @20
         INX
         CPX #$6C
         BCC @19
         LDX #0
@19:     STX DEMO_COUNT
@20:     LDX STICK
         CPX #$F
         BNE @0
         JSR HOVER
         LDA #20
         STA S1_2_VAL
@0:      LDA FUEL_STATUS
         CMP #EMPTY
         BNE @10
         LDA #60
         STA S1_2_VAL
@10:     TXA
         AND #RIGHT
         BNE @1
         LDA #17
         STA S1_2_VAL
         LDA CHOPPER_ANGLE
         CMP #14
         BCS @70
         LDA FRAME
         AND #1
         BNE @71
@70:     INC CHOPPER_X
@71:     LDA FRAME
         AND #3
         BNE @1
         INC CHOPPER_ANGLE
         INC CHOPPER_ANGLE
@1:      TXA
         AND #LEFT
         BNE @2
         LDA #17
         STA S1_2_VAL
         LDA CHOPPER_ANGLE
         CMP #4
         BCC @73
         LDA FRAME
         AND #1
         BNE @74
@73:     DEC CHOPPER_X
@74:     LDA FRAME
         AND #3
         BNE @2
         DEC CHOPPER_ANGLE
         DEC CHOPPER_ANGLE
@2:      LDA FUEL_STATUS
         CMP #EMPTY
         BEQ @3
         TXA
         AND #UP
         BNE @3
         LDA #13
         STA S1_2_VAL
         DEC CHOPPER_Y
         JSR HOVER
@3:      TXA
         AND #DOWN
         BNE @4
         LDA #26
         STA S1_2_VAL
         LDA CHOPPER_STATUS
         CMP #LAND
         BEQ @4
         CMP #PICKUP
         BEQ @4
         INC CHOPPER_Y
         JSR HOVER
;
@4:      LDA CHOPPER_ANGLE
         BPL @5
         LDA #0
         STA CHOPPER_ANGLE
@5:      CMP #18
         BCC @6
         LDA #16
         STA CHOPPER_ANGLE
@6:      LDA CHOPPER_ANGLE
         ORA TEMP1_I
         STA CHOPPER_ANGLE
         RTS
;
READ_TRIG:
         LDA CHOPPER_STATUS
         CMP #CRASH
         BEQ @2
;
         LDA DEMO_STATUS
;        CMP #0      ON
         BNE @9
         LDA FRAME
         AND #$F
         BEQ @10
         RTS
;
@9:      LDX TRIG0
         BEQ @0
         STX TRIG_FLAG
         RTS
@0:      LDA TRIG_FLAG
         BEQ @2
         STX TRIG_FLAG
         LDA MODE
         CMP #TITLE_MODE
         BEQ @30
         CMP #OPTION_MODE
         BNE @10
@30:     LDA #START_MODE
         STA MODE
;        LDA #1
         STA DEMO_STATUS
@10:     LDA ELEVATOR_DX
         EOR #<-2
         STA ELEVATOR_DX
         LDX #1
@1:      LDA ROCKET_STATUS,X
         BEQ @3
         DEX
         BPL @1
@2:      RTS
;
@3:      LDA CHOPPER_ANGLE
         AND #%00011110
         LSR
         CMP #4
         BCC @6
         CMP #6
         BCS @7
         LDA #3
         BNE @6
@7:      SEC
         SBC #2
@6:      CMP #6
         BCC @4
         LDA #5
@4:      CMP #0
         BNE @5
         LDA #1
@5:      STA ROCKET_STATUS,X
         LDA CHOPPER_X
         AND #3
         CLC
         ADC CHOPPER_X
         ADC #8
         STA ROCKET_X,X
         LDA CHOPPER_Y
         CLC
         ADC #8
         STA ROCKET_Y,X
         LDA #$3F
         STA S2_VAL
         RTS
;
HOVER:   LDA FRAME
         AND #7
         BNE @2
         LDA CHOPPER_ANGLE
         CMP #4
         BCC @3
         CMP #14
         BCC @2
@3:      CMP #8
         BCS @1
         INC CHOPPER_ANGLE
         INC CHOPPER_ANGLE
         RTS
@1:      DEC CHOPPER_ANGLE
         DEC CHOPPER_ANGLE
@2:      RTS
;
DRAW_MAP:
DO_X:
         LDX CHOPPER_X
         CPX #MIN_RIGHT+1
         BCC @2
         LDX #MIN_RIGHT
         STX CHOPPER_X
         LDA SX
         CMP #$D8+1
         BCC @1
         LDA #1+1
         STA SX
@1:      DEC SX_F
         LDA SX_F
         AND #3
         EOR #3
         BNE @2
         INC SX
;
@2:      CPX #MIN_LEFT
         BCS @4
         LDX #MIN_LEFT
         STX CHOPPER_X
         LDA SX
         CMP #1+1+1
         BCS @3
         LDA #$D8+1
         STA SX
@3:      INC SX_F
         LDA SX_F
         AND #3
;        EOR #0
         BNE @4
         DEC SX
@4:
DO_Y:
         LDA SY
         CMP #24
         BEQ @80
         LDX CHOPPER_Y
         CPX #MIN_DOWN+1
         BCC @80
         LDX #MIN_DOWN
         STX CHOPPER_Y
         BNE @21     ; FORCED
@80:     LDX CHOPPER_Y
         CPX #MAX_DOWN+1
         BCC @3
         LDA #MAX_DOWN
         STA CHOPPER_Y
         LDA SY_F
         AND #7
;        EOR #0
         BNE @21
         LDA SY
         CMP #24
         BEQ @3
@21:     INC SY_F
         LDA SY_F
         AND #7
;        EOR #0
         BNE @3
         INC SY
@3:      LDA SY
         CMP #<-1
         BEQ @81
         CPX #MIN_UP
         BCS @81
         LDX #MIN_UP
         STX CHOPPER_Y
         BNE @31     ; FORCED
@81:     CPX #MAX_UP
         BCS @4
         LDA #MAX_UP
         STA CHOPPER_Y
         LDA SY_F
         AND #7
         EOR #7
         BNE @31
         LDA SY
         CMP #<-1
         BEQ @4
@31:     DEC SY_F
         LDA SY_F
         AND #7
         EOR #7
         BNE @4
         DEC SY
;
@4:      LDA SX_F
         AND #3
         STA HSCROL
         LDA SY_F
         AND #7
         STA VSCROL
         LDA SX
         STA TEMP1_I
         LDA SY
         STA TEMP2_I
         JSR COMPUTE_MAP_ADR_I
         LDX #0
         LDY #MAP_LINES
@5:      INX
         LDA ADR1_I
         STA DSP_MAP,X
         INX
         LDA ADR1_I+1
         STA DSP_MAP,X
         INC ADR1_I+1
         INX
         DEY
         BNE @5
         RTS
;
COMPUTE_MAP_ADR_I:
         LDA #<(MAP-5)
         CLC
         ADC TEMP1_I
         STA ADR1_I
         LDA #>(MAP-5)
         ADC #0
         STA ADR1_I+1
         LDA TEMP2_I
         CLC
         ADC ADR1_I+1
         STA ADR1_I+1
         RTS
;
COMPUTE_MAP_ADR:
         LDA #<(MAP-5)
         CLC
         ADC TEMP1
         STA ADR1
         LDA #>(MAP-5)
         ADC #0
         STA ADR1+1
         LDA TEMP2
         CLC
         ADC ADR1+1
         STA ADR1+1
         RTS
;
DO_LASER_1:
         LDA FRAME
         AND #7
         BNE @4
         LDA LASER_STATUS
         CMP #OFF
         BEQ @2
         LDA TIM1_VAL
         CLC
         ADC LASER_SPD
         STA TIM1_VAL
         BNE @2
         LDX #0
@1:      LDA LASER_SHAPES,X
         STA LASERS_1,X
         INX
         CPX #32
         BNE @1
         LDX #0
@5:      LDA LASER_SHAPES+24,X
         STA LASER_3,X
         INX
         CPX #8
         BNE @5
         RTS
@2:      LDX #32-1
         LDA #0
@3:      STA LASERS_1,X
         DEX
         BPL @3
         LDX #8-1
;        LDA #0
@6:      STA LASER_3,X
         DEX
         BPL @6
@4:      RTS
;
DO_LASER_2:
         LDA FRAME
         AND #7
         BNE @4
         LDA LASER_STATUS
         CMP #OFF
         BEQ @2
         LDA TIM2_VAL
         CLC
         ADC LASER_SPD
         STA TIM2_VAL
         BNE @2
         LDX #0
@1:      LDA LASER_SHAPES,X
         STA LASERS_2,X
         INX
         CPX #32
         BNE @1
         LDX #0
@5:      LDA LASER_SHAPES+16,X
         STA LASER_3,X
         INX
         CPX #8
         BNE @5
         RTS
@2:      LDX #32-1
         LDA #0
@3:      STA LASERS_2,X
         DEX
         BPL @3
@4:      RTS
;
DO_BLOCKS:
         LDA FRAME
         AND #$7F
         BNE @9
         LDX #32-1
         LDA #0
@1:      STA BLOCK_1,X
         DEX
         BPL @1
         LDA RANDOM
         BMI @3
         LDX #7
         LDA #$55
@2:      STA BLOCK_1,X
         DEX
         BPL @2
@3:      LDA RANDOM
         BMI @5
         LDX #7
         LDA #$55
@4:      STA BLOCK_2,X
         DEX
         BPL @4
@5:      LDA RANDOM
         BMI @7
         LDX #7
         LDA #$55
@6:      STA BLOCK_3,X
         DEX
         BPL @6
@7:      LDA RANDOM
         BMI @9
         LDX #7
         LDA #$55
@8:      STA BLOCK_4,X
         DEX
         BPL @8
@9:      RTS
;
DO_ELEVATOR:
         DEC ELEVATOR_TIM
         BNE @3
         LDA ELEVATOR_SPD
         STA ELEVATOR_TIM
         LDX #32-1
         LDA #0
@1:      STA BLOCK_5,X
         DEX
         BPL @1
         LDA ELEVATOR_NUM
         CLC
         ADC ELEVATOR_DX
         STA ELEVATOR_NUM
         AND #3
         STA ELEVATOR_NUM
         ASL
         TAX
         LDA ELEVATORS,X
         STA ADR1_I
         LDA ELEVATORS+1,X
         STA ADR1_I+1
         LDY #7
         LDA #$55
@2:      STA (ADR1_I),Y
         DEY
         BPL @2
@3:      RTS
;
ELEVATORS:
 .word BLOCK_5,BLOCK_6
 .word BLOCK_7,BLOCK_8
;
DO_EXP:
         LDX #7
@1:      LDA EXP_SHAPE,X
         AND RANDOM
         STA EXPLOSION,X
         STA EXPLOSION2,X
         DEX
         BPL @1
         LDX #3
@2:      LDA RANDOM
         AND #$0F
         ORA #$A0
         STA MISS_CHR_LEFT,X
         INX
         CPX #5
         BNE @2
         LDX #3
@3:      LDA RANDOM
         AND #$E0
         ORA #$0A
         STA MISS_CHR_RIGHT,X
         INX
         CPX #5
         BNE @3
         RTS
;
DO_NUMBERS:
         LDA MODE
         CMP #NEW_PLAYER_MODE
         BEQ @1
         CMP #GAME_OVER_MODE
         BNE DO_N
@1:      RTS
; SCORE
DO_N:    LDA #<SCORE_DIG
         STA S_ADR
         LDA #>SCORE_DIG
         STA S_ADR+1
         LDA #0
         STA S_FLG
         LDX #5
         LDA SCORE3
         JSR DDIG
         LDA SCORE2
         JSR DDIG
         LDA SCORE1
         JSR DDIG
; DEC BONUS
         LDA MODE
         CMP #GO_MODE
         BNE @1
         LDA BONUS1
         ORA BONUS2
         BEQ @1
         LDA FRAME
         AND #7
         BNE @1
         SED
         LDA BONUS1
         SEC
         SBC #1
         STA BONUS1
         LDA BONUS2
         SBC #0
         STA BONUS2
         CLD
; BONUS
@1:      LDA #<BONUS_DIG
         STA S_ADR
         LDA #>BONUS_DIG
         STA S_ADR+1
         LDA #0
         STA S_FLG
         LDX #3
         LDA BONUS2
         JSR DDIG
         LDA BONUS1
         JSR DDIG
; DEC FUEL
         LDA MODE
         CMP #GO_MODE
         BNE @4
         LDA FUEL_STATUS
         CMP #FULL
         BNE @4
         LDA FUEL1
         ORA FUEL2
         BEQ @3
         LDA FRAME
         AND #15
         BNE @4
         SED
         LDA FUEL1
         SEC
         SBC #1
         STA FUEL1
         LDA FUEL2
         SBC #0
         STA FUEL2
         CLD
         JMP @4
@3:      LDA #EMPTY
         STA FUEL_STATUS
; FUEL
@4:      LDA #<FUEL_DIG
         STA S_ADR
         LDA #>FUEL_DIG
         STA S_ADR+1
         LDA #0
         STA S_FLG
         LDX #3
         LDA FUEL2
         JSR DDIG
         LDA FUEL1
;        JSR DDIG
;        RTS
;
; DRAW DIGIT
;
DDIG:    TAY
         LDA S_FLG
         BNE @1
         TYA
         AND #$F0
         BNE @1
         TYA
         ORA #$A0
         TAY
         BNE @2
@1:      LDA #1
         STA S_FLG
@2:      LDA S_FLG
         BNE @3
         TYA
         AND #$F
         BNE @3
         TYA
         ORA #$A
         TAY
         BNE @4
@3:      LDA #1
         STA S_FLG
@4:      TYA
         STA S_TEMP
         LSR
         LSR
         LSR
         LSR
         JSR DRAW
         LDA S_TEMP
         AND #$F
;        JSR DRAW
;        RTS
;
DRAW:    CMP #$A
         BNE @1
         CPX #0
         BNE @0
         LDA #0
         BEQ @1         ; FORCED
@0:      LDA #<($F0+128)  ; BLANK
@1:      CLC
         ADC #$10+128   ; '0'
         LDY #0
         STA (S_ADR),Y
         CMP #$10+128
         BNE @2
         LDA #$A+128
@2:      INY
         AND #$8F
         STA (S_ADR),Y
         LDA S_ADR
         CLC
         ADC #2
         STA S_ADR
         LDA S_ADR+1
         ADC #0
         STA S_ADR+1
         DEX
         RTS
;
INC_SCORE:
         LDA DEMO_STATUS
;        CMP #0      ON
         BEQ @1
         SED
         TXA
         CLC
         ADC SCORE1
         STA SCORE1
         TYA
         ADC SCORE2
         STA SCORE2
         LDA SCORE3
         ADC #0
         STA SCORE3
         CLD
@1:      RTS
;
DEMO_STICK:
 .byte $0B,$0B,$0B,$0B,$09,$09,$09,$09
 .byte $09,$09,$0A,$0A,$0A,$0A,$0B,$09
 .byte $09,$0B,$0A,$0A,$0B,$09,$0B,$0A
 .byte $0B,$09,$0B,$0A,$0A,$0A,$0A,$0B
 .byte $0B,$09,$09,$0B,$0B,$0A,$09,$0D
 .byte $09,$0B,$0A,$0A,$0A,$0A,$0A,$0A
 .byte $0B,$09,$09,$09,$0A,$0E,$06,$07
 .byte $07,$07,$05,$05,$05,$05,$07,$06
 .byte $06,$07,$05,$06,$06,$07,$05,$05
 .byte $07,$06,$05,$07,$07,$07,$06,$06
 .byte $06,$06,$06,$07,$07,$06,$05,$05
 .byte $07,$06,$06,$07,$05,$05,$06,$06
 .byte $06,$06,$07,$05,$05,$07,$06,$06
 .byte $07,$06,$09,$09
;
; EOF
;
