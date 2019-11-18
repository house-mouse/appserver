cmake_minimum_required(VERSION 3.12)
include(FetchContent)

#
# wslay 
#

FetchContent_Declare(wslay-external
                     GIT_SHALLOW TRUE
                     GIT_REPOSITORY "https://github.com/tatsuhiro-t/wslay"
                     )

FetchContent_Populate(wslay-external)

add_subdirectory(${wslay-external_SOURCE_DIR} ${wslay-external_BINARY_DIR})


SET(WSLAY_LINK_DIRECTORIES
        ${wslay-external_BINARY_DIR}
        PARENT_SCOPE)

SET(WSLAY_LIBRARY_DIRS
        ${wslay-external_BINARY_DIR}
        PARENT_SCOPE)

# Figure out how to get source/binary resolved here..
SET(WSLAY_INCLUDE_DIRS ${wslay-external_BINARY_DIR}/lib/includes ${wslay-external_SOURCE_DIR}/lib/includes PARENT_SCOPE)

