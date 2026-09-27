#ifndef FORT_H
#define FORT_H

#include "emu.h"

/* Game variables at the addresses of the Atari original, from src/fort7.s */
#define PLAY_SCRN 0x0300
#define CHR_SET1 0x0800
#define CHR_SET2 0x0C00
#define FRAME 0x14
#define DEMO_STATUS 0x4B
#define SX 0x54
#define LEVEL 0x5A
#define CHOPPER_STATUS 0x62
#define CHOPPER_X 0x63
#define CHOPPER_Y 0x64
#define CHOPPER_COL 0x67
#define ROCKET_STATUS 0x78
#define ROCKETS 3
#define MODE 0xA0
#define POD_NUM 0xEB
#define MAX_PODS 39
#define GRAV_SKILL 0xF7
#define PILOT_SKILL 0xF9
#define CHOPS 0xFB
#define CHOP_LEFT 0xFC
#define OPT_NUM 0xFD

/* MODE */
#define TITLE_MODE 1
#define GO_MODE 2
#define NEW_LEVEL_MODE 4
#define NEW_PLAYER_MODE 5
#define PAUSE_MODE 8
#define OPTION_MODE 9

/* CHOPPER_STATUS */
#define FLY 3
#define CRASH 4

/* The Atari OS shadows and hardware registers, in RAM on the Picocomputer */
#define COLOR0 0x02C4
#define STICK0 0x0278
#define STRIG0 0x0284
#define HPOSP0 0xD000
#define P0PF 0xD104
#define TRIG0 0xD110
#define CONSOL 0xD11F
#define AUDF1 0xD200
#define AUDC1 0xD201
#define AUDCTL 0xD208
#define KBCODE 0xD309
#define SKSTAT 0xD30F

/* HID keys */
#define KEY_P 0x13
#define KEY_Z 0x1D
#define KEY_ENTER 0x28
#define KEY_ESC 0x29
#define KEY_SPACE 0x2C
#define KEY_F2 0x3B
#define KEY_F3 0x3C
#define KEY_F4 0x3D
#define KEY_PAUSE 0x48
#define KEY_RIGHT 0x4F
#define KEY_LEFT 0x50
#define KEY_DOWN 0x51
#define KEY_UP 0x52
#define KEY_LCTRL 0xE0

/* The address of an exported symbol of the ROM, from its label file. */
unsigned fort_sym(const char *name);

/* A constant from src/xram.inc. */
unsigned fort_xram(const char *name);

/* Boot the ROM to the title screen, with RAM and XRAM random or filled
   with a byte. */
bool fort_boot(emu_t *emu);
bool fort_boot_fill(emu_t *emu, const char *fill);

/* Press fire on the title screen, and run until the chopper flies. */
bool fort_play(emu_t *emu);

/* A key held for two frames, then released for two. */
bool fort_tap(emu_t *emu, unsigned key);

/* A button of gamepad 0 held for two frames, then released for two. */
bool fort_tap_pad(emu_t *emu, const char *button);

/* The options screen settings, one byte each. */
int fort_settings(emu_t *emu);

/* One byte of RAM or XRAM, or -1 without an answer. */
int fort_ram(emu_t *emu, unsigned addr);
int fort_xram_byte(emu_t *emu, unsigned addr);

#endif
