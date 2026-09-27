cmake_minimum_required(VERSION 3.21)

project(FORT-APOCALYPSE-TESTS C)

set(FORT_ROM ${CMAKE_CURRENT_LIST_DIR}/../build/cc65/release/fort.rp6502
    CACHE FILEPATH "The ROM under test")
set(FORT_EMU ${CMAKE_CURRENT_LIST_DIR}/../tools/rp6502-emu
    CACHE FILEPATH "The emulator that runs the ROM")

# The linker writes the label file next to the ROM.
string(REGEX REPLACE "\\.rp6502$" ".lbl" FORT_LBL "${FORT_ROM}")

enable_testing()

add_executable(fort_tests)
target_sources(fort_tests PRIVATE
    main.c
    emu.c
    fort.c
    test_boot.c
    test_title.c
    test_input.c
    test_pokey.c
    test_game.c
)
target_compile_definitions(fort_tests PRIVATE
    FORT_ROM="${FORT_ROM}"
    FORT_LBL="${FORT_LBL}"
    FORT_XRAM_INC="${CMAKE_CURRENT_LIST_DIR}/../src/xram.inc"
    FORT_EMU="${FORT_EMU}"
)
if(CMAKE_C_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(fort_tests PRIVATE -Wall)
endif()

add_test(NAME fort_tests COMMAND fort_tests)
