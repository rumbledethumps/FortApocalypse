; ANTIC display lists and character sets on the VGA
;
; Once a frame the display list is walked the way ANTIC walks it. Each run
; of mode 4 lines becomes a band of 4-bit 8x8 tiles on plane 1, with pixel
; value 0 transparent. Plane 0 is a bitmap with one color a scanline, the
; background color, so the display list interrupts that change COLBK from
; one scanline to the next draw what they drew on the Atari. The display
; list interrupts run in scanline order during the walk.

.include "rp6502.inc"
.include "atari.inc"
.include "xram.inc"

.importzp ptr1, ptr2, ptr3, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp8
.import xreg_call, xreg_buf, read_t2
.import NTSC
.export antic_init, antic_frame, antic_rainbow, WSYNC, color
.export sl_line, line_msc_lo, line_msc_hi, line_row, line_xoff, line_chbase
.export snap_count, snap_line, snap_hpos, snap_color, snap_sizem

MAX_SNAPS = 8

; 6502 cycles from the first instruction of a display list interrupt to the
; end of the scanline where it starts. The fetches of ANTIC use most of the
; cycles of a mode 4 line.
DLI_CYCLES_BLANK = 61
DLI_CYCLES_MODE4 = 21

; Cycles between the timer reads in run_dli and WSYNC that are not
; display list interrupt code.
DLI_OVERHEAD = 80

.bss
antic_rainbow: .res 1       ; nonzero while T1 colors the title

; Per canvas row
colbk_line: .res 240        ; COLBK
backdrop:   .res 240        ; the bitmap row now in XRAM
sl_line:    .res 240        ; mode line, or $FF

; Per mode line
line_msc_lo: .res MAX_ROWS
line_msc_hi: .res MAX_ROWS
line_row:    .res MAX_ROWS  ; glyph row minus canvas row of the line
line_xoff:   .res MAX_ROWS  ; color clock of the first byte fetched
line_chbase: .res MAX_ROWS

; Per band
nbands:      .res 1
band_begin:  .res MAX_BANDS
band_end:    .res MAX_BANDS
band_rows:   .res MAX_BANDS
band_row0:   .res MAX_BANDS
band_width:  .res MAX_BANDS
band_xpos:   .res MAX_BANDS
band_slot:   .res MAX_BANDS
band_tm_lo:  .res MAX_BANDS
band_tm_hi:  .res MAX_BANDS
band_pf0:    .res MAX_BANDS
band_pf1:    .res MAX_BANDS
band_pf2:    .res MAX_BANDS
band_pf3:    .res MAX_BANDS
band_bk:     .res MAX_BANDS

; The layout the VGA is programmed with
prog_nbands: .res 1
prog_begin:  .res MAX_BANDS
prog_end:    .res MAX_BANDS
prog_plane:  .res 1
sprite_plane: .res 1

; Player and missile registers, from the top of the frame and from after
; each display list interrupt.
snap_count: .res 1
snap_line:  .res MAX_SNAPS
snap_hpos:  .res MAX_SNAPS * 8
snap_color: .res MAX_SNAPS * 8
snap_sizem: .res MAX_SNAPS

; Walk state
sl:          .res 1         ; canvas row of the next scanline
valid:       .res 1         ; colbk_line is written below this row
msc:         .res 2         ; memory scan counter
nlines:      .res 1
vs_prev:     .res 1
band_open:   .res 1
dl_ins:      .res 1
tm:          .res 2         ; next tile row in XRAM
line_avail:  .res 1         ; DLI cycles before the end of the DLI line

; Display list interrupt state
dli_line:    .res 1         ; canvas row the next COLBK write lands on
dli_syncs:   .res 1
dli_t2:      .res 2

; Character sets: two slots of 256 tiles in XRAM
slot_page:   .res 2         ; CHBASE of the set in each slot, 0 for none
slot_used:   .res 2         ; a band of this frame uses the slot
slot_fresh:  .res 2         ; convert every glyph
parity:      .res 1         ; the half of each set to compare

.segment "SHADOW"
shadow:      .res 2048      ; per slot, the glyphs in XRAM

