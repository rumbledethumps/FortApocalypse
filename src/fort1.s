;
; FILE: FORT1.S
;
;
START:   SEI
         CLD
         LDX #Z2_LEN
@3:      LDA Z2,X
         STA RAM2_STUFF,X
         DEX
         BNE @3
         LDA #%00111110
         STA SDMCTL
         LDA #$14
         STA PRIOR
         LDA #%00000011
         STA GRACTL
;        LDA #3
         STA SKCTL
         LDA #>PLAYER
         STA PMBASE
         LDA #>CHR_SET1
         STA CHBAS
         LDX #0
         STX AUDCTL
         STX COLOR4
         STX TIM6_VAL
;
         STX PILOT_SKILL
         STX GRAV_SKILL
         INX         ; X=1
         STX ELEVATOR_DX
         INX         ; X=2
         STX CHOPS
         LDA #<LINE1
         STA VDSLST
         LDA #>LINE1
         STA VDSLST+1
         JSR M_START
         LDA #TITLE_MODE
         STA MODE
;
SET_FONTS:
;        LDA #CHR.SET1
;        STA ADR1
;        LDA /CHR.SET1
;        STA ADR1+1
;
;1       LDY #0
;        TYA
;2       STA (ADR1),Y
;        INY
;        BNE .2
;        INC ADR1+1
;        LDA ADR1+1
;        CMP /CHR.SET1+$800
;        BNE .1
;
         LDX #0
@3:      LDA FNT1,X
         STA CHR_SET1+15,X
         LDA FNT1+$100-15,X
         STA CHR_SET1+$100,X
         LDA FNT1+$200-15,X
         STA CHR_SET1+$200,X
;
         LDA FNT2,X
         STA CHR_SET2+$100+8,X
         LDA FNT2+$100-8,X
         STA CHR_SET2+$200,X
         LDA FNT2+$200-8,X
         STA CHR_SET2+$300,X
         INX
         BNE @3
;
         LDX #Z1_LEN
@4:      LDA Z1,X
         STA RAM1_STUFF,X
         DEX
         BPL @4
;
         LDA #$40
         STA NMIEN
         CLI
; TITLE
TITLE:
         LDX #$FF
         TXS
         LDA #$43
         STA COLOR0
         LDA #$0F
         STA COLOR1
         LDA #$83
         STA COLOR2
         JSR SCREEN_OFF
         LDA #<DSP_LST3
         STA SDLST
         LDA #>DSP_LST3
         STA SDLST+1
         LDA #$3B
         STA TEMP3
         LDY #0
         STY TEMP1_I
@1:      LDA TEMP3
         STA PLAY_SCRN,Y
         JSR INC_CHR
         INY
         CPY #40
         BNE @1
         LDA #<(PLAY_SCRN+39)
         STA ADR1
         LDA #>(PLAY_SCRN+39)
         STA ADR1+1
         LDA #$3B
         STA TEMP3
         LDX #17
         LDY #0
@2:      LDA TEMP3
         STA (ADR1),Y
         INY
         JSR INC_CHR
         STA (ADR1),Y
         DEY
         LDA ADR1
         CLC
         ADC #40
         STA ADR1
         LDA ADR1+1
         ADC #0
         STA ADR1+1
         DEX
         BPL @2
;
         LDA #<T2
         STA VVBLKD
         LDA #>T2
         STA VVBLKD+1
;
         LDX #5
         STX TEMP1
         DEX         ; X=4
         STX TEMP2
         LDX #<T_1
         LDY #>T_1
         JSR PRINT
         INC TEMP1   ; =6
         LDA #6
         STA TEMP2
         LDX #<T_2
         LDY #>T_2
         JSR PRINT
         LDA #10
         STA TEMP2
         LDX #<T_3
         LDY #>T_3
         JSR PRINT
         LDX #7
@3:      LDA T_5,X
         STA PLAY_SCRN+426,X
         DEX
         BPL @3
         LDA #4
         STA TEMP1
         LDA #12
         STA TEMP2
         LDX #<T_4
         LDY #>T_4
         JSR PRINT
