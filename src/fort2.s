;
; FILE: FORT2.S
;
; OPTIONS SET-UP
; MOVE PODS
; MOVE CRUISE MISSILE
; MOVE TANKS
; CHECK HYPER CHAMBERS
;
READ_USER:
         LDA CONSOL
         CMP CONSOL_FLAG
         BEQ @4
         STA CONSOL_FLAG
         LDX #0
         STX TIM6_VAL
         CMP #6      ; START
         BNE @1
         LDA #START_MODE
         STA MODE
;        LDA #1      OFF
         STA DEMO_STATUS
         JMP @9
@1:      LDX MODE
         CPX #OPTION_MODE
         BNE @2
         JSR CHECK_OPTIONS
         JMP @9
@2:      CMP #1      ; OPTION and SELECT, sent by Esc
         BEQ @3
         CMP #3      ; OPTION
         BEQ @3
         CMP #5      ; SELECT
         BNE @4
@3:      LDA #OPTION_MODE
         STA MODE
;        LDA #1      OFF
         STA DEMO_STATUS
         JSR SCREEN_OFF
         LDA #0
         STA OPT_NUM
         JSR CHECK_OPTIONS
         JMP @9
@4:      LDA SKSTAT
         AND #%00000100
         BNE @9
         LDA KBCODE
         CMP #$21    ; SPACE
         BNE @9
         LDA MODE
         PHA
         LDA #PAUSE_MODE
         STA MODE
         JSR CLEAR_SOUNDS
@37:     LDA SKSTAT
         AND #%00000100
         BEQ @37
@5:      LDA SKSTAT
         AND #%00000100
         BNE @38
         LDA KBCODE
         CMP #$21    ; SPACE
         BEQ @6
@38:     LDA CONSOL
         CMP #7
         BNE @6
         LDA TRIG0
         BNE @5
@6:      LDA SKSTAT
         AND #%00000100
         BEQ @6
         PLA
         STA MODE
;
@9:      RTS
;
CHECK_OPTIONS:
         LDA CONSOL
         CMP #3      ; OPTION
         BNE @2
         LDX OPT_NUM
         INX
         CPX #3
         BCC @1
         LDX #0
@1:      STX OPT_NUM
@2:      CMP #5      ; SELECT
         BNE @8
         LDA OPT_NUM
;        CMP #0
         BNE @4
         LDX GRAV_SKILL
         INX
         CPX #3
         BCC @3
         LDX #0
@3:      STX GRAV_SKILL
@4:      CMP #1
         BNE @6
         LDX PILOT_SKILL
         INX
         CPX #3
         BCC @5
         LDX #0
@5:      STX PILOT_SKILL
@6:      CMP #2
         BNE @8
         LDX CHOPS
         INX
         CPX #3
         BCC @7
         LDX #0
@7:      STX CHOPS
;
@8:      LDA #13
         STA TEMP1
         LDA #1
         STA TEMP2
         LDX #<OPTT1
         LDY #>OPTT1
         JSR PRINT
         LDA #0
         STA TEMP1
         LDA #3
         STA TEMP2
         LDX #<OPTT2
         LDY #>OPTT2
         JSR PRINT
         LDA #28
         STA TEMP1
         LDX #<OPTT3
         LDY #>OPTT3
         JSR PRINT
;        JSR PRINT.OPTS
;        RTS
;
PRINT_OPTS:
         LDA #0
         STA TEMP1
         LDA #7      ; OPTION
         STA TEMP2
;
         LDX #<OPT1
         LDY #>OPT1
         JSR PRINT
;
         INC TEMP2
         INC TEMP2
         LDX #<OPT2
         LDY #>OPT2
         JSR PRINT
;
         INC TEMP2
         INC TEMP2
         LDX #<OPT3
         LDY #>OPT3
         JSR PRINT
;
         LDA OPT_NUM
         ASL
         CLC
         ADC #7      ; OPTION
         STA TEMP2
         LDA OPT_NUM
         ASL
         TAX
         LDA OPT_TAB,X
         STA ADR2
         LDA OPT_TAB+1,X
         STA ADR2+1
         JSR CCL
         LDY #0
         STY TEMP5
         STY TEMP6