.rodata

; Glyph byte to 4-bit tile bytes: each 2-bit pixel is doubled.
.macro pixel_pairs shift, inverse
    .repeat 256, i
        .byte ((i >> shift) & 3) * $11 + inverse * (((i >> shift) & 3) = 3) * $11
    .endrepeat
.endmacro
tile_n0: pixel_pairs 6, 0
tile_n1: pixel_pairs 4, 0
tile_n2: pixel_pairs 2, 0
tile_n3: pixel_pairs 0, 0
; The same with pixel value 3 as color 4
tile_i0: pixel_pairs 6, 1
tile_i1: pixel_pairs 4, 1
tile_i2: pixel_pairs 2, 1
tile_i3: pixel_pairs 0, 1

.code

antic_init:
        ; Force the first frame to program the VGA.
        lda #$FF
        sta prog_nbands
        ; The backdrop bitmap and the Atari palette
        lda #1
        sta RIA_STEP0
        lda #<XRAM_BACKCFG
        sta RIA_ADDR0
        lda #>XRAM_BACKCFG
        sta RIA_ADDR0+1
        lda #1
        sta RIA_RW0         ; x_wrap
        stz RIA_RW0         ; y_wrap
        stz RIA_RW0         ; x_pos_px
        stz RIA_RW0
        stz RIA_RW0         ; y_pos_px
        stz RIA_RW0
        lda #16
        sta RIA_RW0         ; width_px
        stz RIA_RW0
        lda #240
        sta RIA_RW0         ; height_px
        stz RIA_RW0
        lda #<XRAM_BACKDROP
        sta RIA_RW0
        lda #>XRAM_BACKDROP
        sta RIA_RW0
        lda #<XRAM_NTSC
        sta RIA_RW0
        lda #>XRAM_NTSC
        sta RIA_RW0
        lda #<XRAM_NTSC
        sta RIA_ADDR0
        lda #>XRAM_NTSC
        sta RIA_ADDR0+1
        ldx #0
:       lda NTSC,x
        sta RIA_RW0
        inx
        bne :-
:       lda NTSC+256,x
        sta RIA_RW0
        inx
        bne :-
        ; An all-black backdrop, which the first frame keeps in step.
        lda #<XRAM_BACKDROP
        sta RIA_ADDR0
        lda #>XRAM_BACKDROP
        sta RIA_ADDR0+1
        ldy #>(240 * 16)
        ldx #<(240 * 16)
:       stz RIA_RW0
        dex
        bne :-
        dey
        bpl :-
        ldx #239
:       stz backdrop,x
        dex
        cpx #$FF
        bne :-
        rts

antic_frame:
        stz sl
        stz valid
        stz nlines
        stz nbands
        stz band_open
        stz vs_prev
        stz snap_count
        stz slot_used
        stz slot_used+1
        lda #<XRAM_TILEMAP
        sta tm
        lda #>XRAM_TILEMAP
        sta tm+1
        ; Players behind the playfield are on plane 0, else on plane 2.
        ldx #2
        lda PRIOR
        and #$04
        beq :+
        ldx #0
:       stx sprite_plane
        lda #1
        sta RIA_STEP0
        jsr snapshot
        ; No display list without DL DMA and a playfield width.
        lda DMACTL
        and #$20
        beq @end
        lda DMACTL
        and #$03
        beq @end
        lda DLISTL
        sta ptr1
        lda DLISTH
        sta ptr1+1
@next:
        lda sl
        cmp #240
        bcs @end
        lda (ptr1)
        sta dl_ins
        jsr dl_inc
        lda dl_ins
        and #$0F
        beq @blank
        cmp #1
        beq @jump
        jsr mode_line
        bra @next
@blank:
        jsr close_band
        stz vs_prev
        lda dl_ins
        lsr
        lsr
        lsr
        lsr
        and #7
        inc a
        jsr blank_rows
        lda #DLI_CYCLES_BLANK
        sta line_avail
        bit dl_ins
        bpl @next
        jsr run_dli
        bra @next
