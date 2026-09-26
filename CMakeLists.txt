cmake_minimum_required(VERSION 3.21)

include(${CMAKE_CURRENT_LIST_DIR}/tools/rp6502.cmake)

project(FORT-APOCALYPSE C ASM)

find_package(Python3 REQUIRED COMPONENTS Interpreter)
add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/levels.s
    COMMAND ${Python3_EXECUTABLE}
        ${CMAKE_CURRENT_SOURCE_DIR}/src/levels.py
        ${CMAKE_CURRENT_BINARY_DIR}/levels.s
        ${CMAKE_CURRENT_SOURCE_DIR}/atari/LEVEL.1N
        ${CMAKE_CURRENT_SOURCE_DIR}/atari/LEVEL.2N
        ${CMAKE_CURRENT_SOURCE_DIR}/src/navitron1.txt
        ${CMAKE_CURRENT_SOURCE_DIR}/src/navitron2.txt
    DEPENDS
        src/levels.py
        atari/LEVEL.1N
        atari/LEVEL.2N
        src/navitron1.txt
        src/navitron2.txt
    VERBATIM
)

add_executable(fort)
rp6502_asset(fort help src/help.txt)
rp6502_executable(fort DATA 0x5000 RESET 0x9200)
target_link_options(fort PRIVATE -C ${CMAKE_CURRENT_SOURCE_DIR}/src/fort.cfg)
target_sources(fort PRIVATE
    src/fort.s
    src/os.s
    src/antic.s
    src/gtia.s
    src/pokey.s
    src/input.s
    src/palette.s
    ${CMAKE_CURRENT_BINARY_DIR}/levels.s
)
