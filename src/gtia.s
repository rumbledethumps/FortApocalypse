; GTIA players and missiles as VGA sprites, and their collisions
;
; Each player and missile becomes 1-bit custom sprites, 8 pixels drawn
; double width, one for each band of scanlines between the display list
; interrupts that move them. Collisions are found from the same bits and
; from the character data of the display, pixel for pixel, as GTIA found
; them while it drew the frame.

.include "rp6502.inc"
.include "atari.inc"
.include "xram.inc"

.importzp ptr1, ptr2, ptr3, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7, tmp8
.import color
.import sl_line, line_msc_lo, line_msc_hi, line_row, line_xoff, line_chbase
.import snap_count, snap_line, snap_hpos, snap_color, snap_sizem
.export gtia_init, gtia_frame

MAX_SEGS = 64

.bss
nspr:       .res 1
prev_nspr:  .res 1
img:        .res 2          ; next sprite image in XRAM
coll:       .res 16         ; M0PF-M3PF, P0PF-P3PF, M0PL-M3PL, P0PL-P3PL
ext_first:  .res 8          ; first and last scanline with bits of
ext_last:   .res 8          ; P0-P3 and M0-M3
cfg_lo:     .res 1

; Rows of an object between two snapshots
nsegs:      .res 1
seg_obj:    .res MAX_SEGS   ; 0-3 players, 4-7 missiles
seg_first:  .res MAX_SEGS
seg_last:   .res MAX_SEGS
seg_hpos:   .res MAX_SEGS
seg_size:   .res MAX_SEGS

; The object being drawn or tested
obj:        .res 1
obj_hpos:   .res 1
obj_size:   .res 1          ; missile width: 0 normal, 4 double, 8 quad
obj_color:  .res 1
row_first:  .res 1
row_last:   .res 1

; The playfield under the object being tested
pf_bits:    .res 1          ; colors found: PF0 1, PF1 2, PF2 4, PF3 8
pf_h:       .res 1          ; first color clock, 48 or more
pf_lshift:  .res 1          ; pixels left of color clock 48
pf_rmask:   .res 1          ; pixels left of color clock 208
pf_line:    .res 1          ; mode line of pf_gl0-2
pf_shift:   .res 1          ; pf_h in the first line byte
pf_c3:      .res 3          ; the color of pixel value 3 of each byte

; Player segments with rows and color clocks in common with the object
ncand:      .res 1
cand:       .res MAX_SEGS

.rodata

; Missile m of a missile byte, as 0-3
mis_bits:
    .repeat 4, m
        .repeat 256, i
            .byte (i >> (2 * m)) & 3
        .endrepeat
    .endrepeat

; The pixels of a glyph byte of value 1, 2 and 3, leftmost in bit 7, as
; the high nibble.
.macro pixels_of v
    .repeat 256, i
        .byte ((i >> 6) = v) << 7 | ((i >> 4 & 3) = v) << 6 | ((i >> 2 & 3) = v) << 5 | ((i & 3) = v) << 4
    .endrepeat
.endmacro
pf_m1:  pixels_of 1
pf_m2:  pixels_of 2
pf_m3:  pixels_of 3

.code

gtia_init:
        ; Every sprite starts hidden.
        lda #MAX_SPRITES
        sta prev_nspr
        stz nspr
        jmp hide

gtia_frame:
        stz nspr
        stz nsegs
        lda #<XRAM_SPRITES
        sta img
        lda #>XRAM_SPRITES
        sta img+1
        jsr extents
        ; GTIA draws player 0 over player 3, and the fifth player over the
        ; players. The VGA draws later sprites over earlier ones.
        lda GRACTL
        and #$02
        beq @missiles
        lda #3
:       sta obj
        jsr build
        lda obj
        dec a
        bpl :-
@missiles:
        lda GRACTL
        and #$01
        beq @done
        lda #4
:       sta obj
        jsr build
        lda obj
        inc a
        cmp #8
        bne :-
@done:  jsr hide
        lda nspr
        sta prev_nspr
        jmp collide

; Move the sprites not used this frame off the canvas, farther than the
; largest sprite reaches.
hide:
        ldx nspr
@loop:  cpx prev_nspr
        bcs @done
        jsr cfg_addr
        stz RIA_RW0         ; x_pos_px
        lda #$FE
        sta RIA_RW0
        stz RIA_RW0         ; y_pos_px
        sta RIA_RW0
        stz RIA_RW0         ; xram_sprite_ptr
        stz RIA_RW0
        stz RIA_RW0         ; palette_ptr
        stz RIA_RW0
        stz RIA_RW0         ; width_height
        stz RIA_RW0         ; options
        inx
        bra @loop
