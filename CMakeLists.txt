cmake_minimum_required(VERSION 3.15)
project(IvarArcade VERSION 1.0.0 LANGUAGES C CXX)

# Set C/C++ standards
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Platform detection
if(WIN32)
    set(PLATFORM_WINDOWS TRUE)
    message(STATUS "Building for Windows")
elseif(UNIX AND NOT APPLE)
    set(PLATFORM_LINUX TRUE)
    message(STATUS "Building for Linux")
elseif(APPLE)
    set(PLATFORM_MACOS TRUE)
    message(STATUS "Building for macOS")
endif()

# Build options
option(BUILD_DMARQUEES "Build dmarquees marquee daemon" ON)
option(BUILD_ANALYZE_GAMES "Build analyze_games utility" ON)

# Installation directory
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    if(WIN32)
        set(CMAKE_INSTALL_PREFIX "C:/IvarArcade" CACHE PATH "Install path" FORCE)
    else()
        set(CMAKE_INSTALL_PREFIX "$ENV{HOME}/marquees" CACHE PATH "Install path" FORCE)
    endif()
endif()

# Output directories
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# Add subdirectories
if(BUILD_DMARQUEES)
    if(PLATFORM_LINUX)
        add_subdirectory(dmarquees)
    else()
        message(WARNING "dmarquees is only supported on Linux (requires DRM)")
    endif()
endif()

if(BUILD_ANALYZE_GAMES)
    add_subdirectory(analyze_games)
endif()

# Install shared resources
install(DIRECTORY images/ DESTINATION images
    PATTERN ".git" EXCLUDE)

install(DIRECTORY plugins/ DESTINATION plugins
    PATTERN ".git" EXCLUDE)

# Print summary
message(STATUS "")
message(STATUS "IvarArcade Build Configuration:")
message(STATUS "  Version: ${PROJECT_VERSION}")
message(STATUS "  Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "  Install prefix: ${CMAKE_INSTALL_PREFIX}")
message(STATUS "  C Compiler: ${CMAKE_C_COMPILER}")
message(STATUS "  C++ Compiler: ${CMAKE_CXX_COMPILER}")
message(STATUS "")
message(STATUS "Components:")
message(STATUS "  dmarquees: ${BUILD_DMARQUEES}")
message(STATUS "  analyze_games: ${BUILD_ANALYZE_GAMES}")
message(STATUS "")
