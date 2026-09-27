; Picocomputer boot, and the parts of the Atari OS that the game uses

.include "rp6502.inc"
.include "atari.inc"

.import CART_START
.import antic_init, antic_frame, antic_tiles, antic_rainbow
.import gtia_init, gtia_frame
.import pokey_init, pokey_frame
.import input_init, input_frame, input_stick, input_trig
.import __BSS_RUN__, __BSS_SIZE__
.export RAINBOW, LEAVE_VBI, xreg_call, xreg_buf, read_t2, atari_cycles, overruns
.exportzp ptr1, ptr2, ptr3, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7, tmp8

; The main thread runs as fast as it ran on an NTSC Atari, which has the
; cycles of a frame that DMA and the interrupts leave. MAIN_CYCLES is a
; frame of 262 scanlines of 114 cycles, less the 9 cycles of each scanline
; that memory refresh takes. With it the GO mode main loop at the start of
; the first level runs 0.30 passes a frame, and 0.31 on the Atari.
MAIN_CYCLES = 262 * (114 - 9)

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
atari_cycles: .res 2        ; the DMA and interrupt cycles of this frame
slice:        .res 2        ; main-thread cycles in VIA timer 1, or 0
slice_t2:     .res 2        ; VIA timer 2 when timer 1 started
carry:        .res 2        ; main-thread cycles the last frame had no room for
irq_vsync:    .res 1        ; RIA_VSYNC when the frame began
vbi_t2:       .res 2        ; VIA timer 2 when the vertical blank began
overruns:     .res 1        ; frames that ran into the next VSYNC
xreg_buf:     .res 4 + 2 * 8 ; device, channel, address, bytes, values
irq_depth:    .res 1        ; nonzero while a frame is being run

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
        ; VIA timer 1 is one-shot and timer 2 runs free as a cycle counter.
        lda #$E0
        trb VIA_CR
        lda #$7F
        sta VIA_IER
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
        jsr antic_init
        jsr gtia_init
        jsr pokey_init
        jsr input_init
        lda #$80
        sta RIA_IRQ
        jmp CART_START

; VSYNC, or the end of the main thread's cycles. The frame just ending is
; displayed and its collisions are found, then the Atari vertical blank runs
; as the OS ran it.
irq:
        pha
        txa
        pha
        tya
        pha
        cld
        lda slice
        ora slice+1
        beq @vsync
        lda #$40            ; no more timer 1 interrupts
        sta VIA_IER
        bit VIA_IFR
        bvc @early
        ; The main thread has run its cycles, so the CPU waits for VSYNC.
        lda irq_vsync
:       cmp RIA_VSYNC
        beq :-
        bra @done
@early: ; VSYNC came first, and the next frame has the cycles left over.
        jsr read_t2
        sta tmp1
        stx tmp2
        sec
        lda slice_t2
        sbc tmp1
        sta tmp1
        lda slice_t2+1
        sbc tmp2
        sta tmp2
        sec
        lda slice
        sbc tmp1
        sta carry
        lda slice+1
        sbc tmp2
        sta carry+1
        bcs @done
        stz carry
        stz carry+1
@done:  stz slice
        stz slice+1
@vsync: lda RIA_IRQ
        lda irq_depth
        beq @frame
        ; A VSYNC during the end of the previous one. The Atari OS runs
        ; only the first stage of its vertical blank then.
        inc overruns
        lda RIA_VSYNC
        sta irq_vsync
        jsr rtclock
        jmp exit
@frame:
        inc irq_depth
        lda RIA_VSYNC
        sta irq_vsync
        stz atari_cycles
        stz atari_cycles+1
        jsr antic_frame
        jsr gtia_frame
        jsr antic_tiles
        jsr pokey_frame
        jsr input_frame
        jsr read_t2
        sta vbi_t2
        stx vbi_t2+1
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
        sei                 ; VERTBLKD comes here with interrupts enabled
        stz irq_depth
        ; The vertical blank is Atari interrupt time.
        jsr read_t2
        sta tmp1
        stx tmp2
        sec
        lda vbi_t2
        sbc tmp1
        tay
        lda vbi_t2+1
        sbc tmp2
        tax
        tya
        clc
        adc atari_cycles
        sta atari_cycles
        txa
        adc atari_cycles+1
        sta atari_cycles+1
        lda RIA_VSYNC
        cmp irq_vsync
        beq :+
        inc overruns        ; VSYNC is pending, so the next frame starts
        bra exit
        ; The main thread runs until timer 1 ends its cycles.
:       sec
        lda #<MAIN_CYCLES
        sbc atari_cycles
        tay
        lda #>MAIN_CYCLES
        sbc atari_cycles+1
        tax
        bcs :+
        ldy #0
        ldx #0
:       tya
        clc
        adc carry
        tay
        txa
        adc carry+1
        tax
        bcc :+
        ldy #$FF
        ldx #$FF
:       stz carry
        stz carry+1
        cpx #0
        bne :+
        cpy #64
        bcs :+
        ldy #64
:       sty slice
        stx slice+1
        sty VIA_T1CL
        stx VIA_T1CH
        jsr read_t2
        sta slice_t2
        stx slice_t2+1
        lda #$C0
        sta VIA_IER
exit:   pla
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