;
T1:      JMP RAINBOW
;
T2:
         LDA FRAME
         AND #3
         BNE @1
         LDA COLOR2
         PHA
         LDA COLOR1
         STA COLOR2
         LDA COLOR0
         STA COLOR1
         PLA
         STA COLOR0
;
@1:      LDA FRAME
         AND #7
         BNE @2
         INC TEMP1_I
;
@2:      LDA #$AF
         STA AUDC1
         STA AUDC2
         LDA #$FF
         SEC
         SBC TEMP1_I
         STA AUDF1
         TAX
         DEX
         STX AUDF2
;
         LDA TEMP1_I
         CMP #$F3
         BEQ @4
         LDX #START_MODE
         LDA TRIG0
         BEQ @3
         LDA CONSOL
         CMP #6
         BEQ @3
         LDX #OPTION_MODE
         CMP #7
         BNE @3
;
         JMP VVBLKD_RET
@3:      STX MODE
         LDX #0
         STX OPT_NUM
         INX         ; X=1
@5:      STX DEMO_STATUS
         JMP T3
@4:      LDX #<-1    ; START DEMO
         BNE @5      ; FORCED
;
INC_CHR:
         INC TEMP3
         LDA TEMP3
         CMP #$3E
         BNE @1
         LDA #$3B
@1:      STA TEMP3
         RTS
;
T_1:
 .byte $A6,$AF,$B2,$B4  ; -/FORT/
 .byte $00,$00  ; /  /
 .byte $A1,$B0,$AF,$A3,$A1,$AC,$B9,$B0,$B3,$A5  ; -/APOCALYPSE/
 .byte $FF
T_2:
 .byte $A2,$B9  ; -/BY/
 .byte $00,$00  ; /  /
 .byte $B3,$B4,$A5,$B6,$A5  ; -/STEVE/
 .byte $00,$00  ; /  /
 .byte $A8,$A1,$AC,$A5,$B3  ; -/HALES/
 .byte $FF
T_3:
 .byte $A3,$AF,$B0,$B9,$B2,$A9,$A7,$A8,$B4  ; -/COPYRIGHT/
 .byte $FF
T_4:
 .byte $B3,$B9,$AE,$A1,$B0,$B3,$A5  ; -/SYNAPSE/
 .byte $00,$00  ; /  /
 .byte $B3,$AF,$A6,$B4,$B7,$A1,$B2,$A5  ; -/SOFTWARE/
 .byte $FF
;
T3:      SEI
         LDA #$A     ; LASER BLOCK
         STA COLOR1
         LDA #$94    ; LASERS,HOUSE
         STA COLOR2
         LDA #$9A    ; LETTERS
         STA COLOR3
         LDA #<VERTBLKD
         STA VVBLKD
         LDA #>VERTBLKD
         STA VVBLKD+1
         JSR SCREEN_OFF
         JSR LEAVE_VBI
         LDA #$C0
         STA NMIEN
         CLI
;
MAIN:
         LDA MODE
         CMP #GO_MODE
         BEQ @2
         LDA FRAME
@1:      CMP FRAME
         BEQ @1
@2:
;
         LDA MODE
         CMP #GO_MODE
         BNE @6
         JSR PACE
         JSR MOVE_PODS
         JSR MOVE_TANKS
         JSR MOVE_CRUISE_MISSILES
         JSR MOVE_SLAVES
         JSR SET_SCANNER
         JSR CHECK_FUEL_BASE
         JSR CHECK_FORT
         JSR CHECK_LEVEL
;
@6:      JSR CHECK_HYPER_CHAMBER
         JSR CHECK_MODES
         JSR READ_USER
;
         LDA DEMO_STATUS
         BPL @3
         INC DEMO_STATUS   ; =0
         LDA #START_MODE
         STA MODE
;
@3:      LDA MODE
         CMP #TITLE_MODE
         BEQ @5
         CMP #OPTION_MODE
         BNE @4
