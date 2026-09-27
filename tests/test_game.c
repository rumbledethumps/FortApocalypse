#include "fort.h"
#include "utest.h"

struct game
{
    emu_t emu;
    int overruns; /* before the game started */
};

UTEST_F_SETUP(game)
{
    ASSERT_TRUE(fort_boot(&utest_fixture->emu));
    utest_fixture->overruns = fort_ram(&utest_fixture->emu, fort_sym("overruns"));
    ASSERT_TRUE(fort_play(&utest_fixture->emu));
}

UTEST_F_TEARDOWN(game)
{
    emu_stop(&utest_fixture->emu);
}

UTEST_F(game, start)
{
    emu_t *emu = &utest_fixture->emu;
    ASSERT_EQ(0, fort_ram(emu, LEVEL));
    ASSERT_EQ(0, fort_ram(emu, fort_sym("antic_rainbow")));
    ASSERT_EQ(0, fort_ram(emu, CHOPPER_COL));
}

UTEST_F(game, chopper_sprites)
{
    /* Players 0 and 1 draw the chopper, and a sprite is at twice the
       distance of each from the left edge of the playfield. */
    emu_t *emu = &utest_fixture->emu;
    unsigned cfg = fort_xram("XRAM_SPRCFG");
    uint8_t sprites[48 * 10], hpos[2];
    int found[2] = {-1, -1};
    ASSERT_NE(0u, cfg);
    ASSERT_TRUE(emu_ok(emu, "run 2"));
    ASSERT_TRUE(emu_dump(emu, "ram:$D000", 2, hpos));
    for (unsigned i = 0; i < 48; i += 12)
    {
        char where[16];
        snprintf(where, sizeof(where), "xram:$%04X", cfg + i * 10);
        ASSERT_TRUE(emu_dump(emu, where, 120, sprites + i * 10));
    }
    for (unsigned p = 0; p < 2; p++)
        for (unsigned i = 0; i < 48; i++)
            if ((int16_t)(sprites[i * 10] | sprites[i * 10 + 1] << 8) == 2 * (hpos[p] - 48))
                found[p] = i;
    ASSERT_NE(-1, found[0]);
    ASSERT_NE(-1, found[1]);
    ASSERT_EQ(sprites[found[0] * 10 + 2], sprites[found[1] * 10 + 2]);
    ASSERT_EQ(sprites[found[0] * 10 + 3], sprites[found[1] * 10 + 3]);
}

UTEST_F(game, fly)
{
    emu_t *emu = &utest_fixture->emu;
    int x = fort_ram(emu, CHOPPER_X), sx = fort_ram(emu, SX);
    ASSERT_TRUE(emu_ok(emu, "press 0x%02X", KEY_RIGHT));
    ASSERT_TRUE(emu_ok(emu, "run 40"));
    ASSERT_GT(fort_ram(emu, CHOPPER_X), x);
    ASSERT_NE(sx, fort_ram(emu, SX));
    ASSERT_TRUE(emu_ok(emu, "release 0x%02X", KEY_RIGHT));
    x = fort_ram(emu, CHOPPER_X);
    ASSERT_TRUE(emu_ok(emu, "press 0x%02X", KEY_LEFT));
    ASSERT_TRUE(emu_ok(emu, "run 40"));
    ASSERT_LT(fort_ram(emu, CHOPPER_X), x);
    ASSERT_EQ(FLY, fort_ram(emu, CHOPPER_STATUS));
}

UTEST_F(game, fire)
{
    /* A rocket, and the noise of its launch on the second channel */
    emu_t *emu = &utest_fixture->emu;
    unsigned psg = fort_xram("XRAM_PSG");
    uint8_t rockets[ROCKETS], chan[8];
    char where[16];
    ASSERT_NE(0u, psg);
    ASSERT_TRUE(emu_ok(emu, "press 0x%02X", KEY_Z));
    ASSERT_TRUE(emu_ok(emu, "run 4"));
    ASSERT_TRUE(emu_dump(emu, "ram:$0078", ROCKETS, rockets));
    ASSERT_NE(0, rockets[0] | rockets[1] | rockets[2]);
    snprintf(where, sizeof(where), "xram:$%04X", psg + 8);
    ASSERT_TRUE(emu_dump(emu, where, sizeof(chan), chan));
    ASSERT_EQ(0x40, chan[5]); /* PSG_WAVE_NOISE */
    ASSERT_EQ(1, chan[6]);    /* PSG_GATE */
}

UTEST_F(game, crash)
{
    /* Down and left from the start flies into the hill, which the
       collisions of the chopper players with the playfield find. */
    emu_t *emu = &utest_fixture->emu;
    ASSERT_EQ(0x10, fort_ram(emu, CHOP_LEFT));
    ASSERT_TRUE(emu_ok(emu, "press 0x%02X 0x%02X", KEY_DOWN, KEY_LEFT));
    ASSERT_TRUE(emu_ok(emu, "wait $%02X %u 300", CHOPPER_STATUS, CRASH));
    ASSERT_NE(0, fort_ram(emu, CHOPPER_COL));
    ASSERT_TRUE(emu_ok(emu, "release 0x%02X 0x%02X", KEY_DOWN, KEY_LEFT));
    ASSERT_TRUE(emu_ok(emu, "wait $%02X %u 600", MODE, NEW_PLAYER_MODE));
    ASSERT_TRUE(emu_ok(emu, "wait $%02X %u 600", MODE, GO_MODE));
    ASSERT_EQ(0x09, fort_ram(emu, CHOP_LEFT));
}

