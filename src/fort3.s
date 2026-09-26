;
; FILE: FORT3.S
;
; MAIN INTERUPT DRIVER
;        PART (I)
; UPDATE.CHOPPER
; UPDATE.ROBOT.CHOPPER
; UPDATE.ROCKETS
; DO.ROBOT CHOPPER
; DO.CHOPPER
; ROBOT.BRAINS
;
VERTBLKD: SEI
         PHP
         CLD
         LDA #0
         STA ATTRACT
         LDA M2PL
         ORA M3PL
         AND #%00000011
         ORA P0PL
         ORA P1PL
         ASL
         ASL
         ASL
         ASL
         ORA P0PF
         ORA P1PF
;        AND #%00000010
         STA CHOPPER_COL
         LDA M0PL
         ORA M1PL
         AND #%00001100
         ORA P2PL
         ORA P2PF
         ORA P3PL
         ORA P3PF
         STA ROBOT_COL
         STA HITCLR
;
         JSR DO_NUMBERS
         JSR DRAW_MAP
         JSR UPDATE_CHOPPER
         JSR UPDATE_ROBOT_CHOPPER
         JSR READ_TRIG
         JSR DO_EXP
;
         LDA MODE
         CMP #GO_MODE
         BNE @1
;
         JSR DO_ROBOT_CHOPPER
         JSR UPDATE_ROCKETS
         JSR DO_LASER_1
         JSR DO_LASER_2
         JSR DO_BLOCKS
         JSR DO_ELEVATOR
         JSR DO_CHOPPER
         JSR ROBOT_BRAINS
         JSR READ_STICK
;
@1:
;
;        .EQ $7000
;        LDA CHOP.X
;        STA P
;        LDA CHOP.Y
;        STA P+1
;        LDA CHOPPER.X
;        STA P+2
;        LDA CHOPPER.Y
;        STA P+3
;        LDA SX
;        STA P+4
;        LDA SY
;        STA P+5
;        LDA SX.F
;        STA P+6
;        LDA SY.F
;        STA P+7
         PLP
         CLI
         JMP VVBLKD_RET
;
ROBOT_BRAINS:
         LDA R_STATUS
         CMP #OFF
         BEQ @1
         CMP #CRASH
         BEQ @2
         LDA FRAME
         AND ROBOT_SPD
         BEQ R_START
         RTS
;
         LDA TIM7_VAL
         BEQ @0
@1:      DEC TIM7_VAL
         BNE @2
@0:      LDA #$88
         STA PCOLR2
         STA PCOLR3
         LDA #8
         STA ROBOT_ANGLE
         LDA RANDOM
         AND #7
         LDX LEVEL
         DEX         ; X=1?
         BNE @3
         CLC
         ADC #8
@3:      TAX
         LDA ROB_X,X
         STA R_X
         LDA ROB_Y,X
         STA R_Y
         LDA R_X
         SEC
         SBC CHOP_X
         BPL @4
         EOR #<-2
@4:      CMP #34
         BCS @6
         LDA R_Y
         SEC
         SBC CHOP_Y
         BPL @5
         EOR #<-2
@5:      CMP #8
         BCC @2
@6:      LDA #FLY
         STA R_STATUS
         LDX #0
         STX R_FX
         STX R_FY
         STX TIM7_VAL
         INX         ; X=1
         STX TIM8_VAL
         JMP POS_ROBOT
@2:      RTS
;
;    0001020304050607
ROB_X:
 .byte $84,$C3,$49,$C3,$49,$84,$84,$84
 .byte $D7,$D7,$D7,$D6,$D6,$D6,$33,$33
ROB_Y:
 .byte $00,$16,$16,$21,$21,$00,$00,$00
 .byte $12,$12,$12,$06,$06,$06,$06,$06
;
R_START: LDA ROBOT_ANGLE
         AND #1
         STA TEMP4_I
         LDA ROBOT_ANGLE
         AND #$FE
         STA ROBOT_ANGLE
;
         JSR POS_ROBOT
R_F:
         DEC TIM8_VAL
         BNE @10
         LDA #5
         STA TIM8_VAL
         LDA ROBOT_STATUS
         CMP #ON
         BNE @10
         LDA ROCKET_STATUS+2
;        CMP #0
         BNE @10
@2:      LDA ROBOT_ANGLE
         AND #%00011110
         LSR
         CMP #4
         BCC @60
         CMP #6
         BCS @70
         LDA #3
         BNE @60     ; FORCED
