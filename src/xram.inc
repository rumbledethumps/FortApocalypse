; XRAM memory map

.ifndef XRAM_INC
XRAM_INC = 1

MAX_BANDS   = 16
MAX_SPRITES = 48
MAX_ROWS    = 32            ; mode lines with a tile row in one frame

XRAM_TILES0   = $0000       ; 256 4-bit 8x8 tiles, one character set
XRAM_TILES1   = $2000       ; the second character set
XRAM_TILEMAP  = $4000       ; MAX_ROWS rows of up to 48 tiles
XRAM_BACKDROP = $4600       ; 8-bit bitmap, 16x240, one color a row
XRAM_SPRITES  = $5500       ; 1-bit sprite images, one byte a row
XRAM_NTSC     = $6100       ; the 256 Atari colors
XRAM_BANDPAL  = $6300       ; MAX_BANDS palettes of 16 colors
XRAM_SPRPAL   = $6500       ; MAX_SPRITES palettes of 2 colors
XRAM_BANDCFG  = $6600       ; MAX_BANDS mode2_config_t
XRAM_SPRCFG   = $6700       ; MAX_SPRITES mode5_csprite_t
XRAM_BACKCFG  = $6900       ; mode3_config_t
XRAM_KEYBOARD = $6910       ; keyboard_t
XRAM_GAMEPAD  = $6930       ; gamepad_t
XRAM_PSG      = $6A00       ; psg_t
XRAM_RANDOM   = $8000       ; random bytes for the POKEY RANDOM register

SPRITE_IMAGES = XRAM_NTSC - XRAM_SPRITES

.macro xreg_vga_canvas canvas
    xreg 1, 0, 0, canvas
.endmacro

CANVAS_320X240 = 1

MODE2_4BPP = $02
MODE3_8BPP = $03
MODE5_CUSTOM = $38
MODE5_HDOUBLE = $40

.struct mode2_config_t
    x_wrap           .byte
    y_wrap           .byte
    x_pos_px         .word
    y_pos_px         .word
    width_tiles      .word
    height_tiles     .word
    xram_data_ptr    .word
    xram_palette_ptr .word
    xram_tile_ptr    .word
.endstruct

.struct mode3_config_t
    x_wrap           .byte
    y_wrap           .byte
    x_pos_px         .word
    y_pos_px         .word
    width_px         .word
    height_px        .word
    xram_data_ptr    .word
    xram_palette_ptr .word
.endstruct

.struct mode5_csprite_t
    x_pos_px        .word
    y_pos_px        .word
    xram_sprite_ptr .word
    palette_ptr     .word
    width_height    .byte
    options         .byte
.endstruct

KEYBOARD_BYTES = 32

GAMEPAD_PLAYERS = 4

GAMEPAD_DPAD_UP    = $01
GAMEPAD_DPAD_DOWN  = $02
GAMEPAD_DPAD_LEFT  = $04
GAMEPAD_DPAD_RIGHT = $08
GAMEPAD_FEAT_CONNECTED = $80

GAMEPAD_BTN0_A  = $01
GAMEPAD_BTN0_B  = $02
GAMEPAD_BTN0_X  = $08
GAMEPAD_BTN0_Y  = $10
GAMEPAD_BTN0_L1 = $40
GAMEPAD_BTN0_R1 = $80

GAMEPAD_BTN1_SELECT = $04
GAMEPAD_BTN1_START  = $08

.struct gamepad_t
    player .struct
        dpad   .byte
        sticks .byte
        btn0   .byte
        btn1   .byte
        lx     .byte
        ly     .byte
        rx     .byte
        ry     .byte
        l2     .byte
        r2     .byte
    .endstruct
    .res (::GAMEPAD_PLAYERS - 1) * .sizeof(player)
.endstruct

PSG_CHANNELS = 8

PSG_WAVE_SQUARE   = $10
PSG_WAVE_SAWTOOTH = $20
PSG_WAVE_NOISE    = $40

PSG_GATE = $01

.struct psg_t
    channel .struct
        freq         .word
        duty         .byte
        vol_attack   .byte
        vol_decay    .byte
        wave_release .byte
        pan_gate     .byte
        reserved     .byte
    .endstruct
    .res (::PSG_CHANNELS - 1) * .sizeof(channel)
.endstruct

.endif
