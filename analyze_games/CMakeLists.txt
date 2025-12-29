cmake_minimum_required(VERSION 3.15)

# analyze_games - MAME game analyzer (cross-platform)
project(analyze_games LANGUAGES CXX)

# Source files
set(SOURCES
    analyze_games.cpp
)

# Create executable
add_executable(analyze_games ${SOURCES})

# Platform-specific configuration
if(WIN32)
    # Windows-specific settings
    target_compile_definitions(analyze_games PRIVATE
        _CRT_SECURE_NO_WARNINGS
        NOMINMAX
    )
    
    # Find TinyXML2 - you may need to install via vcpkg on Windows
    find_package(tinyxml2 CONFIG REQUIRED)
    target_link_libraries(analyze_games PRIVATE tinyxml2::tinyxml2)
    
elseif(UNIX)
    # Linux-specific settings
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(TINYXML2 REQUIRED tinyxml2)
    
    target_include_directories(analyze_games PRIVATE
        ${TINYXML2_INCLUDE_DIRS}
    )
    
    target_link_libraries(analyze_games PRIVATE
        ${TINYXML2_LIBRARIES}
    )
endif()

# Compiler options
target_compile_options(analyze_games PRIVATE
    $<$<CXX_COMPILER_ID:MSVC>:/W4>
    $<$<NOT:$<CXX_COMPILER_ID:MSVC>>:-Wall>
    $<$<CONFIG:Release>:$<IF:$<CXX_COMPILER_ID:MSVC>,/O2,-O2>>
    $<$<CONFIG:Debug>:$<IF:$<CXX_COMPILER_ID:MSVC>,/Od,-g>>
)

# Installation
install(TARGETS analyze_games
    RUNTIME DESTINATION bin
)

# Install README
install(FILES README.md
    DESTINATION share/doc/analyze_games
)