@1:      LDY TEMP5
         LDA (ADR2),Y
;        CMP #0
         BEQ @3
         CMP #$FF
         BEQ @2
         ORA #$80
         LDY TEMP6
         STA (ADR1),Y
         INC TEMP6
         CLC
         ADC #32
@3:      LDY TEMP6
         STA (ADR1),Y
         INC TEMP6
         INC TEMP5
         BNE @1      ; FORCED
@2:
;
         LDA #28
         STA TEMP1
         LDA #7      ; OPTION
         STA TEMP2
         LDA GRAV_SKILL
         ASL
         TAY
         LDX OPT_1,Y
         LDA OPT_1+1,Y
         TAY
         JSR PRINT
;
         INC TEMP2
         INC TEMP2
         LDA PILOT_SKILL
         ASL
         TAY
         LDX OPT_2,Y
         LDA OPT_2+1,Y
         TAY
         JSR PRINT
;
         INC TEMP2
         INC TEMP2
         LDA CHOPS
         ASL
         TAY
         LDX OPT_3,Y
         LDA OPT_3+1,Y
         TAY
         JMP PRINT
;        RTS
OPTT1:
 .byte $2F,$30,$34,$29,$2F,$2E,$33  ; /OPTIONS/
 .byte $FF
OPTT2:
 .byte $2F,$30,$34,$29,$2F,$2E  ; /OPTION/
 .byte $FF
OPTT3:
 .byte $33,$25,$2C,$25,$23,$34  ; /SELECT/
 .byte $FF
OPT1:
 .byte $27,$32,$21,$36,$29,$34,$39,$00,$33,$2B,$29,$2C,$2C  ; /GRAVITY SKILL/
 .byte $FF
OPT2:
 .byte $30,$29,$2C,$2F,$34,$00,$33,$2B,$29,$2C,$2C  ; /PILOT SKILL/
 .byte $FF
OPT3:
 .byte $32,$2F,$22,$2F,$00,$30,$29,$2C,$2F,$34,$33  ; /ROBO PILOTS/
 .byte $FF
OPT1_1:
 .byte $37,$25,$21,$2B,$00,$00,$00,$00  ; /WEAK    /
 .byte $FF
OPT1_2:
 .byte $2E,$2F,$32,$2D,$21,$2C  ; /NORMAL/
 .byte $FF
OPT1_3:
 .byte $33,$34,$32,$2F,$2E,$27  ; /STRONG/
 .byte $FF
OPT2_1:
 .byte $2E,$2F,$36,$29,$23,$25  ; /NOVICE/
 .byte $FF
OPT2_2:
 .byte $30,$32,$2F,$00,$00,$00,$00,$00,$00  ; /PRO      /
 .byte $FF
OPT2_3:
 .byte $25,$38,$30,$25,$32,$34  ; /EXPERT/
 .byte $FF
OPT3_1:
 .byte $33,$25,$36,$25,$2E,$00,$00,$00  ; /SEVEN   /
 .byte $FF
OPT3_2:
 .byte $2E,$29,$2E,$25,$00,$00,$00,$00  ; /NINE    /
 .byte $FF
OPT3_3:
 .byte $25,$2C,$25,$36,$25,$2E  ; /ELEVEN/
 .byte $FF
OPT_1:
 .word OPT1_1,OPT1_2,OPT1_3
OPT_2:
 .word OPT2_1,OPT2_2,OPT2_3
OPT_3:
 .word OPT3_1,OPT3_2,OPT3_3
OPT_TAB:
 .word OPT1,OPT2,OPT3
;
MOVE_PODS:
         LDA #POD_SPEED
@1:      PHA
         JSR MP1
         PLA
         SEC
         SBC #1
         BNE @1
@2:      RTS
;
MP1:
         LDX POD_NUM
;
         LDA POD_STATUS,X
         STA POD_COM
         AND #$0F
         CMP #OFF
         BEQ P_END
         CMP #BEGIN
         BNE @1
         JMP P_BEGIN
