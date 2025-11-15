#!/bin/bash
# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Build script for SCALIBR C bindings

set -e

echo "Building SCALIBR C Bindings..."

# Determine the platform
PLATFORM=$(uname -s)
case "$PLATFORM" in
    Linux*)     LIBRARY_NAME="libscalibr.so"; GOOS="linux";;
    Darwin*)    LIBRARY_NAME="libscalibr.dylib"; GOOS="darwin";;
    MINGW*|MSYS*|CYGWIN*) LIBRARY_NAME="scalibr.dll"; GOOS="windows";;
    *)          echo "Unsupported platform: $PLATFORM"; exit 1;;
esac

echo "Platform: $PLATFORM"
echo "Library: $LIBRARY_NAME"

# Navigate to the script directory
cd "$(dirname "$0")"

# Clone osv-scalibr if not present (required for build)
if [ ! -d "osv-scalibr" ]; then
    echo "Cloning osv-scalibr (latest)..."
    git clone --depth 1 https://github.com/google/osv-scalibr.git osv-scalibr
    if [ $? -ne 0 ]; then
        echo "Failed to clone osv-scalibr"
        echo "You can also create a symlink: ln -s <path> osv-scalibr"
        exit 1
    fi
    echo "Successfully cloned osv-scalibr"
    
    # Fix osv-scalibr dependencies
    echo "Fixing osv-scalibr dependencies..."
    (cd osv-scalibr && go mod tidy)
else
    echo "osv-scalibr directory found"
fi

# Download Go dependencies
echo "Downloading Go dependencies..."
go mod download

# Create output directory
mkdir -p dist

# Build the Go shared library
echo "Building Go shared library..."
CGO_ENABLED=1 GOOS=$GOOS go build -buildmode=c-shared -o "dist/$LIBRARY_NAME"

echo "Build complete!"
echo "Library: dist/$LIBRARY_NAME"
echo ""
echo "Usage from C/C++:"
echo "  #include \"scalibr_c.h\""
echo "  // Link with -L./dist -lscalibr"
echo ""
echo "Usage from Java/JNA:"
echo "  Native.load(\"scalibr\", ScalibrNative.class)"