@70:     SEC
         SBC #2
@60:     CMP #6
         BCC @4
         LDA #5
@4:      CMP #0
         BNE @5
         LDA #1
@5:      STA ROCKET_STATUS+2
         LDA ROBOT_X
         AND #3
         CLC
         ADC ROBOT_X
         ADC #8
         STA ROCKET_X+2
         LDA ROBOT_Y
         CLC
         ADC #8
         STA ROCKET_Y+2
         LDA #$3F
         STA S2_VAL
@10:
;
R_B:
         LDA R_X
         LDX #215
         CMP #216
         BEQ @90
         LDX #49
         CMP #48
         BNE @0
@90:
         LDA FRAME
         AND #3
         BNE @94
         LDA ROBOT_ANGLE
         CMP #4
         BCC @95
         CMP #14
         BCC @94
@95:     CMP #8
         BCS @34
         INC ROBOT_ANGLE
         INC ROBOT_ANGLE
         BNE @94     ; FORCED
@34:     DEC ROBOT_ANGLE
         DEC ROBOT_ANGLE
@94:     LDA ROBOT_STATUS
         CMP #OFF
         BNE @2
         STX R_X
         JMP @2
;
@0:      LDA CHOP_X
         SEC
         SBC R_X
         BEQ @2
         BPL @1
         JSR R_LEFT
         JMP @2
@1:      JSR R_RIGHT
;
@2:      LDA CHOP_Y
         SEC
         SBC R_Y
         BEQ @4
         BPL @3
         JSR R_UP
         JMP @4
@3:      JSR R_DOWN
;
@4:
         JSR POS_ROBOT
R_END:
         LDA ROBOT_ANGLE
         BPL @1
         LDA #0
         STA ROBOT_ANGLE
@1:      CMP #18
         BCC @2
         LDA #16
         STA ROBOT_ANGLE
@2:      LDA ROBOT_ANGLE
         ORA TEMP4_I
         STA ROBOT_ANGLE
         LDA R_FX
         AND #3
         STA R_FX
         LDA R_FY
         AND #7
         STA R_FY
         RTS
;
R_LEFT:
         LDA R_X
         STA TEMP1_I
         LDA R_Y
         STA TEMP2_I
         JSR CHECK_CHR_I
         BCS @2
         DEC TEMP1_I
         JSR CHECK_CHR_I
         BCS @2
         DEC TEMP1_I
         JSR CHECK_CHR_I
         BCS @2
         DEC R_FX
         LDA R_FX
         CMP #<-1
         BNE @1
         DEC R_X
@1:      LDA FRAME
         AND #3
         BNE @2
         DEC ROBOT_ANGLE
         DEC ROBOT_ANGLE
@2:      RTS
;
R_RIGHT:
         LDA R_X
         STA TEMP1_I
         LDA R_Y
         STA TEMP2_I
         JSR CHECK_CHR_I
         BCS @2
         INC TEMP1_I
         JSR CHECK_CHR_I
         BCS @2
         INC TEMP1_I
         JSR CHECK_CHR_I
         BCS @2
         INC R_FX
         LDA R_FX
         CMP #4
         BNE @1
         INC R_X
@1:      LDA FRAME
         AND #3
         BNE @2
         INC ROBOT_ANGLE
         INC ROBOT_ANGLE
@2:      RTS
;
R_DOWN:
         LDA R_X
         STA TEMP1_I
         LDA R_Y
         STA TEMP2_I
         JSR CHECK_CHR_I
         BCS @2
         INC TEMP2_I
         JSR CHECK_CHR_I
         BCS @2
         INC TEMP2_I
         JSR CHECK_CHR_I
         BCS @2
         INC R_FY
         LDA R_FY
         CMP #8
         BNE @1
         INC R_Y
@1:
@2:      RTS
;
R_UP:
         LDA R_X
         STA TEMP1_I
         LDA R_Y
         CMP #3
         BCC @0
         STA TEMP2_I
         JSR CHECK_CHR_I
         BCS @1
         DEC TEMP2_I
         JSR CHECK_CHR_I
         BCS @1
         DEC TEMP2_I
         JSR CHECK_CHR_I
         BCS @1
         DEC TEMP2_I
         JSR CHECK_CHR_I
         BCS @1
