; Keyboard and gamepads as the Atari joystick, fire button, console keys
; and space bar
;
; Joystick: arrows, WASD, the keypad, or a d-pad or left stick
; Fire: Ctrl, Alt, Z, X or Enter, or A, B, X or Y
; START, SELECT, OPTION: F4, F3, F2, or Start, Select, L1
; Pause, the space bar of the Atari: Space or P, or R1

.include "rp6502.inc"
.include "atari.inc"
.include "xram.inc"

.importzp tmp1, tmp2, tmp3, tmp4
.export input_init, input_frame, input_stick, input_trig

.bss
input_stick: .res 1         ; STICK0: bit clear for up, down, left, right
input_trig:  .res 1         ; STRIG0: 0 while fire is held
keys:        .res KEYBOARD_BYTES

.code

input_init:
        xreg 0, 0, 0, XRAM_KEYBOARD
        xreg 0, 0, 2, XRAM_GAMEPAD
        lda #$0F
        sta input_stick
        lda #1
        sta input_trig
        rts

input_frame:
        lda #1
        sta RIA_STEP0
        lda #<XRAM_KEYBOARD
        sta RIA_ADDR0
        lda #>XRAM_KEYBOARD
        sta RIA_ADDR0+1
        ldx #0
:       lda RIA_RW0
        sta keys,x
        inx
        cpx #KEYBOARD_BYTES
        bne :-
        ; Directions and buttons as tmp1: up 1, down 2, left 4, right 8,
        ; fire $10, and tmp2: START 1, SELECT 2, OPTION 4, pause 8.
        stz tmp1
        stz tmp2
        ldx #0
@key:   lda key_code,x
        beq @pads
        and #7
        tay
        lda bit_mask,y
        sta tmp3
        lda key_code,x
        lsr
        lsr
        lsr
        tay
        lda keys,y
        and tmp3
        beq :+
        lda key_bits,x
        ora tmp1
        sta tmp1
        lda key_console,x
        ora tmp2
        sta tmp2
:       inx
        bra @key
@pads:  ; Every connected gamepad
        ldx #0
@pad:   txa
        clc
        adc #<XRAM_GAMEPAD
        sta RIA_ADDR0
        lda #>XRAM_GAMEPAD
        adc #0
        sta RIA_ADDR0+1
        lda RIA_RW0         ; dpad
        bpl @nextpad
        and #$0F
        sta tmp3
        lda RIA_RW0         ; sticks
        and #$0F
        ora tmp3
        ora tmp1
        sta tmp1
        lda RIA_RW0         ; btn0
        sta tmp3
        and #GAMEPAD_BTN0_A | GAMEPAD_BTN0_B | GAMEPAD_BTN0_X | GAMEPAD_BTN0_Y
        beq :+
        lda #$10
        tsb tmp1
:       lda tmp3
        and #GAMEPAD_BTN0_L1
        beq :+
        lda #4
        tsb tmp2
:       lda tmp3
        and #GAMEPAD_BTN0_R1
        beq :+
        lda #8
        tsb tmp2
:       lda RIA_RW0         ; btn1
        sta tmp3
        and #GAMEPAD_BTN1_START
        beq :+
        lda #1
        tsb tmp2
:       lda tmp3
        and #GAMEPAD_BTN1_SELECT
        beq @nextpad
        lda #2
        tsb tmp2
@nextpad:
        txa
        clc
        adc #.sizeof(gamepad_t::player)
        tax
        cpx #.sizeof(gamepad_t)
        bne @pad
        ; The Atari registers
        lda tmp1
        and #$0F
        eor #$0F
        sta input_stick
        ldx #0
        lda tmp1
        and #$10
        bne :+
        inx
:       stx input_trig
        stx TRIG0
        lda tmp2
        and #7
        eor #7
        sta CONSOL
        ; The space bar sets KBCODE and holds SKSTAT bit 2 low.
        ldx #$FF
        lda tmp2
        and #8
        beq :+
        lda #$21
        sta KBCODE
        ldx #$FB
:       stx SKSTAT
        rts

bit_mask:
        .byte $01, $02, $04, $08, $10, $20, $40, $80

; HID keycodes, and what each one does.
key_code:
        .byte $52, $1A, $60, $5F, $61   ; up: arrow, W, keypad 8, 7, 9
        .byte $51, $16, $5A, $59, $5B   ; down: arrow, S, keypad 2, 1, 3
        .byte $50, $04, $5C             ; left: arrow, A, keypad 4
        .byte $4F, $07, $5E             ; right: arrow, D, keypad 6
        .byte $E0, $E4, $E2, $E6        ; fire: Ctrl, Alt
        .byte $1D, $1B, $28, $58        ; fire: Z, X, Enter, keypad Enter
        .byte $3D, $3C, $3B             ; START, SELECT, OPTION: F4, F3, F2
        .byte $2C, $13                  ; pause: Space, P
        .byte 0
key_bits:
        .byte $01, $01, $01, $05, $09
        .byte $02, $02, $02, $06, $0A
        .byte $04, $04, $04
        .byte $08, $08, $08
        .byte $10, $10, $10, $10
        .byte $10, $10, $10, $10
        .byte 0, 0, 0
        .byte 0, 0
key_console:
        .byte 0, 0, 0, 0, 0
        .byte 0, 0, 0, 0, 0
        .byte 0, 0, 0
        .byte 0, 0, 0
        .byte 0, 0, 0, 0
        .byte 0, 0, 0, 0
        .byte 1, 2, 4
        .byte 8, 8
