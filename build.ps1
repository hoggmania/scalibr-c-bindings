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

# Build script for SCALIBR C bindings (Windows)

Write-Host "Building SCALIBR C Bindings..." -ForegroundColor Green

# Check for GCC
Write-Host "Checking for C compiler (required for CGO)..." -ForegroundColor Yellow
$gccPath = Get-Command gcc -ErrorAction SilentlyContinue
if (-not $gccPath) {
    Write-Host ""
    Write-Host "ERROR: GCC compiler not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "CGO requires a C compiler to build the shared library." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please install one of the following:" -ForegroundColor Cyan
    Write-Host "  1. MinGW-w64 (Recommended): choco install mingw" -ForegroundColor White
    Write-Host "  2. TDM-GCC: https://jmeubank.github.io/tdm-gcc/" -ForegroundColor White
    Write-Host "  3. MSYS2: https://www.msys2.org/" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host "Found GCC: $($gccPath.Source)" -ForegroundColor Green

# Navigate to the script directory
Set-Location $PSScriptRoot

# Download osv-scalibr dependency if not present
if (-not (Test-Path "osv-scalibr")) {
    Write-Host "Cloning osv-scalibr v0.3.6..." -ForegroundColor Yellow
    git clone --depth 1 --branch v0.3.6 https://github.com/google/osv-scalibr.git osv-scalibr
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to clone osv-scalibr. Please clone manually or create a symlink." -ForegroundColor Red
        exit 1
    }
    Write-Host "osv-scalibr cloned successfully" -ForegroundColor Green
    Write-Host "Downloading Go dependencies..." -ForegroundColor Yellow
    go mod download
} else {
    Write-Host "osv-scalibr already present" -ForegroundColor Green
}

# Create output directory
Write-Host "Creating output directory..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "dist" | Out-Null

# Build the Go shared library
Write-Host "Building Go shared library..." -ForegroundColor Yellow
$env:CGO_ENABLED = "1"
$env:GOOS = "windows"
go build -buildmode=c-shared -o "dist\scalibr.dll"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to build library" -ForegroundColor Red
    exit 1
}

Write-Host "Build complete!" -ForegroundColor Green
Write-Host "Library: dist\scalibr.dll"
Write-Host ""
Write-Host "Usage from C/C++:" -ForegroundColor Cyan
Write-Host "  #include `"scalibr_c.h`""
Write-Host "  // Link with dist\scalibr.dll"
