; POKEY sound on the PSG, and the POKEY RANDOM register
;
; Once a frame each PSG channel is set from a POKEY channel. Pure tones
; become square waves, and the polynomial counters become noise or buzz at
; the rate POKEY clocked them.

.include "rp6502.inc"
.include "atari.inc"
.include "xram.inc"

.importzp ptr1, ptr2, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7, tmp8
.export pokey_init, pokey_frame

; PSG frequencies are Hz*3. The pure tone of a POKEY channel is its clock
; over 2*(AUDF+M).
F64K  = 95881               ; 3 * 63920.8 / 2
F15K  = 23550               ; 3 * 15699.9 / 2
F179M = 2684659             ; 3 * 1789772.5 / 2

.bss
seed:     .res 2
last_f:   .res 4            ; AUDF, AUDC and AUDCTL now on the PSG
last_c:   .res 4
last_ctl: .res 1

.rodata

; The PSG frequency of each AUDF, for the 64 kHz, 15 kHz and 1.79 MHz
; clocks. Frequencies above 65535 are inaudible, so they are cut there.
.macro frequencies k, m
    .repeat 256, i
        .word (k / (i + m)) - ((k / (i + m)) > $FFFF) * ((k / (i + m)) - $FFFF)
    .endrepeat
.endmacro
freq64:  frequencies F64K, 1
freq15:  frequencies F15K, 1
freq179: frequencies F179M, 4

.code

pokey_init:
        xreg 0, 1, 0, XRAM_PSG
        lda #<XRAM_PSG
        sta RIA_ADDR0
        lda #>XRAM_PSG
        sta RIA_ADDR0+1
        lda #1
        sta RIA_STEP0
        ldx #64
:       stz RIA_RW0
        dex
        bne :-
        ; Changed channels are written, and AUDCTL is never $FF.
        lda #$FF
        sta last_ctl
        ; A read of RANDOM returns the next of 32K random bytes, through
        ; portal 1.
        lda #RIA_ATTR_LRAND
        sta RIA_A
        lda #RIA_OP_ATTR_GET
        sta RIA_OP
        jsr RIA_SPIN
        sta seed
        stx seed+1
        ora seed+1
        bne :+
        inc seed
:       lda #<XRAM_RANDOM
        sta RIA_ADDR0
        lda #>XRAM_RANDOM
        sta RIA_ADDR0+1
        ldy #$40
        ldx #0
:       jsr rng
        sta RIA_RW0
        lda seed
        sta RIA_RW0
        dex
        bne :-
        dey
        bne :-
        lda #1
        sta RIA_STEP1
        ; fall through

; Start RANDOM at a new place in the table.
reseed:
        jsr rng
        and #$3F
        clc
        adc #>XRAM_RANDOM
        sta RIA_ADDR1+1
        lda seed
        sta RIA_ADDR1
        rts

; 16-bit xorshift, 7 9 8. The new value is in seed, its high byte in A.
rng:
        lda seed+1
        lsr
        lda seed
        ror
        eor seed+1
        sta seed+1
        ror
        eor seed
        sta seed
        eor seed+1
        sta seed+1
        rts

pokey_frame:
        jsr reseed
        lda #1
        sta RIA_STEP0
        lda AUDCTL
        cmp last_ctl
        beq :+
        sta last_ctl
        ; A new AUDCTL changes every channel.
        lda #$FF
        sta last_c
        sta last_c+1
        sta last_c+2
        sta last_c+3
:       ldx #0
@chan:  stx tmp8
        txa
        asl
        tay
        lda AUDF1,y
        sta tmp1
        lda AUDC1,y
        sta tmp2
        cmp last_c,x
        bne :+
        lda tmp1
        cmp last_f,x
        beq @next
:       lda tmp1
        sta last_f,x
        lda tmp2
        sta last_c,x
        jsr channel
@next:  ldx tmp8
        inx
        cpx #4
        bne @chan
        rts

; PSG channel tmp8 from AUDF tmp1 and AUDC tmp2.
channel:
        ; psg_t channel at XRAM_PSG + 8*channel
        lda tmp8
        asl
        asl
        asl
        sta RIA_ADDR0
        lda #>XRAM_PSG
        sta RIA_ADDR0+1
        ; Silent at volume 0, and in volume-only mode, which outputs a level
        ; and no wave.
        lda tmp2
        and #$1F
        cmp #$01
        bcs :+
        jmp @off
:       cmp #$10
        bcc :+
        jmp @off
:       ; The clock of this channel
        ldy tmp1
        lda last_ctl
        ldx tmp8
        cpx #0
        bne :+
        bit #$40
        bne @fast
:       cpx #2
        bne :+
        bit #$20
        bne @fast
:       and #$01
        bne @slow
        lda #<freq64
        ldx #>freq64
        bra @table
@slow:  lda #<freq15
        ldx #>freq15
        bra @table
@fast:  lda #<freq179
        ldx #>freq179
@table: sta ptr2
        stx ptr2+1
        tya
        asl
        tay
        bcc :+
        inc ptr2+1
:       lda (ptr2),y
        sta tmp3            ; frequency of the pure tone
        iny
        lda (ptr2),y
        sta tmp4
        ; Distortion: bits 7-5 of AUDC.
        lda tmp2
        lsr
        lsr
        lsr
        lsr
        lsr
        tax
        lda wave,x
        sta tmp5
        ; Buzz from the 4 and 5-bit polynomials repeats every 15 or 31
        ; POKEY clocks, so it sounds a 15th or a 31st of the pure tone.
        lda divisor,x
        beq @write
        sta tmp6
        jsr div_freq
@write:
        lda tmp3            ; freq
        sta RIA_RW0
        lda tmp4
        sta RIA_RW0
        lda #128            ; duty
        sta RIA_RW0
        lda tmp2            ; vol_attack and vol_decay
        and #$0F
        tax
        lda attenuation,x
        sta RIA_RW0
        sta RIA_RW0
        lda tmp5            ; wave_release
        sta RIA_RW0
        lda #PSG_GATE       ; pan_gate
        sta RIA_RW0
        rts
@off:   lda tmp8
        asl
        asl
        asl
        ora #6
        sta RIA_ADDR0
        stz RIA_RW0         ; pan_gate
        rts

; tmp4:tmp3 = tmp4:tmp3 / tmp6
div_freq:
        stz tmp7
        ldx #16
:       asl tmp3
        rol tmp4
        rol tmp7
        lda tmp7
        cmp tmp6
        bcc :+
        sbc tmp6
        sta tmp7
        inc tmp3
:       dex
        bne :--
        rts

; Distortions 0-7 of AUDC: the PSG wave, and the divisor of the tone.
wave:
        .byte PSG_WAVE_NOISE     ; 5-bit and 17-bit polynomials
        .byte PSG_WAVE_SQUARE    ; 5-bit
        .byte PSG_WAVE_NOISE     ; 5-bit and 4-bit
        .byte PSG_WAVE_SQUARE    ; 5-bit
        .byte PSG_WAVE_NOISE     ; 17-bit
        .byte PSG_WAVE_SQUARE    ; pure tone
        .byte PSG_WAVE_SAWTOOTH  ; 4-bit
        .byte PSG_WAVE_SQUARE    ; pure tone
divisor:
        .byte 0, 31, 0, 31, 0, 0, 15, 0

; POKEY volume 0-15 is linear and PSG attenuation is logarithmic.
attenuation:
        .byte $F0, $C0, $A0, $90, $70, $60, $50, $40
        .byte $30, $30, $20, $20, $10, $10, $10, $00