@done:  rts

; RIA_ADDR0 = the mode5_csprite_t of sprite X.
cfg_addr:
        txa
        asl
        sta cfg_lo          ; 2x
        asl
        asl                 ; 8x
        pha
        lda #0
        rol
        tay
        pla
        clc
        adc cfg_lo
        bcc :+
        iny
:       clc
        adc #<XRAM_SPRCFG
        sta RIA_ADDR0
        tya
        adc #>XRAM_SPRCFG
        sta RIA_ADDR0+1
        lda #1
        sta RIA_STEP0
        rts

; The first and last scanlines with bits of each object, within the
; snapshots where GTIA displays it.
extents:
        ldx #7
:       lda #1              ; none
        sta ext_first,x
        stz ext_last,x
        dex
        bpl :-
        ldx #3
@player:
        jsr displayed
        bcc @nextp
        txa
        clc
        adc #4
        jsr ext_column
        bcs @nextp
        lda tmp1
        sta ext_first,x
        lda tmp2
        sta ext_last,x
@nextp: dex
        bpl @player
        ; The missiles share a column. Their extent together bounds a
        ; search, a scanline at a time, for each missile's.
        lda #$FF
        sta tmp5
        stz tmp6
        ldx #7
@shown: jsr displayed
        bcc :++
        lda tmp1
        cmp tmp5
        bcs :+
        sta tmp5
:       lda tmp2
        cmp tmp6
        bcc :+
        sta tmp6
:       dex
        cpx #4
        bcs @shown
        lda tmp6
        bne :+
        rts
:       sta tmp2
        lda tmp5
        sta tmp1
        lda #3
        jsr ext_column
        bcc :+
        rts
:       ldy tmp1
@row:   jsr ext_f
        beq @nextr
        ldx #4
@mis:   sta tmp3
        and #3
        beq :++
        lda ext_last,x
        bne :+
        tya
        sta ext_first,x
:       tya
        sta ext_last,x
:       lda tmp3
        lsr
        lsr
        inx
        cpx #8
        bne @mis
@nextr: cpy tmp2
        iny
        bcc @row
        rts

; Carry set when GTIA displays object X in some snapshot, at HPOS 27-221.
; The first and last scanlines of those snapshots are in tmp1 and tmp2.
displayed:
        stx tmp3
        lda #$FF
        sta tmp1
        stz tmp2
        ldy #0
@snap:  cpy snap_count
        beq @done
        tya
        asl
        asl
        asl
        ora tmp3
        tax
        lda snap_hpos,x
        cmp #34-7
        bcc @next
        cmp #222
        bcs @next
        lda snap_line,y
        clc
        adc #8
        cmp tmp1
        bcs :+
        sta tmp1
:       lda #247
        iny
        cpy snap_count
        beq :+
        lda snap_line,y
        clc
        adc #7
:       dey
        sta tmp2
@next:  iny
        bra @snap
@done:  ldx tmp3
        lda tmp2
        cmp #1
        rts

; The first and last scanlines with bits in page PMBASE+A, from scanline
; tmp1 to tmp2, into tmp1 and tmp2, searched 8 scanlines at a time. Carry
; set when there are none.
ext_column:
        clc
        adc PMBASE
.repeat 8, k
        sta .ident(.sprintf("ext_g%d", k))+2
.endrepeat
        sta ext_f+2
        ldy tmp1
@down:  jsr ext_group
        bne @first
        tya
        clc
        adc #8
        bcs @none
        tay
        cpy tmp2
        bcc @down
        beq @down
@none:  sec
        rts
@first: jsr ext_f
        bne :+
        iny
        bra @first
:       cpy tmp2
        beq :+
        bcs @none
:       sty tmp4
        lda tmp2
        sec
        sbc #7
        tay
@up:    jsr ext_group
        bne @last
        tya
        sec
        sbc #8
        tay
        bra @up
@last:  tya
        clc
        adc #7
        cmp tmp2
        bcc :+
        lda tmp2
:       tay
:       jsr ext_f
        bne :+
        dey
        bra :-
:       sty tmp2
        lda tmp4
        sta tmp1
        clc
        rts

; The bits of 8 scanlines from Y, or of scanline Y, of the column the
; operands are set to.
ext_group:
.repeat 8, k
.ident(.sprintf("ext_g%d", k)):
    .if k = 0
        lda $FF00+k,y
    .else
        ora $FF00+k,y
    .endif
.endrepeat
        rts
ext_f:  lda $FF00,y
        rts