;
@1:      JSR P_COL
         BCS P_END
         JSR P_ERASE
         JSR P_MOVE
         JSR P_DRAW
;
P_END:
         LDX POD_NUM
         INX
         CPX #MAX_PODS
         BCC @1
         LDX #0
@1:      STX POD_NUM
         RTS
;
GET_POD_ADR:
         LDA POD_X,X
         STA TEMP1
         LDA POD_Y,X
         STA TEMP2
         JMP COMPUTE_MAP_ADR
;
GET_POD_VAL:
         JSR GET_POD_ADR
         LDY #0
         LDA (ADR1),Y
         STA TEMP1
         INY
         LDA (ADR1),Y
         STA TEMP2
         RTS
;
PUT_POD_VAL:
         JSR GET_POD_ADR
         LDY #0
         LDA TEMP3
         STA (ADR1),Y
         INY
         LDA TEMP4
         STA (ADR1),Y
         RTS
;
POS_POD:
         LDA POD_X,X
         STA TEMP1
         LDA POD_Y,X
         STA TEMP2
         JMP POS_IT
;
P_BEGIN:
@1:      LDA RANDOM
         CMP #50
         BCC @1
         CMP #256-50
         BCS @1
         STA POD_X,X
@2:      LDA RANDOM
         CMP #40
         BCS @2
         STA POD_Y,X
         JSR GET_POD_ADR
         LDY #0
         LDA (ADR1),Y
         INY
         ORA (ADR1),Y
         BNE @1
         LDA #ON
         STA POD_STATUS,X
         STA POD_COM
         JSR P_DRAW
         LDA #$01
         STA POD_DX,X
         JMP P_END
;
P_COL:
         JSR GET_POD_VAL
         LDA TEMP1
         CMP #MISS_LEFT
         BEQ @1
         CMP #MISS_RIGHT
         BEQ @1
         CMP #EXP
         BEQ @1
         LDA TEMP2
         CMP #MISS_LEFT
         BEQ @1
         CMP #MISS_RIGHT
         BEQ @1
         CMP #EXP
         BEQ @1
         CLC
         RTS
@1:      JSR P_ERASE
         LDA #OFF
         STA POD_STATUS,X
         LDX #$50
         LDY #$00
         JSR INC_SCORE
         SEC
         RTS
;
P_ERASE:
         JSR POS_POD
         LDA POD_TEMP1,X
         STA TEMP3
         LDA POD_TEMP2,X
         STA TEMP4
         JMP PUT_POD_VAL
;
P_DRAW:
         JSR POS_POD
         JSR GET_POD_VAL
         LDA TEMP1
         STA POD_TEMP1,X
         LDA TEMP2
         STA POD_TEMP2,X
         LDA POD_COM
         LSR
         LSR
         LSR
         TAY
         LDA POD_CHR,Y
         STA TEMP3
         LDA POD_CHR+1,Y
         STA TEMP4
         JMP PUT_POD_VAL
;
P_MOVE:
@0:      LDA POD_DX,X
         BPL @1
         LDA POD_COM
         SEC
         SBC #$10
         AND #$3F
         STA POD_COM
         AND #$F0
         CMP #$30
         BNE @2
         DEC POD_X,X
         JMP @2
@1:      LDA POD_COM
         CLC
         ADC #$10
         AND #$3F
         STA POD_COM
         AND #$F0
;        CMP #0
         BNE @2
         INC POD_X,X
@2:      LDA POD_X,X
         STA TEMP1
         LDA POD_Y,X
         STA TEMP2
         JSR COMPUTE_MAP_ADR
         LDY #0
         LDA (ADR1),Y
         INY
         ORA (ADR1),Y
         BNE @3
         LDA POD_X,X
         CMP #50
         BCC @3
         CMP #256-50
         BCC @4
@3:      LDA POD_DX,X
         EOR #<-2
         STA POD_DX,X
         JMP @0
@4:
;
         LDA POD_COM
         STA POD_STATUS,X
         RTS