UTEST_F(game, pause)
{
    emu_t *emu = &utest_fixture->emu;
    int pod, y;
    ASSERT_TRUE(fort_tap(emu, KEY_P));
    ASSERT_TRUE(emu_ok(emu, "wait $%02X %u 30", MODE, PAUSE_MODE));
    ASSERT_TRUE(emu_ok(emu, "run 5"));
    pod = fort_ram(emu, POD_NUM);
    y = fort_ram(emu, CHOPPER_Y);
    ASSERT_TRUE(emu_ok(emu, "run 250"));
    ASSERT_EQ(PAUSE_MODE, fort_ram(emu, MODE));
    ASSERT_EQ(pod, fort_ram(emu, POD_NUM));
    ASSERT_EQ(y, fort_ram(emu, CHOPPER_Y));
    ASSERT_TRUE(fort_tap(emu, KEY_P));
    ASSERT_TRUE(emu_ok(emu, "wait $%02X %u 30", MODE, GO_MODE));
    ASSERT_TRUE(emu_ok(emu, "run 30"));
    ASSERT_NE(pod, fort_ram(emu, POD_NUM));
}

UTEST_F(game, pause_keys)
{
    emu_t *emu = &utest_fixture->emu;
    ASSERT_TRUE(fort_tap(emu, KEY_PAUSE));
    ASSERT_TRUE(emu_ok(emu, "wait $%02X %u 30", MODE, PAUSE_MODE));
    ASSERT_TRUE(emu_ok(emu, "run 5"));
    ASSERT_TRUE(fort_tap(emu, KEY_PAUSE));
    ASSERT_TRUE(emu_ok(emu, "wait $%02X %u 30", MODE, GO_MODE));
    ASSERT_TRUE(emu_ok(emu, "pad 0 connect"));
    ASSERT_TRUE(fort_tap_pad(emu, "start"));
    ASSERT_TRUE(emu_ok(emu, "wait $%02X %u 30", MODE, PAUSE_MODE));
    ASSERT_TRUE(emu_ok(emu, "run 5"));
    ASSERT_TRUE(fort_tap_pad(emu, "start"));
    ASSERT_TRUE(emu_ok(emu, "wait $%02X %u 30", MODE, GO_MODE));
}

UTEST_F(game, options)
{
    /* Esc ends the game and opens the options screen as it was. */
    emu_t *emu = &utest_fixture->emu;
    int settings = fort_settings(emu);
    ASSERT_TRUE(fort_tap(emu, KEY_ESC));
    ASSERT_TRUE(emu_ok(emu, "wait $%02X %u 60", MODE, OPTION_MODE));
    ASSERT_TRUE(emu_ok(emu, "run 10"));
    ASSERT_EQ(OPTION_MODE, fort_ram(emu, MODE));
    ASSERT_EQ(0, fort_ram(emu, OPT_NUM));
    ASSERT_EQ(settings, fort_settings(emu));
}

/* The main loop moves 15 pods a pass, and POD_NUM counts them modulo
   MAX_PODS. */
static int main_passes_x100(emu_t *emu, unsigned frames)
{
    int last = fort_ram(emu, POD_NUM), pods = 0;
    for (unsigned i = 0; i < frames; i++)
    {
        int pod;
        if (!emu_ok(emu, "run 1"))
            return -1;
        pod = fort_ram(emu, POD_NUM);
        pods += (pod - last + MAX_PODS) % MAX_PODS;
        last = pod;
    }
    return pods * 100 / 15;
}

UTEST_F(game, main_loop_rate)
{
    /* The main loop on an NTSC Atari runs 0.31 passes a frame at the start
       of the first level. */
    emu_t *emu = &utest_fixture->emu;
    int passes = main_passes_x100(emu, 240);
    ASSERT_GE(passes, 240 * 27);
    ASSERT_LE(passes, 240 * 35);
}

UTEST_F(game, no_overruns)
{
    /* Every frame fits in its VSYNC while the map scrolls. The first game
       converts the second character set to tiles, which takes one frame
       more. */
    emu_t *emu = &utest_fixture->emu;
    unsigned overruns = fort_sym("overruns");
    int before, sx;
    ASSERT_NE(0u, overruns);
    before = fort_ram(emu, overruns);
    ASSERT_LE(before, utest_fixture->overruns + 1);
    sx = fort_ram(emu, SX);
    ASSERT_TRUE(emu_ok(emu, "press 0x%02X", KEY_RIGHT));
    ASSERT_TRUE(emu_ok(emu, "run 60"));
    ASSERT_NE(sx, fort_ram(emu, SX));
    ASSERT_TRUE(emu_ok(emu, "run 180"));
    ASSERT_EQ(before, fort_ram(emu, overruns));
}

UTEST_F(game, no_overruns_crash)
{
    /* Every frame fits in its VSYNC through a crash and the next pilot. */
    emu_t *emu = &utest_fixture->emu;
    unsigned overruns = fort_sym("overruns");
    int before;
    ASSERT_NE(0u, overruns);
    before = fort_ram(emu, overruns);
    ASSERT_TRUE(emu_ok(emu, "press 0x%02X 0x%02X", KEY_DOWN, KEY_LEFT));
    ASSERT_TRUE(emu_ok(emu, "wait $%02X %u 300", CHOPPER_STATUS, CRASH));
    ASSERT_TRUE(emu_ok(emu, "release 0x%02X 0x%02X", KEY_DOWN, KEY_LEFT));
    ASSERT_TRUE(emu_ok(emu, "wait $%02X %u 600", MODE, NEW_PLAYER_MODE));
    ASSERT_TRUE(emu_ok(emu, "wait $%02X %u 600", MODE, GO_MODE));
    ASSERT_EQ(before, fort_ram(emu, overruns));
}