@jump:
        jsr close_band
        stz vs_prev
        ldy #1
        lda (ptr1),y
        tax
        lda (ptr1)
        sta ptr1
        stx ptr1+1
        bit dl_ins
        bvs @end            ; JVB
        lda #1
        jsr blank_rows
        bra @next
@end:
        jsr close_band
        lda #240
        sec
        sbc sl
        beq :+
        jsr blank_rows
:       jsr refresh_sets
        jsr write_backdrop
        jsr write_bands
        jmp program_vga

dl_inc:
        inc ptr1
        bne :+
        inc ptr1+1
:       rts

; Run the display list interrupt of the line just walked.
run_dli:
        bit NMIEN
        bmi :+
        rts
:       lda sl
        sta dli_line
        stz dli_syncs
        jsr read_t2
        sta dli_t2
        stx dli_t2+1
        lda #>@ret
        pha
        lda #<@ret
        pha
        php
        jmp (VDSLST)
@ret:
        jsr commit_colbk
        lda dli_line
        sta valid
        jmp snapshot

; COLBK is the color of row dli_line, and later writes go to the next row.
commit_colbk:
        ldx dli_line
        cpx #240
        bcs :+
        lda COLBK
        sta colbk_line,x
        inc dli_line
:       rts

; STA WSYNC on the Atari halts the 6502 until the horizontal blank at the
; end of the scanline, so a color written after it is the color of the
; next scanline. The display list interrupts call this in its place.
WSYNC:
        php
        pha
        phx
        phy
        inc dli_syncs
        lda dli_syncs
        cmp #1
        bne @next
        ; When the interrupt code is still running at the end of the
        ; scanline where it started, STA WSYNC halts until the end of the
        ; next scanline.
        jsr read_t2
        sta tmp1
        sec
        lda dli_t2
        sbc tmp1
        tay
        stx tmp1
        lda dli_t2+1
        sbc tmp1
        bne @next
        tya
        sec
        sbc #DLI_OVERHEAD
        bcc @done
        cmp line_avail
        bcc @done
@next:  jsr commit_colbk
@done:  ply
        plx
        pla
        plp
        rts

; The player and missile registers in effect from row sl.
snapshot:
        ldy snap_count
        cpy #MAX_SNAPS
        bcs @done
        lda sl
        sta snap_line,y
        lda SIZEM
        sta snap_sizem,y
        tya
        asl
        asl
        asl
        tay
        ldx #0
:       lda HPOSP0,x
        sta snap_hpos,y
        lda HPOSM0,x
        sta snap_hpos+4,y
        lda COLPM0,x
        sta snap_color,y
        sta snap_color+4,y
        iny
        inx
        cpx #4
        bne :-
        ; The fifth player colors all four missiles with COLPF3.
        lda PRIOR
        and #$10
        beq :+
        lda COLPF3
        sta snap_color,y
        sta snap_color+1,y
        sta snap_color+2,y
        sta snap_color+3,y
:       inc snap_count
@done:  rts

; A rows without playfield from sl on.
blank_rows:
        ldx #$FF
; A rows from sl on, of mode line X, or none for $FF. Rows below those the
; display list interrupts colored take the current COLBK.
fill_rows:
        stx tmp8
        clc
        adc sl
        cmp #240
        bcc :+
        lda #240
:       sta tmp1            ; end
        ldx sl
@loop:  cpx tmp1
        bcs @done
        lda tmp8
        sta sl_line,x
        cpx valid
        bcc :+
        lda COLBK
        sta colbk_line,x
:       inx
        bra @loop
@done:  stx sl
        rts

; A display list mode line. Mode 4, the only one the game uses, is drawn;
; other modes are blank lines of their height.
mode_line:
        bit dl_ins
        bvc :+
        lda (ptr1)
        sta msc
        ldy #1
        lda (ptr1),y
        sta msc+1
        jsr dl_inc
        jsr dl_inc
:       lda dl_ins
        and #$0F
        cmp #4
        beq @mode4
        tax
        jsr close_band
        stz vs_prev
        lda mode_height-2,x
        jmp blank_rows
