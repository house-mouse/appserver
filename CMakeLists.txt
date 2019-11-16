cmake_minimum_required(VERSION 3.11)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake_modules
		${CMAKE_CURRENT_BINARY_DIR}/_deps/wslay-external-build/)
#.//build/_deps/wslay-external-build/wslay-config.cmake

SET(CMAKE_BUILD_TYPE "Debug" CACHE STRING "Debug type")

project(centrus)



include(common)

add_subdirectory(libs/zlib)
add_subdirectory(libs/uv)
add_subdirectory(libs/openssl)
#add_subdirectory(libs/libressl)
add_subdirectory(libs/wslay)
add_subdirectory(libs/h2o)
add_subdirectory(libs/curl)

set (LIB_UV_INCLUDE_DIRS ${LIBUV_INCLUDE_DIRECTORIES})
set (LIB_OPENSSL_INCLUDE_DIRS ${OPENSSL_INCLUDE_DIRECTORIES})
add_subdirectory(submodules/uv-ssl-client)


add_executable(centrus
    centrus.cpp

    filepath.cpp
    filepath.hpp
    logger.hpp
    webserver.cpp
    webserver.hpp
)

target_link_directories(centrus PUBLIC
	${LIBUV_LINK_DIRECTORIES})
target_link_libraries(centrus PUBLIC
        libh2o uv_a ssl crypto ${ZLIB_LIBRARIES} z)

message("zlib: " ${ZLIB_INCLUDE_DIRS})
message("libuv: " ${LIBUV_INCLUDE_DIRECTORIES})
message("h2o: " ${LIBH2O_INCLUDE_DIRECTORIES})
message("wslay: " ${WSLAY_INCLUDE_DIRS})

target_include_directories(centrus PUBLIC
        ${LIBUV_INCLUDE_DIRECTORIES} ${OPENSSL_INCLUDE_DIRECTORIES} ${LIBH2O_INCLUDE_DIRECTORIES} ${LIBUV_INCLUDE_DIRS})

add_custom_command(TARGET centrus PRE_BUILD
                   COMMAND ${CMAKE_COMMAND} -E copy_directory
                   ${CMAKE_CURRENT_BINARY_DIR}/_deps/h2o-external-src/examples $<TARGET_FILE_DIR:centrus>)


