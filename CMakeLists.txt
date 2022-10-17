cmake_minimum_required(VERSION 3.2)

project(SLAM)

set(GPU TRUE)

if (${GPU} MATCHES TRUE)
    message("Using GPU")
    find_package(CUDA REQUIRED)
    set(CUDA_NVCC_FLAGS "${CUDA_NVCC_FLAGS} -std=c++11" )
    add_compile_definitions(GPU)
endif()

file(GLOB_RECURSE SRC_FILES src/*.cc)
file(GLOB_RECURSE CUDA_FILES src/*.cu)
add_executable(SLAM ${SRC_FILES} ${CUDA_FILES})

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3")
set(CMAKE_INSTALL_PREFIX ${PROJECT_SOURCE_DIR})
set(INCLUDE_DIR ${PROJECT_SOURCE_DIR}/include)

find_package( OpenCV REQUIRED )

target_include_directories(SLAM PRIVATE ${INCLUDE_DIR} ${OpenCV_INCLUDE_DIRS})
target_link_libraries( SLAM PRIVATE ${OpenCV_LIBS} )