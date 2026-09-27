#ifndef EMU_H
#define EMU_H

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <sys/types.h>

/* One emulator process, driven through --script on a pipe. */
typedef struct
{
    pid_t pid;
    FILE *to;
    FILE *from;
    char reply[4096];
} emu_t;

/* Start the ROM with RAM and XRAM filled as --fill gives, "random" or a
   byte. */
bool emu_start(emu_t *emu, const char *rom, const char *fill);
void emu_stop(emu_t *emu);

/* Send one script command and return its reply, or NULL once the
   emulator has exited. */
const char *emu_cmd(emu_t *emu, const char *fmt, ...);

/* Send one command and report whether it answered ok. */
bool emu_ok(emu_t *emu, const char *fmt, ...);

/* Read count bytes, where addr is "ram:$1234" or "xram:$1234". */
bool emu_dump(emu_t *emu, const char *addr, unsigned count, uint8_t *buf);

#endif
