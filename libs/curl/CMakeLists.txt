cmake_minimum_required(VERSION 3.12)
include(FetchContent)
cmake_policy(SET CMP0042 NEW)

#
# curl
#


FetchContent_Declare(curl-external
                     GIT_SHALLOW TRUE
                     GIT_REPOSITORY "https://github.com/curl/curl.git"
                     GIT_TAG 7627a2dd9d4b7417672fdec3dc6e7f8d3de379de
                     )

FetchContent_Populate(curl-external)
add_subdirectory(${curl-external_SOURCE_DIR} ${curl-external_BINARY_DIR})


