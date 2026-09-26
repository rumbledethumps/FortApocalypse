#include "utest.h"
#include <signal.h>

UTEST_STATE();

int main(int argc, const char *const argv[])
{
    /* A failed check ends the emulator, and a later write to its pipe
       must fail the test rather than kill the process. */
    signal(SIGPIPE, SIG_IGN);
    return utest_main(argc, argv);
}