@5:      LDA FRAME
         AND #%00000100
         BEQ @4
         DEC TIM6_VAL
         BNE @4
         JMP TITLE
;
@4:      JMP MAIN
;
CHECK_LEVEL:
         LDA LEVEL
;        CMP #0
         BEQ DO_LEVEL_1
         CMP #1
         BNE @1
         JMP DO_LEVEL_2
@1:      JMP DO_LEVEL_3
@2:      RTS
;
DO_LEVEL_1:
         LDA CHOPPER_STATUS
         CMP #LAND
         BNE @1
         LDA CHOP_Y
         CMP #35
         BCC @1
         LDA CHOP_X
         CMP #130
         BCC @1
         CMP #130+6+1
         BCS @1
         LDA SLAVES_LEFT
         BNE PSL
         INC LEVEL   ; =1
         JSR GIVE_BONUS
         JSR CLEAR_INFO
         JSR CLEAR_SOUNDS
         LDA #STOP_MODE
         STA MODE
         LDA #130
         STA TEMP1
         LDA #40
         STA TEMP2
         JSR COMPUTE_MAP_ADR
         LDA ADR1
         STA TEMP3
         LDA ADR1+1
         STA TEMP4
         LDA #3
         STA TEMP2
@2:      JSR MOVE_RAMP
         LDY #5
@3:      LDX #5
         JSR WAIT_FRAME
         JSR HOVER
         INC CHOPPER_Y
         DEY
         BPL @3
         LDA TEMP3
         STA ADR1
         LDA TEMP4
         STA ADR1+1
         DEC TEMP2
         BNE @2
         LDA #NEW_LEVEL_MODE
         STA MODE
@1:      RTS
;
PSL:     JMP PRINT_SLAVES_LEFT
;
MOVE_RAMP:
         LDX #4
@1:      LDA ADR1
         STA ADR2
         LDY ADR1+1
         DEY
         STY ADR2+1
         LDY #5
@2:      LDA (ADR2),Y
         STA (ADR1),Y
         DEY
         BPL @2
         DEC ADR1+1
         DEX
         BPL @1
         RTS
;
DO_LEVEL_2:
         LDA FORT_STATUS
         CMP #OFF
         BNE @1
         LDA CHOP_Y
         CMP #2
         BCS @1
         LDA CHOP_X
         CMP #130
         BCC @1
         CMP #130+4+1
         BCS @1
         LDA SLAVES_LEFT
         BNE PSL
         INC LEVEL   ; =2
         JSR GIVE_BONUS
         LDA #NEW_LEVEL_MODE
         STA MODE
@1:      RTS
;
DO_LEVEL_3:
         LDA CHOPPER_STATUS
         CMP #LAND
         BNE @1
         LDA CHOP_Y
         CMP #13
         BCS @1
         LDA CHOP_X
         CMP #$17
         BCC @1
         CMP #$F4
         BCS @1
         JSR GIVE_BONUS
         INC LEVEL   ; =3
         LDA #GAME_OVER_MODE
         STA MODE
@1:      RTS
;
UNPACK:
@0:      JSR GET_BYTE
         LDY #0
         LDX TEMP4
         BNE @10
@1:      CMP CHR1,Y
         BEQ @2
         INY
         CPY #CHR1_L
         BNE @1
@9:      LDX #1
         BNE @3      ; FORCED
@10:     CMP CHR2,Y
         BEQ @2
         INY
         CPY #CHR2_L
         BNE @10
         BEQ @9      ; FORCED
@2:      STA TEMP1
         JSR GET_BYTE
         TAX
         LDA TEMP1
@3:      LDY #0
         STA (ADR2),Y
         INC ADR2
         BNE @4
         INC ADR2+1
@4:      DEX
         BNE @3
         LDA ADR2
         CMP TEMP2
         LDA ADR2+1
         SBC TEMP3
         BCC @0
         RTS
;
GET_BYTE:
         LDY #0
         LDA (ADR1),Y
         INC ADR1
         BNE @1
         INC ADR1+1