; ptr1 = the memory of object obj, and ptr3 its missile table.
obj_base:
        lda obj
        cmp #4
        bcs :+
        adc #4
        bra :++
:       and #3
        clc
        adc #>mis_bits
        sta ptr3+1
        lda #<mis_bits
        sta ptr3
        lda #3
:       clc
        adc PMBASE
        sta ptr1+1
        stz ptr1
        rts

; The 8 pixels of object obj on scanline Y, in A. A missile is 2 color
; clocks wide, 4 double and 8 quad.
row_bits:
        lda obj
        cmp #4
        bcs :+
        lda (ptr1),y
        rts
:       phy
        lda (ptr1),y
        tay
        lda (ptr3),y
        ply
        ora obj_size
        tax
        lda missile_pixels,x
        rts

missile_pixels:
        .byte $00, $40, $80, $C0
        .byte $00, $30, $C0, $F0
        .byte $00, $0F, $F0, $FF

; The sprites and segments of object obj.
build:
        ldx obj
        lda ext_first,x
        sta row_first
        lda ext_last,x
        sta row_last
        cmp row_first
        bcs :+
        rts
:       jsr obj_base
        ldx #0
@snap:  cpx snap_count
        bne :+
        rts
:       stx tmp8
        ; Scanlines from this snapshot to the next, within the extent.
        lda snap_line,x
        clc
        adc #8
        cmp row_first
        bcs :+
        lda row_first
:       sta tmp6            ; first scanline
        lda #247
        inx
        cpx snap_count
        beq :+
        lda snap_line,x
        clc
        adc #7
:       cmp row_last
        bcc :+
        lda row_last
:       sta tmp7            ; last scanline
        cmp tmp6
        bcc @next
        ; The object's registers in this snapshot
        lda tmp8
        asl
        asl
        asl
        ora obj
        tay
        lda snap_hpos,y
        sta obj_hpos
        lda snap_color,y
        sta obj_color
        ldx tmp8
        lda snap_sizem,x
        ldy obj
:       cpy #5
        bcc :+
        lsr
        lsr
        dey
        bra :-
:       and #3
        tay
        lda size_offset,y
        sta obj_size
        ; GTIA draws nothing and finds no collisions in the horizontal
        ; blank, color clocks 222 to 33, and the canvas shows 48 to 207.
        lda obj_hpos
        cmp #34-7
        bcc @next
        cmp #222
        bcs @next
        jsr add_segment
        lda obj_hpos
        cmp #48-7
        bcc @next
        cmp #208
        bcs @next
        jsr add_sprites
@next:  ldx tmp8
        inx
        jmp @snap

size_offset:
        .byte 0, 4, 0, 8

add_segment:
        ldx nsegs
        cpx #MAX_SEGS
        bcs :+
        lda obj
        sta seg_obj,x
        lda tmp6
        sta seg_first,x
        lda tmp7
        sta seg_last,x
        lda obj_hpos
        sta seg_hpos,x
        lda obj_size
        sta seg_size,x
        inc nsegs
:       rts

; Sprites for scanlines tmp6 to tmp7, at most 64 rows each.
add_sprites:
        ldx nspr
        cpx #MAX_SPRITES
        bcc :+
        rts
:       lda tmp7            ; rows with data
        sec
        sbc tmp6
        cmp #64
        bcc :+
        lda #63
:       inc a
        sta tmp1
        clc                 ; rows in the image, a multiple of 4
        adc #3
        and #$FC
        sta tmp2
        clc                 ; the images must fit
        lda img
        adc tmp2
        lda img+1
        adc #0
        cmp #>(XRAM_SPRITES + SPRITE_IMAGES)
        bcc :+
        rts
:       jsr cfg_addr
        lda obj_hpos        ; x_pos_px = 2*(hpos-48)
        sec
        sbc #48
        sta tmp3
        lda #0
        sbc #0
        asl tmp3
        rol
        tax
        lda tmp3
        sta RIA_RW0
        stx RIA_RW0
        lda tmp6            ; y_pos_px = scanline-8
        sec
        sbc #8
        sta RIA_RW0
        lda #0
        sbc #0
        sta RIA_RW0
        lda img             ; xram_sprite_ptr
        sta RIA_RW0
        lda img+1
        sta RIA_RW0
        lda nspr            ; palette_ptr
        asl
        asl
        sta tmp3
        sta RIA_RW0
        lda #>XRAM_SPRPAL
        sta RIA_RW0
        lda tmp2            ; width_height: 8 wide, tmp2 high
        lsr
        lsr
        dec a
        asl
        asl
        asl
        asl
        ora #$01
        sta RIA_RW0
        lda #MODE5_HDOUBLE  ; options: 1 bit
        sta RIA_RW0
        ; Palette: clear, then the color.
        lda tmp3
        sta RIA_ADDR0
        lda #>XRAM_SPRPAL
        sta RIA_ADDR0+1
        stz RIA_RW0
        stz RIA_RW0
        lda obj_color
        jsr color
        lda ptr3
        sta RIA_RW0
        lda ptr3+1
        sta RIA_RW0
        jsr obj_base        ; color used ptr3
        ; The image
        lda img
        sta RIA_ADDR0
        lda img+1
        sta RIA_ADDR0+1
        ldy tmp6
        lda tmp1
        sta tmp4