@0:      DEC R_FY
         LDA R_FY
         CMP #<-1
         BNE @1
         DEC R_Y
@1:      RTS
;
CHECK_CHR_I:
         JSR COMPUTE_MAP_ADR_I
         LDY #0
         LDA (ADR1_I),Y
         AND #$7F
         LDY #0
         STY ADR2_I+1
         ASL
         ROL ADR2_I+1
         ASL
         ROL ADR2_I+1
         ASL
         ROL ADR2_I+1
         CLC
         ADC #<CHR_SET2
         STA ADR2_I
         LDA #>CHR_SET2
         ADC ADR2_I+1
         STA ADR2_I+1
         LDY #7
@1:      LDA (ADR2_I),Y
         BNE @2
         DEY
         BPL @1
         CLC
         RTS
@2:      SEC
         RTS
;
DO_CHOPPER:
         LDA CHOPPER_STATUS
         CMP #OFF
         BNE @2
@1:      RTS
;
@20:     JMP @4
;
@2:      CMP #CRASH
         BEQ @1
         CMP #LAND
         BEQ @3
         CMP #PICKUP
         BEQ @3
         LDA FRAME
         AND GRAV_SKL
         BNE @3
         INC CHOPPER_Y
;
@3:      LDA CHOPPER_COL
         BEQ @12
         CMP #4
         BEQ @20     ; LASER
         CMP #8
         BNE @6      ; HYPER
;
;        LDA RANDOM
;        CMP #26
;        BLT .20
         LDA LEVEL
;        CMP #0
         BNE @20
;        LDA #0
         STA CHOPPER_COL
         LDA #HYPERSPACE_MODE
         STA MODE
         LDA #1
         STA S3_VAL
         STA S5_VAL
@12:     LDX #FLY
         BNE @5      ; FORCED
;
@6:      LDA CHOP_X
         STA TEMP1_I
         LDA CHOP_Y
         STA TEMP2_I
         JSR COMPUTE_MAP_ADR_I
         LDA #0
         STA TEMP3_I
         STA TEMP4_I
         JSR CHECK_LAND
         INC ADR1_I+1
         JSR CHECK_LAND
         INC ADR1_I+1
         JSR CHECK_LAND
         LDA CHOPPER_COL
         AND #%11110000
         BNE @4
         LDA CHOPPER_COL
         AND #%00000010
         BEQ @9
         JSR PICK_UP_SLAVE
         BCC @9
         LDX #PICKUP
         JMP @5
@9:      LDA TEMP3_I
         CMP #3
         BEQ @4
         DEC CHOPPER_Y
         LDX FUEL_STATUS
         LDA CHOP_Y
         CMP #10+4
         BCC @8
         CPX #EMPTY
         BEQ @4
@8:      CPX #REFUEL
         BEQ @7
         LDA TEMP4_I
         BNE @7
         JSR SAVE_POS
@7:      LDX #LAND
         BNE @5      ; FORCED
@4:      LDA #20
         STA TIM3_VAL
         LDA #1
         STA S3_VAL
         LDX #CRASH
@5:      STX CHOPPER_STATUS
         RTS
;
SAVE_POS:
         LDA SX_F
         STA LAND_FX
         LDA SY_F
         STA LAND_FY
         LDA SX
         STA LAND_X
         LDA SY
         STA LAND_Y
         LDA CHOPPER_X
         STA LAND_CHOP_X
         LDA CHOPPER_Y
         STA LAND_CHOP_Y
         LDA CHOPPER_ANGLE
         STA LAND_CHOP_ANGLE
         RTS
;
CHECK_LAND:
         LDY #0
         LDX #LAND_LEN
         LDA (ADR1_I),Y
@1:      CMP LAND_CHR,X
         BEQ @2
         CMP #$48
         BEQ @3
         DEX
         BPL @1
         INC TEMP3_I
@2:      RTS
@3:      INC TEMP4_I
         RTS
;
P1:      LDX #OFF
         JMP DRCE
;
DO_ROBOT_CHOPPER:
         LDA R_STATUS
         CMP #OFF
         BEQ P1
         LDA R_X
         CMP SX
         BCC P1
         SEC
         SBC SX
         CMP #48
         BCS P1
         LDY SY
         BPL @1
         LDY #0
@1:      STY TEMP1_I
         LDA R_Y
         CMP TEMP1_I
         BCC P1
         SEC
         SBC SY
         CMP #19
         BCS P1