@1:      RTS
;
CHR1:
 .byte $00,$61,$0E,$0F,$10,$11,$0A,$0B,$0C,$0D,$03,$07,$1F,$73,$74  ; " a./01*+,-#'?st"
 .byte $41,$44,$48,$58,$59,$5A,$D8
 .byte $47+128
CHR1_L = *-CHR1
;
CHR2:
 .byte $00,$55,$AA,$FF
CHR2_L = *-CHR2
;
PACK_ADR:
; LEVEL.1
 .word PACKED_MAP_1
; LEVEL.2
 .word PACKED_MAP_2
; LEVEL.1
 .word PACKED_MAP_1
;
CHECK_MODES:
         LDA MODE
@1:      CMP #START_MODE
         BNE @2
         JMP M_START
@2:      CMP #GAME_OVER_MODE
         BNE @3
         JMP M_GAME_OVER
@3:      CMP #NEW_LEVEL_MODE
         BNE @4
         JMP M_NEW_LEVEL
@4:      CMP #NEW_PLAYER_MODE
         BNE @30
         JMP M_NEW_PLAYER
;
@30:
         RTS
;
M_START:
         JSR SCREEN_OFF
         LDX #0
         STX LEVEL
         STX SCORE1
         STX SCORE2
         STX SCORE3
         STX BONUS1
         STX BONUS2
         STX TIM1_VAL
         STX FUEL1
         STX FUEL2
         STX GAME_POINTS
         STX SLAVES_SAVED
         INX         ; X=1
         STX ELEVATOR_TIM
         STX TANK_SPD
         STX MISSILE_SPD
         LDA #128
         STA TIM2_VAL
         LDA #ON
         STA FORT_STATUS
         STA LASER_STATUS
         LDA #EMPTY
         STA FUEL_STATUS
         LDA #OFF
         STA R_STATUS
         LDX GRAV_SKILL
         LDA GRAV_TAB,X
         STA GRAV_SKL
         LDX CHOPS
         LDA CHOP_TAB,X
         LDY DEMO_STATUS
;        CPY #0      ON
         BNE @0
         LDA #2
@0:
         STA CHOP_LEFT
         LDX PILOT_SKILL
         LDA LASER_TAB,X
         STA LASER_SPD
         LDA POD_TAB,X
         STA START_PODS
         LDA ROBOT_TAB,X
         STA ROBOT_SPD
         LDA TANK_TAB,X
         STA TANK_SPEED
         LDA MISSILE_TAB,X
         STA MISSILE_SPEED
         LDA ELEVATOR_TAB,X
         STA ELEVATOR_SPD
         LDX #7
         LDA #0
@1:      STA WINDOW_1,X
         STA WINDOW_2,X
         DEX
         BPL @1
         LDX #7
         LDA #$55
         LDY RANDOM
         BMI @3
@2:      STA WINDOW_1,X
         DEX
         BPL @2
         BMI @4      ; FORCED
@3:      STA WINDOW_2,X
         DEX
         BPL @3
@4:      LDA #NEW_LEVEL_MODE
         STA MODE
         RTS
;
GRAV_TAB:
 .byte $F,7
ROBOT_TAB:
 .byte 3,1,0
CHOP_TAB:
 .byte $7,$9,$11
LASER_TAB:
 .byte 4,8,16
POD_TAB:
 .byte 13-1,26-1,MAX_PODS-1
TANK_TAB:
 .byte 4
MISSILE_TAB:
 .byte 3,2,1
ELEVATOR_TAB:
 .byte 37+25,37+10,37+0
;
M_NEW_PLAYER:
         JSR SCREEN_OFF
         SED
         LDA CHOP_LEFT
         SEC
         SBC #1
         STA CHOP_LEFT
         CLD
;        LDA CHOP.LEFT
         CMP #$99
         BNE @1
         LDA #GAME_OVER_MODE
         STA MODE
         RTS
;
@1:      LDA #$1F    ; CHOPPER CLR
         STA PCOLR0
         STA PCOLR1
         LDA FUEL_STATUS
         CMP #EMPTY
         BNE @10
         LDA #FULL
         STA FUEL_STATUS
         LDX #0
         STX FUEL1
         INX         ; X=1
         STX FUEL2