@mode4:
        ; Vertical scrolling shows rows VSCROL-7 of the first line of a
        ; region, and rows 0-VSCROL of the line below the region.
        stz tmp2            ; first row
        lda #7
        sta tmp3            ; last row
        lda dl_ins
        and #$20
        tax
        beq @novs
        lda vs_prev
        bne @vsdone
        lda VSCROL
        and #7
        sta tmp2
        bra @vsdone
@novs:  lda vs_prev
        beq @vsdone
        lda VSCROL
        and #7
        sta tmp3
@vsdone:
        stx vs_prev
        ; 40 bytes from color clock 48, or 48 bytes from 32+HSCROL.
        ldy #40
        lda #48
        sta tmp4            ; color clock of the first byte
        lda dl_ins
        and #$10
        beq :+
        ldy #48
        lda HSCROL
        and #$0F
        clc
        adc #32
        sta tmp4
:       sty tmp5            ; bytes
        ; The tile rows of a band are 8 scanlines apart, so a line that
        ; starts below glyph row 0 starts a band.
        lda tmp2
        beq :+
        jsr close_band
:       lda band_open
        beq @open
        ldx nbands
        lda band_width-1,x
        cmp tmp5
        beq @same
        jsr close_band
@open:  jsr open_band
@same:
        ldx nlines
        cpx #MAX_ROWS
        bcc :+
        lda #1
        jmp blank_rows
:       lda msc
        sta line_msc_lo,x
        lda msc+1
        sta line_msc_hi,x
        lda tmp2
        sec
        sbc sl
        sta line_row,x
        lda tmp4
        sta line_xoff,x
        lda CHBASE
        sta line_chbase,x
        inc nlines
        phx
        jsr copy_line
        ldx nbands
        inc band_rows-1,x
        lda tmp3
        sec
        sbc tmp2
        inc a
        plx
        jsr fill_rows
        lda #DLI_CYCLES_MODE4
        sta line_avail
        ; A line that ends above glyph row 7 ends its band.
        lda tmp3
        cmp #7
        beq :+
        jsr close_band
:       bit dl_ins
        bpl :+
        jsr close_band
        jsr run_dli
:       rts

; Scanlines of modes 2-15
mode_height:
        .byte 8, 10, 8, 16, 8, 16, 8, 4, 4, 2, 1, 2, 1, 1

open_band:
        ldx nbands
        cpx #MAX_BANDS
        bcc :+
        dec nbands
        dex
:       lda sl
        sta band_begin,x
        lda tmp2
        sta band_row0,x
        stz band_rows,x
        lda tmp5
        sta band_width,x
        ; Two canvas pixels a color clock, from color clock 48
        lda tmp4
        sec
        sbc #48
        asl
        sta band_xpos,x
        lda tm
        sta band_tm_lo,x
        lda tm+1
        sta band_tm_hi,x
        lda COLPF0
        sta band_pf0,x
        lda COLPF1
        sta band_pf1,x
        lda COLPF2
        sta band_pf2,x
        lda COLPF3
        sta band_pf3,x
        lda COLBK
        sta band_bk,x
        lda CHBASE
        jsr find_slot
        sta band_slot,x
        inc nbands
        lda #1
        sta band_open
        rts

close_band:
        lda band_open
        beq :+
        ldx nbands
        lda sl
        sta band_end-1,x
        stz band_open
:       rts

; The slot for the character set at page A, in A. A slot that no band of
; this frame uses takes a character set that is in neither slot.
find_slot:
        phx
        ldx #0
        cmp slot_page
        beq @found
        inx
        cmp slot_page+1
        beq @found
        ldx #0
        ldy slot_used
        beq :+
        inx
:       sta slot_page,x
        lda #1
        sta slot_fresh,x
@found: lda #1
        sta slot_used,x
        txa
        plx
        rts

; Copy the line at msc to the tile rows, and advance msc. The memory scan
; counter of ANTIC wraps within 4K.
copy_line:
        lda tm
        sta RIA_ADDR0
        lda tm+1
        sta RIA_ADDR0+1
        lda msc
        sta ptr2
        lda msc+1
        sta ptr2+1
        clc
        lda msc
        adc tmp5
        sta tmp8            ; low byte of the end
        bcc @one
        beq @one
        lda msc+1
        and #$0F
        cmp #$0F
        bne @one
        ; The bytes up to the 4K boundary, then from the start of the 4K.
        lda #0
        sec
        sbc msc
        tay
        jsr copy_bytes
        lda msc+1
        and #$F0
        sta ptr2+1
        stz ptr2
        ldy tmp8
        jsr copy_bytes
        bra @advance