;
         LDA R_X
         SEC
         SBC SX
         ASL
         ASL
         CLC
         ADC #22
         STA TEMP1_I
         LDA SX_F
         AND #3
         CLC
         ADC TEMP1_I
         ADC R_FX
         STA ROBOT_X
         LDA R_Y
         LDY SY
         BPL @2
         LDY #0
@2:      STY TEMP1_I
         SEC
         SBC TEMP1_I
         ASL
         ASL
         ASL
         CLC
         ADC #71+12
         STA TEMP1_I
         LDA SY_F
         EOR #$FF
         AND #7
         CLC
         ADC TEMP1_I
         LDY SY
         BPL @3
         CLC
         ADC #8
@3:      CLC
         ADC R_FY
         STA ROBOT_Y
         LDX #FLY
         LDA ROBOT_COL
         BEQ @4
         LDA R_STATUS
         CMP #CRASH
         BEQ @4
         LDX #CRASH
         LDA #20
         STA TIM7_VAL
         LDA #1
         STA S3_VAL
@4:      LDA R_STATUS
         CMP #CRASH
         BEQ @5
         STX R_STATUS
@5:      LDX #ON
DRCE:
         STX ROBOT_STATUS
         RTS
;
UPDATE_CHOPPER:
         LDA CHOPPER_STATUS
         CMP #BEGIN
         BEQ @20
         CMP #OFF
         BNE @0
         LDA #0
         STA HPOSP0
         STA HPOSP1
         RTS
@20:     LDA #FLY
         STA CHOPPER_STATUS
         JMP CCXY
;
@0:      LDY OCHOPPER_Y
         LDX #17
         LDA #0
@1:      STA PLAYER+PL0,Y
         STA PLAYER+PL1,Y
         INY
         DEX
         BPL @1
;
         LDA CHOPPER_X
         STA HPOSP0
         CLC
         ADC #8
         STA HPOSP1
;
         LDA CHOPPER_ANGLE
         ASL
         TAX
         LDA CHOPPER_SHAPES,X
         STA ADR1_I
         LDA CHOPPER_SHAPES+1,X
         STA ADR1_I+1
;
         LDA #0
         STA TEMP1_I
         LDA #18
         STA TEMP2_I
;
         LDX CHOPPER_Y
         STX OCHOPPER_Y
@2:      LDY TEMP1_I
         LDA (ADR1_I),Y
         STA PLAYER+PL0,X
         LDY TEMP2_I
         LDA (ADR1_I),Y
         STA PLAYER+PL1,X
         INC TEMP1_I
         INC TEMP2_I
         INX
         LDA TEMP1_I
         CMP #18
         BNE @2
;
         LDA CHOPPER_STATUS
         CMP #CRASH
         BNE @11
         LDX CHOPPER_Y
         LDY #18
@10:     LDA PLAYER+PL0,X
         AND RANDOM
         STA PLAYER+PL0,X
         LDA PLAYER+PL1,X
         AND RANDOM
         STA PLAYER+PL1,X
         INX
         DEY
         BNE @10
         INC PCOLR0
         INC PCOLR1
         LDA RANDOM
         ORA #$F
         STA BAK2_COLOR
         LDA MODE
         CMP #GO_MODE
         BNE @11
         LDA FRAME
         AND #1
         BNE @12
         INC CHOPPER_Y
@12:     DEC TIM3_VAL
         BNE @11
         LDA R_STATUS
         CMP #OFF
         BEQ @23
         JSR POS_ROBOT
         LDA #OFF
         STA R_STATUS
@23:     JSR POS_CHOPPER
;
         LDA #NEW_PLAYER_MODE
         STA MODE
;
@11:
         LDA FRAME
         AND #3
         BNE @3
         LDA CHOPPER_ANGLE
         EOR #1
         STA CHOPPER_ANGLE
;
@3:
         LDA MODE
         CMP #GO_MODE
         BNE CCEND
         JSR POS_CHOPPER
CCXY:
         LDA CHOPPER_X
         SEC
         SBC #24
         LSR
         LSR
         CLC
         ADC SX
         STA CHOP_X
         LDA CHOPPER_Y
         SEC
         SBC #76+12
         LSR
         LSR
         LSR
         STA TEMP1_I
         LDA SY
         BPL @1
         LDA #0
@1:      CLC
         ADC TEMP1_I
         STA CHOP_Y
;
         JMP POS_CHOPPER
