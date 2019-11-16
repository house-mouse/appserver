cmake_minimum_required(VERSION 3.12)
include(common)
include(FetchContent)

#
# zlib 
#

FetchContent_Declare(zlib-external
                     GIT_SHALLOW TRUE
                     GIT_REPOSITORY "https://github.com/madler/zlib"
                     )

FetchContent_Populate(zlib-external)

add_subdirectory(${zlib-external_SOURCE_DIR} ${zlib-external_BINARY_DIR})


SET(ZLIB_LINK_DIRECTORIES
        ${zlib-external_BINARY_DIR}
        PARENT_SCOPE)

SET(ZLIB_LIBRARY_DIRS
        ${zlib-external_BINARY_DIR}
        PARENT_SCOPE)


SET(ZLIB_INCLUDE_DIRS ${zlib-external_SOURCE_DIR}/include PARENT_SCOPE)

