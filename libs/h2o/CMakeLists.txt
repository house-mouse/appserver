cmake_minimum_required(VERSION 3.12)
include(FetchContent)

#
# h2o
#

FetchContent_Declare(h2o-external
                     GIT_SHALLOW TRUE
#                     GIT_REPOSITORY "https://github.com/h2o/h2o.git"
# 		     GIT_TAG 484f8345497663578a0e90ffb3586899beda25b3
                    GIT_REPOSITORY "https://github.com/house-mouse/h2o.git"
                     )

FetchContent_Populate(h2o-external)

set(ENV{OPENSSL_ROOT_DIR} ${openssl-external_BINARY_DIR})
include(h2o.cmake)

#.//build/_deps/wslay-external-build/wslay-config.cmake



message("ADDING: " ${h2o-external_SOURCE_DIR}/include)
target_include_directories(libh2o PUBLIC ${h2o-external_SOURCE_DIR}/include)
target_include_directories(libh2o PUBLIC ${openssl-external_SOURCE_DIR}/include)

set(LIBH2O_INCLUDE_DIRECTORIES ${h2o-external_SOURCE_DIR}/include PARENT_SCOPE)
set(ZLIB_LIBRARIES ${ZLIB_LIBARIES} PARENT_SCOPE)
