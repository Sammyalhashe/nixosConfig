cmake_minimum_required(VERSION 3.16)
project(xrealAirDebugCamera CXX)

set(CMAKE_CXX_STANDARD 17)

# Only require the OpenCV components actually used to avoid pulling optional deps (viz/hdf)
find_package(OpenCV QUIET COMPONENTS core imgproc highgui videoio calib3d)
if(NOT OpenCV_FOUND)
    message(WARNING "OpenCV components (core,imgproc,highgui,videoio,calib3d) not found; skipping xrealAirDebugCamera example")
    return()
endif()

include_directories(
    ${OpenCV_INCLUDE_DIRS}
)

add_executable(
    xrealAirDebugCamera
    src/camera.cpp
)

target_include_directories(xrealAirDebugCamera
    BEFORE PUBLIC ${XREAL_AIR_INCLUDE_DIR}
)

target_link_libraries(xrealAirDebugCamera
    ${XREAL_AIR_LIBRARY} ${OpenCV_LIBS}
)
