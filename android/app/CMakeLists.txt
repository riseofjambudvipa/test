cmake_minimum_required(VERSION 3.22.1)
project(whisper_jni_project VERSION 1.0)

# Disable building tests, examples, and server of whisper.cpp to save compilation time
set(WHISPER_BUILD_TESTS OFF CACHE BOOL "Build tests" FORCE)
set(WHISPER_BUILD_EXAMPLES OFF CACHE BOOL "Build examples" FORCE)
set(WHISPER_BUILD_SERVER OFF CACHE BOOL "Build server" FORCE)

# Set whisper.cpp root directory path
set(WHISPER_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/../../third_party/whisper.cpp)

# Include the whisper.cpp subdirectory, setting dynamic build path
add_subdirectory(${WHISPER_ROOT} ${CMAKE_CURRENT_BINARY_DIR}/whisper_build)

# Add our JNI wrapper library target
add_library(
    whisper_jni
    SHARED
    src/main/cpp/whisper_jni.cpp
)

# Find Android logging library
find_library(log-lib log)

# Link JNI wrapper with core whisper library and Android libraries
target_link_libraries(
    whisper_jni
    whisper
    ${log-lib}
    android
)

# Configure include directories for compiler resolution
target_include_directories(
    whisper_jni PRIVATE
    ${WHISPER_ROOT}
    ${WHISPER_ROOT}/include
    ${WHISPER_ROOT}/ggml/include
)
