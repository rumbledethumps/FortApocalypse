#include "emu.h"
#include "utest.h"

struct boot
{
    emu_t emu;
};

UTEST_F_SETUP(boot)
{
    ASSERT_TRUE(emu_start(&utest_fixture->emu, FORT_ROM));
}

UTEST_F_TEARDOWN(boot)
{
    emu_stop(&utest_fixture->emu);
}

UTEST_F(boot, hello)
{
    emu_t *emu = &utest_fixture->emu;
    ASSERT_TRUE(emu_ok(emu, "wait \"Hello, world!\" 60"));
    ASSERT_TRUE(emu_ok(emu, "expect-exit 0 60"));
}
