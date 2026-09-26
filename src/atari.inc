; Atari 400/800 hardware and OS locations on the Picocomputer
;
; The write registers are at their Atari addresses. The read registers
; share those addresses on the Atari, but here all of them are RAM, so
; each read register is $100 above its write register.

.ifndef ATARI_INC
ATARI_INC = 1

; OS zero page
RTCLOK   = $12
ATRACT   = $4D

; OS page 2
VDSLST   = $0200
VVBLKI   = $0222
VVBLKD   = $0224
SDMCTL   = $022F
SDLSTL   = $0230
SDLSTH   = $0231
GPRIOR   = $026F
STICK0   = $0278
STRIG0   = $0284
PCOLR0   = $02C0
COLOR0   = $02C4
COLOR4   = $02C8
CHBAS    = $02F4

; OS vertical blank exits, as JMP instructions
SYSVBV   = $E45F
XITVBV   = $E462

; GTIA
HPOSP0   = $D000
HPOSM0   = $D004
SIZEP0   = $D008
SIZEM    = $D00C
COLPM0   = $D012
COLPF0   = $D016
COLPF1   = $D017
COLPF2   = $D018
COLPF3   = $D019
COLBK    = $D01A
PRIOR    = $D01B
GRACTL   = $D01D
M0PF     = $D100
P0PF     = $D104
M0PL     = $D108
P0PL     = $D10C
TRIG0    = $D110
CONSOL   = $D11F

; POKEY
AUDF1    = $D200
AUDC1    = $D201
AUDCTL   = $D208
KBCODE   = $D309
SKSTAT   = $D30F

; ANTIC
DMACTL   = $D400
DLISTL   = $D402
DLISTH   = $D403
HSCROL   = $D404
VSCROL   = $D405
PMBASE   = $D407
CHBASE   = $D409
NMIEN    = $D40E

.endif