;
POD_CHR:
 .byte $40,$00
 .byte $5B,$5C
 .byte $5D,$5E
 .byte $00,$5F
;
MOVE_CRUISE_MISSILES:
         DEC MISSILE_SPD
         BNE MCE
         LDA MISSILE_SPEED
         STA MISSILE_SPD
;
MM1:
         LDX #MAX_TANKS-1
M_ST:
         LDA CM_STATUS,X
         CMP #OFF
         BEQ M_END
         CMP #BEGIN
         BNE @1
         JMP M_BEGIN
;
@1:      JSR M_COL
         BCS M_END
         JSR M_ERASE
         JSR M_MOVE
         JSR M_DRAW
;
M_END:
         LDA TANK_STATUS,X
         CMP #ON
         BNE @2
         LDA TANK_Y,X
         SEC
         SBC CHOP_Y
         BMI @2
         CMP #14
         BCS @2
         LDA CM_STATUS,X
         CMP #OFF
         BNE @2
         LDA CHOP_X
         SEC
         SBC #2
         SBC TANK_X,X
         BPL @1
         EOR #<-2
@1:      CMP #9
         BCS @2
         LDA #BEGIN
         STA CM_STATUS,X
;
@2:      DEX
         BPL M_ST
MCE:
         LDX #MAX_TANKS-1
@1:      LDA CM_STATUS,X
         CMP #OFF
         BNE @2
         DEX
         BPL @1
         LDA #0
         STA AUDC4
         STA S6_VAL
@2:      RTS
;
GET_MISS_ADR:
         LDA CM_X,X
         STA TEMP1
         LDA CM_Y,X
         STA TEMP2
         JMP COMPUTE_MAP_ADR
;
M_BEGIN:
         LDY TANK_X,X
         INY
         TYA
         STA CM_X,X
         LDA TANK_Y,X
         SEC
         SBC #2
         STA CM_Y,X
         LDY #LEFT
         LDA CHOP_X
         SEC
         SBC TANK_X,X
         BMI @1
         LDY #RIGHT
@1:      TYA
         STA CM_STATUS,X
         LDA #0
         STA CM_TEMP,X
         LDA #20
         STA CM_TIME,X
         LDA #1
         STA S6_VAL
         JMP M_END
;
M_COL:
         JSR GET_MISS_ADR
         LDY #0
         LDA (ADR1),Y
         CMP #EXP
         BEQ M_COL2
         CLC
         RTS
;
M_COL2:
         JSR M_ERASE
         LDA #1
         STA S3_VAL
         LDA #OFF
         STA CM_STATUS,X
         LDA #<-1
         STA CM_TIME,X
         STX TEMP1
         LDX #$10
         LDY #$00
         JSR INC_SCORE
         LDX TEMP1
         SEC
         RTS
;
M_ERASE:
         JSR GET_MISS_ADR
         LDA CM_TEMP,X
         CMP #EXP_WALL
         BEQ @2
         CMP #$60+128
         BCS @1
         CMP #$40
         BEQ @1
         CMP #$5B
         BCC @2
         CMP #$5F+1
         BCC @1
@2:      LDY #0
         STA (ADR1),Y
@1:      RTS
;
M_MOVE:
         LDA CM_STATUS,X
         CMP #LEFT
         BEQ @1
         INC CM_X,X
         JMP @2
@1:      DEC CM_X,X
@2:      LDA CM_TIME,X
         BPL @3
@4:      INC CM_Y,X
         JMP @8
@3:      LDA CHOP_X
         SEC
         SBC CM_X,X
         STA TEMP1
         LDA CM_STATUS,X
         CMP #LEFT
         BNE @5
         LDA TEMP1
         BPL @4
         BMI @6      ; FORCED
@5:      LDA TEMP1
         BMI @4
@6:      LDA CM_X,X
         CMP #$D8
         BCS @4
         CMP #$2D
         BCC @4
         LDY CHOP_Y
         INY
         TYA
         SEC
         SBC CM_Y,X
         BEQ @8
         BPL @7
         DEC CM_Y,X
         JMP @8
