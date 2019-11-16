cmake_minimum_required(VERSION 3.12)
include(FetchContent)

#
# pantheios 
#

FetchContent_Declare(pantheios-external
                     GIT_SHALLOW TRUE
                     GIT_REPOSITORY "https://github.com/synesissoftware/Pantheios"
                     )

FetchContent_Populate(pantheios-external)

add_subdirectory(${pantheios-external_SOURCE_DIR} ${pantheios-external_BINARY_DIR})

