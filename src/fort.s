;******************
;*      Fort      *
;*   Apocalypse   *
;*      ROM       *
;*                *
;* By Steve Hales *
;*                *
;*   Copyright    *
;*  September 1   *
;* 1982  Synapse  *
;*    Software    *
;*                *
;******************
;
; FEBUARY 8, 1983
;
; SYSTEM EQUATES
;
FRAME    = $14
ATTRACT  = $4D
VDSLST   = $200
VVBLKI   = $222
VVBLKD   = $224
SDMCTL   = $22F
SDLST    = $230
PRIOR    = $26F
PCOLR0   = $2C0
PCOLR1   = $2C1
PCOLR2   = $2C2
PCOLR3   = $2C3
COLOR0   = $2C4
COLOR1   = $2C5
COLOR2   = $2C6
COLOR3   = $2C7
COLOR4   = $2C8
DMACTL   = $D400
M0PF     = $D000
M1PF     = $D001
M2PF     = $D002
M3PF     = $D003
P0PF     = $D004
P1PF     = $D005
P2PF     = $D006
P3PF     = $D007
M0PL     = $D008
M1PL     = $D009
M2PL     = $D00A
M3PL     = $D00B
P0PL     = $D00C
P1PL     = $D00D
P2PL     = $D00E
P3PL     = $D00F
COLPM0   = $D012
COLPM1   = $D013
COLPM2   = $D014
COLPM3   = $D015
COLPF0   = $D016
COLPF1   = $D017
COLPF2   = $D018
COLPF3   = $D019
COLBK    = $D01A
HITCLR   = $D01E
CHBASE   = $D409
RANDOM   = $D20A
CHBAS    = $2F4
CH       = $2FC
CH2      = $2F2
KBCODE   = $D209
GRACTL   = $D01D
SIZEP0   = $D008
SIZEP1   = $D009
SIZEP2   = $D00A
SIZEP3   = $D00B
PMBASE   = $D407
HPOSP0   = $D000
HPOSP1   = $D001
HPOSP2   = $D002
HPOSP3   = $D003
HPOSM0   = $D004
HPOSM1   = $D005
HPOSM2   = $D006
HPOSM3   = $D007
SIZEM    = $D00C
CONSOL   = $D01F
NMIEN    = $D40E
DLIST    = $D402
HSCROL   = $D404
VSCROL   = $D405
WSYNC    = $D40A
VCOUNT   = $D40B
STICK    = $278
TRIG0    = $D010
AUDF1    = $D200
AUDC1    = $D201
AUDF2    = $D202
AUDC2    = $D203
AUDF3    = $D204
AUDC3    = $D205
AUDF4    = $D206
AUDC4    = $D207
AUDCTL   = $D208
SKCTL    = $D20F
SKSTAT   = $D20F
CDTMV1   = $218
CDTMV2   = $21A
CDTMA1   = $226
CDTMA2   = $228
VVBLKI_RET = $E45F
VVBLKD_RET = $E462
;
; CONSTANTS
;
MIS      = $300
PL0      = $400
PL1      = $500
PL2      = $600
PL3      = $700
RIGHT    = $8
LEFT     = $4
DOWN     = $2
UP       = $1
CHECK_SUM = $264C
;
; CHANGE THESE CONSTANTS
; WHEN PROGRAM NEED TO GO MOBILE
;
;                START    LEN
PLAYER       = $0         ; $800  R
PLAY_SCRN    = $300       ; $300  R
CHR_SET1     = $800       ; $400  R
CHR_SET2     = $C00       ; $400  R
POD_1        = $C00+920   ; $4E   R
POD_2        = $3925      ; $9B   R
MAP          = $1100+3    ; $2800 R
SLAVES       = $3904      ; $20   R
SCANNER      = $39C0      ; $640  R
RAM1_STUFF   = $C00+144   ; $48
RAM2_STUFF   = $100
PL           = $8000
PACKED_MAP   = PL         ; $D34
PACKED_SCAN  = PL+$D34    ; $4ED
PROGRAM      = PL+$1221   ; $2D2C
S_LINE1        = CHR_SET1+736
S_LINE2        = CHR_SET1+832
S_LINE3        = CHR_SET1+928
LASERS_1       = CHR_SET2+8
LASERS_2       = CHR_SET2+40
LASER_3        = CHR_SET2+72
BLOCK_1        = CHR_SET2+80
BLOCK_2        = CHR_SET2+88
BLOCK_3        = CHR_SET2+96
BLOCK_4        = CHR_SET2+104
BLOCK_5        = CHR_SET2+112
BLOCK_6        = CHR_SET2+120
BLOCK_7        = CHR_SET2+128
BLOCK_8        = CHR_SET2+136
WINDOW_1       = CHR_SET2+712
WINDOW_2       = CHR_SET2+720
EXP            = $20
EXP2           = $3F
EXPLOSION      = CHR_SET2+256
EXPLOSION2     = CHR_SET2+504
MISS_LEFT      = $71
MISS_RIGHT     = $72
MISS_CHR_LEFT  = CHR_SET2+904
MISS_CHR_RIGHT = CHR_SET2+912
EXP_WALL       = $47+128
;
MAX_LEFT       = 48
MAX_RIGHT      = 192
MAX_UP         = 100
MAX_DOWN       = 212
MAX_FUEL       = $2000
MIN_LEFT       = 110
MIN_RIGHT      = 130
MIN_UP         = 146
MIN_DOWN       = 166
MAX_TANKS      = 6
POD_SPEED      = 15
;
; ZERO PAGE USAGE
;
ADR1     = $15
ADR2     = ADR1+2
TEMP1    = ADR2+2
TEMP2    = TEMP1+1
TEMP3    = TEMP2+1
TEMP4    = TEMP3+1
TEMP5    = TEMP4+1
TEMP6    = TEMP5+1
TEMP_MODE = TEMP6+1
;
ADR1_I   = TEMP_MODE+1
ADR2_I   = ADR1_I+2
TEMP1_I  = ADR2_I+2
TEMP2_I  = TEMP1_I+1
TEMP3_I  = TEMP2_I+1
TEMP4_I  = TEMP3_I+1
S_ADR    = TEMP4_I+1
S_TEMP   = S_ADR+2
S_FLG    = S_TEMP+1
TANK_START_X = S_FLG+1
TANK_START_Y = TANK_START_X+MAX_TANKS
TIM1_VAL = TANK_START_Y+MAX_TANKS  ; LASER 1
TIM2_VAL = TIM1_VAL+1  ; LASER 2
TIM3_VAL = TIM2_VAL+1  ; CHOP EXPLODE
TIM4_VAL = TIM3_VAL+1  ; RE FUEL
TIM5_VAL = TIM4_VAL+1  ; TANK EXPLODE
TIM6_VAL = TIM5_VAL+1  ; DEMO TIMER
TIM7_VAL = TIM6_VAL+1  ; ROBO EXPLODE
TIM8_VAL = TIM7_VAL+1  ; ROBO MISSILE
TIM9_VAL = TIM8_VAL+1  ; SLAVE MESS
SSIZEM   = TIM9_VAL+1
S1_1_VAL = $43
S1_2_VAL = S1_1_VAL+1
S2_VAL   = S1_2_VAL+1
S3_VAL   = S2_VAL+1
S4_VAL   = S3_VAL+1
S5_VAL   = S4_VAL+1
S6_VAL   = S5_VAL+1  ; MISSILE SND
GAME_POINTS = S6_VAL+1
DEMO_STATUS = GAME_POINTS+1
DEMO_COUNT  = DEMO_STATUS+1
;
MAX_PODS     = 39
;
POD_STATUS   = POD_1
POD_DX       = POD_STATUS+MAX_PODS
POD_X        = POD_2
POD_Y        = POD_X+MAX_PODS
POD_TEMP1    = POD_Y+MAX_PODS
POD_TEMP2    = POD_TEMP1+MAX_PODS
;
SLAVE_STATUS = SLAVES
SLAVE_X      = SLAVE_STATUS+8
SLAVE_Y      = SLAVE_X+8
SLAVE_DX     = SLAVE_Y+8
;
         .include "fort7.s"
;
         .segment "CODE"
         .export CART_START
;
;
;
; REST OF PROGRAM IS
; INSIDE INCLUDE FILES
;
;
         .include "fnt1.s"
         .include "fnt2.s"
;
         .include "fort1.s"
         .include "fort2.s"
         .include "fort3.s"
         .include "fort4.s"
         .include "fort5.s"
         .include "fort6.s"
         .include "fort8.s"
;
END_CART:
         .segment "CARTHDR"
         .word CART_START
         .byte $00
         .byte %10000100
         .word CART_START
;
; EOF
;
