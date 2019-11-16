cmake_minimum_required(VERSION 3.12)
include(FetchContent)

#
# libuv
#


FetchContent_Declare(libuv-external
                    GIT_SHALLOW TRUE
                    GIT_REPOSITORY "https://github.com/libuv/libuv.git"
#                    GIT_TAG "4101d1dfed05bae4b543d1769adcb11067e8dcdb"
#                    GIT_TAG "a9e6cc7b9967308cac61414aa907070412461c8f"
                    )

FetchContent_Populate(libuv-external)
SET(LIBUV_INCLUDE_DIRECTORIES ${libuv-external_SOURCE_DIR}/include PARENT_SCOPE)
SET(LIBUV_INCLUDE_DIRS ${libuv-external_SOURCE_DIR}/include PARENT_SCOPE) # H2O uses LIBUV_INCLUDE_DIRS

add_subdirectory(${libuv-external_SOURCE_DIR} ${libuv-external_BINARY_DIR})

#if (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
#    set(SFX /Debug)
#endif()

SET(LIBUV_LINK_DIRECTORIES 
	${libuv-external_BINARY_DIR}${SFX}
	PARENT_SCOPE)

