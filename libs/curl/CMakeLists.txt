cmake_minimum_required(VERSION 3.12)
include(FetchContent)
cmake_policy(SET CMP0042 NEW)

#
# curl
#


FetchContent_Declare(curl-external
                    GIT_SHALLOW TRUE
                    GIT_REPOSITORY "https://github.com/curl/curl.git"
                    )

FetchContent_Populate(curl-external)
add_subdirectory(${curl-external_SOURCE_DIR} ${curl-external_BINARY_DIR})


