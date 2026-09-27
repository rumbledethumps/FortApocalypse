#include "fort.h"
#include "utest.h"

struct title
{
    emu_t emu;
};

UTEST_F_SETUP(title)
{
    ASSERT_TRUE(fort_boot(&utest_fixture->emu));
}

UTEST_F_TEARDOWN(title)
{
    emu_stop(&utest_fixture->emu);
}

UTEST_F(title, rainbow)
{
    /* T1 sets COLPF3 from VCOUNT on every scanline of the text, and canvas
       row 0 is scanline 8. Each row of the backdrop has its own color. */
    emu_t *emu = &utest_fixture->emu;
    unsigned sl_line = fort_sym("sl_line");
    unsigned ntsc = fort_sym("NTSC");
    unsigned backpal = fort_xram("XRAM_BACKPAL");
    int rows = 0;
    ASSERT_NE(0u, sl_line);
    ASSERT_NE(0u, ntsc);
    ASSERT_NE(0u, backpal);
    ASSERT_EQ(1, fort_ram(emu, fort_sym("antic_rainbow")));
    for (unsigned row = 0; row < 240; row++)
    {
        unsigned color = (row + 7) & 0xFE;
        int line = fort_ram(emu, sl_line + row);
        ASSERT_NE(-1, line);
        if (line == 0xFF)
            continue;
        ASSERT_EQ_MSG(fort_ram(emu, ntsc + color * 2), fort_xram_byte(emu, backpal + row * 2), "backdrop row");
        ASSERT_EQ_MSG(fort_ram(emu, ntsc + color * 2 + 1), fort_xram_byte(emu, backpal + row * 2 + 1), "backdrop row");
        rows++;
    }
    ASSERT_GE(rows, 100);
}

UTEST_F(title, colors_rotate)
{
    emu_t *emu = &utest_fixture->emu;
    uint8_t before[3], after[3];
    ASSERT_TRUE(emu_dump(emu, "ram:$02C4", 3, before));
    ASSERT_TRUE(emu_ok(emu, "run 8"));
    ASSERT_TRUE(emu_dump(emu, "ram:$02C4", 3, after));
    ASSERT_EQ(before[0], after[2]);
    ASSERT_EQ(before[1], after[0]);
    ASSERT_EQ(before[2], after[1]);
}

UTEST_F(title, tones)
{
    /* The title plays two pure tones a little apart. */
    emu_t *emu = &utest_fixture->emu;
    unsigned psg = fort_xram("XRAM_PSG");
    ASSERT_NE(0u, psg);
    for (unsigned ch = 0; ch < 2; ch++)
    {
        uint8_t chan[8];
        char where[16];
        snprintf(where, sizeof(where), "xram:$%04X", psg + ch * 8);
        ASSERT_TRUE(emu_dump(emu, where, sizeof(chan), chan));
        ASSERT_GT(chan[0] | chan[1] << 8, 3 * 100);
        ASSERT_LT(chan[0] | chan[1] << 8, 3 * 200);
        ASSERT_EQ(0x10, chan[5]); /* PSG_WAVE_SQUARE */
        ASSERT_EQ(1, chan[6]);    /* PSG_GATE */
    }
}

UTEST_F(title, level_entry)
{
    /* The level setup keeps ENTERING on the screen for 84 frames on an
       NTSC Atari. */
    emu_t *emu = &utest_fixture->emu;
    int frames = 0;
    ASSERT_TRUE(fort_tap(emu, KEY_LCTRL));
    ASSERT_TRUE(emu_ok(emu, "wait $%02X %u 60", MODE, NEW_LEVEL_MODE));
    while (fort_ram(emu, MODE) == NEW_LEVEL_MODE && frames < 200)
    {
        ASSERT_TRUE(emu_ok(emu, "run 1"));
        frames++;
    }
    ASSERT_GE(frames, 75);
    ASSERT_LE(frames, 100);
}

UTEST_F(title, start_key)
{
    emu_t *emu = &utest_fixture->emu;
    ASSERT_TRUE(fort_tap(emu, KEY_F4));
    ASSERT_TRUE(emu_ok(emu, "wait $%02X %u 600", MODE, GO_MODE));
    ASSERT_EQ(1, fort_ram(emu, DEMO_STATUS));
}

UTEST_F(title, options)
{
    emu_t *emu = &utest_fixture->emu;
    ASSERT_EQ(TITLE_MODE, fort_ram(emu, MODE));
    ASSERT_TRUE(fort_tap(emu, KEY_F2));
    ASSERT_EQ(OPTION_MODE, fort_ram(emu, MODE));
    ASSERT_EQ(0, fort_ram(emu, OPT_NUM));
    ASSERT_EQ(0, fort_ram(emu, GRAV_SKILL));
    ASSERT_TRUE(fort_tap(emu, KEY_F3));
    ASSERT_EQ(1, fort_ram(emu, GRAV_SKILL));
    ASSERT_TRUE(fort_tap(emu, KEY_F2));
    ASSERT_EQ(1, fort_ram(emu, OPT_NUM));
}