@10:     LDA #4
         STA TEMP1
         LDA #8
         STA TEMP2
         LDX #<NEW_PILOT
         LDY #>NEW_PILOT
         JSR PRINT
         LDA #5
         STA TEMP1
         LDA #10
         STA TEMP2
         LDX #<PILOTS_LEFT
         LDY #>PILOTS_LEFT
         JSR PRINT
         LDA #<(PLAY_SCRN+428)
         STA S_ADR
         LDA #>(PLAY_SCRN+428)
         STA S_ADR+1
         LDX #0
         STX S_FLG
         STX DEMO_COUNT
         INX         ; X=1
         LDA CHOP_LEFT
         JSR DDIG
;
         LDX #75
         JSR WAIT_FRAME
;
         LDA LAND_X
         STA SX
         LDA LAND_Y
         STA SY
         LDA LAND_FX
         STA SX_F
         LDA LAND_FY
         STA SY_F
         LDA LAND_CHOP_X
         STA CHOPPER_X
         LDA LAND_CHOP_Y
         STA CHOPPER_Y
         LDA LAND_CHOP_ANGLE
         STA CHOPPER_ANGLE
         LDA #0
         STA CHOPPER_COL
         JSR SCREEN_ON
         LDA #BEGIN
         STA CHOPPER_STATUS
         LDA #GO_MODE
         STA MODE
         RTS
;
NEW_PILOT:
 .byte $A7,$A5,$B4  ; -/GET/
 .byte $00,$00  ; /  /
 .byte $B2,$A5,$A1,$A4,$B9  ; -/READY/
 .byte $00,$00  ; /  /
 .byte $B0,$A9,$AC,$AF,$B4  ; -/PILOT/
 .byte $FF
PILOTS_LEFT:
 .byte $B0,$A9,$AC,$AF,$B4,$B3  ; -/PILOTS/
 .byte $00,$00  ; /  /
 .byte $AC,$A5,$A6,$B4  ; -/LEFT/
 .byte $FF
;
M_NEW_LEVEL:
         JSR SCREEN_OFF
         LDA #12
         STA TEMP1
         LDA #6
         STA TEMP2
         LDX #<ENTER
         LDY #>ENTER
         JSR PRINT
         LDA #2
         STA TEMP1
         LDA #8
         STA TEMP2
         LDY LEVEL
         DEY         ; Y=0
         BEQ @0
@5:      LDX #<LVL_1
         LDY #>LVL_1
         JSR PRINT
         JMP @1
@0:      LDX #<LVL_2
         LDY #>LVL_2
         JSR PRINT
@1:      LDX LEVEL
         LDA LEVEL_COLOR,X
         STA BAK_COLOR
         STA COLOR0
         TXA
         ASL
         TAX
         LDA LEVEL_START,X
         STA SX
         LDA LEVEL_START+1,X
         STA SY
         LDA LEVEL_CHOP_START,X
         STA CHOPPER_X
         LDA LEVEL_CHOP_START+1,X
         STA CHOPPER_Y
         LDA #0
         STA SX_F
         LDY LEVEL
         CPY #2
         BEQ @4
         LDA #7
@4:      STA SY_F
         LDA #8
         STA CHOPPER_ANGLE
         JSR SAVE_POS
         LDA #$99
         STA BONUS1
         STA BONUS2
;
         LDX #MAX_TANKS-1
@2:      LDY LEVEL
         DEY
         BEQ @91
         LDA TANK_START_X_L1,X
         STA TANK_START_X,X
         LDA TANK_START_Y_L1,X
         BNE @92     ; FORCED
@91:     LDA TANK_START_X_L2,X
         STA TANK_START_X,X
         LDA TANK_START_Y_L2,X
@92:     STA TANK_START_Y,X
         LDA #BEGIN
         STA TANK_STATUS,X
         LDA #OFF
         STA CM_STATUS,X
         DEX
         BPL @2