CCEND:   RTS
;
UPDATE_ROBOT_CHOPPER:
         LDA ROBOT_STATUS
         CMP #OFF
         BNE @0
         LDA #0
         STA ROBOT_X
         STA ROBOT_Y
;        RTS
;
@0:      LDY OROBOT_Y
         LDX #17
         LDA #0
@1:      STA PLAYER+PL2,Y
         STA PLAYER+PL3,Y
         INY
         DEX
         BPL @1
;
         LDA ROBOT_ANGLE
         ASL
         TAX
         LDA CHOPPER_SHAPES,X
         STA ADR1_I
         LDA CHOPPER_SHAPES+1,X
         STA ADR1_I+1
;
         LDA #0
         STA TEMP1_I
         LDA #18
         STA TEMP2_I
;
         LDX ROBOT_Y
         STX OROBOT_Y
@2:      LDY TEMP1_I
         LDA (ADR1_I),Y
         STA PLAYER+PL2,X
         LDY TEMP2_I
         LDA (ADR1_I),Y
         STA PLAYER+PL3,X
         INC TEMP1_I
         INC TEMP2_I
         INX
         LDA TEMP1_I
         CMP #18
         BNE @2
;
         LDA R_STATUS
         CMP #CRASH
         BNE @12
         LDX ROBOT_Y
         LDY #18
@10:     LDA PLAYER+PL2,X
         AND RANDOM
         STA PLAYER+PL2,X
         LDA PLAYER+PL3,X
         AND RANDOM
         STA PLAYER+PL3,X
         INX
         DEY
         BNE @10
         INC PCOLR2
         INC PCOLR3
         DEC TIM7_VAL
         BNE @12
         LDA #OFF
         STA R_STATUS
         JSR POS_ROBOT
         LDA #255
         STA TIM7_VAL
@12:
;
         LDA FRAME
         AND #3
         BNE @3
         LDA ROBOT_ANGLE
         EOR #1
         STA ROBOT_ANGLE
;
@3:      RTS
;
UPDATE_ROCKETS:
;
CHECK_ROCKET_COL:
         LDX #2
NXT_RCK: LDA ROCKET_STATUS,X
;        CMP #0
         BNE @23
@9:      JMP @6
@23:     CMP #7
         BEQ @9
         LDA ROCKET_X,X
         SEC
         SBC #32+1
         LSR
         LSR
         CLC
         ADC SX
         STA TEMP1_I
         STA ROCKET_TEMPX,X
         LDA #0
         LDY SY
         BMI @0
         LDA SY_F
         AND #7
@0:      CLC
         ADC ROCKET_Y,X
         SEC
         SBC #82+12
         LSR
         LSR
         LSR
         STA TEMP2_I
         LDA SY
         BPL @1
         LDA #0
@1:      CLC
         ADC TEMP2_I
         STA TEMP2_I
         STA ROCKET_TEMPY,X
         JSR CHECK_CHR_I
         BCC @6
         LDY #1
         STY S3_VAL
         DEY         ; Y=0
         STY S2_VAL
         LDA (ADR1_I),Y
         STA ROCKET_TEMP,X
         CMP #EXP2
         BNE @4
         LDY LEVEL
         DEY
         BNE @4
         STY ROCKET_TEMP+0
         STY ROCKET_TEMP+1
         STY ROCKET_TEMP+2
         LDA #EXPLODE
         STA FORT_STATUS
         BNE @3      ; FORCED
@4:      CMP #EXP_WALL
         BNE @10
         STX TEMP1_I
         LDA #$10
         STA BAK2_COLOR
         LDX #$20
         LDY #$00
         JSR INC_SCORE
         LDX TEMP1_I
         LDA #0
         STA ROCKET_TEMP,X
         BEQ @21     ; FORCED
@10:     LDY #HIT_LIST_LEN
@2:      CMP HIT_LIST,Y
         BEQ @3
         DEY
         BPL @2
@21:     LDA #7
         BNE @5      ; FORCED
@3:      LDA #0
@5:      STA ROCKET_STATUS,X
         LDY #0
         LDA #EXP
         STA (ADR1_I),Y
         LDA #7
         STA ROCKET_TIM,X
@6:
;
MOVE_ROCKETS:
         LDA ROCKET_STATUS,X