@7:      INC CM_Y,X
@8:      JSR GET_MISS_ADR
         LDY #0
         LDA (ADR1),Y
         CMP #MISS_LEFT
         BEQ @7
         CMP #MISS_RIGHT
         BEQ @7
@9:      LDA CM_TIME,X
         BMI @10
         DEC CM_TIME,X
@10:     RTS
;
M_DRAW:
         JSR GET_MISS_ADR
         LDY #0
         LDA (ADR1),Y
         STA CM_TEMP,X
         LDA #MISS_LEFT
         LDY CM_STATUS,X
         CPY #LEFT
         BEQ @1
         LDA #MISS_RIGHT
@1:      LDY #0
         STA (ADR1),Y
         LDA CM_TEMP,X
         JSR CHECK_CHR
         BCC @2
         JMP M_COL2
@2:      RTS
;
CHECK_HYPER_CHAMBER:
         LDA MODE
         CMP #HYPERSPACE_MODE
         BNE @1
         LDA #STOP_MODE
         STA MODE
         LDA #$F
         STA BAK2_COLOR
         LDX #2
         JSR WAIT_FRAME
         LDA #$0
         STA BAK2_COLOR
         LDA RANDOM
         AND #3
         TAX
         LDA H_XF,X
         STA SX_F
         LDA H_YF,X
         STA SY_F
         LDA H_X,X
         STA SX
         LDA H_Y,X
         STA SY
         LDA H_CX,X
         STA CHOPPER_X
         LDA H_CY,X
         STA CHOPPER_Y
         LDA #8
         STA CHOPPER_ANGLE
         LDA #0
         STA CHOPPER_COL
         LDA #GO_MODE
         STA MODE
;        JSR SAVE.POS
@1:      RTS
;
H_XF:
 .byte $DD,$76,$10,$4B
H_YF:
 .byte $7A,$7B,$B8,$B8
H_X:
 .byte $22,$BC,$55,$87
H_Y:
 .byte $0F,$0F,$18,$18
H_CX:
 .byte $73,$78,$76,$75
H_CY:
 .byte $8C,$89,$AF,$AF
;
CHECK_CHR:
         LDY #0
         STY ADR2+1
         AND #$7F
         ASL
         ROL ADR2+1
         ASL
         ROL ADR2+1
         ASL
         ROL ADR2+1
         CLC
         ADC #<CHR_SET2
         STA ADR2
         LDA #>CHR_SET2
         ADC ADR2+1
         STA ADR2+1
         LDY #7
@1:      LDA (ADR2),Y
         BNE @2
         DEY
         BPL @1
         CLC
         RTS
@2:      SEC
         RTS
;
POS_TANK:
         LDA TANK_X,X
         STA TEMP1
         LDY TANK_Y,X
         DEY
         STY TEMP2
         JSR POS_IT
         LDA TANK_Y,X
         STA TEMP2
         RTS
;
MOVE_TANKS:
MT1:
         DEC TANK_SPD
         BEQ @1
         JMP MT2
;
@1:      LDA TANK_SPEED
         STA TANK_SPD
;
         LDX #MAX_TANKS-1
;
@2:      LDA TANK_Y,X
         STA TEMP2
         LDA TANK_STATUS,X
         CMP #OFF
         BNE @3
         JMP @11
@3:      CMP #BEGIN
         BNE @5
         LDA #ON
         STA TANK_STATUS,X
         LDA TANK_START_X,X
         STA TANK_X,X
         LDA TANK_START_Y,X
         STA TANK_Y,X
         LDA #<-1
         LDY RANDOM
         BPL @4
         LDA #1
@4:      STA TANK_DX,X
         JSR POS_TANK
         JMP @7
@5:      CMP #CRASH
         BNE @13
         JMP @11
; RESTORE OLD POS
@13:     LDA TANK_X,X
         STA TEMP1
         JSR COMPUTE_MAP_ADR
         STX TEMP1
         LDY #0
         TXA
         ASL
         ADC TEMP1
         TAX