;
;        LDA #OFF
         STA R_STATUS
;
         LDX #MAX_PODS-1
;        LDA #OFF
@6:      STA POD_STATUS,X
         DEX
         BPL @6
         LDX START_PODS
         LDA #BEGIN
@7:      STA POD_STATUS,X
         DEX
         BPL @7
         LDA #0
         STA POD_NUM
         STA SLAVE_NUM
;
         LDA LEVEL
         ASL
         TAX
         LDA PACK_ADR,X
         STA ADR1
         LDA PACK_ADR+1,X
         STA ADR1+1
         LDA #<MAP
         STA ADR2
         LDA #>MAP
         STA ADR2+1
         LDA #<(MAP+$2800)
         STA TEMP2
         LDA #>(MAP+$2800)
         STA TEMP3
         LDA #0
         STA TEMP4
         JSR UNPACK
;
MAKE_CONTURE:
         LDA #<MAP
         STA ADR1
         LDA #>MAP
         STA ADR1+1
         LDY #0
@1:      LDA (ADR1),Y
         CMP #$73    ; 's'
         BNE @3
@2:      LDA RANDOM
         AND #3
;        CMP #0
         BEQ @2
         CLC
         ADC #$62-1
         BNE @5      ; FORCED
@3:      CMP #$74    ; 't'
         BNE @5
@4:      LDA RANDOM
         AND #3
;        CMP #0
         BEQ @4
         CLC
         ADC #$65-1
@5:      STA (ADR1),Y
         INY
         BNE @1
         INC ADR1+1
         LDA ADR1+1
         CMP #>(MAP+$2800)
         BNE @1
;
         LDA #<MAP
         STA ADR1
         LDA #>MAP
         STA ADR1+1
         LDA #<(MAP+255-40)
         STA ADR2
         LDA #>(MAP+255-40)
         STA ADR2+1
         LDX #0
@6:      LDY #0
@7:      LDA (ADR1),Y
         STA (ADR2),Y
         INY
         CPY #40
         BNE @7
         INC ADR1+1
         INC ADR2+1
         INX
         CPX #40
         BNE @6
;
         LDY LEVEL
         CPY #2
         BNE @71
;
         LDA #$7E
         STA TEMP1
         LDA #$13
         STA TEMP2
         JSR COMPUTE_MAP_ADR
         LDX #2
@69:     LDY #$D
         LDA #0
@70:     STA (ADR1),Y
         DEY
         BPL @70
         INC ADR1+1
         DEX
         BPL @69
@71:
;
         LDA LEVEL
         ASL
         TAX
         LDA SCAN_INFO,X
         STA ADR1
         LDA SCAN_INFO+1,X
         STA ADR1+1
         LDA #<SCANNER
         STA ADR2
         LDA #>SCANNER
         STA ADR2+1
         LDA #<(SCANNER+1600)
         STA TEMP2
         LDA #>(SCANNER+1600)
         STA TEMP3
         LDA #1
         STA TEMP4
         JSR UNPACK
;
         LDA #<SCANNER
         STA ADR1
         LDA #>SCANNER
         STA ADR1+1
         LDA #<(SCANNER+$1B)
         STA ADR2
         LDA #>(SCANNER+$1B)
         STA ADR2+1
         LDX #39
@50:     LDY #12
@51:     LDA (ADR1),Y
         STA (ADR2),Y
         DEY
         BPL @51
         LDA ADR1
         CLC
         ADC #40
         STA ADR1
         BCC @52
         INC ADR1+1
@52:     LDA ADR2
         CLC
         ADC #40
         STA ADR2
         BCC @53
         INC ADR2+1
@53:     DEX
         BPL @50
;
S_BEGIN:
         LDX #8
         STX SLAVES_LEFT
         DEX         ; X=7
         LDA #OFF
@1:      STA SLAVE_STATUS,X
         DEX
         BPL @1
         LDA LEVEL
         CMP #2
         BEQ @12
         LDX #7
