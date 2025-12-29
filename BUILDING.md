# Building IvarArcade

IvarArcade supports both **Make** (Linux) and **CMake** (cross-platform) build systems.

## Prerequisites

### Linux (RetroPie/Raspberry Pi)
```bash
sudo apt install build-essential cmake pkg-config
sudo apt install libdrm-dev libpng-dev libtinyxml2-dev
```

### Windows
1. Install [Visual Studio 2019 or later](https://visualstudio.microsoft.com/) with C++ support
2. Install [CMake](https://cmake.org/download/) (3.15 or later)
3. Install [vcpkg](https://github.com/microsoft/vcpkg) for dependency management:
   ```powershell
   git clone https://github.com/Microsoft/vcpkg.git
   cd vcpkg
   .\bootstrap-vcpkg.bat
   .\vcpkg integrate install
   ```
4. Install dependencies via vcpkg:
   ```powershell
   .\vcpkg install tinyxml2:x64-windows
   ```

## Building with Make (Linux only)

### Build everything:
```bash
make
```

### Build individual components:
```bash
make dmarquees      # Build only dmarquees
make analyze_games  # Build only analyze_games
```

### Install:
```bash
make install        # Install to ~/marquees/
```

### Clean:
```bash
make clean
```

## Building with CMake (Cross-platform)

### Linux

```bash
# Create build directory
mkdir build && cd build

# Configure
cmake ..

# Build
cmake --build .

# Install (optional)
cmake --install . --prefix ~/marquees
```

### Windows

Using **Visual Studio Developer Command Prompt** or **PowerShell**:

```powershell
# Create build directory
mkdir build
cd build

# Configure (with vcpkg toolchain)
cmake .. -DCMAKE_TOOLCHAIN_FILE=C:/path/to/vcpkg/scripts/buildsystems/vcpkg.cmake

# Build
cmake --build . --config Release

# Install (optional)
cmake --install . --prefix C:\IvarArcade
```

Or open the folder in **Visual Studio** and use CMake integration directly.

### Build Options

```bash
# Build only specific components
cmake .. -DBUILD_DMARQUEES=OFF          # Skip dmarquees (auto-disabled on Windows)
cmake .. -DBUILD_ANALYZE_GAMES=OFF      # Skip analyze_games

# Specify build type
cmake .. -DCMAKE_BUILD_TYPE=Release     # Release build
cmake .. -DCMAKE_BUILD_TYPE=Debug       # Debug build

# Custom install location
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local/ivararcade
```

## Platform Support

| Component      | Linux | Windows | macOS |
|----------------|-------|---------|-------|
| dmarquees      | ✅    | ❌      | ❌    |
| analyze_games  | ✅    | ✅      | ✅    |

**Note:** `dmarquees` requires Linux DRM (Direct Rendering Manager) and is not available on Windows or macOS. The `analyze_games` utility is fully cross-platform.

## IDE Support

### VS Code
- Install the **CMake Tools** extension
- Open the project folder
- CMake will auto-detect and configure
- Use the CMake sidebar to build and debug

### Visual Studio (Windows)
- **File → Open → Folder** and select the IvarArcade directory
- Visual Studio will detect `CMakeLists.txt` automatically
- Use the build toolbar or **Build → Build All**

### CLion
- **File → Open** and select the IvarArcade directory
- CLion will detect and configure CMake automatically

## Troubleshooting

### Linux: Missing dependencies
```bash
# If pkg-config can't find libraries:
sudo ldconfig
pkg-config --list-all | grep -E 'drm|png|tinyxml'
```

### Windows: vcpkg not found
Make sure to pass the correct toolchain file path:
```powershell
cmake .. -DCMAKE_TOOLCHAIN_FILE=C:/path/to/vcpkg/scripts/buildsystems/vcpkg.cmake
```

### Cannot find TinyXML2
Ensure the package is installed:
- **Linux:** `sudo apt install libtinyxml2-dev`
- **Windows:** `vcpkg install tinyxml2:x64-windows`