:       jsr row_bits
        sta RIA_RW0
        iny
        dec tmp4
        bne :-
        lda tmp2
        sec
        sbc tmp1
        beq :++
        tax
:       stz RIA_RW0
        dex
        bne :-
:       clc
        lda img
        adc tmp2
        sta img
        bcc :+
        inc img+1
:       inc nspr
        ; The scanlines after these 64
        tya
        beq :+
        dec a
        cmp tmp7
        bcs :+
        sty tmp6
        jmp add_sprites
:       rts

; The collision registers for the frame.
collide:
        ldx #15
:       stz coll,x
        dex
        bpl :-
        ldx #0
@seg:   cpx nsegs
        bne :+
        jmp @done
:       stx tmp8
        lda seg_obj,x
        sta obj
        lda seg_hpos,x
        sta obj_hpos
        lda seg_size,x
        sta obj_size
        jsr obj_base
        jsr pf_setup
        jsr candidates
        ldx tmp8
        ldy seg_first,x
@row:   jsr row_bits
        beq @next
        sta tmp7            ; the object's pixels on this scanline
        sty tmp6
        jsr playfield
        lda ncand
        beq :+
        jsr players
:       ldy tmp6
@next:  ldx tmp8
        tya
        cmp seg_last,x
        iny
        bcc @row
        lda pf_bits
        beq @none
        ldy obj
        cpy #4
        bcs :+
        ora coll+4,y        ; P0PF-P3PF
        sta coll+4,y
        bra @none
:       ora coll-4,y        ; M0PF-M3PF
        sta coll-4,y
@none:  inx
        bra @seg
@done:  ldx #15
:       lda coll,x
        sta M0PF,x
        dex
        bpl :-
        rts

; Only color clocks 48-207 have playfield.
pf_setup:
        stz pf_bits
        lda #$FF
        sta pf_line
        sta pf_rmask
        stz pf_lshift
        lda obj_hpos
        cmp #48
        bcs :+
        eor #$FF            ; the object starts 48-hpos pixels early
        sec
        adc #48
        sta pf_lshift
        cmp #8
        bcc @left
        stz pf_rmask
@left:  lda #48
        sta pf_h
        rts
:       sta pf_h
        sbc #200            ; hpos-200 pixels are past 207
        bcc @done
        beq @done
        tax
        lda #0
        cpx #8
        bcs :+
        lda right_mask,x
:       sta pf_rmask
@done:  rts

right_mask:
        .byte $FF, $FE, $FC, $F8, $F0, $E0, $C0, $80
left_mask:
        .byte $FF, $7F, $3F, $1F, $0F, $07, $03, $01

; Playfield colors under pixels tmp7 of obj on scanline tmp6, into
; pf_bits.
playfield:
        lda tmp6
        sec
        sbc #8
        tax
        ldy sl_line,x
        cpy #$FF
        bne :+
        rts
:       txa
        clc
        adc line_row,y
        sta tmp4            ; glyph row
        cpy pf_line
        beq :+
        jsr pf_chars
:       ; The pixels from the first clock of the first byte, in tmp2 and
        ; tmp3
        lda tmp7
        and pf_rmask
        ldx pf_lshift
        beq :++
:       asl
        dex
        bne :-
:       stz tmp3
        ldx pf_shift
        beq :++
:       lsr
        ror tmp3
        dex
        bne :-
:       sta tmp2
        ldy tmp4
        and #$F0
        beq :+
        sta tmp5
pf_gl0: ldx $FFFF,y
        beq :+
        lda pf_c3
        jsr pf_colors
:       lda tmp2
        asl
        asl
        asl
        asl
        beq :+
        sta tmp5
pf_gl1: ldx $FFFF,y
        beq :+
        lda pf_c3+1
        jsr pf_colors
:       lda tmp3
        bne :+
        rts
:       sta tmp5
pf_gl2: ldx $FFFF,y
        bne :+
        rts
:       lda pf_c3+2
        jmp pf_colors

