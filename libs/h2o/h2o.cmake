# Copyright (c) 2014,2015 DeNA Co., Ltd., Kazuho Oku, Brian Stanback, Laurentiu Nicola, Masanori Ogino, Ryosuke Matsumoto,
#                         David Carlier
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.

CMAKE_MINIMUM_REQUIRED(VERSION 2.8.11)
CMAKE_POLICY(SET CMP0003 NEW)

PROJECT(h2o)

SET(VERSION_MAJOR "2")
SET(VERSION_MINOR "3")
SET(VERSION_PATCH "0")
SET(VERSION_PRERELEASE "-DEV")
SET(VERSION "${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}${VERSION_PRERELEASE}")
SET(LIBRARY_VERSION_MAJOR "0")
SET(LIBRARY_VERSION_MINOR "14")
SET(LIBRARY_VERSION_PATCH "0")
SET(LIBRARY_VERSION "${LIBRARY_VERSION_MAJOR}.${LIBRARY_VERSION_MINOR}.${LIBRARY_VERSION_PATCH}${VERSION_PRERELEASE}")
SET(LIBRARY_SOVERSION "${LIBRARY_VERSION_MAJOR}.${LIBRARY_VERSION_MINOR}")

INCLUDE(GNUInstallDirs)
INCLUDE(CheckCSourceCompiles)
INCLUDE(CMakePushCheckState)
INCLUDE(ExternalProject)

CONFIGURE_FILE(${h2o-external_SOURCE_DIR}/version.h.in ${CMAKE_CURRENT_SOURCE_DIR}/include/h2o/version.h)
CONFIGURE_FILE(${h2o-external_SOURCE_DIR}/libh2o.pc.in ${CMAKE_CURRENT_BINARY_DIR}/libh2o.pc @ONLY)
#CONFIGURE_FILE(${h2o-external_SOURCE_DIR}/libh2o-evloop.pc.in ${CMAKE_CURRENT_BINARY_DIR}/libh2o-evloop.pc @ONLY)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${h2o-external_SOURCE_DIR}/cmake)

FIND_PACKAGE(PkgConfig)
FIND_PACKAGE(Threads REQUIRED)

#IF ((CMAKE_SYSTEM_NAME STREQUAL "Darwin") AND NOT (DEFINED OPENSSL_ROOT_DIR OR DEFINED ENV{OPENSSL_ROOT_DIR}))
#    MESSAGE(STATUS "*************************************************************************\n"
#                "   * Setting OPENSSL_ROOT_DIR to /usr/local/opt/openssl. On macOS, OpenSSL *\n"
#                "   * should be installed using homebrew or OPENSSL_ROOT_DIR must be set to *\n"
#                "   * the path that has OpenSSL installed.                                  *\n"
#                "   *************************************************************************")
#    SET(OPENSSL_ROOT_DIR "/usr/local/opt/openssl")
#ENDIF ()
#FIND_PACKAGE(OpenSSL REQUIRED)
FIND_PACKAGE(ZLIB REQUIRED)