@9:      LDA #<MAP
         STA ADR1
         LDA #>MAP
         STA ADR1+1
;
         LDY #0
@10:     LDA (ADR1),Y
         CMP #$48    ; '^H'
         BNE @11
         INY
         LDA (ADR1),Y
         DEY
         CMP #$48
         BNE @11
         DEC ADR1+1
         LDA (ADR1),Y
         INC ADR1+1
         CMP #$1F    ; '?'
         BNE @11
         LDA RANDOM
         CMP #10
         BCC @11
         CMP #50
         BCS @11
         TYA
         CLC
         ADC #5
         STA SLAVE_X,X
         LDA ADR1+1
         SEC
         SBC #>MAP
         STA SLAVE_Y,X
         LDA #1
         STA (ADR1),Y
         LDA #ON
         STA SLAVE_STATUS,X
         LDA #$10
         STA SLAVE_DX,X
         DEX
         BMI @12
@11:     INY
         BNE @10
         INC ADR1+1
         LDA ADR1+1
         CMP #>(MAP+$2800)
         BNE @10
         TXA
         BPL @9
;
@12:
         LDA #NEW_PLAYER_MODE
         STA MODE
         RTS
;
LEVEL_COLOR:
 .byte $42
 .byte $C2
 .byte $42
LEVEL_CHOP_START:
 .byte 90,100
 .byte 119,100
 .byte 116,170
LEVEL_START:
 .byte $02,$FF
 .byte $6D,$FF
 .byte $6E,$18
SCAN_INFO:
 .word PACKED_SCAN_1  ; LVL 1
 .word PACKED_SCAN_2  ; LVL 2
 .word PACKED_SCAN_1  ; LVL 1
TANK_START_X_L1:
 .byte $53,$63,$90,$A0,$59,$AE
TANK_START_Y_L1:
 .byte $12,$12,$12,$12,$26,$26
TANK_START_X_L2:
 .byte $50,$65,$A0,$B5,$3D,$54
TANK_START_Y_L2:
 .byte $0C,$0C,$0C,$0C,$26,$26
;
ENTER:
 .byte $A5,$AE,$B4,$A5,$B2,$A9,$AE,$A7  ; -/ENTERING/
 .byte $FF
LVL_1:
 .byte $B6,$A1,$B5,$AC,$B4,$B3  ; -/VAULTS/
 .byte $00,$00  ; /  /
 .byte $AF,$A6  ; -/OF/
 .byte $00,$00  ; /  /
 .byte $A4,$B2,$A1,$A3,$AF,$AE,$A9,$B3  ; -/DRACONIS/
 .byte $FF
LVL_2:
 .byte $A3,$B2,$B9,$B3,$B4,$A1,$AC,$AC,$A9,$AE,$A5  ; -/CRYSTALLINE/
 .byte $00,$00  ; /  /
 .byte $A3,$A1,$B6,$A5,$B3  ; -/CAVES/
 .byte $FF
;
INC_GAME_POINTS:
         CLC
         ADC GAME_POINTS
         STA GAME_POINTS
         RTS
;
M_TAB:
 .byte <-2,<-1,0
;
M_GAME_OVER:
         JSR SCREEN_OFF
;
         LDA SLAVES_SAVED
         LSR
         LSR
         JSR INC_GAME_POINTS
         LDA FORT_STATUS
         CMP #OFF
         BNE @1
         LDA #3
         JSR INC_GAME_POINTS
@1:      LDA LEVEL
         CMP #3
         BNE @2
         INC GAME_POINTS
@2:      JSR INC_GAME_POINTS
         LDA SCORE3
         JSR INC_GAME_POINTS
;
         LDX GRAV_SKILL
         LDA M_TAB,X
         JSR INC_GAME_POINTS
         LDA #2
         CLC
         SBC CHOPS
         EOR #<-1
         JSR INC_GAME_POINTS
         LDX PILOT_SKILL
         LDA M_TAB,X
         JSR INC_GAME_POINTS
;
         LDA GAME_POINTS
         BPL @3
         LDA #0
