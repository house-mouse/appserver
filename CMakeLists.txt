cmake_minimum_required(VERSION 3.11)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake_modules
		${CMAKE_CURRENT_BINARY_DIR}/_deps/wslay-external-build/)
#.//build/_deps/wslay-external-build/wslay-config.cmake

SET(CMAKE_BUILD_TYPE "Debug" CACHE STRING "Debug type")

project(appserver)



include(common)

add_subdirectory(libs/zlib)
add_subdirectory(libs/uv)
add_subdirectory(libs/openssl)
#add_subdirectory(libs/libressl)
add_subdirectory(libs/wslay)
add_subdirectory(libs/h2o)
#add_subdirectory(libs/curl)

FetchContent_MakeAvailable(openssl-external wslay-external h2o-external)

set (LIB_UV_INCLUDE_DIRS ${LIBUV_INCLUDE_DIRECTORIES})
set (LIB_OPENSSL_INCLUDE_DIRS ${OPENSSL_INCLUDE_DIRECTORIES})
#add_subdirectory(submodules/uv-ssl-client)


add_library(libappserver
    appserver.cpp

    filepath.cpp
    filepath.hpp
    logger.hpp
    logger.cpp
    cputime.hpp
    cputime.cpp
    webserver.cpp
    webserver.hpp
    webserver_handler.hpp
    webserver_handler.cpp
    webserver_staticfile_handler.hpp
    webserver_staticfile_handler.cpp
    appserver_websocket.cpp
    appserver_websocket.hpp
    uvmutex.hpp
    uvmutex.cpp
    uvlogconsumer.hpp
    uvlogconsumer.cpp

    libs/readerwriterqueue/atomicops.h
    libs/readerwriterqueue/readerwriterqueue.h
)

add_executable(appserver_demo
    webserver_demo.cpp
    webserver_demo.hpp
)
target_link_libraries(appserver_demo PUBLIC libappserver wslay)

target_link_directories(libappserver 
  PUBLIC 
    ${LIBUV_LINK_DIRECTORIES} 
)

target_link_libraries(libappserver PUBLIC libh2o uv_a ssl crypto  z)
target_include_directories(libappserver PUBLIC
        ${LIBUV_INCLUDE_DIRECTORIES} 
	${OPENSSL_INCLUDE_DIRECTORIES} 
	${LIBH2O_INCLUDE_DIRECTORIES} 
	${LIBUV_INCLUDE_DIRS}
	${CMAKE_CURRENT_SOURCE_DIR}
        ${CMAKE_CURRENT_SOURCE_DIR}/libs/readerwriterqueue
)

message("zlib: " ${ZLIB_INCLUDE_DIRS})
message("libuv: " ${LIBUV_INCLUDE_DIRECTORIES})
message("h2o: " ${LIBH2O_INCLUDE_DIRECTORIES})
message("wslay: " ${WSLAY_INCLUDE_DIRS})

# This just doesn't work yet:
#add_custom_command(TARGET appserver_demo POST_BUILD
#                   COMMAND ${CMAKE_COMMAND} -E copy_directory
#                   ${CMAKE_CURRENT_BINARY_DIR}/_deps/h2o-external-src/examples $<TARGET_FILE_DIR:appserver_demo>)