CHECK_C_SOURCE_COMPILES("
#include <stdint.h>
int main(void) {
uint64_t a;
__sync_add_and_fetch(&a, 1);
return 0;
}" ARCH_SUPPORTS_64BIT_ATOMICS)

# Find out if libc provices backtrace()
CMAKE_PUSH_CHECK_STATE()
FIND_LIBRARY(LIBC_BACKTRACE_LIB "execinfo")
IF (LIBC_BACKTRACE_LIB)
    SET(CMAKE_REQUIRED_LIBRARIES ${LIBC_BACKTRACE_LIB})
ENDIF()
CHECK_C_SOURCE_COMPILES("
#include <execinfo.h>
int main(void) {
void *p[10];
int ret = backtrace(p, 10);
backtrace_symbols_fd(p, ret, 2);
return 0;
}" LIBC_HAS_BACKTRACE)
CMAKE_POP_CHECK_STATE()

IF (LIBC_HAS_BACKTRACE)
    ADD_DEFINITIONS("-DLIBC_HAS_BACKTRACE")
    IF (LIBC_BACKTRACE_LIB)
        LIST(APPEND EXTRA_LIBS ${LIBC_BACKTRACE_LIB})
    ENDIF ()
ENDIF ()

#OPTION(WITHOUT_LIBS "skip building libs even when possible" OFF)
OPTION(BUILD_SHARED_LIBS "whether to build a shared library" OFF)

#FIND_PROGRAM(RUBY ruby)
#FIND_PROGRAM(BISON bison)
#IF (RUBY AND BISON)
#    SET(WITH_MRUBY_DEFAULT "ON")
#ELSE ()
#    SET(WITH_MRUBY_DEFAULT "OFF")
#ENDIF ()
#OPTION(WITH_MRUBY "whether or not to build with mruby support" ${WITH_MRUBY_DEFAULT})

OPTION(WITH_PICOTLS "whether or not to build with picotls" "ON")

FIND_PROGRAM(CCACHE ccache)
IF (CCACHE)
    SET(WITH_CCACHE_DEFAULT "ON")
ELSE ()
    SET(WITH_CCACHE_DEFAULT "OFF")
ENDIF()
OPTION(WITH_CCACHE "whether or not to build using ccache" ${WITH_CCACHE_DEFAULT})
IF (WITH_CCACHE)
    SET_PROPERTY(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ccache)
    SET_PROPERTY(GLOBAL PROPERTY RULE_LAUNCH_LINK ccache)
ENDIF ()


#IF (OPENSSL_VERSION VERSION_LESS "1.0.2")
#    MESSAGE(STATUS "*************************************************************************\n"
#                "   * OpenSSL 1.0.2 is required for HTTP/2 interoperability with web        *\n"
#                "   * browsers.                                                             *\n"
#                "   *************************************************************************\n")
#ENDIF (OPENSSL_VERSION VERSION_LESS "1.0.2")
#IF(OPENSSL_VERSION VERSION_EQUAL "1.1.0" AND OPENSSL_VERSION STRLESS "1.1.0g")
#    MESSAGE(STATUS "*************************************************************************\n"
#                "   * OpenSSL 1.1.0 ~ 1.1.0f would cause session resumption failed when     *\n"
#                "   * using external cache.                                                 *\n"
#                "   *************************************************************************\n")
#ENDIF(OPENSSL_VERSION VERSION_EQUAL "1.1.0" AND OPENSSL_VERSION STRLESS "1.1.0g")


INCLUDE_DIRECTORIES(
    ${h2o-external_SOURCE_DIR}/include
    ${h2o-external_SOURCE_DIR}/deps/cloexec
    ${h2o-external_SOURCE_DIR}/deps/brotli/c/include
    ${h2o-external_SOURCE_DIR}/deps/golombset
    ${h2o-external_SOURCE_DIR}/deps/hiredis
    ${h2o-external_SOURCE_DIR}/deps/libgkc
    ${h2o-external_SOURCE_DIR}/deps/libyrmcds
    ${h2o-external_SOURCE_DIR}/deps/klib
    ${h2o-external_SOURCE_DIR}/deps/neverbleed
    ${h2o-external_SOURCE_DIR}/deps/picohttpparser
    ${h2o-external_SOURCE_DIR}/deps/picotest
    ${h2o-external_SOURCE_DIR}/deps/yaml/include
    ${h2o-external_SOURCE_DIR}/deps/yoml)

#IF (PKG_CONFIG_FOUND)
#    PKG_CHECK_MODULES(LIBUV libuv>=1.0.0)
#    IF (LIBUV_FOUND)
        INCLUDE_DIRECTORIES(${LIBUV_INCLUDE_DIRS})
        LINK_DIRECTORIES(${LIBUV_LIBRARY_DIRS})
#    ENDIF (LIBUV_FOUND)
#ENDIF (PKG_CONFIG_FOUND)
#IF (NOT LIBUV_FOUND)
#    FIND_PACKAGE(LibUV)
#    IF (LIBUV_FOUND AND LIBUV_VERSION VERSION_LESS "1.0.0")
#        MESSAGE(STATUS "libuv found but ignored; is too old")
#        UNSET(LIBUV_FOUND)
#    ENDIF ()
#    IF (LIBUV_FOUND)
#        INCLUDE_DIRECTORIES(${LIBUV_INCLUDE_DIR})
#    ENDIF (LIBUV_FOUND)
#ENDIF (NOT LIBUV_FOUND)
#IF (NOT LIBUV_FOUND)
    SET(LIBUV_LIBRARIES uv)
#ENDIF (NOT LIBUV_FOUND)
#IF (DISABLE_LIBUV)
#    MESSAGE(STATUS "ignoring found libuv because of DISABLE_LIBUV")
#    SET(LIBUV_FOUND FALSE)
#ENDIF(DISABLE_LIBUV)

#IF (PKG_CONFIG_FOUND)
#    PKG_CHECK_MODULES(WSLAY libwslay)
#    IF (WSLAY_FOUND)
#        INCLUDE_DIRECTORIES(${WSLAY_INCLUDE_DIRS})
#        LINK_DIRECTORIES(${WSLAY_LIBRARY_DIRS})
#    ENDIF (WSLAY_FOUND)
#ENDIF (PKG_CONFIG_FOUND)
#IF (NOT WSLAY_FOUND)
#    FIND_PACKAGE(Wslay)
#    IF (WSLAY_FOUND)
#        INCLUDE_DIRECTORIES(${WSLAY_INCLUDE_DIR})
#    ENDIF (WSLAY_FOUND)
#ENDIF (NOT WSLAY_FOUND)
#IF (NOT WSLAY_FOUND)
    SET(WSLAY_LIBRARIES wslay)
#ENDIF (NOT WSLAY_FOUND)

IF (ZLIB_FOUND)
    INCLUDE_DIRECTORIES(${ZLIB_INCLUDE_DIRS})
    LINK_DIRECTORIES(${ZLIB_LIBRARY_DIRS})
ENDIF (ZLIB_FOUND)

SET(CC_WARNING_FLAGS "-Wall -Wno-unused-value -Wno-unused-function")
IF ("${CMAKE_C_COMPILER_ID}" STREQUAL "GNU")
    IF (NOT ("${CMAKE_C_COMPILER_VERSION}" VERSION_LESS "4.6"))
        SET(CC_WARNING_FLAGS "${CC_WARNING_FLAGS} -Wno-unused-but-set-variable")
    ENDIF ()
    IF (NOT ("${CMAKE_C_COMPILER_VERSION}" VERSION_LESS "4.5"))
        SET(CC_WARNING_FLAGS "${CC_WARNING_FLAGS} -Wno-unused-result")
    ENDIF ()
ENDIF ()

SET(CMAKE_C_FLAGS "-g ${CC_WARNING_FLAGS} ${CMAKE_C_FLAGS} -DH2O_ROOT=\"${CMAKE_INSTALL_PREFIX}\" -DH2O_CONFIG_PATH=\"${CMAKE_INSTALL_SYSCONFDIR}/h2o.conf\"")

# CMake defaults to a Debug build, whereas H2O defaults to an optimied build
IF(NOT CMAKE_BUILD_TYPE)
    SET(CMAKE_BUILD_TYPE Release)
ENDIF(NOT CMAKE_BUILD_TYPE)
SET(CMAKE_C_FLAGS_DEBUG  "-O0")
SET(CMAKE_C_FLAGS_RELEASE  "-O2")

SET(LIBYAML_SOURCE_FILES
    ${h2o-external_SOURCE_DIR}/deps/yaml/src/api.c
    ${h2o-external_SOURCE_DIR}/deps/yaml/src/dumper.c
    ${h2o-external_SOURCE_DIR}/deps/yaml/src/emitter.c
    ${h2o-external_SOURCE_DIR}/deps/yaml/src/loader.c
    ${h2o-external_SOURCE_DIR}/deps/yaml/src/parser.c
    ${h2o-external_SOURCE_DIR}/deps/yaml/src/reader.c
    ${h2o-external_SOURCE_DIR}/deps/yaml/src/scanner.c
    ${h2o-external_SOURCE_DIR}/deps/yaml/src/writer.c)

SET(BROTLI_SOURCE_FILES
    ${h2o-external_SOURCE_DIR}/deps/brotli/c/common/dictionary.c
    ${h2o-external_SOURCE_DIR}/deps/brotli/c/enc/backward_references.c
    ${h2o-external_SOURCE_DIR}/deps/brotli/c/enc/backward_references_hq.c
    ${h2o-external_SOURCE_DIR}/deps/brotli/c/enc/bit_cost.c
    ${h2o-external_SOURCE_DIR}/deps/brotli/c/enc/block_splitter.c
    ${h2o-external_SOURCE_DIR}/deps/brotli/c/enc/brotli_bit_stream.c
    ${h2o-external_SOURCE_DIR}/deps/brotli/c/enc/cluster.c
    ${h2o-external_SOURCE_DIR}/deps/brotli/c/enc/compress_fragment.c
    ${h2o-external_SOURCE_DIR}/deps/brotli/c/enc/compress_fragment_two_pass.c
    ${h2o-external_SOURCE_DIR}/deps/brotli/c/enc/dictionary_hash.c
    ${h2o-external_SOURCE_DIR}/deps/brotli/c/enc/encode.c
    ${h2o-external_SOURCE_DIR}/deps/brotli/c/enc/entropy_encode.c
    ${h2o-external_SOURCE_DIR}/deps/brotli/c/enc/histogram.c
    ${h2o-external_SOURCE_DIR}/deps/brotli/c/enc/literal_cost.c
    ${h2o-external_SOURCE_DIR}/deps/brotli/c/enc/memory.c
    ${h2o-external_SOURCE_DIR}/deps/brotli/c/enc/metablock.c
    ${h2o-external_SOURCE_DIR}/deps/brotli/c/enc/static_dict.c
    ${h2o-external_SOURCE_DIR}/deps/brotli/c/enc/utf8_util.c
    ${h2o-external_SOURCE_DIR}/lib/handler/compress/brotli.c)

SET(PICOTLS_INCLUDE_DIRECTORIES
    ${h2o-external_SOURCE_DIR}/deps/picotls/deps/cifra/src/ext
    ${h2o-external_SOURCE_DIR}/deps/picotls/deps/cifra/src
    ${h2o-external_SOURCE_DIR}/deps/picotls/deps/micro-ecc
    ${h2o-external_SOURCE_DIR}/deps/picotls/include)

SET(PICOTLS_SOURCE_FILES
    ${h2o-external_SOURCE_DIR}/deps/picotls/deps/micro-ecc/uECC.c
    ${h2o-external_SOURCE_DIR}/deps/picotls/deps/cifra/src/aes.c
    ${h2o-external_SOURCE_DIR}/deps/picotls/deps/cifra/src/blockwise.c
    ${h2o-external_SOURCE_DIR}/deps/picotls/deps/cifra/src/chacha20.c
    ${h2o-external_SOURCE_DIR}/deps/picotls/deps/cifra/src/chash.c
    ${h2o-external_SOURCE_DIR}/deps/picotls/deps/cifra/src/curve25519.c
    ${h2o-external_SOURCE_DIR}/deps/picotls/deps/cifra/src/drbg.c
    ${h2o-external_SOURCE_DIR}/deps/picotls/deps/cifra/src/hmac.c
    ${h2o-external_SOURCE_DIR}/deps/picotls/deps/cifra/src/gcm.c
    ${h2o-external_SOURCE_DIR}/deps/picotls/deps/cifra/src/gf128.c
    ${h2o-external_SOURCE_DIR}/deps/picotls/deps/cifra/src/modes.c
    ${h2o-external_SOURCE_DIR}/deps/picotls/deps/cifra/src/poly1305.c
    ${h2o-external_SOURCE_DIR}/deps/picotls/deps/cifra/src/sha256.c
    ${h2o-external_SOURCE_DIR}/deps/picotls/deps/cifra/src/sha512.c
    ${h2o-external_SOURCE_DIR}/deps/picotls/lib/picotls.c
    ${h2o-external_SOURCE_DIR}/deps/picotls/lib/cifra.c
    ${h2o-external_SOURCE_DIR}/deps/picotls/lib/uecc.c
    ${h2o-external_SOURCE_DIR}/deps/picotls/lib/openssl.c)

SET(LIB_SOURCE_FILES
    ${h2o-external_SOURCE_DIR}/deps/cloexec/cloexec.c
    ${h2o-external_SOURCE_DIR}/deps/hiredis/async.c
    ${h2o-external_SOURCE_DIR}/deps/hiredis/hiredis.c
    ${h2o-external_SOURCE_DIR}/deps/hiredis/net.c
    ${h2o-external_SOURCE_DIR}/deps/hiredis/read.c
    ${h2o-external_SOURCE_DIR}/deps/hiredis/sds.c
    ${h2o-external_SOURCE_DIR}/deps/libgkc/gkc.c
    ${h2o-external_SOURCE_DIR}/deps/libyrmcds/close.c
    ${h2o-external_SOURCE_DIR}/deps/libyrmcds/connect.c
    ${h2o-external_SOURCE_DIR}/deps/libyrmcds/recv.c
    ${h2o-external_SOURCE_DIR}/deps/libyrmcds/send.c
    ${h2o-external_SOURCE_DIR}/deps/libyrmcds/send_text.c
    ${h2o-external_SOURCE_DIR}/deps/libyrmcds/socket.c
    ${h2o-external_SOURCE_DIR}/deps/libyrmcds/strerror.c
    ${h2o-external_SOURCE_DIR}/deps/libyrmcds/text_mode.c
    ${h2o-external_SOURCE_DIR}/deps/picohttpparser/picohttpparser.c

    ${h2o-external_SOURCE_DIR}/lib/common/cache.c
    ${h2o-external_SOURCE_DIR}/lib/common/file.c
    ${h2o-external_SOURCE_DIR}/lib/common/filecache.c
    ${h2o-external_SOURCE_DIR}/lib/common/hostinfo.c
    ${h2o-external_SOURCE_DIR}/lib/common/http1client.c
    ${h2o-external_SOURCE_DIR}/lib/common/http2client.c
    ${h2o-external_SOURCE_DIR}/lib/common/httpclient.c
    ${h2o-external_SOURCE_DIR}/lib/common/memcached.c
    ${h2o-external_SOURCE_DIR}/lib/common/memory.c
    ${h2o-external_SOURCE_DIR}/lib/common/multithread.c
    ${h2o-external_SOURCE_DIR}/lib/common/redis.c
    ${h2o-external_SOURCE_DIR}/lib/common/serverutil.c
    ${h2o-external_SOURCE_DIR}/lib/common/socket.c
    ${h2o-external_SOURCE_DIR}/lib/common/socketpool.c
    ${h2o-external_SOURCE_DIR}/lib/common/string.c
    ${h2o-external_SOURCE_DIR}/lib/common/time.c
    ${h2o-external_SOURCE_DIR}/lib/common/timerwheel.c
    ${h2o-external_SOURCE_DIR}/lib/common/token.c
    ${h2o-external_SOURCE_DIR}/lib/common/url.c
    ${h2o-external_SOURCE_DIR}/lib/common/balancer/roundrobin.c
    ${h2o-external_SOURCE_DIR}/lib/common/balancer/least_conn.c

    ${h2o-external_SOURCE_DIR}/lib/core/config.c
    ${h2o-external_SOURCE_DIR}/lib/core/configurator.c
    ${h2o-external_SOURCE_DIR}/lib/core/context.c
    ${h2o-external_SOURCE_DIR}/lib/core/headers.c
    ${h2o-external_SOURCE_DIR}/lib/core/logconf.c
    ${h2o-external_SOURCE_DIR}/lib/core/proxy.c
    ${h2o-external_SOURCE_DIR}/lib/core/request.c
    ${h2o-external_SOURCE_DIR}/lib/core/util.c

    ${h2o-external_SOURCE_DIR}/lib/handler/access_log.c
    ${h2o-external_SOURCE_DIR}/lib/handler/compress.c
    ${h2o-external_SOURCE_DIR}/lib/handler/compress/gzip.c
    ${h2o-external_SOURCE_DIR}/lib/handler/errordoc.c
    ${h2o-external_SOURCE_DIR}/lib/handler/expires.c
    ${h2o-external_SOURCE_DIR}/lib/handler/fastcgi.c
    ${h2o-external_SOURCE_DIR}/lib/handler/file.c
    ${h2o-external_SOURCE_DIR}/lib/handler/headers.c
    ${h2o-external_SOURCE_DIR}/lib/handler/mimemap.c
    ${h2o-external_SOURCE_DIR}/lib/handler/proxy.c
    ${h2o-external_SOURCE_DIR}/lib/handler/redirect.c
    ${h2o-external_SOURCE_DIR}/lib/handler/reproxy.c
    ${h2o-external_SOURCE_DIR}/lib/handler/throttle_resp.c
    ${h2o-external_SOURCE_DIR}/lib/handler/server_timing.c
    ${h2o-external_SOURCE_DIR}/lib/handler/status.c
    ${h2o-external_SOURCE_DIR}/lib/handler/headers_util.c
    ${h2o-external_SOURCE_DIR}/lib/handler/status/events.c
    ${h2o-external_SOURCE_DIR}/lib/handler/status/requests.c
    ${h2o-external_SOURCE_DIR}/lib/handler/status/ssl.c
    ${h2o-external_SOURCE_DIR}/lib/handler/http2_debug_state.c
    ${h2o-external_SOURCE_DIR}/lib/handler/status/durations.c
    ${h2o-external_SOURCE_DIR}/lib/handler/configurator/access_log.c
    ${h2o-external_SOURCE_DIR}/lib/handler/configurator/compress.c
    ${h2o-external_SOURCE_DIR}/lib/handler/configurator/errordoc.c
    ${h2o-external_SOURCE_DIR}/lib/handler/configurator/expires.c
    ${h2o-external_SOURCE_DIR}/lib/handler/configurator/fastcgi.c
    ${h2o-external_SOURCE_DIR}/lib/handler/configurator/file.c
    ${h2o-external_SOURCE_DIR}/lib/handler/configurator/headers.c
    ${h2o-external_SOURCE_DIR}/lib/handler/configurator/proxy.c
    ${h2o-external_SOURCE_DIR}/lib/handler/configurator/redirect.c
    ${h2o-external_SOURCE_DIR}/lib/handler/configurator/reproxy.c
    ${h2o-external_SOURCE_DIR}/lib/handler/configurator/throttle_resp.c
    ${h2o-external_SOURCE_DIR}/lib/handler/configurator/server_timing.c
    ${h2o-external_SOURCE_DIR}/lib/handler/configurator/status.c
    ${h2o-external_SOURCE_DIR}/lib/handler/configurator/http2_debug_state.c
    ${h2o-external_SOURCE_DIR}/lib/handler/configurator/headers_util.c

    ${h2o-external_SOURCE_DIR}/lib/http1.c

    ${h2o-external_SOURCE_DIR}/lib/tunnel.c

    ${h2o-external_SOURCE_DIR}/lib/http2/cache_digests.c
    ${h2o-external_SOURCE_DIR}/lib/http2/casper.c
    ${h2o-external_SOURCE_DIR}/lib/http2/connection.c
    ${h2o-external_SOURCE_DIR}/lib/http2/frame.c
    ${h2o-external_SOURCE_DIR}/lib/http2/hpack.c
    ${h2o-external_SOURCE_DIR}/lib/http2/scheduler.c
    ${h2o-external_SOURCE_DIR}/lib/http2/stream.c
    ${h2o-external_SOURCE_DIR}/lib/http2/http2_debug_state.c)

SET(UNIT_TEST_SOURCE_FILES
    ${LIB_SOURCE_FILES}
    ${LIBYAML_SOURCE_FILES}
    ${BROTLI_SOURCE_FILES}
    ${h2o-external_SOURCE_DIR}/deps/picotest/picotest.c
    ${h2o-external_SOURCE_DIR}/t/00unit/test.c
    ${h2o-external_SOURCE_DIR}/t/00unit/lib/common/balancer/least_conn.c
    ${h2o-external_SOURCE_DIR}/t/00unit/lib/common/balancer/roundrobin.c
    ${h2o-external_SOURCE_DIR}/t/00unit/lib/common/cache.c
    ${h2o-external_SOURCE_DIR}/t/00unit/lib/common/hostinfo.c
    ${h2o-external_SOURCE_DIR}/t/00unit/lib/common/httpclient.c
    ${h2o-external_SOURCE_DIR}/t/00unit/lib/common/multithread.c
    ${h2o-external_SOURCE_DIR}/t/00unit/lib/common/serverutil.c
    ${h2o-external_SOURCE_DIR}/t/00unit/lib/common/socket.c
    ${h2o-external_SOURCE_DIR}/t/00unit/lib/common/string.c
    ${h2o-external_SOURCE_DIR}/t/00unit/lib/common/time.c
    ${h2o-external_SOURCE_DIR}/t/00unit/lib/common/url.c
    ${h2o-external_SOURCE_DIR}/t/00unit/lib/common/timerwheel.c
    ${h2o-external_SOURCE_DIR}/t/00unit/lib/core/headers.c
    ${h2o-external_SOURCE_DIR}/t/00unit/lib/core/proxy.c
    ${h2o-external_SOURCE_DIR}/t/00unit/lib/core/util.c
    ${h2o-external_SOURCE_DIR}/t/00unit/lib/handler/compress.c
    ${h2o-external_SOURCE_DIR}/t/00unit/lib/handler/fastcgi.c
    ${h2o-external_SOURCE_DIR}/t/00unit/lib/handler/file.c
    ${h2o-external_SOURCE_DIR}/t/00unit/lib/handler/headers.c
    ${h2o-external_SOURCE_DIR}/t/00unit/lib/handler/mimemap.c
    ${h2o-external_SOURCE_DIR}/t/00unit/lib/handler/redirect.c
    ${h2o-external_SOURCE_DIR}/t/00unit/lib/http2/cache_digests.c
    ${h2o-external_SOURCE_DIR}/t/00unit/lib/http2/casper.c
    ${h2o-external_SOURCE_DIR}/t/00unit/lib/http2/hpack.c
    ${h2o-external_SOURCE_DIR}/t/00unit/lib/http2/scheduler.c
    ${h2o-external_SOURCE_DIR}/t/00unit/src/ssl.c
    ${h2o-external_SOURCE_DIR}/t/00unit/issues/293.c
    ${h2o-external_SOURCE_DIR}/t/00unit/issues/percent-encode-zero-byte.c)

LIST(REMOVE_ITEM UNIT_TEST_SOURCE_FILES
    ${h2o-external_SOURCE_DIR}/lib/common/balancer/least_conn.c
    ${h2o-external_SOURCE_DIR}/lib/common/balancer/roundrobin.c
    ${h2o-external_SOURCE_DIR}/lib/common/cache.c
    ${h2o-external_SOURCE_DIR}/lib/common/hostinfo.c
    ${h2o-external_SOURCE_DIR}/lib/common/httpclient.c
    ${h2o-external_SOURCE_DIR}/lib/common/multithread.c
    ${h2o-external_SOURCE_DIR}/lib/common/serverutil.c
    ${h2o-external_SOURCE_DIR}/lib/common/socket.c
    ${h2o-external_SOURCE_DIR}/lib/common/string.c
    ${h2o-external_SOURCE_DIR}/lib/common/time.c
    ${h2o-external_SOURCE_DIR}/lib/common/timerwheel.c
    ${h2o-external_SOURCE_DIR}/lib/common/url.c
    ${h2o-external_SOURCE_DIR}/lib/core/headers.c
    ${h2o-external_SOURCE_DIR}/lib/core/proxy.c
    ${h2o-external_SOURCE_DIR}/lib/core/util.c
    ${h2o-external_SOURCE_DIR}/lib/handler/compress.c
    ${h2o-external_SOURCE_DIR}/lib/handler/compress/gzip.c
    ${h2o-external_SOURCE_DIR}/lib/handler/fastcgi.c
    ${h2o-external_SOURCE_DIR}/lib/handler/file.c
    ${h2o-external_SOURCE_DIR}/lib/handler/headers.c
    ${h2o-external_SOURCE_DIR}/lib/handler/mimemap.c
    ${h2o-external_SOURCE_DIR}/lib/handler/redirect.c
    ${h2o-external_SOURCE_DIR}/lib/http2/cache_digests.c
    ${h2o-external_SOURCE_DIR}/lib/http2/casper.c
    ${h2o-external_SOURCE_DIR}/lib/http2/hpack.c
    ${h2o-external_SOURCE_DIR}/lib/http2/scheduler.c)

SET(FUZZED_SOURCE_FILES
    ${LIB_SOURCE_FILES}
    ${LIBYAML_SOURCE_FILES}
    ${BROTLI_SOURCE_FILES})

SET(EXTRA_LIBS ${EXTRA_LIBS} m ${CMAKE_THREAD_LIBS_INIT})

IF (ZLIB_FOUND)
    LIST(INSERT EXTRA_LIBS 0 ${ZLIB_LIBRARIES})
ENDIF (ZLIB_FOUND)

IF (WSLAY_FOUND)
    ADD_LIBRARY(libh2o ${h2o-external_SOURCE_DIR}/lib/websocket.c ${LIB_SOURCE_FILES})
#    ADD_LIBRARY(libh2o-evloop ${h2o-external_SOURCE_DIR}/lib/websocket.c ${LIB_SOURCE_FILES})
ELSE ()
    ADD_LIBRARY(libh2o ${LIB_SOURCE_FILES})
#    ADD_LIBRARY(libh2o-evloop ${LIB_SOURCE_FILES})
ENDIF (WSLAY_FOUND)

#TARGET_LINK_LIBRARIES(libh2o ${LIBUV_LIBRARIES} ${EXTRA_LIBS} ssl crypto)
SET_TARGET_PROPERTIES(libh2o PROPERTIES
    OUTPUT_NAME h2o
    VERSION ${LIBRARY_VERSION}
    SOVERSION ${LIBRARY_SOVERSION})
#SET_TARGET_PROPERTIES(libh2o-evloop PROPERTIES
#    OUTPUT_NAME h2o-evloop
#    COMPILE_FLAGS "-DH2O_USE_LIBUV=0"
#    VERSION ${LIBRARY_VERSION}
#    SOVERSION ${LIBRARY_SOVERSION})
#TARGET_LINK_LIBRARIES(libh2o-evloop ${EXTRA_LIBS})

TARGET_INCLUDE_DIRECTORIES(libh2o PUBLIC ${OPENSSL_INCLUDE_DIR})
#TARGET_INCLUDE_DIRECTORIES(libh2o-evloop PUBLIC ${OPENSSL_INCLUDE_DIR})

message("OPENSSL_LIBRARIES: " ${OPENSSL_LIBRARIES})
#TARGET_LINK_LIBRARIES(libh2o PUBLIC ${OPENSSL_LIBRARIES} ${CMAKE_DL_LIBS})
#TARGET_LINK_LIBRARIES(libh2o-evloop ${OPENSSL_LIBRARIES} ${CMAKE_DL_LIBS})
IF (LIBUV_FOUND AND NOT WITHOUT_LIBS)
    INSTALL(TARGETS libh2o DESTINATION ${CMAKE_INSTALL_LIBDIR})
ELSE ()
    SET_TARGET_PROPERTIES(libh2o PROPERTIES EXCLUDE_FROM_ALL 1)
ENDIF ()
#IF (NOT WITHOUT_LIBS)
#    INSTALL(TARGETS libh2o-evloop DESTINATION ${CMAKE_INSTALL_LIBDIR})
#ELSE ()
#    SET_TARGET_PROPERTIES(libh2o-evloop PROPERTIES EXCLUDE_FROM_ALL 1)
#ENDIF()

#ADD_CUSTOM_TARGET(lib-examples DEPENDS examples-http1client examples-simple examples-socket-client)
IF (WSLAY_FOUND)
    ADD_DEPENDENCIES(lib-examples examples-websocket)
ENDIF (WSLAY_FOUND)
#ADD_EXECUTABLE(examples-http1client ${h2o-external_SOURCE_DIR}/examples/libh2o/http1client.c)
ADD_EXECUTABLE(examples-socket-client ${h2o-external_SOURCE_DIR}/examples/libh2o/socket-client.c)
ADD_EXECUTABLE(examples-simple ${h2o-external_SOURCE_DIR}/examples/libh2o/simple.c)
TARGET_LINK_LIBRARIES(examples-simple ssl crypto)
ADD_EXECUTABLE(examples-websocket ${h2o-external_SOURCE_DIR}/lib/websocket.c ${h2o-external_SOURCE_DIR}/examples/libh2o/websocket.c)

#ADD_CUSTOM_TARGET(lib-examples-evloop DEPENDS examples-http1client-evloop examples-simple-evloop examples-socket-client-evloop examples-latency-optimization-evloop)
#IF (WSLAY_FOUND)
#    ADD_DEPENDENCIES(lib-examples-evloop examples-websocket-evloop)
#ENDIF (WSLAY_FOUND)
#ADD_EXECUTABLE(examples-latency-optimization-evloop ${h2o-external_SOURCE_DIR}/examples/libh2o/latency-optimization.c)
#ADD_EXECUTABLE(examples-http1client-evloop ${h2o-external_SOURCE_DIR}/examples/libh2o/http1client.c)
#ADD_EXECUTABLE(examples-socket-client-evloop ${h2o-external_SOURCE_DIR}/examples/libh2o/socket-client.c)
#ADD_EXECUTABLE(examples-simple-evloop ${h2o-external_SOURCE_DIR}/examples/libh2o/simple.c)
#ADD_EXECUTABLE(examples-websocket-evloop ${h2o-external_SOURCE_DIR}/lib/websocket.c ${h2o-external_SOURCE_DIR}/examples/libh2o/websocket.c)


#SET_TARGET_PROPERTIES(examples-http1client PROPERTIES
#    EXCLUDE_FROM_ALL 1)
#TARGET_LINK_LIBRARIES(examples-http1client libh2o ${LIBUV_LIBRARIES} ${EXTRA_LIBS})

SET_TARGET_PROPERTIES(examples-socket-client PROPERTIES
    EXCLUDE_FROM_ALL 1)
TARGET_LINK_LIBRARIES(examples-socket-client libh2o ${LIBUV_LIBRARIES} ${EXTRA_LIBS})

SET_TARGET_PROPERTIES(examples-simple PROPERTIES
    EXCLUDE_FROM_ALL 1)
TARGET_LINK_LIBRARIES(examples-simple libh2o ${LIBUV_LIBRARIES} ${EXTRA_LIBS})

SET_TARGET_PROPERTIES(examples-websocket PROPERTIES
    EXCLUDE_FROM_ALL 1)
TARGET_LINK_LIBRARIES(examples-websocket libh2o ${LIBUV_LIBRARIES} ${WSLAY_LIBRARIES} ${EXTRA_LIBS})

#SET_TARGET_PROPERTIES(examples-latency-optimization-evloop PROPERTIES
#    COMPILE_FLAGS "-DH2O_USE_LIBUV=0"
#    EXCLUDE_FROM_ALL 1)
#TARGET_LINK_LIBRARIES(examples-latency-optimization-evloop libh2o-evloop ${EXTRA_LIBS})

#SET_TARGET_PROPERTIES(examples-http1client-evloop PROPERTIES
#    COMPILE_FLAGS "-DH2O_USE_LIBUV=0"
#    EXCLUDE_FROM_ALL 1)
#TARGET_LINK_LIBRARIES(examples-http1client-evloop libh2o-evloop ${EXTRA_LIBS})

#SET_TARGET_PROPERTIES(examples-socket-client-evloop PROPERTIES
#    COMPILE_FLAGS "-DH2O_USE_LIBUV=0"
#    EXCLUDE_FROM_ALL 1)
#TARGET_LINK_LIBRARIES(examples-socket-client-evloop libh2o-evloop ${EXTRA_LIBS})

#SET_TARGET_PROPERTIES(examples-simple-evloop PROPERTIES
#    COMPILE_FLAGS "-DH2O_USE_LIBUV=0"
#    EXCLUDE_FROM_ALL 1)
#TARGET_LINK_LIBRARIES(examples-simple-evloop libh2o-evloop  ${EXTRA_LIBS})

#SET_TARGET_PROPERTIES(examples-websocket-evloop PROPERTIES
#    COMPILE_FLAGS "-DH2O_USE_LIBUV=0"
#    EXCLUDE_FROM_ALL 1)
#TARGET_LINK_LIBRARIES(examples-websocket-evloop libh2o-evloop ${WSLAY_LIBRARIES} ${EXTRA_LIBS})


# standalone server directly links to libh2o using evloop
#SET(STANDALONE_SOURCE_FILES
#    ${LIB_SOURCE_FILES}
#    ${LIBYAML_SOURCE_FILES}
#    ${BROTLI_SOURCE_FILES}
#    ${h2o-external_SOURCE_DIR}/deps/neverbleed/neverbleed.c
#    ${h2o-external_SOURCE_DIR}/src/main.c
#    ${h2o-external_SOURCE_DIR}/src/ssl.c)
#SET(STANDALONE_COMPILE_FLAGS "-DH2O_USE_LIBUV=0 -DH2O_USE_BROTLI=1")
#IF (WITH_MRUBY)
#    IF (${CMAKE_C_COMPILER_ID} STREQUAL "Clang")
#        SET(MRUBY_TOOLCHAIN "clang")
#    ELSE ()
#        SET(MRUBY_TOOLCHAIN "gcc")
#    ENDIF ()
#    ADD_CUSTOM_TARGET(mruby MRUBY_TOOLCHAIN=${MRUBY_TOOLCHAIN} MRUBY_CONFIG=${h2o-external_SOURCE_DIR}/misc/mruby_config.rb MRUBY_BUILD_DIR=${CMAKE_CURRENT_BINARY_DIR}/mruby MRUBY_ADDITIONAL_CONFIG=${MRUBY_ADDITIONAL_CONFIG} ruby minirake
#        WORKING_DIRECTORY ${h2o-external_SOURCE_DIR}/deps/mruby)
#    LIST(APPEND STANDALONE_SOURCE_FILES
#        ${h2o-external_SOURCE_DIR}/lib/handler/mruby.c
#        ${h2o-external_SOURCE_DIR}/lib/handler/mruby/sender.c
#        ${h2o-external_SOURCE_DIR}/lib/handler/mruby/http_request.c
#        ${h2o-external_SOURCE_DIR}/lib/handler/mruby/redis.c
#        ${h2o-external_SOURCE_DIR}/lib/handler/mruby/sleep.c
#        ${h2o-external_SOURCE_DIR}/lib/handler/mruby/middleware.c
#        ${h2o-external_SOURCE_DIR}/lib/handler/mruby/channel.c
#        ${h2o-external_SOURCE_DIR}/lib/handler/configurator/mruby.c)
#    SET(STANDALONE_COMPILE_FLAGS "${STANDALONE_COMPILE_FLAGS} -DH2O_USE_MRUBY=1")
#ENDIF (WITH_MRUBY)
IF (WITH_PICOTLS)
    LIST(APPEND STANDALONE_SOURCE_FILES ${PICOTLS_SOURCE_FILES})
    SET(STANDALONE_COMPILE_FLAGS "${STANDALONE_COMPILE_FLAGS} -DH2O_USE_PICOTLS=1")
    INCLUDE_DIRECTORIES(${PICOTLS_INCLUDE_DIRECTORIES})
ENDIF ()
#ADD_EXECUTABLE(h2o ${STANDALONE_SOURCE_FILES})
#SET_TARGET_PROPERTIES(h2o PROPERTIES COMPILE_FLAGS ${STANDALONE_COMPILE_FLAGS})
#TARGET_INCLUDE_DIRECTORIES(h2o PUBLIC ${OPENSSL_INCLUDE_DIR})
#message("THIS? ${OPENSSL_LIBRARIES}")
#TARGET_LINK_LIBRARIES(h2o PUBLIC ${OPENSSL_LIBRARIES} ${CMAKE_DL_LIBS})
#TARGET_LINK_LIBRARIES(h2o PUBLIC ssl crypto )
#IF (WITH_MRUBY)
#    TARGET_INCLUDE_DIRECTORIES(h2o BEFORE PRIVATE ${h2o-external_SOURCE_DIR}/deps/mruby/include ${CMAKE_CURRENT_SOURCE_DIR}/deps/mruby-input-stream/src)
    # note: the paths need to be determined before libmruby.flags.mak is generated
#    TARGET_LINK_LIBRARIES(h2o
#        "${CMAKE_CURRENT_BINARY_DIR}/mruby/host/lib/libmruby.a"
#        "${CMAKE_CURRENT_BINARY_DIR}/mruby/host/mrbgems/mruby-onig-regexp/onigmo-6.1.2/.libs/libonigmo.a"
#        "m")
#    ADD_DEPENDENCIES(h2o mruby)
#ENDIF (WITH_MRUBY)
#TARGET_LINK_LIBRARIES(h2o PUBLIC ${EXTRA_LIBS})

#INSTALL(TARGETS h2o
#    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
#    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR})

IF (NOT WITHOUT_LIBS)
    INSTALL(DIRECTORY include/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR} FILES_MATCHING PATTERN "*.h")
    IF (LIBUV_FOUND)
        INSTALL(FILES "${CMAKE_BINARY_DIR}/libh2o.pc" DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig)
    ENDIF ()
#    INSTALL(FILES "${CMAKE_BINARY_DIR}/libh2o-evloop.pc" DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig)
ENDIF ()

INSTALL(PROGRAMS share/h2o/annotate-backtrace-symbols share/h2o/fastcgi-cgi share/h2o/fetch-ocsp-response share/h2o/kill-on-close share/h2o/setuidgid share/h2o/start_server DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/h2o)
INSTALL(FILES share/h2o/ca-bundle.crt DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/h2o)
INSTALL(FILES share/h2o/status/index.html DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/h2o/status)
INSTALL(DIRECTORY doc/ DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/doc/h2o PATTERN "Makefile" EXCLUDE PATTERN "h2o.8" EXCLUDE PATTERN "README.md" EXCLUDE)
INSTALL(FILES doc/h2o.8 DESTINATION ${CMAKE_INSTALL_MANDIR}/man8/)
INSTALL(FILES doc/h2o.conf.5 DESTINATION ${CMAKE_INSTALL_MANDIR}/man5/)
INSTALL(DIRECTORY examples/ DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/doc/h2o/examples)
IF (WITH_MRUBY)
    INSTALL(DIRECTORY share/h2o/mruby DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/h2o)
ENDIF (WITH_MRUBY)

# tests
#ADD_EXECUTABLE(t-00unit-evloop.t ${UNIT_TEST_SOURCE_FILES})
#SET_TARGET_PROPERTIES(t-00unit-evloop.t PROPERTIES
#    COMPILE_FLAGS "-DH2O_USE_LIBUV=0 -DH2O_USE_BROTLI=1 -DH2O_UNITTEST=1"
#    EXCLUDE_FROM_ALL 1)

#IF(EXISTS ${h2o-external_SOURCE_DIR}/deps/theft/Makefile)
#    ExternalProject_Add(build-theft
#                        SOURCE_DIR "${h2o-external_SOURCE_DIR}/deps/theft"
#                        BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/theft"
#                        CONFIGURE_COMMAND "true"
#                        BUILD_COMMAND cd "${h2o-external_SOURCE_DIR}/deps/theft" && make "BUILD=${CMAKE_CURRENT_BINARY_DIR}/theft"
#                        INSTALL_COMMAND "true")
#    SET_TARGET_PROPERTIES(build-theft PROPERTIES EXCLUDE_FROM_ALL TRUE)
#    LINK_DIRECTORIES("${CMAKE_CURRENT_BINARY_DIR}/theft")
#    ADD_EXECUTABLE(t-00property-testing.t ${h2o-external_SOURCE_DIR}/t/00prop/prop.c)
#    ADD_DEPENDENCIES(t-00property-testing.t build-theft)
#    TARGET_INCLUDE_DIRECTORIES(t-00property-testing.t BEFORE PUBLIC "${h2o-external_SOURCE_DIR}/deps/theft/inc")
#    TARGET_LINK_LIBRARIES(t-00property-testing.t theft libh2o-evloop ${EXTRA_LIBS})
#    SET_TARGET_PROPERTIES(t-00property-testing.t PROPERTIES EXCLUDE_FROM_ALL TRUE)
#    SET(OPTIONAL_TEST "t-00property-testing.t")
#ENDIF ()

IF (LIBUV_FOUND)
    ADD_EXECUTABLE(t-00unit-libuv.t ${UNIT_TEST_SOURCE_FILES})
    SET_TARGET_PROPERTIES(t-00unit-libuv.t PROPERTIES
        COMPILE_FLAGS "-DH2O_USE_BROTLI=1 -DH2O_UNITTEST=1"
        EXCLUDE_FROM_ALL 1)
ENDIF (LIBUV_FOUND)

#TARGET_INCLUDE_DIRECTORIES(t-00unit-evloop.t PUBLIC ${OPENSSL_INCLUDE_DIR})
#TARGET_LINK_LIBRARIES(t-00unit-evloop.t ${OPENSSL_LIBRARIES} ${EXTRA_LIBS})
IF (LIBUV_FOUND)
    TARGET_INCLUDE_DIRECTORIES(t-00unit-libuv.t PUBLIC ${OPENSSL_INCLUDE_DIR})
    TARGET_LINK_LIBRARIES(t-00unit-libuv.t ${LIBUV_LIBRARIES} ${OPENSSL_LIBRARIES} ${EXTRA_LIBS})
ENDIF (LIBUV_FOUND)

ADD_CUSTOM_TARGET(check env H2O_ROOT=. BINARY_DIR=${CMAKE_CURRENT_BINARY_DIR} prove -I. -v t/*.t
    WORKING_DIRECTORY ${h2o-external_SOURCE_DIR}
    DEPENDS h2o t-00unit-evloop.t lib-examples-evloop ${OPTIONAL_TEST})
#IF (LIBUV_FOUND)
#    ADD_DEPENDENCIES(check t-00unit-libuv.t lib-examples)
#ENDIF ()

ADD_CUSTOM_TARGET(doc make -f ../misc/doc.mk all BINARY_DIR=${CMAKE_CURRENT_BINARY_DIR}
    WORKING_DIRECTORY ${h2o-external_SOURCE_DIR}/doc
    DEPENDS h2o)
ADD_CUSTOM_TARGET(doc-clean make -f ../misc/doc.mk clean
    WORKING_DIRECTORY ${h2o-external_SOURCE_DIR}/doc)
ADD_CUSTOM_TARGET(doc-publish make -f ../misc/doc.mk publish BINARY_DIR=${CMAKE_CURRENT_BINARY_DIR}
    WORKING_DIRECTORY ${h2o-external_SOURCE_DIR}/doc
    DEPENDS h2o)

GET_FILENAME_COMPONENT(EXTERNALPROJECT_SSL_ROOT_DIR ${OPENSSL_INCLUDE_DIR} DIRECTORY)

IF (EXISTS ${h2o-external_SOURCE_DIR}/misc/h2get/CMakeLists.txt)
    ExternalProject_Add(h2get
                        CONFIGURE_COMMAND ${CMAKE_COMMAND} -DH2GET_SSL_ROOT_DIR=${EXTERNALPROJECT_SSL_ROOT_DIR} ${h2o-external_SOURCE_DIR}/misc/h2get
                        SOURCE_DIR ${h2o-external_SOURCE_DIR}/misc/h2get
                        BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/h2get_bin
                        BUILD_COMMAND make
                        INSTALL_COMMAND true)
    SET_TARGET_PROPERTIES(h2get PROPERTIES EXCLUDE_FROM_ALL TRUE)
    ADD_DEPENDENCIES(check h2get)
ENDIF ()

ExternalProject_Add(picotls-cli
                    CONFIGURE_COMMAND ${CMAKE_COMMAND} -DOPENSSL_ROOT_DIR=${EXTERNALPROJECT_SSL_ROOT_DIR} ${h2o-external_SOURCE_DIR}/deps/picotls
                    SOURCE_DIR ${h2o-external_SOURCE_DIR}/deps/picotls
                    BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/picotls
                    BUILD_COMMAND make cli
                    INSTALL_COMMAND true)
SET_TARGET_PROPERTIES(picotls-cli PROPERTIES EXCLUDE_FROM_ALL TRUE)
ADD_DEPENDENCIES(check picotls-cli)

#ADD_CUSTOM_TARGET(check-valgrind env H2O_VALGRIND=./misc/h2o_valgrind/ H2O_ROOT=. BINARY_DIR=${CMAKE_CURRENT_BINARY_DIR} prove -I. -v t/*.t
#    WORKING_DIRECTORY ${h2o-external_SOURCE_DIR}
#    DEPENDS h2o t-00unit-evloop.t)
#IF (LIBUV_FOUND)
#    ADD_DEPENDENCIES(check t-00unit-libuv.t lib-examples)
#ENDIF ()

ADD_CUSTOM_TARGET(check-as-root env H2O_ROOT=. BINARY_DIR=${CMAKE_CURRENT_BINARY_DIR} prove -I. -v t/90root-*.t
    WORKING_DIRECTORY ${h2o-external_SOURCE_DIR})

ADD_CUSTOM_TARGET(check-as-root-valgrind env H2O_VALGRIND=./misc/h2o_valgrind/ H2O_ROOT=. BINARY_DIR=${CMAKE_CURRENT_BINARY_DIR} prove -I. -v t/90root-*.t
    WORKING_DIRECTORY ${h2o-external_SOURCE_DIR})


IF (BUILD_FUZZER)
    IF(NOT CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        MESSAGE(FATAL_ERROR "The fuzzer needs clang as a compiler")
    ENDIF()
    ADD_EXECUTABLE(h2o-fuzzer-http1 ${h2o-external_SOURCE_DIR}/fuzz/driver.cc)
    ADD_EXECUTABLE(h2o-fuzzer-http2 ${h2o-external_SOURCE_DIR}/fuzz/driver.cc)
    ADD_EXECUTABLE(h2o-fuzzer-url ${h2o-external_SOURCE_DIR}/fuzz/driver_url.cc)
    SET_TARGET_PROPERTIES(h2o-fuzzer-http1 PROPERTIES COMPILE_FLAGS "-DHTTP1")
    SET_TARGET_PROPERTIES(h2o-fuzzer-http2 PROPERTIES COMPILE_FLAGS "-DHTTP2")
    SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_C_FLAGS}")
    IF (OSS_FUZZ)
        # Use https://github.com/google/oss-fuzz compatible options
        SET(LIB_FUZZER FuzzingEngine)
        SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fno-omit-frame-pointer")
        SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-omit-frame-pointer")
    ELSE ()
        EXEC_PROGRAM(${CMAKE_CXX_COMPILER} ARGS "--version 2>&1 | grep version" OUTPUT_VARIABLE _clang_version_info)
        STRING(REGEX REPLACE "^.*[ ]version[ ]([0-9]+)\\.[0-9]+.*" "\\1" CLANG_MAJOR "${_clang_version_info}")
        STRING(REGEX REPLACE "^.*[ ]version[ ][0-9]+\\.([0-9]+).*" "\\1" CLANG_MINOR "${_clang_version_info}")

        IF ("${CLANG_MAJOR}.${CLANG_MINOR}" VERSION_LESS "5.0")
            ADD_CUSTOM_TARGET(libFuzzer ${h2o-external_SOURCE_DIR}/misc/build_libFuzzer.sh WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
            ADD_DEPENDENCIES(h2o-fuzzer-http1 libFuzzer)
            ADD_DEPENDENCIES(h2o-fuzzer-http2 libFuzzer)
            ADD_DEPENDENCIES(h2o-fuzzer-url libFuzzer)

            SET(LIB_FUZZER "${CMAKE_CURRENT_BINARY_DIR}/libFuzzer.a")
            SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fno-omit-frame-pointer -fsanitize=address -fsanitize-coverage=edge,indirect-calls,8bit-counters")
            SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-omit-frame-pointer -fsanitize=address -fsanitize-coverage=edge,indirect-calls,8bit-counters")
        ELSE()
            SET(FUZZED_SOURCE_FILES "fuzz/driver.cc" "fuzz/driver_url.cc" ${FUZZED_SOURCE_FILES})
            IF (NOT CMAKE_SYSTEM_NAME STREQUAL "FreeBSD")
              SET_SOURCE_FILES_PROPERTIES(${FUZZED_SOURCE_FILES} PROPERTIES COMPILE_FLAGS "-fno-omit-frame-pointer -fsanitize=fuzzer,address -fsanitize-coverage=trace-pc-guard")
            ELSE()
              SET_SOURCE_FILES_PROPERTIES(${FUZZED_SOURCE_FILES} PROPERTIES COMPILE_FLAGS "-fno-omit-frame-pointer -fsanitize=fuzzer,address")
            ENDIF()
            SET_TARGET_PROPERTIES(h2o-fuzzer-http1 h2o-fuzzer-http2 h2o-fuzzer-url PROPERTIES LINK_FLAGS "-fsanitize=fuzzer,address")
            IF (NOT CMAKE_SYSTEM_NAME STREQUAL "FreeBSD")
              SET(CMAKE_EXE_LINKER_FLAGS "-fsanitize=address -fsanitize-coverage=trace-pc-guard")
            ELSE()
              SET(CMAKE_EXE_LINKER_FLAGS "-fsanitize=address")
            ENDIF()
        ENDIF()

    ENDIF (OSS_FUZZ)

#    TARGET_LINK_LIBRARIES(h2o-fuzzer-http1 libh2o-evloop ${EXTRA_LIBS} ${LIB_FUZZER})
#    TARGET_LINK_LIBRARIES(h2o-fuzzer-http2 libh2o-evloop ${EXTRA_LIBS} ${LIB_FUZZER})
#    TARGET_LINK_LIBRARIES(h2o-fuzzer-url libh2o-evloop ${EXTRA_LIBS} ${LIB_FUZZER})

ENDIF (BUILD_FUZZER)

IF (NOT ARCH_SUPPORTS_64BIT_ATOMICS)
    SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DH2O_NO_64BIT_ATOMICS")
ENDIF (NOT ARCH_SUPPORTS_64BIT_ATOMICS)

# environment-specific tweaks
IF (APPLE)
    SET_SOURCE_FILES_PROPERTIES(${h2o-external_SOURCE_DIR}/lib/socket.c 
				${h2o-external_SOURCE_DIR}/lib/websocket.c 
				${h2o-external_SOURCE_DIR}/src/main.c 
				${h2o-external_SOURCE_DIR}/examples/simple.c 
				${h2o-external_SOURCE_DIR}/examples/websocket.c 
				PROPERTIES COMPILE_FLAGS -Wno-deprecated-declarations)
ELSEIF (CMAKE_SYSTEM_NAME STREQUAL "Linux")
     SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -pthread -D_GNU_SOURCE")
ELSEIF ("${CMAKE_SYSTEM_NAME}" MATCHES "SunOS")
    SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -pthreads -D_POSIX_PTHREAD_SEMANTICS")
    TARGET_LINK_LIBRARIES(h2o "socket" "nsl")
#    TARGET_LINK_LIBRARIES(t-00unit-evloop.t "socket" "nsl")
    IF (LIBUV_FOUND)
        TARGET_LINK_LIBRARIES(t-00unit-libuv.t "socket" "nsl")
    ENDIF (LIBUV_FOUND)
ELSE ()
    # for FreeBSD, etc.
    SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -pthread")
ENDIF ()

# Retain CXX_FLAGS for std c++ compatiability across fuzz build/test environments
IF (NOT OSS_FUZZ)
    SET(CMAKE_CXX_FLAGS "${CMAKE_C_FLAGS}")
ENDIF (NOT OSS_FUZZ)

IF ("${VERSION_PRERELEASE}" STREQUAL "-DEV" AND EXISTS "${CMAKE_SOURCE_DIR}/.git")
    ADD_DEFINITIONS("-DH2O_HAS_GITREV_H")
    ADD_CUSTOM_TARGET(gitrev ALL
        COMMAND perl ${h2o-external_SOURCE_DIR}/misc/generate_gitrev.pl
        WORKING_DIRECTORY ${h2o-external_SOURCE_DIR})
    ADD_DEPENDENCIES(libh2o gitrev)
#    ADD_DEPENDENCIES(libh2o-evloop gitrev)
#    ADD_DEPENDENCIES(h2o gitrev)
#    ADD_DEPENDENCIES(t-00unit-evloop.t gitrev)
    IF (LIBUV_FOUND)
        ADD_DEPENDENCIES(t-00unit-libuv.t gitrev)
    ENDIF (LIBUV_FOUND)
ENDIF ()
