cmake_minimum_required(VERSION 3.16)
project(xrealAirLibrary C)

set(CMAKE_C_STANDARD 17)

find_package(json-c REQUIRED CONFIG)

add_subdirectory(modules/hidapi)
add_subdirectory(modules/Fusion/Fusion)

set(PROTOCOL_SOURCES src/imu_protocol_hid.c)

# Conditionally include xreal_one protocol if header exists
set(XOD_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/modules/xreal_one_driver")
set(XOD_HAVE_HEADER OFF)
if(EXISTS "${XOD_ROOT}/include/xreal_one_driver.h")
	set(XOD_HAVE_HEADER ON)
	list(APPEND PROTOCOL_SOURCES src/imu_protocol_xo.c)
endif()

add_library(
		xrealAirLibrary
		src/crc32.c
		src/device.c
		src/device_imu.c
		src/device_mcu.c
		src/hid_ids.c
		${PROTOCOL_SOURCES}
)

target_compile_options(xrealAirLibrary PRIVATE -fPIC)

target_include_directories(xrealAirLibrary
		BEFORE PUBLIC include
)

target_include_directories(xrealAirLibrary
		SYSTEM BEFORE PRIVATE 
		${CMAKE_CURRENT_SOURCE_DIR}/modules/hidapi
		${CMAKE_CURRENT_SOURCE_DIR}/modules/Fusion
)

if(XOD_HAVE_HEADER)
    target_include_directories(xrealAirLibrary SYSTEM BEFORE PRIVATE "${XOD_ROOT}/include")
endif()

target_link_libraries(xrealAirLibrary
		PRIVATE hidapi::hidapi json-c::json-c Fusion m
)

# Optionally bring in xreal_one_driver to satisfy the XO protocol implementation
if(EXISTS "${XOD_ROOT}/CMakeLists.txt")
	add_subdirectory("${XOD_ROOT}" "${CMAKE_CURRENT_BINARY_DIR}/xreal_one_driver")
	target_link_libraries(xrealAirLibrary PRIVATE xreal_one_driver)
endif()

set(XREAL_AIR_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/include PARENT_SCOPE)
set(XREAL_AIR_LIBRARY xrealAirLibrary PARENT_SCOPE)

set(NREAL_AIR_INCLUDE_DIR ${XREAL_AIR_INCLUDE_DIR} PARENT_SCOPE)
set(NREAL_AIR_LIBRARY ${XREAL_AIR_LIBRARY} PARENT_SCOPE)
