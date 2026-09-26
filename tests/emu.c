#include "emu.h"
#include <signal.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

bool emu_start(emu_t *emu, const char *rom)
{
    int to[2], from[2];
    memset(emu, 0, sizeof(*emu));
    if (pipe(to))
        return false;
    if (pipe(from))
    {
        close(to[0]);
        close(to[1]);
        return false;
    }
    emu->pid = fork();
    if (emu->pid == 0)
    {
        dup2(to[0], STDIN_FILENO);
        dup2(from[1], STDOUT_FILENO);
        close(to[0]);
        close(to[1]);
        close(from[0]);
        close(from[1]);
        execl(FORT_EMU, FORT_EMU, "--script", "-", "--mute",
              "--seed", "6502", rom, (char *)NULL);
        _exit(127);
    }
    close(to[0]);
    close(from[1]);
    if (emu->pid < 0)
    {
        close(to[1]);
        close(from[0]);
        return false;
    }
    emu->to = fdopen(to[1], "w");
    emu->from = fdopen(from[0], "r");
    return emu_ok(emu, "reply");
}

void emu_stop(emu_t *emu)
{
    if (emu->to)
        fclose(emu->to);
    if (emu->from)
        fclose(emu->from);
    if (emu->pid > 0)
    {
        kill(emu->pid, SIGTERM);
        waitpid(emu->pid, NULL, 0);
    }
    memset(emu, 0, sizeof(*emu));
}

static const char *emu_vcmd(emu_t *emu, const char *fmt, va_list ap)
{
    size_t len;
    if (!emu->to || !emu->from)
        return NULL;
    vfprintf(emu->to, fmt, ap);
    fputc('\n', emu->to);
    if (fflush(emu->to))
        return NULL;
    if (!fgets(emu->reply, sizeof(emu->reply), emu->from))
        return NULL;
    len = strlen(emu->reply);
    while (len && (emu->reply[len - 1] == '\n' || emu->reply[len - 1] == '\r'))
        emu->reply[--len] = 0;
    return emu->reply;
}

const char *emu_cmd(emu_t *emu, const char *fmt, ...)
{
    const char *reply;
    va_list ap;
    va_start(ap, fmt);
    reply = emu_vcmd(emu, fmt, ap);
    va_end(ap);
    return reply;
}

bool emu_ok(emu_t *emu, const char *fmt, ...)
{
    const char *reply;
    va_list ap;
    va_start(ap, fmt);
    reply = emu_vcmd(emu, fmt, ap);
    va_end(ap);
    if (!reply)
        return false;
    if (strncmp(reply, "ok", 2) || (reply[2] && reply[2] != ' '))
    {
        fprintf(stderr, "emu: %s\n", reply);
        return false;
    }
    return true;
}

bool emu_dump(emu_t *emu, const char *addr, unsigned count, uint8_t *buf)
{
    const char *p;
    char *end;
    unsigned i;
    if (!emu_ok(emu, "dump %s %u", addr, count))
        return false;
    p = emu->reply + 2;
    for (i = 0; i < count; i++)
    {
        unsigned long v = strtoul(p, &end, 16);
        if (end == p || v > 0xFF)
            return false;
        buf[i] = (uint8_t)v;
        p = end;
    }
    return true;
}