; The colors of glyph byte X under pixels tmp5, into pf_bits. Pixel value
; 3 is color A.
pf_colors:
        sta tmp1
        lda pf_m1,x
        and tmp5
        beq :+
        lda #1
        tsb pf_bits
:       lda pf_m2,x
        and tmp5
        beq :+
        lda #2
        tsb pf_bits
:       lda pf_m3,x
        and tmp5
        beq :+
        lda tmp1
        tsb pf_bits
:       rts

; The three glyphs under the object on mode line Y, as the operands of
; pf_gl0-2. Pixel value 3 is PF3 in a character with bit 7 set, else PF2.
pf_chars:
        sty pf_line
        lda line_chbase,y
        sta tmp1
        lda pf_h
        sec
        sbc line_xoff,y     ; color clocks into the line
        tax
        and #3
        sta pf_shift
        txa
        lsr
        lsr
        clc
        adc line_msc_lo,y
        sta ptr2
        ; ANTIC's memory scan counter wraps within 4K.
        lda line_msc_hi,y
        adc #0
        eor line_msc_hi,y
        and #$0F
        eor line_msc_hi,y
        sta ptr2+1
.repeat 3, k
        lda (ptr2)
        ldx #4
        asl
        bcc :+
        ldx #8
:       stx pf_c3+k
        stz tmp5            ; CHBASE*256 + 8*(character & $7F)
        asl
        rol tmp5
        asl
        rol tmp5
        sta .ident(.sprintf("pf_gl%d", k))+1
        lda tmp5
        adc tmp1
        sta .ident(.sprintf("pf_gl%d", k))+2
    .if k < 2
        inc ptr2
        bne :+
        lda ptr2+1
        inc a
        eor ptr2+1
        and #$0F
        eor ptr2+1
        sta ptr2+1
:
    .endif
.endrepeat
        rts

; The player segments that obj can overlap.
candidates:
        stz ncand
        ldx #0
@seg:   cpx nsegs
        beq @done
        lda seg_obj,x
        cmp #4
        bcs @next
        cmp obj
        beq @next
        ldy tmp8
        lda seg_last,y
        cmp seg_first,x
        bcc @next
        lda seg_last,x
        cmp seg_first,y
        bcc @next
        lda seg_hpos,x
        sec
        sbc obj_hpos
        bcs :+
        eor #$FF
        inc a
:       cmp #8
        bcs @next
        txa
        ldy ncand
        sta cand,y
        inc ncand
@next:  inx
        bra @seg
@done:  rts

; Players under pixels tmp7 of obj on scanline tmp6.
players:
        ldy #0
@cand:  cpy ncand
        beq @done
        phy
        ldx cand,y
        lda tmp6
        cmp seg_first,x
        bcc :+
        lda seg_last,x
        cmp tmp6
        bcc :+
        jsr overlap
:       ply
        iny
        bra @cand
@done:  rts

; A pixel of obj on a pixel of player seg_obj,x sets the bit of that
; player in obj's register.
overlap:
        lda seg_obj,x       ; the player's pixels
        clc
        adc #4
        adc PMBASE
        sta ptr2+1
        stz ptr2
        ldy tmp6
        lda (ptr2),y
        sta tmp3
        ; Line up both at the leftmost of the two.
        lda seg_hpos,x
        sec
        sbc obj_hpos
        bcc @left
        tay
        lda tmp7            ; obj is left of the player
:       dey
        bmi :+
        asl
        bra :-
:       and tmp3
        bra @test
@left:  eor #$FF
        inc a
        tay
        lda tmp3            ; the player is left of obj
:       dey
        bmi :+
        asl
        bra :-
:       and tmp7
@test:  beq @none
        ; Only color clocks 34-221 collide. The pixels are lined up at the
        ; rightmost of the two.
        sta tmp3
        lda seg_hpos,x
        cmp obj_hpos
        bcs :+
        lda obj_hpos
:       cmp #34
        bcs :+
        eor #$FF
        sec
        adc #34
        tay
        lda tmp3
        and left_mask,y
        bra @clip
:       sbc #214
        bcc @same
        beq @same
        tay
        lda tmp3
        and right_mask,y
        bra @clip
@same:  lda tmp3
@clip:  beq @none
        ldy seg_obj,x
        lda player_bit,y
        ldy obj
        cpy #4
        bcs :+
        ora coll+12,y       ; P0PL-P3PL
        sta coll+12,y
        rts
:       ora coll+4,y        ; M0PL-M3PL
        sta coll+4,y
@none:  rts

player_bit:
        .byte $01, $02, $04, $08