UTEST_F(title, esc)
{
    /* Esc opens the options screen as it was, and Esc there starts a
       game. */
    emu_t *emu = &utest_fixture->emu;
    int settings = fort_settings(emu);
    ASSERT_TRUE(fort_tap(emu, KEY_ESC));
    ASSERT_TRUE(emu_ok(emu, "wait $%02X %u 30", MODE, OPTION_MODE));
    ASSERT_TRUE(emu_ok(emu, "run 10"));
    ASSERT_EQ(0, fort_ram(emu, OPT_NUM));
    ASSERT_EQ(settings, fort_settings(emu));
    ASSERT_TRUE(fort_tap(emu, KEY_ESC));
    ASSERT_TRUE(emu_ok(emu, "wait $%02X %u 600", MODE, GO_MODE));
}

UTEST_F(title, options_stick)
{
    /* Down and up move between the options, right and left change one. */
    emu_t *emu = &utest_fixture->emu;
    ASSERT_TRUE(fort_tap(emu, KEY_ESC));
    ASSERT_TRUE(emu_ok(emu, "wait $%02X %u 30", MODE, OPTION_MODE));
    ASSERT_TRUE(fort_tap(emu, KEY_DOWN));
    ASSERT_TRUE(emu_ok(emu, "wait $%02X 1 30", OPT_NUM));
    ASSERT_TRUE(fort_tap(emu, KEY_UP));
    ASSERT_TRUE(emu_ok(emu, "wait $%02X 0 30", OPT_NUM));
    ASSERT_TRUE(fort_tap(emu, KEY_UP));
    ASSERT_TRUE(emu_ok(emu, "wait $%02X 2 30", OPT_NUM));
    ASSERT_TRUE(fort_tap(emu, KEY_DOWN));
    ASSERT_TRUE(emu_ok(emu, "wait $%02X 0 30", OPT_NUM));
    ASSERT_TRUE(fort_tap(emu, KEY_RIGHT));
    ASSERT_TRUE(emu_ok(emu, "wait $%02X 1 30", GRAV_SKILL));
    ASSERT_TRUE(fort_tap(emu, KEY_LEFT));
    ASSERT_TRUE(emu_ok(emu, "wait $%02X 0 30", GRAV_SKILL));
    ASSERT_TRUE(fort_tap(emu, KEY_LEFT));
    ASSERT_TRUE(emu_ok(emu, "wait $%02X 2 30", GRAV_SKILL));
    ASSERT_TRUE(emu_ok(emu, "run 10"));
    ASSERT_EQ(OPTION_MODE, fort_ram(emu, MODE));
}

UTEST_F(title, start_pad)
{
    /* Start begins a game, and held into it, it does not pause it. */
    emu_t *emu = &utest_fixture->emu;
    ASSERT_TRUE(emu_ok(emu, "pad 0 connect"));
    ASSERT_TRUE(emu_ok(emu, "pad 0 press start"));
    ASSERT_TRUE(emu_ok(emu, "wait $%02X %u 600", MODE, GO_MODE));
    ASSERT_TRUE(emu_ok(emu, "run 60"));
    ASSERT_EQ(GO_MODE, fort_ram(emu, MODE));
    ASSERT_TRUE(emu_ok(emu, "pad 0 release start"));
    ASSERT_TRUE(emu_ok(emu, "run 30"));
    ASSERT_EQ(GO_MODE, fort_ram(emu, MODE));
}

UTEST_F(title, demo_fire)
{
    /* Fire during the demo starts a game. */
    emu_t *emu = &utest_fixture->emu;
    ASSERT_TRUE(emu_ok(emu, "run 1800"));
    ASSERT_TRUE(emu_ok(emu, "wait $%02X %u 900", MODE, GO_MODE));
    ASSERT_EQ(0, fort_ram(emu, DEMO_STATUS));
    ASSERT_TRUE(emu_ok(emu, "run 60"));
    ASSERT_TRUE(fort_tap(emu, KEY_LCTRL));
    ASSERT_TRUE(emu_ok(emu, "wait $%02X %u 60", MODE, NEW_LEVEL_MODE));
    ASSERT_NE(0, fort_ram(emu, DEMO_STATUS));
}

UTEST_F(title, demo)
{
    /* About 32 seconds on the title screen start the demo. */
    emu_t *emu = &utest_fixture->emu;
    ASSERT_TRUE(emu_ok(emu, "run 1800"));
    ASSERT_EQ(TITLE_MODE, fort_ram(emu, MODE));
    ASSERT_TRUE(emu_ok(emu, "wait $%02X %u 900", MODE, GO_MODE));
    /* A game started with a key or the fire button sets it to 1. */
    ASSERT_EQ(0, fort_ram(emu, DEMO_STATUS));
}
