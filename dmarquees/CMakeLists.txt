cmake_minimum_required(VERSION 3.15)

# dmarquees - Marquee display daemon (Linux only)
project(dmarquees LANGUAGES C)

# Source files
set(SOURCES
    dmarquees.c
    helpers.c
)

set(HEADERS
    helpers.h
)

# Create executable
add_executable(dmarquees ${SOURCES} ${HEADERS})

# Find required packages
find_package(PkgConfig REQUIRED)
pkg_check_modules(DRM REQUIRED libdrm)
pkg_check_modules(PNG REQUIRED libpng)

# Include directories
target_include_directories(dmarquees PRIVATE
    ${DRM_INCLUDE_DIRS}
    ${PNG_INCLUDE_DIRS}
)

# Link libraries
target_link_libraries(dmarquees PRIVATE
    ${DRM_LIBRARIES}
    ${PNG_LIBRARIES}
)

# Compiler options
target_compile_options(dmarquees PRIVATE
    -Wall
    $<$<CONFIG:Release>:-O2>
    $<$<CONFIG:Debug>:-g>
)

# Installation
install(TARGETS dmarquees
    RUNTIME DESTINATION bin
)

# Install README
install(FILES README.md
    DESTINATION share/doc/dmarquees
)
