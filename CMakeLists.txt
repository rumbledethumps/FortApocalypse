cmake_minimum_required(VERSION 3.21)

include(${CMAKE_CURRENT_LIST_DIR}/tools/rp6502.cmake)

project(FORT-APOCALYPSE C ASM)

add_executable(fort)
rp6502_asset(fort help src/help.txt)
rp6502_executable(fort DATA default RESET default)
target_sources(fort PRIVATE
    src/main-cc65.s
)