@one:   ldy tmp5
        jsr copy_bytes
@advance:
        clc
        lda msc
        adc tmp5
        sta msc
        lda msc+1
        adc #0
        and #$0F
        sta tmp6
        lda msc+1
        and #$F0
        ora tmp6
        sta msc+1
        clc
        lda tm
        adc tmp5
        sta tm
        bcc :+
        inc tm+1
:       rts

; Copy Y bytes from ptr2 to XRAM.
copy_bytes:
        sty tmp6
        ldy #0
@eight: tya
        clc
        adc #8
        bcs @one
        cmp tmp6
        beq :+
        bcs @one
:
.repeat 8
        lda (ptr2),y
        sta RIA_RW0
        iny
.endrepeat
        bra @eight
@one:   cpy tmp6
        beq @done
        lda (ptr2),y
        sta RIA_RW0
        iny
        bra @one
@done:  rts

; Update the tiles of each slot a band uses from the glyphs in RAM. A new
; character set is converted whole. Otherwise half of each set is
; compared each frame, so a glyph changed in RAM is on the screen within
; two frames. Each glyph has two tiles, the second for the glyph shown with
; bit 7 set.
refresh_sets:
        lda parity
        eor #2
        sta parity
        ldx #0
        lda slot_used
        beq :+
        jsr refresh_slot
:       ldx #1
        lda slot_used+1
        beq :+
        jsr refresh_slot
:       rts

refresh_slot:
        stx tmp1            ; slot
        lda slot_fresh,x
        beq @part
        stz slot_fresh,x
        stz tmp2
:       jsr glyph_changed
        inc tmp2
        bpl :-
        rts
@part:  lda parity
        jsr compare_page
        lda parity
        ora #1
        jmp compare_page

; Compare page A of the character set of slot tmp1 with its shadow, 32
; glyphs of 8 bytes, and convert the glyphs that differ.
compare_page:
        sta tmp3
        asl
        asl
        asl
        asl
        asl
        sta tmp4            ; first glyph of the page
        ldx tmp1
        lda slot_page,x
        clc
        adc tmp3
.repeat 8, k
        sta .ident(.sprintf("cmp_src%d", k))+2
.endrepeat
        txa
        asl
        asl
        adc tmp3
        adc #>shadow
.repeat 8, k
        sta .ident(.sprintf("cmp_shd%d", k))+2
.endrepeat
        ldx #0
cp_glyph:
.repeat 8, k
.ident(.sprintf("cmp_src%d", k)):
        lda $FF00+k,x
.ident(.sprintf("cmp_shd%d", k)):
        cmp $FF00+k,x
        bne cp_dirty
.endrepeat
cp_next:  txa
        clc
        adc #8
        tax
        bne cp_glyph
        rts
cp_dirty: txa
        lsr
        lsr
        lsr
        ora tmp4
        sta tmp2
        phx
        jsr glyph_changed
        plx
        bra cp_next

; ptr1 = glyph tmp2 of slot tmp1 in RAM, and ptr2 its shadow.
glyph_pointers:
        lda tmp2
        asl
        asl
        asl
        sta ptr1
        sta ptr2
        lda tmp2
        lsr
        lsr
        lsr
        lsr
        lsr
        pha
        ldx tmp1
        clc
        adc slot_page,x
        sta ptr1+1
        txa
        asl
        asl
        sta ptr2+1
        pla
        clc
        adc ptr2+1
        adc #>shadow
        sta ptr2+1
        rts

; Glyph tmp2 of slot tmp1 changed: copy it to the shadow and convert it.
glyph_changed:
        jsr glyph_pointers
        ldy #7
:       lda (ptr1),y
        sta (ptr2),y
        dey
        bpl :-
        jsr convert_normal
        jmp convert_inverse

