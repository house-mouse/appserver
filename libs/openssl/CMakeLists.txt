cmake_minimum_required(VERSION 3.12)
include(FetchContent)

#
# openssl 
#

FetchContent_Declare(openssl-external
                     GIT_SHALLOW TRUE
                     GIT_REPOSITORY "https://github.com/janbar/openssl-cmake.git"
#                     GIT_TAG 6aaf7e98886869a823e749ea4aa23d06d076e935 # OpenSSL1.1.0 rather than 1.1.1
                     )

FetchContent_Populate(openssl-external)

add_subdirectory(${openssl-external_SOURCE_DIR} ${openssl-external_BINARY_DIR})

set (OPENSSL_FOUND TRUE PARENT_SCOPE)
set (OPENSSL_INCLUDE_DIRECTORY   ${openssl-external_BINARY_DIR}/include PARENT_SCOPE) # /openssl?
set (OPENSSL_INCLUDE_DIRECTORIES ${openssl-external_BINARY_DIR}/include PARENT_SCOPE)
set (OPENSSL_INCLUDE_DIR         ${openssl-external_BINARY_DIR}/include PARENT_SCOPE) # /openssl?

# These all seem goofed up on OSX, where "Debug" is added to the binary dir. :(

if (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    set(SFX /Debug)
endif()


set (OPENSSL_LIBRARY_DIRECTORY ${openssl-external_BINARY_DIR} PARENT_SCOPE)
set (OPENSSL_LIBRARY_DIRECTORIES ${openssl-external_BINARY_DIR}/ssl${SFX}  ${openssl-external_BINARY_DIR}/crypto${SFX}  PARENT_SCOPE)
#set (OPENSSL_LIBRARIES "${openssl-external_BINARY_DIR}/crypto${SFX}/libcrypto.a ${openssl-external_BINARY_DIR}/ssl${SFX}/libssl.a" PARENT_SCOPE)
set (OPENSSL_LIBRARIES "libcrypto.a libssl.a" PARENT_SCOPE)

message("OpenSSL BIN DIR: " ${CMAKE_CURRENT_BINARY_DIR})
message("OpenSSL BIN DIR: " ${openssl-external_BINARY_DIR})
