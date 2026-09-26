; Picocomputer boot, and the parts of the Atari OS that the game uses

.include "rp6502.inc"
.include "atari.inc"

.import CART_START
.import antic_init, antic_frame, antic_rainbow
.import gtia_init, gtia_frame
.import pokey_init, pokey_frame
.import input_init, input_frame, input_stick, input_trig
.import __BSS_RUN__, __BSS_SIZE__
.export RAINBOW, LEAVE_VBI, PACE, xreg_call, xreg_buf, read_t2, irq_cycles, overruns, phase, profile, pace_calls
.exportzp ptr1, ptr2, ptr3, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7, tmp8

; Main-thread cycles a frame in GO mode: those of the Atari, less its
; display DMA and its interrupt work. The main loop then runs 0.54 times a
; frame at the start of the first level, as it does on the Atari.
PACE_CYCLES = 14500

.zeropage
ptr1:   .res 2
ptr2:   .res 2
ptr3:   .res 2
tmp1:   .res 1
tmp2:   .res 1
tmp3:   .res 1
tmp4:   .res 1
tmp5:   .res 1
tmp6:   .res 1
tmp7:   .res 1
tmp8:   .res 1

.bss
irq_start:   .res 2         ; VIA timer 2 when the frame began
irq_cycles:  .res 2         ; cycles the last frame took, modulo 65536
irq_vsync:   .res 1         ; RIA_VSYNC when the frame began
overruns:    .res 1         ; frames that ran into the next VSYNC
phase:       .res 32        ; cycles into the frame at the end of each part
xreg_buf:    .res 4 + 2 * 8 ; device, channel, address, bytes, values
irq_depth:   .res 1         ; nonzero while a frame is being run
t2_last:     .res 2         ; VIA timer 2 at the last mark
main_cycles: .res 3         ; main-thread cycles since the last PACE
budget:      .res 3         ; signed main-thread cycles left
pace_frame:  .res 1         ; RTCLOK+2 at the last PACE
pace_calls:  .res 1         ; main loop passes in GO mode

.segment "STARTUP"
        jmp boot

.code

boot:
        sei
        cld
        ldx #$FF
        txs
        stz RIA_IRQ
        ; Zero the BSS.
        lda #<__BSS_RUN__
        sta ptr1
        lda #>__BSS_RUN__
        sta ptr1+1
        ldx #>__BSS_SIZE__
        ldy #0
        tya
:       sta (ptr1),y
        iny
        bne :-
        inc ptr1+1
        dex
        bne :-
        ldx #<__BSS_SIZE__
        beq :++
:       sta (ptr1),y
        iny
        dex
        bne :-
:
        ; VIA timer 2 runs free as a cycle counter.
        lda #$20
        trb VIA_CR
        lda #$FF
        sta VIA_T2CL
        sta VIA_T2CH
        ; The OS vertical blank exits that INIT.OS reads from the OS ROM.
        lda #$4C
        sta SYSVBV
        sta XITVBV
        lda #<sysvbv
        sta SYSVBV+1
        lda #>sysvbv
        sta SYSVBV+2
        lda #<xitvbv
        sta XITVBV+1
        lda #>xitvbv
        sta XITVBV+2
        lda #<irq
        sta $FFFE
        lda #>irq
        sta $FFFF
        stz irq_depth
        jsr antic_init
        jsr gtia_init
        jsr pokey_init
        jsr input_init
        jsr mark
        lda #$80
        sta RIA_IRQ
        jmp CART_START

; VSYNC. The frame just ending is displayed and its collisions are found,
; then the Atari vertical blank runs as the OS ran it.
irq:
        pha
        txa
        pha
        tya
        pha
        cld
        lda RIA_IRQ
        lda irq_depth
        beq @frame
        ; A VSYNC during the end of the previous one. The Atari OS runs
        ; only the first stage of its vertical blank then.
        jsr rtclock
        jmp exit
@frame:
        inc irq_depth
        jsr read_t2
        sta irq_start
        stx irq_start+1
        jsr mark
        clc
        adc main_cycles
        sta main_cycles
        txa
        adc main_cycles+1
        sta main_cycles+1
        bcc :+
        inc main_cycles+2
:       jsr add_budget
        lda RIA_VSYNC
        sta irq_vsync
        jsr antic_frame
        ldy #0
        jsr profile
        jsr gtia_frame
        ldy #2
        jsr profile
        jsr pokey_frame
        ldy #4
        jsr profile
        jsr input_frame
        ldy #6
        jsr profile
        bit NMIEN
        bvc xitvbv
        jmp (VVBLKI)

; The OS vertical blank, stage 1 and 2.
sysvbv:
        jsr rtclock
        lda SDLSTL
        sta DLISTL
        lda SDLSTH
        sta DLISTH
        lda SDMCTL
        sta DMACTL
        lda GPRIOR
        sta PRIOR
        ldx #8