; RIA_ADDR0 = tile tmp2 of slot tmp1, plus A pages.
tile_addr:
        sta tmp3
        lda tmp2
        asl
        asl
        asl
        asl
        asl
        sta RIA_ADDR0
        lda tmp2
        lsr
        lsr
        lsr
        clc
        adc tmp3
        ldx tmp1
        beq :+
        adc #>XRAM_TILES1
:       sta RIA_ADDR0+1
        rts

convert_normal:
        lda #0
        jsr tile_addr
        ldy #0
:       lda (ptr1),y
        tax
        lda tile_n0,x
        sta RIA_RW0
        lda tile_n1,x
        sta RIA_RW0
        lda tile_n2,x
        sta RIA_RW0
        lda tile_n3,x
        sta RIA_RW0
        iny
        cpy #8
        bne :-
        rts

; Tile 128+n: glyph n shown with bit 7 set.
convert_inverse:
        lda #$10
        jsr tile_addr
        ldy #0
:       lda (ptr1),y
        tax
        lda tile_i0,x
        sta RIA_RW0
        lda tile_i1,x
        sta RIA_RW0
        lda tile_i2,x
        sta RIA_RW0
        lda tile_i3,x
        sta RIA_RW0
        iny
        cpy #8
        bne :-
        rts

; The backdrop bitmap: COLBK a row. On the title, the rows of the text
; take the COLPF3 of T1 instead.
write_backdrop:
        ldx #0
        lda antic_rainbow
        bne @rainbow
@row:   lda colbk_line,x
        cmp backdrop,x
        bne @write
@next:  inx
        cpx #240
        bne @row
        rts
@write: jsr put_row
        bra @next
@rainbow:
        lda colbk_line,x
        ldy sl_line,x
        cpy #$FF
        beq :+
        ; T1 reads VCOUNT on the scanline above, so (scanline-1)/2*2.
        txa
        clc
        adc #7
        and #$FE
:       cmp backdrop,x
        beq :+
        jsr put_row
:       inx
        cpx #240
        bne @rainbow
        rts

; Row X of the backdrop is color A.
put_row:
        sta backdrop,x
        tay
        txa
        asl
        asl
        asl
        asl
        sta RIA_ADDR0
        txa
        lsr
        lsr
        lsr
        lsr
        clc
        adc #>XRAM_BACKDROP
        sta RIA_ADDR0+1
        tya
        ldy #16
:       sta RIA_RW0
        dey
        bne :-
        rts

; Band configurations and palettes.
write_bands:
        ldx #0
@band:  cpx nbands
        bne :+
        rts
:       stx tmp8
        ; mode2_config_t at XRAM_BANDCFG + 16*x
        txa
        asl
        asl
        asl
        asl
        sta RIA_ADDR0
        lda #>XRAM_BANDCFG
        sta RIA_ADDR0+1
        stz RIA_RW0         ; x_wrap
        stz RIA_RW0         ; y_wrap
        lda band_xpos,x
        sta RIA_RW0         ; x_pos_px
        ora #$7F
        bmi :+
        lda #0
:       sta RIA_RW0
        lda band_begin,x    ; y_pos_px
        sec
        sbc band_row0,x
        sta RIA_RW0
        lda #0
        sbc #0
        sta RIA_RW0
        lda band_width,x
        sta RIA_RW0         ; width_tiles
        stz RIA_RW0
        lda band_rows,x
        sta RIA_RW0         ; height_tiles
        stz RIA_RW0
        lda band_tm_lo,x
        sta RIA_RW0         ; xram_data_ptr
        lda band_tm_hi,x
        sta RIA_RW0
        txa                 ; xram_palette_ptr
        asl
        asl
        asl
        asl
        asl
        sta tmp1
        sta RIA_RW0
        txa
        lsr
        lsr
        lsr
        clc
        adc #>XRAM_BANDPAL
        sta tmp2
        sta RIA_RW0
        stz RIA_RW0         ; xram_tile_ptr
        lda band_slot,x
        beq :+
        lda #>XRAM_TILES1