@6:      LDA (ADR1),Y
         CMP #EXP
         BEQ @15
         CMP #MISS_LEFT
         BEQ @15
         CMP #MISS_RIGHT
         BNE @12
@15:     LDX TEMP1
         LDA #CRASH
         STA TANK_STATUS,X
         LDY #2
         LDA #EXP
@14:     STA (ADR1),Y
         DEY
         BPL @14
         LDA #10
         STA TIM5_VAL
         JMP @11
@12:     LDA TANK_TEMP,X
         STA (ADR1),Y
         INX
         INY
         CPY #3
         BNE @6
         LDY #1
         DEC ADR1+1
         LDA #0
         STA (ADR1),Y
; MOVE X
         LDX TEMP1
@7:      JSR POS_TANK
         LDA TANK_X,X
         CLC
         ADC TANK_DX,X
         STA TANK_X,X
; SAVE NEW POS
         JSR POS_TANK
         LDA TANK_X,X
         STA TEMP1
         JSR COMPUTE_MAP_ADR
         STX TEMP1
         LDY #0
         TXA
         ASL
         ADC TEMP1
         TAX
@8:      LDA (ADR1),Y
         STA TANK_TEMP,X
         INX
         INY
         CPY #3
         BNE @8
; CHECK FOR COLLISION
         LDX TEMP1
         LDY #0
         JSR CHECK_TANK_COL
         BCS @7
         LDY #2
         JSR CHECK_TANK_COL
         BCS @7
; DRAW TANK
         LDY #2
@9:      LDA TANK_SHAPE,Y
         STA (ADR1),Y
         DEY
         BPL @9
         DEC ADR1+1
         LDY #$6F+128  ; 'o'
         LDA CHOP_X
         SEC
         SBC TANK_X,X
         BPL @10
         LDY #$70+128  ; 'p'
@10:     TYA
         LDY #1
         STA (ADR1),Y
;
@11:     DEX
         BMI MT2
         JMP @2
;
MT2:
         DEC TIM5_VAL
         BNE @4
         LDA #10
         STA TIM5_VAL
;
         LDX #MAX_TANKS-1
@1:      LDA TANK_STATUS,X
         CMP #CRASH
         BNE @3
         LDA #OFF
         STA TANK_STATUS,X
         LDA TANK_X,X
         STA TEMP1
         LDA TANK_Y,X
         STA TEMP2
         JSR COMPUTE_MAP_ADR
         STX TEMP1
         LDY #0
         TXA
         ASL
         ADC TEMP1
         TAX
@2:      LDA TANK_TEMP,X
         STA (ADR1),Y
         INX
         INY
         CPY #3
         BNE @2
         DEC ADR1+1
         LDY #1
         LDA #0
         STA (ADR1),Y
         LDX #$50
         LDY #$2
         JSR INC_SCORE
;
         LDX TEMP1
         JSR POS_TANK
;
@3:      LDA TANK_STATUS,X
         CMP #OFF
         BNE @10
         LDA CHOP_Y
         CMP #3
         BCC @10
         SEC
         SBC #3
         CMP TANK_START_Y,X
         BCC @10
         LDA TANK_START_X,X
         SEC
         SBC #5
         STA TEMP1
         LDA TANK_START_Y,X
         STA TEMP2
         JSR COMPUTE_MAP_ADR
         LDY #13-1
@9:      LDA (ADR1),Y
         BMI @10
         DEY
         BPL @9
         LDA #BEGIN
         STA TANK_STATUS,X
;
@10:     DEX
         BPL @1
@4:      RTS
;
CHECK_TANK_COL:
         LDX #HIT_LIST2_LEN
@1:      LDA (ADR1),Y
         CMP HIT_LIST,X
         BEQ @2
         DEX
         BPL @1
         LDX TEMP1
         CLC
         RTS
@2:      LDX TEMP1
         LDA TANK_DX,X
         EOR #<-2
         STA TANK_DX,X
         SEC
         RTS
