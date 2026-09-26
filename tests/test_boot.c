#include "emu.h"
#include "utest.h"
#include <string.h>

/* Fixed addresses from the Atari memory map in src/fort.s. */
#define PLAY_SCRN 0x0300
#define CHR_SET1 0x0800
#define CHR_SET2 0x0C00

struct boot
{
    emu_t emu;
};

UTEST_F_SETUP(boot)
{
    ASSERT_TRUE(emu_start(&utest_fixture->emu, FORT_ROM));
    ASSERT_TRUE(emu_ok(&utest_fixture->emu, "run 30"));
}

UTEST_F_TEARDOWN(boot)
{
    emu_stop(&utest_fixture->emu);
}

static bool dump_ram(emu_t *emu, unsigned addr, unsigned count, uint8_t *buf)
{
    char where[16];
    snprintf(where, sizeof(where), "ram:$%04X", addr);
    return emu_dump(emu, where, count, buf);
}

UTEST_F(boot, title_text)
{
    /* "FORT" as PRINT writes it at row 4, column 5: each letter is a
       left and right glyph pair with bit 7 set. */
    static const uint8_t fort[] = {0xA6, 0xC6, 0xAF, 0xCF, 0xB2, 0xD2, 0xB4, 0xD4};
    uint8_t buf[sizeof(fort)];
    ASSERT_TRUE(dump_ram(&utest_fixture->emu, PLAY_SCRN + 4 * 40 + 5, sizeof(buf), buf));
    ASSERT_EQ(0, memcmp(buf, fort, sizeof(fort)));
}

UTEST_F(boot, fonts)
{
    static const uint8_t set1_a[] = {0x00, 0x3F, 0x00, 0x00, 0xFF, 0xF0, 0xF0, 0xF0};
    static const uint8_t set2_a[] = {0x55, 0x65, 0x65, 0x99, 0x99, 0xA9, 0x99, 0x55};
    uint8_t buf[8];
    ASSERT_TRUE(dump_ram(&utest_fixture->emu, CHR_SET1 + 0x21 * 8, sizeof(buf), buf));
    ASSERT_EQ(0, memcmp(buf, set1_a, sizeof(buf)));
    ASSERT_TRUE(dump_ram(&utest_fixture->emu, CHR_SET2 + 0x21 * 8, sizeof(buf), buf));
    ASSERT_EQ(0, memcmp(buf, set2_a, sizeof(buf)));
}
