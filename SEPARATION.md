# SCALIBR C Bindings - Project Separation

## Overview

The C export layer for SCALIBR has been separated into its own standalone project: **scalibr-c-bindings**.

## Why Separate?

1. **Modularity**: C bindings can be used independently by any language (C, C++, Python, Ruby, etc.)
2. **Versioning**: C bindings can have their own release cycle
3. **Simpler Dependencies**: Java/JNA users don't need the full Go source tree
4. **Better Organization**: Clear separation between the core library and language bindings
5. **Reusability**: Other language bindings (Python ctypes, Ruby FFI, etc.) can all share the same C library

## Project Structure

```
scalibr/
  ├── osv-scalibr/              # Main Go library
  │   ├── extractor/
  │   ├── detector/
  │   └── bindings/
  │       └── java/             # Java/JNA bindings
  └── scalibr-c-bindings/       # C bindings (separate project)
      ├── scalibr_c.go          # C exports using CGO
      ├── go.mod                # Module with replace directive
      ├── build.sh              # Linux/macOS build script
      ├── build.ps1             # Windows build script
      └── README.md             # Usage documentation
```

## How It Works

### C Bindings Project

- **Location**: `scalibr-c-bindings/` (separate repository/directory)
- **Purpose**: Exports SCALIBR Go functions as C-compatible API
- **Output**: Shared library (`.so`, `.dll`, `.dylib`)
- **Dependencies**: Depends on `osv-scalibr` via `replace` directive in `go.mod`

### Java Bindings Project

- **Location**: `osv-scalibr/bindings/java/`
- **Purpose**: Java wrapper using JNA
- **Dependencies**: Builds the C bindings library during Maven build
- **Output**: JAR with embedded native library

## Building

### C Bindings Alone

```bash
cd scalibr-c-bindings
./build.sh              # Creates dist/libscalibr.so (or .dylib/.dll)
```

### Java Bindings (includes C bindings build)

```bash
cd osv-scalibr/bindings/java
./build.sh              # Builds C library + Java wrapper
```

## For Other Language Bindings

To create bindings for Python, Ruby, or other languages:

1. Build the C bindings library once:
   ```bash
   cd scalibr-c-bindings
   ./build.sh
   ```

2. Use your language's FFI library to call the C functions:
   - **Python**: Use `ctypes`
   - **Ruby**: Use `ffi` gem
   - **Node.js**: Use `ffi-napi`
   - **Rust**: Use `bindgen`

See `scalibr-c-bindings/README.md` for API documentation and examples.

## Migration Notes

### Old Structure (before separation)

```
osv-scalibr/
  └── bindings/
      ├── cgo/
      │   ├── scalibr_c.go      # C exports
      │   └── go.mod
      └── java/                  # Java bindings
```

### New Structure (after separation)

```
scalibr/
  ├── osv-scalibr/
  │   └── bindings/
  │       └── java/              # Java bindings only
  └── scalibr-c-bindings/        # Separate project
      └── scalibr_c.go           # C exports
```

### What Changed

1. **C bindings moved**: `osv-scalibr/bindings/cgo/` → `scalibr-c-bindings/`
2. **Build scripts updated**: Java build now references `../../../scalibr-c-bindings`
3. **Documentation updated**: All READMEs reflect the new structure

### Breaking Changes

None for end users - the Java bindings API remains the same. The build process is transparent.

## Benefits

1. **Language Independence**: C library can be used by any language
2. **Simpler Maintenance**: Each project has clear responsibilities
3. **Distribution Flexibility**: Can distribute C library separately from Java bindings
4. **Future Expansion**: Easy to add Python, Ruby, etc. bindings later

## Next Steps

Consider creating bindings for other languages:

- **Python**: Using `ctypes` (see README examples)
- **Ruby**: Using `ffi` gem
- **Node.js**: Using `ffi-napi` or `node-gyp`
- **.NET**: Using P/Invoke
- **Rust**: Using `bindgen`

All can share the same `scalibr-c-bindings` library!