@3:      CMP #16
         BCC @4
         LDA #15
@4:      STA GAME_POINTS
;
         LDA SCORE3
         CMP HI3
         BNE @51
         LDA SCORE2
         CMP HI2
         BNE @51
         LDA SCORE1
         CMP HI1
         BCC @52
@53:     LDA SCORE1
         STA HI1
         LDA SCORE2
         STA HI2
         LDA SCORE3
         STA HI3
         JMP @52
@51:     BCS @53
;
@52:     LDA #2
         STA TEMP1
         LDA #0
         STA TEMP2
         STA S_FLG
         LDX #<HS
         LDY #>HS
         JSR PRINT
         LDA #<(PLAY_SCRN+24)
         STA S_ADR
         LDA #>(PLAY_SCRN+24)
         STA S_ADR+1
         LDX #5
         LDA HI3
         JSR DDIG
         LDA HI2
         JSR DDIG
         LDA HI1
         JSR DDIG
;
         LDA #3
         STA TEMP1
         LDA #5
         STA TEMP2
         LDX #<G_1   ; YOUR
         LDY #>G_1   ; MISSION
         JSR PRINT
         LDA #21
         STA TEMP1
         LDX #<G_A   ; ABORTED
         LDY #>G_A
         LDA LEVEL
         CMP #3
         BNE @5
         LDX #<G_C   ; COMPLETED
         LDY #>G_C
@5:      JSR PRINT
;
         LDX #7
         STX TEMP1
         INX         ; X=8
         STX TEMP2
         LDX #<G_2   ; YOUR
         LDY #>G_2   ; RANK
         JSR PRINT
         LDA #21
         STA TEMP1
         LDA #10
         STA TEMP2
         LDX #<G_3   ; CLASS
         LDY #>G_3
         JSR PRINT
         LDA GAME_POINTS
         AND #3
         EOR #3
         CLC
         ADC #1
         LDY #12
         ORA #$10+$80
         STA (ADR1),Y
         CMP #$10+128
         BNE @6
         LDA #$A+128
@6:      INY
         AND #$8F
         STA (ADR1),Y
         LDA #3
         STA TEMP1
         LDA GAME_POINTS
         LSR
         LSR
         AND #3
         ASL
         TAY
         LDX RATING,Y
         LDA RATING+1,Y
         TAY
         JSR PRINT
         LDA #<-1
         STA TIM6_VAL
         LDA #TITLE_MODE
         STA MODE
;        LDA #1
         STA DEMO_STATUS
         RTS
;
G_1:
 .byte $2D,$29,$33,$33,$29,$2F,$2E  ; /MISSION/
 .byte $FF
G_A:
 .byte $21,$22,$2F,$32,$34,$25,$24  ; /ABORTED/
 .byte $FF
G_C:
 .byte $23,$2F,$2D,$30,$2C,$25,$34,$25,$24  ; /COMPLETED/
 .byte $FF
G_2:
 .byte $39,$2F,$35,$32,$00,$00,$32,$21,$2E,$2B,$00,$00,$29,$33  ; /YOUR  RANK  IS/
 .byte $FF
G_3:
 .byte $A3,$AC,$A1,$B3,$B3  ; -/CLASS/
 .byte $FF
RATING:
 .word R_1,R_2,R_3,R_4
R_1:
 .byte $B3,$B0,$A1,$B2,$B2,$AF,$B7  ; -/SPARROW/
 .byte $FF
R_2:
 .byte $A3,$AF,$AE,$A4,$AF,$B2  ; -/CONDOR/
 .byte $FF
R_3:
 .byte $A8,$A1,$B7,$AB  ; -/HAWK/
 .byte $FF
R_4:
 .byte $A5,$A1,$A7,$AC,$A5  ; -/EAGLE/
 .byte $FF
HS:
 .byte $A8,$A9,$A7,$A8  ; -/HIGH/
 .byte $00,$00  ; /  /
 .byte $B3,$A3,$AF,$B2,$A5  ; -/SCORE/
 .byte $FF
;
; EOF
;
