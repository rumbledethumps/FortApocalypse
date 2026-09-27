; Keyboard and gamepads as the Atari joystick, fire button, console keys
; and space bar
;
; Joystick: arrows, WASD, the keypad, or a d-pad or left stick
; Fire: Space, Ctrl, Alt, Z, X or Enter, or A, B, X or Y
; Pause: P or Pause, or Start during a game
; Options: Esc or Select. On the options screen the stick changes the
;   options, and Esc or Start starts a game.
; Start: Start, or fire during the demo
; START, SELECT, OPTION: F4, F3, F2

.include "rp6502.inc"
.include "atari.inc"
.include "xram.inc"

.importzp tmp1, tmp2, tmp3, tmp4
.importzp MODE, DEMO_STATUS, CONSOL_FLAG
.importzp TITLE_MODE, PAUSE_MODE, OPTION_MODE
.export input_init, input_frame, input_stick, input_trig

; Buttons, apart from the joystick and fire
BTN_PAUSE  = $01            ; P, Pause
BTN_ESC    = $02
BTN_SELECT = $04            ; gamepad
BTN_START  = $08            ; gamepad

; Commands are console key presses, CONSOL values, or the space bar.
CMD_START  = 6
CMD_OPTION = 3
CMD_SELECT = 5
CMD_MENU   = 1              ; OPTION and SELECT together
CMD_PAUSE  = $80

; A command is held down, then up, until the game has read it, or for at
; most this many frames.
CMD_FRAMES = 30

.bss
input_stick: .res 1         ; STICK0: bit clear for up, down, left, right
input_trig:  .res 1         ; STRIG0: 0 while fire is held
keys:        .res KEYBOARD_BYTES
buttons:     .res 1
last_btn:    .res 1         ; buttons and joystick of the last frame
last_joy:    .res 1
cmd_queue:   .res 4
cmd_head:    .res 1
cmd_tail:    .res 1
cmd:         .res 1         ; the command being sent
cmd_phase:   .res 1         ; 0 none, 1 down, 2 up
cmd_mode:    .res 1         ; MODE when the command started
cmd_time:    .res 1

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
        ; Joystick and fire as tmp1: up 1, down 2, left 4, right 8, fire
        ; $10. Console keys as tmp2: START 1, SELECT 2, OPTION 4.
        stz tmp1
        stz tmp2
        stz buttons
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
        lda key_button,x
        ora buttons
        sta buttons
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
        and #GAMEPAD_BTN0_A | GAMEPAD_BTN0_B | GAMEPAD_BTN0_X | GAMEPAD_BTN0_Y
        beq :+
        lda #$10
        tsb tmp1
:       lda RIA_RW0         ; btn1
        sta tmp3
        and #GAMEPAD_BTN1_START
        beq :+
        lda #BTN_START
        tsb buttons
:       lda tmp3
        and #GAMEPAD_BTN1_SELECT
        beq @nextpad
        lda #BTN_SELECT
        tsb buttons
@nextpad:
        txa
        clc
        adc #.sizeof(gamepad_t::player)
        tax
        cpx #.sizeof(gamepad_t)
        bne @pad
        ; The Atari joystick and fire button
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
        jsr commands
        ; CONSOL: the console keys held, and the command
        lda tmp2
        and #7
        eor #7
        sta tmp3
        lda #7
        ldx cmd_phase
        cpx #1
        bne :+
        ldx cmd
        bmi :+
        txa
:       and tmp3
        sta CONSOL
        ; The space bar sets KBCODE and holds SKSTAT bit 2 low.
        ldx #$FF
        lda cmd_phase
        cmp #1
        bne :+
        bit cmd
        bpl :+
        lda #$21
        sta KBCODE
        ldx #$FB
:       stx SKSTAT
        rts

; Queue the commands of the buttons pressed this frame, then send the
; command at the front of the queue.
commands:
        lda buttons
        eor last_btn
        and buttons
        sta tmp3            ; buttons pressed this frame
        lda buttons
        sta last_btn
        lda tmp1
        eor last_joy
        and tmp1
        sta tmp4            ; joystick and fire pressed this frame
        lda tmp1
        sta last_joy
        lda tmp3
        and #BTN_PAUSE
        beq :+
        lda #CMD_PAUSE
        jsr queue
:       lda MODE
        cmp #OPTION_MODE
        bne @game
        ; The options screen
        lda tmp3
        and #BTN_ESC | BTN_START
        beq :+
        lda #CMD_START
        jsr queue
:       lda tmp4            ; down 2
        and #2
        beq :+
        lda #CMD_OPTION
        jsr queue
