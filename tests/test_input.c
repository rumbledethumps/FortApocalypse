#include "fort.h"
#include "utest.h"

struct input
{
    emu_t emu;
};

UTEST_F_SETUP(input)
{
    ASSERT_TRUE(fort_boot(&utest_fixture->emu));
}

UTEST_F_TEARDOWN(input)
{
    emu_stop(&utest_fixture->emu);
}

/* STICK0 has a clear bit for each direction: up 1, down 2, left 4, right 8. */
static const struct
{
    const char *press;
    int stick;
} keys[] = {
    {"press 0x52", 0x0E},       /* up arrow */
    {"press 0x1A", 0x0E},       /* W */
    {"press 0x60", 0x0E},       /* keypad 8 */
    {"press 0x51", 0x0D},       /* down arrow */
    {"press 0x16", 0x0D},       /* S */
    {"press 0x5A", 0x0D},       /* keypad 2 */
    {"press 0x50", 0x0B},       /* left arrow */
    {"press 0x04", 0x0B},       /* A */
    {"press 0x5C", 0x0B},       /* keypad 4 */
    {"press 0x4F", 0x07},       /* right arrow */
    {"press 0x07", 0x07},       /* D */
    {"press 0x5E", 0x07},       /* keypad 6 */
    {"press 0x5F", 0x0A},       /* keypad 7 */
    {"press 0x61", 0x06},       /* keypad 9 */
    {"press 0x59", 0x09},       /* keypad 1 */
    {"press 0x5B", 0x05},       /* keypad 3 */
    {"press 0x52 0x50", 0x0A},  /* up and left arrows */
    {"pad 0 press up", 0x0E},   /* d-pad */
    {"pad 0 press down", 0x0D}, /* d-pad */
    {"pad 0 press left", 0x0B}, /* d-pad */
    {"pad 0 press right", 0x07},
    {"pad 0 stick 0 -128 0 0", 0x0E}, /* left stick */
    {"pad 0 stick 127 0 0 0", 0x07},
};

UTEST_F(input, stick)
{
    emu_t *emu = &utest_fixture->emu;
    ASSERT_TRUE(emu_ok(emu, "pad 0 connect western sticks"));
    ASSERT_TRUE(emu_ok(emu, "run 2"));
    ASSERT_EQ(0x0F, fort_ram(emu, STICK0));
    for (unsigned i = 0; i < sizeof(keys) / sizeof(keys[0]); i++)
    {
        ASSERT_TRUE(emu_ok(emu, "%s", keys[i].press));
        ASSERT_TRUE(emu_ok(emu, "run 2"));
        EXPECT_EQ_MSG(keys[i].stick, fort_ram(emu, STICK0), keys[i].press);
        ASSERT_TRUE(emu_ok(emu, "release 0x52 0x51 0x50 0x4F 0x1A 0x16 0x04 0x07"));
        ASSERT_TRUE(emu_ok(emu, "release 0x5F 0x60 0x61 0x5C 0x5E 0x59 0x5A 0x5B"));
        ASSERT_TRUE(emu_ok(emu, "pad 0 release up down left right"));
        ASSERT_TRUE(emu_ok(emu, "pad 0 stick 0 0 0 0"));
        ASSERT_TRUE(emu_ok(emu, "run 2"));
        EXPECT_EQ_MSG(0x0F, fort_ram(emu, STICK0), keys[i].press);
    }
}

