cmake_minimum_required(VERSION 3.12)
include(FetchContent)

#
# uv-ssl-client 
#


# This feels like a wart...
include_directories(PUBLIC ${LIBUV_INCLUDE_DIRS})

FetchContent_Declare(uv-ssl-client-external
                     GIT_SHALLOW TRUE
                     GIT_REPOSITORY "https://github.com/aldanor/uv-ssl-client"
#                    GIT_TAG "4101d1dfed05bae4b543d1769adcb11067e8dcdb"
#                    GIT_TAG "a9e6cc7b9967308cac61414aa907070412461c8f"
                    )

FetchContent_Populate(uv-ssl-client-external)
SET(LIBUV_SSL_CLIENT_INCLUDE_DIRECTORIES ${uv-ssl-client-external_SOURCE_DIR}/include PARENT_SCOPE)
SET(LIBUV_SSL_CLIENT_INCLUDE_DIRS ${uv-ssl-client-external_SOURCE_DIR}/include PARENT_SCOPE) # H2O uses LIBUV_INCLUDE_DIRS

add_subdirectory(${uv-ssl-client-external_SOURCE_DIR} ${uv-ssl-client-external_BINARY_DIR})


#target_include_libraries(uv_ssl_client PUBLIC uv)

#if (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
#    set(SFX /Debug)
#endif()

SET(LIBUV_SSL_CLIENT_LINK_DIRECTORIES 
	${uv-ssl-client-external_BINARY_DIR}${SFX}
	PARENT_SCOPE)

