cmake_minimum_required(VERSION 3.21)

project(FORT-APOCALYPSE-TESTS C)

set(FORT_ROM ${CMAKE_CURRENT_LIST_DIR}/../build/cc65/release/fort.rp6502
    CACHE FILEPATH "The ROM under test")
set(FORT_EMU ${CMAKE_CURRENT_LIST_DIR}/../tools/rp6502-emu
    CACHE FILEPATH "The emulator that runs the ROM")

enable_testing()

add_executable(fort_tests)
target_sources(fort_tests PRIVATE
    main.c
    emu.c
    test_boot.c
)
target_compile_definitions(fort_tests PRIVATE
    FORT_ROM="${FORT_ROM}"
    FORT_EMU="${FORT_EMU}"
)
if(CMAKE_C_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(fort_tests PRIVATE -Wall)
endif()

add_test(NAME fort_tests COMMAND fort_tests)
