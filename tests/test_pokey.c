#include "fort.h"
#include "utest.h"

/* The title screen plays on POKEY channels 1 and 2 only, so these tests
   set channels 3 and 4, which are PSG channels 2 and 3. */

#define F64K 95881    /* 3 * 63920.8 / 2 */
#define F15K 23550    /* 3 * 15699.9 / 2 */
#define F179M 2684659 /* 3 * 1789772.5 / 2 */

#define SQUARE 0x10
#define SAWTOOTH 0x20
#define NOISE 0x40

struct pokey
{
    emu_t emu;
};

UTEST_F_SETUP(pokey)
{
    /* XRAM starts as zeros, so the random bytes are the ROM's. */
    ASSERT_TRUE(fort_boot_fill(&utest_fixture->emu, "0"));
}

UTEST_F_TEARDOWN(pokey)
{
    emu_stop(&utest_fixture->emu);
}


static const struct
{
    const char *name;
    unsigned audctl, channel, audf, audc;
    unsigned freq, wave, attenuation, gate;
} cases[] = {
    {"pure tone", 0x00, 3, 0xFC, 0xAF, 0, SQUARE, 0x00, 1},
    {"volume 8", 0x00, 3, 0xFC, 0xA8, 0, SQUARE, 0x30, 1},
    {"volume 1", 0x00, 4, 0x40, 0xA1, 0, SQUARE, 0xC0, 1},
    {"15 kHz", 0x01, 3, 0xFC, 0xAF, 0, SQUARE, 0x00, 1},
    {"1.79 MHz", 0x20, 3, 0xFC, 0xAF, 0, SQUARE, 0x00, 1},
    {"1.79 MHz is channel 3 only", 0x20, 4, 0xFC, 0xAF, 0, SQUARE, 0x00, 1},
    {"highest", 0x00, 4, 0x00, 0xAF, 0, SQUARE, 0x00, 1},
    {"4-bit buzz of the highest", 0x00, 4, 0x00, 0xCF, 0, SAWTOOTH, 0x00, 1},
    {"1.79 MHz 5-bit buzz", 0x20, 3, 0x02, 0x2F, 0, SQUARE, 0x00, 1},
    {"5-bit buzz", 0x00, 3, 0x20, 0x2F, 0, SQUARE, 0x00, 1},
    {"4-bit buzz", 0x00, 3, 0x20, 0xCF, 0, SAWTOOTH, 0x00, 1},
    {"17-bit noise", 0x00, 4, 0x08, 0x8F, 0, NOISE, 0x00, 1},
    {"5 and 17-bit noise", 0x00, 4, 0x08, 0x0F, 0, NOISE, 0x00, 1},
    {"volume 0", 0x00, 3, 0xFC, 0xA0, 0, 0, 0, 0},
    {"volume only", 0x00, 4, 0xFC, 0xBF, 0, 0, 0, 0},
};

static unsigned expected_freq(unsigned i)
{
    unsigned long clock = F64K, hz3;
    unsigned m = 1;
    if (cases[i].audctl & 0x01)
        clock = F15K;
    if (cases[i].channel == 3 && cases[i].audctl & 0x20)
        clock = F179M, m = 4;
    hz3 = clock / (cases[i].audf + m);
    /* The pure tone repeats every 2 timer pulses, the buzz of the 5-bit
       and 4-bit polynomials every 31 and 15. */
    switch (cases[i].audc >> 5)
    {
    case 1:
    case 3:
        hz3 = hz3 * 2 / 31;
        break;
    case 6:
        hz3 = hz3 * 2 / 15;
        break;
    }
    return hz3 > 0xFFFF ? 0xFFFF : (unsigned)hz3;
}

UTEST_F(pokey, channels)
{
    emu_t *emu = &utest_fixture->emu;
    unsigned psg = fort_xram("XRAM_PSG");
    ASSERT_NE(0u, psg);
    for (unsigned i = 0; i < sizeof(cases) / sizeof(cases[0]); i++)
    {
        unsigned reg = AUDF1 + (cases[i].channel - 1) * 2;
        uint8_t chan[8];
        char where[16];
        ASSERT_TRUE(emu_ok(emu, "poke $%04X 0 0 0 0", AUDF1 + 4));
        ASSERT_TRUE(emu_ok(emu, "poke $%04X %u", AUDCTL, cases[i].audctl));
        ASSERT_TRUE(emu_ok(emu, "poke $%04X %u %u", reg, cases[i].audf, cases[i].audc));
        ASSERT_TRUE(emu_ok(emu, "run 2"));
        snprintf(where, sizeof(where), "xram:$%04X", psg + (cases[i].channel - 1) * 8);
        ASSERT_TRUE(emu_dump(emu, where, sizeof(chan), chan));
        EXPECT_EQ_MSG(cases[i].gate, chan[6], cases[i].name);
        if (!cases[i].gate)
            continue;
        EXPECT_EQ_MSG(expected_freq(i), (unsigned)(chan[0] | chan[1] << 8), cases[i].name);
        EXPECT_EQ_MSG(128, chan[2], cases[i].name);
        EXPECT_EQ_MSG(cases[i].attenuation, chan[3], cases[i].name);
        EXPECT_EQ_MSG(cases[i].attenuation, chan[4], cases[i].name);
        EXPECT_EQ_MSG(cases[i].wave, chan[5], cases[i].name);
    }
}

UTEST_F(pokey, random)
{
    /* RANDOM reads through RIA portal 1 from a table of random bytes. */
    emu_t *emu = &utest_fixture->emu;
    unsigned random = fort_xram("XRAM_RANDOM");
    uint8_t table[256], seen[256] = {0};
    char where[16];
    unsigned distinct = 0;
    ASSERT_NE(0u, random);
    for (unsigned page = random; page < 0x10000; page += 0x2000)
    {
        snprintf(where, sizeof(where), "xram:$%04X", page);
        ASSERT_TRUE(emu_dump(emu, where, sizeof(table), table));
        for (unsigned i = 0; i < sizeof(table); i++)
            seen[table[i]] = 1;
    }
    for (unsigned i = 0; i < sizeof(seen); i++)
        distinct += seen[i];
    EXPECT_GE(distinct, 240u);
}
