cmake_minimum_required(VERSION 3.12)
include(FetchContent)

#
# libressl 
#

FetchContent_Declare(libressl-external
                     GIT_SHALLOW TRUE
                     GIT_REPOSITORY "https://github.com/libressl-portable/portable"
                     )

FetchContent_Populate(libressl-external)

execute_process(COMMAND "./autogen.sh" WORKING_DIRECTORY ${libressl-external_SOURCE_DIR})

add_subdirectory(${libressl-external_SOURCE_DIR} ${libressl-external_BINARY_DIR})

set (OPENSSL_FOUND TRUE PARENT_SCOPE)
set (OPENSSL_INCLUDE_DIRECTORY   ${libressl-external_BINARY_DIR}/include PARENT_SCOPE) # /libressl?
set (OPENSSL_INCLUDE_DIRECTORIES ${libressl-external_BINARY_DIR}/include PARENT_SCOPE)
set (OPENSSL_INCLUDE_DIR         ${libressl-external_BINARY_DIR}/include PARENT_SCOPE) # /libressl?

# These all seem goofed up on OSX, where "Debug" is added to the binary dir. :(

if (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    set(SFX /Debug)
endif()


set (OPENSSL_LIBRARY_DIRECTORY ${libressl-external_BINARY_DIR} PARENT_SCOPE)
set (OPENSSL_LIBRARY_DIRECTORIES ${libressl-external_BINARY_DIR}/ssl${SFX}  ${libressl-external_BINARY_DIR}/crypto${SFX}  PARENT_SCOPE)
#set (OPENSSL_LIBRARIES "${libressl-external_BINARY_DIR}/crypto${SFX}/libcrypto.a ${libressl-external_BINARY_DIR}/ssl${SFX}/libssl.a" PARENT_SCOPE)
set (OPENSSL_LIBRARIES "libcrypto.a libssl.a" PARENT_SCOPE)

message("OpenSSL BIN DIR: " ${CMAKE_CURRENT_BINARY_DIR})
message("OpenSSL BIN DIR: " ${libressl-external_BINARY_DIR})
message("OPENSSL_LIBRARY_DIRECTORY: " ${OPENSSL_LIBRARY_DIRECTORY})