;
SCREEN_ON:
         JSR SCREEN_OFF
         LDA #<DSP_LST1
         STA SDLST
         LDA #>DSP_LST1
         STA SDLST+1
         RTS
;
SCREEN_OFF:
         LDA #<DSP_LST2
         STA SDLST
         LDA #>DSP_LST2
         STA SDLST+1
         LDA #OFF
         STA CHOPPER_STATUS
         STA ROBOT_STATUS
         LDX R_STATUS
         CPX #CRASH
         BNE @0
         STA R_STATUS
@0:      LDX #$E0
         LDA #0
@1:      STA CHR_SET1+$200,X
         INX
         BNE @1
;        LDX #0
;        LDA #0
@2:      STA CHR_SET1+$300,X
         STA PLAY_SCRN+$000,X
         STA PLAY_SCRN+$100,X
         STA PLAY_SCRN+$200,X
         INX
         BNE @2
;        LDA #0
         STA S1_1_VAL
         STA S2_VAL
         STA S3_VAL
         STA S4_VAL
         STA S5_VAL
         STA S6_VAL
         STA BAK2_COLOR
         LDA #20
         STA S1_2_VAL
         LDX #MAX_TANKS-1
         STX TIM7_VAL
@3:      LDA CM_STATUS,X
         CMP #OFF
         BEQ @4
         LDA #OFF
         STA CM_STATUS,X
         JSR M_ERASE
@4:      DEX
         BPL @3
;
         LDX #2
@5:      LDA ROCKET_STATUS,X
         CMP #7      ; EXP
         BNE @6
         LDA ROCKET_TEMPX,X
         STA TEMP1
         LDA ROCKET_TEMPY,X
         STA TEMP2
         JSR COMPUTE_MAP_ADR
         LDY #0
         LDA ROCKET_TEMP,X
         STA (ADR1),Y
@6:      LDA #0
         STA ROCKET_STATUS,X
         STA ROCKET_X,X
         DEX
         BPL @5
;
CLEAR_SOUNDS:
         LDA #0
         STA AUDC1
         STA AUDC2
         STA AUDC3
         STA AUDC4
         RTS
;
CCL:
         LDA TEMP2
         PHA
         LDA TEMP1
         PHA
         LDA TEMP2
         JSR MULT_BY_40
         PLA
         PHA
         CLC
         ADC TEMP1
         ADC #<PLAY_SCRN
         STA ADR1
         LDA #>PLAY_SCRN
         ADC TEMP2
         STA ADR1+1
         PLA
         STA TEMP1
         PLA
         STA TEMP2
         RTS
;
PRINT:
         STX ADR2
         STY ADR2+1
         JSR CCL
         LDY #0
         STY TEMP5
         STY TEMP6
@1:      LDY TEMP5
         LDA (ADR2),Y
;        CMP #0
         BEQ @3
         CMP #$FF
         BEQ @2
         LDY TEMP6
         STA (ADR1),Y
         INC TEMP6
         CLC
         ADC #32
@3:      LDY TEMP6
         STA (ADR1),Y
         INC TEMP6
         INC TEMP5
         BNE @1      ; FORCED
@2:      RTS
;
GIVE_BONUS:
         LDX BONUS1
         LDY BONUS2
         JSR INC_SCORE
         LDA #0
         STA BONUS1
         STA BONUS2
         SED
         LDA CHOP_LEFT
         CLC
         ADC #2
         STA CHOP_LEFT
         CLD
         LDX #2
;        JSR WAIT.FRAME
;        RTS
;
WAIT_FRAME:
         LDA MODE
         STA TEMP_MODE
         LDA FRAME
@1:      CMP FRAME
         BEQ @1
         JSR READ_USER
         LDA MODE
         CMP TEMP_MODE
         BNE @2
         DEX
         BNE WAIT_FRAME
         RTS
;
@2:      LDX #$FF
         TXS
         JMP MAIN
;
CLEAR_INFO:
         LDY #40-1
         LDA #0
@1:      STA PLAY_SCRN,Y
         DEY
         BPL @1
         RTS
;
; EOF
;
