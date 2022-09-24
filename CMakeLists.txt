cmake_minimum_required(VERSION 3.2)

project(cVIT)

file(GLOB_RECURSE SRC_FILES src/*.c include/*.h)
add_executable(cVIT ${SRC_FILES})

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3")

set(CMAKE_INSTALL_PREFIX ${PROJECT_SOURCE_DIR})

set(INSTALL_INCLUDE_DIR ${PROJECT_SOURCE_DIR}/include)

target_include_directories(cVIT PRIVATE ${INSTALL_INCLUDE_DIR})