:       lda tmp4            ; up 1
        and #1
        beq :+
        lda #CMD_OPTION     ; three items, so twice is back one
        jsr queue
        lda #CMD_OPTION
        jsr queue
:       lda tmp4            ; right 8
        and #8
        beq :+
        lda #CMD_SELECT
        jsr queue
:       lda tmp4            ; left 4
        and #4
        beq @send
        lda #CMD_SELECT     ; three values, so twice is back one
        jsr queue
        lda #CMD_SELECT
        jsr queue
        bra @send
@game:  lda tmp3
        and #BTN_ESC | BTN_SELECT
        beq :+
        lda #CMD_MENU
        jsr queue
:       ; Start pauses a game, and starts one on the title screen and in
        ; the demo, where DEMO_STATUS is 0. Fire starts one in the demo too.
        lda DEMO_STATUS
        bne @start
        lda tmp4
        and #$10
        ora tmp3
        and #BTN_START | $10
        beq @send
        lda #CMD_START
        jsr queue
        bra @send
@start: lda tmp3
        and #BTN_START
        beq @send
        lda #CMD_START
        ldx MODE
        cpx #TITLE_MODE
        beq :+
        lda #CMD_PAUSE
:       jsr queue
@send:  lda cmd_phase
        bne @active
        ldx cmd_head
        cpx cmd_tail
        bne :+
        rts
:       lda cmd_queue,x
        sta cmd
        inx
        txa
        and #3
        sta cmd_head
        lda MODE
        sta cmd_mode
        stz cmd_time
        inc cmd_phase
@active:
        inc cmd_time
        lda cmd_time
        cmp #CMD_FRAMES
        bcs @next
        lda cmd_phase
        cmp #1
        bne @up
        ; Down until the game has read it
        lda cmd
        bmi @space
        cmp CONSOL_FLAG
        beq @next
        lda MODE            ; T2 on the title leaves CONSOL_FLAG as it is
        cmp cmd_mode
        bne @next
        rts
@space: lda cmd_mode        ; the pause loop reads the space bar at once
        cmp #PAUSE_MODE
        beq @brief
        lda MODE
        cmp #PAUSE_MODE
        beq @next
        rts
@up:    ; Up until the game has read it
        lda cmd
        bmi @brief
        lda CONSOL_FLAG
        cmp #7
        beq @done
        rts
@brief: lda cmd_time
        cmp #3
        bcs @next
        rts
@next:  inc cmd_phase
        stz cmd_time
        lda cmd_phase
        cmp #3
        bcc :+
@done:  stz cmd_phase
:       rts

; Add command A to the queue, unless it is full.
queue:
        ldx cmd_tail
        sta cmd_queue,x
        inx
        txa
        and #3
        cmp cmd_head
        beq :+
        sta cmd_tail
:       rts

bit_mask:
        .byte $01, $02, $04, $08, $10, $20, $40, $80

; HID keycodes, and what each one does.
key_code:
        .byte $52, $1A, $60, $5F, $61   ; up: arrow, W, keypad 8, 7, 9
        .byte $51, $16, $5A, $59, $5B   ; down: arrow, S, keypad 2, 1, 3
        .byte $50, $04, $5C             ; left: arrow, A, keypad 4
        .byte $4F, $07, $5E             ; right: arrow, D, keypad 6
        .byte $2C, $E0, $E4, $E2, $E6   ; fire: Space, Ctrl, Alt
        .byte $1D, $1B, $28, $58        ; fire: Z, X, Enter, keypad Enter
        .byte $3D, $3C, $3B             ; START, SELECT, OPTION: F4, F3, F2
        .byte $13, $48, $29             ; P, Pause, Esc
        .byte 0
key_bits:
        .byte $01, $01, $01, $05, $09
        .byte $02, $02, $02, $06, $0A
        .byte $04, $04, $04
        .byte $08, $08, $08
        .byte $10, $10, $10, $10, $10
        .byte $10, $10, $10, $10
        .byte 0, 0, 0
        .byte 0, 0, 0
key_console:
        .byte 0, 0, 0, 0, 0
        .byte 0, 0, 0, 0, 0
        .byte 0, 0, 0
        .byte 0, 0, 0
        .byte 0, 0, 0, 0, 0
        .byte 0, 0, 0, 0
        .byte 1, 2, 4
        .byte 0, 0, 0
key_button:
        .byte 0, 0, 0, 0, 0
        .byte 0, 0, 0, 0, 0
        .byte 0, 0, 0
        .byte 0, 0, 0
        .byte 0, 0, 0, 0, 0
        .byte 0, 0, 0, 0
        .byte 0, 0, 0
        .byte BTN_PAUSE, BTN_PAUSE, BTN_ESC
