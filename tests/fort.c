#include "fort.h"
#include <string.h>

unsigned fort_sym(const char *name)
{
    char line[256], label[128];
    unsigned addr = 0, value;
    FILE *f = fopen(FORT_LBL, "r");
    if (!f)
        return 0;
    while (fgets(line, sizeof(line), f))
        if (sscanf(line, "al %x .%127s", &value, label) == 2 && !strcmp(label, name))
        {
            addr = value;
            break;
        }
    fclose(f);
    return addr;
}

unsigned fort_xram(const char *name)
{
    char line[256], label[128];
    unsigned addr = 0, value;
    FILE *f = fopen(FORT_XRAM_INC, "r");
    if (!f)
        return 0;
    while (fgets(line, sizeof(line), f))
        if (sscanf(line, " %127s = $%x", label, &value) == 2 && !strcmp(label, name))
        {
            addr = value;
            break;
        }
    fclose(f);
    return addr;
}

/* utest skips the teardown of a fixture whose setup fails, so these stop
   the emulator themselves. */
bool fort_boot_fill(emu_t *emu, const char *fill)
{
    if (emu_start(emu, FORT_ROM, fill) && emu_ok(emu, "run 30"))
        return true;
    emu_stop(emu);
    return false;
}

bool fort_boot(emu_t *emu)
{
    return fort_boot_fill(emu, "random");
}

bool fort_play(emu_t *emu)
{
    if (fort_tap(emu, KEY_LCTRL) &&
        emu_ok(emu, "wait $%02X %u 600", MODE, GO_MODE) &&
        emu_ok(emu, "wait $%02X %u 600", CHOPPER_STATUS, FLY) &&
        emu_ok(emu, "run 10"))
        return true;
    emu_stop(emu);
    return false;
}

bool fort_tap(emu_t *emu, unsigned key)
{
    return emu_ok(emu, "press 0x%02X", key) && emu_ok(emu, "run 2") &&
           emu_ok(emu, "release 0x%02X", key) && emu_ok(emu, "run 2");
}

bool fort_tap_pad(emu_t *emu, const char *button)
{
    return emu_ok(emu, "pad 0 press %s", button) && emu_ok(emu, "run 2") &&
           emu_ok(emu, "pad 0 release %s", button) && emu_ok(emu, "run 2");
}

int fort_settings(emu_t *emu)
{
    return fort_ram(emu, GRAV_SKILL) | fort_ram(emu, PILOT_SKILL) << 8 |
           fort_ram(emu, CHOPS) << 16;
}

static int byte_at(emu_t *emu, const char *space, unsigned addr)
{
    char where[16];
    uint8_t value;
    snprintf(where, sizeof(where), "%s:$%04X", space, addr);
    if (!emu_dump(emu, where, 1, &value))
        return -1;
    return value;
}

int fort_ram(emu_t *emu, unsigned addr)
{
    return byte_at(emu, "ram", addr);
}

int fort_xram_byte(emu_t *emu, unsigned addr)
{
    return byte_at(emu, "xram", addr);
}