:       lda PCOLR0,x
        sta COLPM0,x
        dex
        bpl :-
        lda CHBAS
        sta CHBASE
        lda input_stick
        sta STICK0
        lda input_trig
        sta STRIG0
        jmp (VVBLKD)

xitvbv:
        stz irq_depth
        ldy #8
        jsr profile
        lda RIA_VSYNC
        cmp irq_vsync
        beq :+
        inc overruns
:       jsr read_t2
        sta tmp1
        sec
        lda irq_start
        sbc tmp1
        sta irq_cycles
        stx tmp1
        lda irq_start+1
        sbc tmp1
        sta irq_cycles+1
exit:
        jsr mark
        pla
        tay
        pla
        tax
        pla
        rti

rtclock:
        inc RTCLOK+2
        bne :+
        inc RTCLOK+1
        bne :+
        inc RTCLOK
:       rts

; T1 on the title screen sets COLPF3 to VCOUNT*2 on every scanline.
RAINBOW:
        lda #1
        sta antic_rainbow
:       wai
        bra :-

; T2 leaves the vertical blank without returning to the OS, then T3 waits
; for the top of the next frame before it enables the DLIs.
LEAVE_VBI:
        stz irq_depth
        stz antic_rainbow
        lda RIA_VSYNC
:       cmp RIA_VSYNC
        beq :-
        rts

; The Atari runs the GO mode main loop as often as its CPU allows, so the
; game speed of pods, tanks and missiles follows the main loop. The main
; thread gets the cycles it had on the Atari in each frame.
PACE:
        php
        sei
        inc pace_calls
        lda RTCLOK+2
        sec
        sbc pace_frame
        cmp #3
        bcc @count
        ; Not paced since two frames ago, so start over.
        stz budget
        stz budget+1
        stz budget+2
        stz main_cycles
        stz main_cycles+1
        stz main_cycles+2
        jsr mark
        bra @done
@count:
        jsr mark
        clc
        adc main_cycles
        sta main_cycles
        txa
        adc main_cycles+1
        sta main_cycles+1
        lda #0
        adc main_cycles+2
        sta main_cycles+2
        sec
        lda budget
        sbc main_cycles
        sta budget
        lda budget+1
        sbc main_cycles+1
        sta budget+1
        lda budget+2
        sbc main_cycles+2
        sta budget+2
        stz main_cycles
        stz main_cycles+1
        stz main_cycles+2
@wait:
        bit budget+2
        bpl @done
        lda RTCLOK+2
        plp
        php
:       cmp RTCLOK+2
        beq :-
        ; The wait is not main-thread work.
        sei
        stz main_cycles
        stz main_cycles+1
        stz main_cycles+2
        jsr mark
        bra @wait
@done:
        lda RTCLOK+2
        sta pace_frame
        plp
        rts

; A frame gives the main thread PACE_CYCLES more, up to one frame ahead.
add_budget:
        clc
        lda budget
        adc #<PACE_CYCLES
        sta budget
        lda budget+1
        adc #>PACE_CYCLES
        sta budget+1
        lda budget+2
        adc #0
        sta budget+2
        bmi @done
        lda budget+2
        bne @clamp
        lda budget
        cmp #<PACE_CYCLES
        lda budget+1
        sbc #>PACE_CYCLES
        bcc @done
@clamp:
        lda #<PACE_CYCLES
        sta budget
        lda #>PACE_CYCLES
        sta budget+1
        stz budget+2
@done:
        rts

; Cycles since the last mark, in AX.
mark:
        jsr read_t2
        tay
        sec
        lda t2_last
        sty t2_last
        sty tmp1
        sbc tmp1
        pha
        lda t2_last+1
        stx t2_last+1
        stx tmp1
        sbc tmp1
        tax
        pla
        rts

; Cycles since the start of the frame at phase+Y.
profile:
        jsr read_t2
        sta tmp1
        sec
        lda irq_start
        sbc tmp1
        sta phase,y
        stx tmp1
        lda irq_start+1
        sbc tmp1
        sta phase+1,y
        rts

; VIA timer 2 in AX.
read_t2:
:       ldx VIA_T2CH
        lda VIA_T2CL
        cpx VIA_T2CH
        bne :-
        rts

; Set extended registers from xreg_buf.
xreg_call:
        lda xreg_buf
        sta RIA_XSTACK
        lda xreg_buf+1
        sta RIA_XSTACK
        lda xreg_buf+2
        sta RIA_XSTACK
        ldx #0
:       lda xreg_buf+5,x
        sta RIA_XSTACK
        lda xreg_buf+4,x
        sta RIA_XSTACK
        inx
        inx
        cpx xreg_buf+3
        bne :-
        lda #RIA_OP_XREG
        sta RIA_OP
        jmp RIA_SPIN
