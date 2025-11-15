# SCALIBR C Bindings

C-compatible shared library bindings for [OSV-SCALIBR](https://github.com/google/osv-scalibr), enabling integration with C, C++, Java (via JNA), Python (via ctypes), and other languages.

## Overview

This standalone project provides a C-compatible API layer on top of the Go-based SCALIBR library. It exports SCALIBR's functionality as a shared library (`.so`, `.dylib`, or `.dll`) that can be called from any language supporting C FFI.

## Features

- **C-Compatible API**: Clean C structs and functions for easy FFI
- **Cross-Platform**: Builds on Linux, macOS, and Windows
- **JSON Results**: Structured scan results in JSON format
- **Memory Management**: Explicit memory management functions for safe interop
- **Language Agnostic**: Can be used from any language with C FFI support

## Prerequisites

- **Go 1.20** or higher
- **C Compiler** (for CGO):
  - Linux: GCC
  - macOS: Xcode Command Line Tools
  - Windows: MinGW-w64 (install with `choco install mingw`)
- **osv-scalibr source**: Download and extract v0.3.6

### Setting up osv-scalibr dependency

Download and extract the osv-scalibr source code:

**Linux/macOS:**
```bash
curl -L -o osv-scalibr.zip https://github.com/google/osv-scalibr/archive/refs/tags/v0.3.6.zip
unzip osv-scalibr.zip
mv osv-scalibr-0.3.6 osv-scalibr
```

**Windows (PowerShell):**
```powershell
Invoke-WebRequest -Uri https://github.com/google/osv-scalibr/archive/refs/tags/v0.3.6.zip -OutFile osv-scalibr.zip
Expand-Archive -Path osv-scalibr.zip -DestinationPath .
Rename-Item -Path osv-scalibr-0.3.6 -NewName osv-scalibr
```

Alternatively, create a symbolic link to an existing osv-scalibr clone:
```bash
ln -s ../osv-scalibr osv-scalibr  # Linux/macOS
```
```powershell
New-Item -ItemType SymbolicLink -Path .\osv-scalibr -Target ..\osv-scalibr  # Windows
```

## Building

### Linux/macOS

```bash
./build.sh
```

This creates `dist/libscalibr.so` (Linux) or `dist/libscalibr.dylib` (macOS).

### Windows

```powershell
.\build.ps1
```

This creates `dist\scalibr.dll`.

## API Reference

### Data Structures

```c
// Scan configuration
typedef struct {
    char* root_path;           // Root path to scan
    char** plugins;            // Array of plugin names
    int plugins_count;         // Number of plugins
    char** paths_to_extract;   // Specific paths to extract
    int paths_count;           // Number of paths
    int max_file_size;         // Maximum file size to scan
    int verbose;               // Verbose logging (0=off, 1=on)
    int offline;               // Offline mode (0=online, 1=offline)
} ScanConfig;

// Scan result
typedef struct {
    char* json_result;         // JSON-formatted scan results
    char* error_message;       // Error message if scan failed
    int status_code;           // 0=success, non-zero=error
} ScanResult;
```

### Functions

```c
// Get SCALIBR version
char* ScalibrVersion();

// Perform a scan with full configuration
ScanResult* ScalibrScan(ScanConfig* config);

// Simplified scan of a single path with defaults
ScanResult* ScalibrScanPath(char* path);

// Free a C string returned by SCALIBR
void ScalibrFreeString(char* str);

// Free a scan result structure
void ScalibrFreeScanResult(ScanResult* result);
```

## Usage Examples

### C/C++

```c
#include "scalibr_c.h"
#include <stdio.h>
#include <stdlib.h>

int main() {
    // Get version
    char* version = ScalibrVersion();
    printf("SCALIBR version: %s\n", version);
    ScalibrFreeString(version);
    
    // Simple scan
    ScanResult* result = ScalibrScanPath("/path/to/scan");
    if (result->status_code == 0) {
        printf("Scan successful:\n%s\n", result->json_result);
    } else {
        fprintf(stderr, "Scan failed: %s\n", result->error_message);
    }
    ScalibrFreeScanResult(result);
    
    return 0;
}
```

Compile with:
```bash
gcc -o example example.c -L./dist -lscalibr
LD_LIBRARY_PATH=./dist ./example
```

### Java (JNA)

See the [Java bindings project](../osv-scalibr/bindings/java) for a complete Java wrapper using JNA.

Basic usage:
```java
interface ScalibrNative extends Library {
    ScalibrNative INSTANCE = Native.load("scalibr", ScalibrNative.class);
    
    Pointer ScalibrVersion();
    Pointer ScalibrScanPath(String path);
    void ScalibrFreeScanResult(Pointer result);
}

// Use it
String version = ScalibrNative.INSTANCE.ScalibrVersion().getString(0);
System.out.println("Version: " + version);
```

### Python (ctypes)

```python
from ctypes import *

# Load library
lib = CDLL("./dist/libscalibr.so")  # or scalibr.dll on Windows

# Define result structure
class ScanResult(Structure):
    _fields_ = [
        ("json_result", c_char_p),
        ("error_message", c_char_p),
        ("status_code", c_int)
    ]

# Set return types
lib.ScalibrVersion.restype = c_char_p
lib.ScalibrScanPath.argtypes = [c_char_p]
lib.ScalibrScanPath.restype = POINTER(ScanResult)

# Use it
version = lib.ScalibrVersion()
print(f"Version: {version.decode()}")

result = lib.ScalibrScanPath(b"/path/to/scan")
if result.contents.status_code == 0:
    print(f"Results: {result.contents.json_result.decode()}")
lib.ScalibrFreeScanResult(result)
```

## Advanced Configuration

For advanced scanning with custom plugins and options:

```c
ScanConfig config;
config.root_path = "/path/to/scan";

// Specify plugins
char* plugins[] = {"python", "javascript", "go"};
config.plugins = plugins;
config.plugins_count = 3;

// Specific paths
char* paths[] = {"/etc/os-release", "/usr/lib"};
config.paths_to_extract = paths;
config.paths_count = 2;

// Other options
config.max_file_size = 100 * 1024 * 1024;  // 100MB
config.verbose = 1;
config.offline = 0;

ScanResult* result = ScalibrScan(&config);
// ... handle result ...
ScalibrFreeScanResult(result);
```

## Memory Management

**Important**: Always free allocated memory to prevent leaks:

- `ScalibrFreeString(char*)` - For version strings
- `ScalibrFreeScanResult(ScanResult*)` - For scan results (frees all internal strings too)

## Troubleshooting

### Library Not Found

**Linux/macOS**:
```bash
export LD_LIBRARY_PATH=/path/to/scalibr-c-bindings/dist
# or
export DYLD_LIBRARY_PATH=/path/to/scalibr-c-bindings/dist  # macOS
```

**Windows**:
Add `dist` folder to PATH or copy `scalibr.dll` next to your executable.

### CGO Build Errors

Ensure you have a C compiler installed:
- **Linux**: `sudo apt install build-essential`
- **macOS**: `xcode-select --install`
- **Windows**: Install MinGW-w64 via `choco install mingw`

## Integration with Java Bindings

The [Java bindings project](../osv-scalibr/bindings/java) depends on this library. To use the Java bindings:

1. Build this C bindings library first
2. The Java build will automatically use the library from `dist/`

## License

Apache License 2.0 - See [LICENSE](../osv-scalibr/LICENSE)

## Related Projects

- [OSV-SCALIBR](https://github.com/google/osv-scalibr) - Main Go library
- [Java Bindings](../osv-scalibr/bindings/java) - High-level Java wrapper using JNA