:       sta RIA_RW0
        ; Palette: 0 COLBK, 1-3 COLPF0-2, 4 COLPF3. Color 0 is clear so the
        ; backdrop shows through, except on the title, where COLPF3 is.
        lda tmp1
        sta RIA_ADDR0
        lda tmp2
        sta RIA_ADDR0+1
        lda band_bk,x
        jsr color
        lda antic_rainbow
        bne :+
        stz ptr3
        stz ptr3+1
:       jsr put_ptr3
        ldx tmp8
        lda band_pf0,x
        jsr put_color
        ldx tmp8
        lda band_pf1,x
        jsr put_color
        ldx tmp8
        lda band_pf2,x
        jsr put_color
        ldx tmp8
        lda band_pf3,x
        jsr color
        lda antic_rainbow
        beq :+
        stz ptr3
        stz ptr3+1
:       jsr put_ptr3
        ldx tmp8
        inx
        jmp @band

; ptr3 = RGB555 of Atari color A.
color:
        asl
        tay
        bcs :+
        lda NTSC,y
        sta ptr3
        lda NTSC+1,y
        sta ptr3+1
        rts
:       lda NTSC+256,y
        sta ptr3
        lda NTSC+257,y
        sta ptr3+1
        rts

put_color:
        jsr color
put_ptr3:
        lda ptr3
        sta RIA_RW0
        lda ptr3+1
        sta RIA_RW0
        rts

; Program the VGA when the layout differs from the last frame. The canvas
; is set again, which clears every plane.
program_vga:
        lda sprite_plane
        cmp prog_plane
        bne @change
        lda nbands
        cmp prog_nbands
        bne @change
        tax
@cmp:   dex
        bpl :+
        rts
:       lda band_begin,x
        cmp prog_begin,x
        bne @change
        lda band_end,x
        cmp prog_end,x
        beq @cmp
@change:
        lda sprite_plane
        sta prog_plane
        lda nbands
        sta prog_nbands
        ldx #0
:       cpx nbands
        beq :+
        lda band_begin,x
        sta prog_begin,x
        lda band_end,x
        sta prog_end,x
        inx
        bra :-
:       xreg_vga_canvas CANVAS_320X240
        ; MODE on device 1 channel 0
        lda #1
        sta xreg_buf
        stz xreg_buf+1
        sta xreg_buf+2
        ; The backdrop on plane 0
        ldx #0
        lda #3
        jsr xreg_word
        lda #MODE3_8BPP
        jsr xreg_word
        lda #<XRAM_BACKCFG
        ldy #>XRAM_BACKCFG
        jsr xreg_word_y
        lda #0
        jsr xreg_word
        lda #0
        jsr xreg_word
        lda #0
        jsr xreg_word
        jsr xreg_call
        ; The players and missiles
        ldx #0
        lda #5
        jsr xreg_word
        lda #MODE5_CUSTOM
        jsr xreg_word
        lda #<XRAM_SPRCFG
        ldy #>XRAM_SPRCFG
        jsr xreg_word_y
        lda #MAX_SPRITES
        jsr xreg_word
        lda sprite_plane
        jsr xreg_word
        lda #0
        jsr xreg_word
        lda #0
        jsr xreg_word
        jsr xreg_call
        ; The bands on plane 1
        stz tmp8
@band:  lda tmp8
        cmp nbands
        beq @same
        ldx #0
        lda #2
        jsr xreg_word
        lda #MODE2_4BPP
        jsr xreg_word
        lda tmp8
        asl
        asl
        asl
        asl
        ldy #>XRAM_BANDCFG
        jsr xreg_word_y
        lda #1
        jsr xreg_word
        ldy tmp8
        lda band_begin,y
        jsr xreg_word
        ldy tmp8
        lda band_end,y
        jsr xreg_word
        jsr xreg_call
        inc tmp8
        bra @band
@same:  rts

; Put word A, with Y the high byte or 0, at value X of xreg_buf.
xreg_word:
        ldy #0
xreg_word_y:
        sta xreg_buf+4,x
        tya
        sta xreg_buf+5,x
        inx
        inx
        stx xreg_buf+3
        rts
