cmake_minimum_required(VERSION 3.21)

include(${CMAKE_CURRENT_LIST_DIR}/tools/rp6502.cmake)

project(FORT-APOCALYPSE C ASM)

add_executable(fort)
rp6502_asset(fort help src/help.txt)
rp6502_executable(fort DATA 0x9200 RESET 0x9200)
target_link_options(fort PRIVATE -C ${CMAKE_CURRENT_SOURCE_DIR}/src/fort.cfg)
target_sources(fort PRIVATE
    src/fort.s
    src/os.s
)