;        CMP #0      OFF
         BEQ @2
         CMP #7      ; EXP
         BEQ @3
         LDA SSIZEM
         STA SIZEM
         LDA ROCKET_X,X
         CMP #0+4
         BCC @2
         CMP #255-4
         BCS @2
         LDA ROCKET_Y,X
         CMP #MAX_DOWN+18
         BCS @2
         CMP #MAX_UP
         BCS @5
@2:      LDA #0      ; OFF
         STA ROCKET_STATUS,X
@3:      LDA #0
         STA ROCKET_X,X
         LDA #$F0
         STA ROCKET_Y,X
@5:      LDY OROCKET_Y,X
         LDA PLAYER+MIS+0,Y
         AND ROCKET1_MASK,X
         STA PLAYER+MIS+0,Y
         LDA PLAYER+MIS+1,Y
         AND ROCKET1_MASK,X
         STA PLAYER+MIS+1,Y
         LDA PLAYER+MIS+4,Y
         AND ROCKET1_MASK,X
         STA PLAYER+MIS+4,Y
         LDA PLAYER+MIS+5,Y
         AND ROCKET1_MASK,X
         STA PLAYER+MIS+5,Y
         LDA ROCKET_Y,X
         STA OROCKET_Y,X
         TAY
         LDA ROCKET2_MASK,X
         PHA
         ORA PLAYER+MIS+0,Y
         STA PLAYER+MIS+0,Y
         PLA
         ORA PLAYER+MIS+1,Y
         STA PLAYER+MIS+1,Y
         LDA SSIZEM
         AND ROCKET1_MASK,X
         STA SSIZEM
         LDA ROCKET_STATUS,X
         CMP #3
         BEQ @10
         LDA SSIZEM
         ORA ROCKET3_MASK,X
         STA SSIZEM
         LDA ROCKET2_MASK,X
         PHA
         ORA PLAYER+MIS+4,Y
         STA PLAYER+MIS+4,Y
         PLA
         ORA PLAYER+MIS+5,Y
         STA PLAYER+MIS+5,Y
@10:     LDY ROCKET_STATUS,X
;        CPY #0      OFF
         BEQ @4
         CPY #7      ; EXP
         BEQ @4
         LDA ROCKET_X,X
         CLC
         ADC ROCKET_DX-1,Y
         STA ROCKET_X,X
         LDA ROCKET_Y,X
         CLC
         ADC ROCKET_DY-1,Y
         STA ROCKET_Y,X
@4:      DEX
         BMI ROCKET_EXP
         JMP NXT_RCK
;
ROCKET_EXP:
         LDX #2
@1:      LDA ROCKET_STATUS,X
         CMP #7      ; EXP
         BNE @2
         DEC ROCKET_TIM,X
         BNE @2
         LDA ROCKET_TEMPX,X
         STA TEMP1_I
         LDA ROCKET_TEMPY,X
         STA TEMP2_I
         LDA #0
         STA BAK2_COLOR
         JSR COMPUTE_MAP_ADR_I
         LDA ROCKET_TEMP,X
         CMP #EXP
         BEQ @4
         LDY #HIT_LIST_LEN
@0:      CMP HIT_LIST,Y
         BEQ @4
         DEY
         BPL @0
         INY         ; Y=0
         STA (ADR1_I),Y
@4:      LDA #0      ; OFF
         STA ROCKET_STATUS,X
@2:      DEX
         BPL @1
@3:      RTS
;
HIT_LIST:
 .byte $40,$5B,$5C,$5D,$5E,$5F
 .byte $3B,$3C,$3D,$3E,$49,$4A
TANK_SHAPE:
 .byte $EC,$ED,$EE,$EF,$F0  ; -/lmnop/
 .byte MISS_LEFT,MISS_RIGHT
HIT_LIST_LEN = *-HIT_LIST-1
 .byte $61,$00  ; /a /
 .byte EXP
HIT_LIST2_LEN = *-HIT_LIST-1
;
ROCKET_DX:
 .byte <-4,<-4,0,4,4
ROCKET_DY:
 .byte 2,0,2,0,2
;
ROCKET1_MASK:
 .byte %11111100
 .byte %11110011
 .byte %11001111
;.DA #%00111111
ROCKET2_MASK:
 .byte %00000011
 .byte %00001100
 .byte %00110000
;.DA #%11000000
ROCKET3_MASK:
 .byte %00000001
 .byte %00000100
 .byte %00010000
;.DA #%01000000
;
; EOF
;