UTEST_F(input, fire)
{
    static const char *const fire[] = {
        "press 0xE0", /* left Ctrl */
        "press 0xE4", /* right Ctrl */
        "press 0xE2", /* left Alt */
        "press 0xE6", /* right Alt */
        "press 0x1D", /* Z */
        "press 0x1B", /* X */
        "press 0x28", /* Enter */
        "press 0x58", /* keypad Enter */
        "pad 0 press a",
        "pad 0 press b",
        "pad 0 press x",
        "pad 0 press y",
    };
    emu_t *emu = &utest_fixture->emu;
    ASSERT_TRUE(emu_ok(emu, "pad 0 connect"));
    for (unsigned i = 0; i < sizeof(fire) / sizeof(fire[0]); i++)
    {
        ASSERT_TRUE(emu_ok(emu, "%s", fire[i]));
        ASSERT_TRUE(emu_ok(emu, "run 2"));
        EXPECT_EQ_MSG(0, fort_ram(emu, TRIG0), fire[i]);
        EXPECT_EQ_MSG(0, fort_ram(emu, STRIG0), fire[i]);
        ASSERT_TRUE(emu_ok(emu, "release 0xE0 0xE4 0xE2 0xE6 0x1D 0x1B 0x28 0x58"));
        ASSERT_TRUE(emu_ok(emu, "pad 0 release a b x y"));
        ASSERT_TRUE(emu_ok(emu, "run 2"));
        EXPECT_EQ_MSG(1, fort_ram(emu, TRIG0), fire[i]);
        EXPECT_EQ_MSG(1, fort_ram(emu, STRIG0), fire[i]);
    }
}

UTEST_F(input, console)
{
    /* CONSOL has a clear bit for each key held: START 1, SELECT 2,
       OPTION 4. */
    static const struct
    {
        const char *press;
        int consol;
    } console[] = {
        {"press 0x3D", 6}, /* F4 */
        {"press 0x3C", 5}, /* F3 */
        {"press 0x3B", 3}, /* F2 */
        {"pad 0 press start", 6},
        {"pad 0 press select", 5},
        {"pad 0 press l1", 3},
        {"press 0x3D 0x3B", 2},
    };
    emu_t *emu = &utest_fixture->emu;
    ASSERT_TRUE(emu_ok(emu, "pad 0 connect"));
    ASSERT_EQ(7, fort_ram(emu, CONSOL));
    for (unsigned i = 0; i < sizeof(console) / sizeof(console[0]); i++)
    {
        ASSERT_TRUE(emu_ok(emu, "%s", console[i].press));
        ASSERT_TRUE(emu_ok(emu, "run 2"));
        EXPECT_EQ_MSG(console[i].consol, fort_ram(emu, CONSOL), console[i].press);
        ASSERT_TRUE(emu_ok(emu, "release 0x3D 0x3C 0x3B"));
        ASSERT_TRUE(emu_ok(emu, "pad 0 release start select l1"));
        ASSERT_TRUE(emu_ok(emu, "run 2"));
        EXPECT_EQ_MSG(7, fort_ram(emu, CONSOL), console[i].press);
    }
}

UTEST_F(input, pause_key)
{
    /* The Atari space bar: KBCODE $21, and SKSTAT bit 2 clear while it is
       held. */
    static const char *const pause[] = {"press 0x2C", "press 0x13", "pad 0 press r1"};
    emu_t *emu = &utest_fixture->emu;
    ASSERT_TRUE(emu_ok(emu, "pad 0 connect"));
    ASSERT_EQ(0xFF, fort_ram(emu, SKSTAT));
    for (unsigned i = 0; i < sizeof(pause) / sizeof(pause[0]); i++)
    {
        ASSERT_TRUE(emu_ok(emu, "poke $%04X 0", KBCODE));
        ASSERT_TRUE(emu_ok(emu, "%s", pause[i]));
        ASSERT_TRUE(emu_ok(emu, "run 2"));
        EXPECT_EQ_MSG(0xFB, fort_ram(emu, SKSTAT), pause[i]);
        EXPECT_EQ_MSG(0x21, fort_ram(emu, KBCODE), pause[i]);
        ASSERT_TRUE(emu_ok(emu, "release 0x2C 0x13"));
        ASSERT_TRUE(emu_ok(emu, "pad 0 release r1"));
        ASSERT_TRUE(emu_ok(emu, "run 2"));
        EXPECT_EQ_MSG(0xFF, fort_ram(emu, SKSTAT), pause[i]);
    }
}
