// Copyright 2025 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Package main provides C-exported functions for calling SCALIBR from other languages.
package main

/*
#include <stdlib.h>
#include <string.h>

typedef struct {
    char* json_result;
    char* error_message;
    int status_code;
} ScanResult;

typedef struct {
    char* root_path;
    char** plugins;
    int plugins_count;
    char** paths_to_extract;
    int paths_count;
    int max_file_size;
    int verbose;
    int offline;
} ScanConfig;
*/
import "C"
import (
	"context"
	"encoding/json"
	"fmt"
	"unsafe"

	scalibr "github.com/google/osv-scalibr"
	cpb "github.com/google/osv-scalibr/binary/proto/config_go_proto"
	scalibrfs "github.com/google/osv-scalibr/fs"
	"github.com/google/osv-scalibr/log"
	"github.com/google/osv-scalibr/plugin"
	pl "github.com/google/osv-scalibr/plugin/list"
)

// Version returns the SCALIBR version string
//
//export ScalibrVersion
func ScalibrVersion() *C.char {
	return C.CString("1.0.0")
}

// FreeString frees a C string allocated by Go
//
//export ScalibrFreeString
func ScalibrFreeString(str *C.char) {
	C.free(unsafe.Pointer(str))
}

// FreeScanResult frees the memory allocated for a ScanResult
//
//export ScalibrFreeScanResult
func ScalibrFreeScanResult(result *C.ScanResult) {
	if result == nil {
		return
	}
	if result.json_result != nil {
		C.free(unsafe.Pointer(result.json_result))
	}
	if result.error_message != nil {
		C.free(unsafe.Pointer(result.error_message))
	}
	C.free(unsafe.Pointer(result))
}

// Scan performs a SCALIBR scan with the given configuration
//
//export ScalibrScan
func ScalibrScan(config *C.ScanConfig) *C.ScanResult {
	result := (*C.ScanResult)(C.malloc(C.size_t(unsafe.Sizeof(C.ScanResult{}))))
	result.json_result = nil
	result.error_message = nil
	result.status_code = 0

	if config == nil {
		result.error_message = C.CString("config cannot be nil")
		result.status_code = 1
		return result
	}

	// Convert C config to Go
	rootPath := C.GoString(config.root_path)
	if rootPath == "" {
		rootPath = "/"
	}

	// Extract plugin names
	var pluginNames []string
	if config.plugins_count > 0 {
		pluginNames = make([]string, config.plugins_count)
		plugins := (*[1 << 30]*C.char)(unsafe.Pointer(config.plugins))[:config.plugins_count:config.plugins_count]
		for i, p := range plugins {
			pluginNames[i] = C.GoString(p)
		}
	}

	// Extract paths to scan
	var pathsToExtract []string
	if config.paths_count > 0 {
		pathsToExtract = make([]string, config.paths_count)
		paths := (*[1 << 30]*C.char)(unsafe.Pointer(config.paths_to_extract))[:config.paths_count:config.paths_count]
		for i, p := range paths {
			pathsToExtract[i] = C.GoString(p)
		}
	}

	// Configure logging
	if config.verbose != 0 {
		// Logging is controlled via log.SetLogger if needed
		// No Initialize method exists in the current API
		log.Infof("Running SCALIBR scan in verbose mode")
	}

	// Get plugins
	plugins, err := pl.FromNames(pluginNames, &cpb.PluginConfig{})
	if err != nil {
		result.error_message = C.CString(fmt.Sprintf("failed to load plugins: %v", err))
		result.status_code = 2
		return result
	}

	// Set up capabilities
	capab := &plugin.Capabilities{
		Network:       plugin.NetworkOffline,
		DirectFS:      true,
		RunningSystem: true,
	}
	if config.offline == 0 {
		capab.Network = plugin.NetworkOnline
	}

	// Create scan config
	scanConfig := &scalibr.ScanConfig{
		ScanRoots:      scalibrfs.RealFSScanRoots(rootPath),
		Plugins:        plugin.FilterByCapabilities(plugins, capab),
		PathsToExtract: pathsToExtract,
		MaxFileSize:    int(config.max_file_size),
		Capabilities:   capab,
	}

	// Run the scan
	scanner := scalibr.New()
	scanResult := scanner.Scan(context.Background(), scanConfig)

	if scanResult == nil {
		result.error_message = C.CString("scan returned nil result")
		result.status_code = 3
		return result
	}

	// Convert result to JSON
	jsonBytes, err := json.MarshalIndent(scanResult, "", "  ")
	if err != nil {
		result.error_message = C.CString(fmt.Sprintf("failed to marshal result: %v", err))
		result.status_code = 4
		return result
	}

	result.json_result = C.CString(string(jsonBytes))
	result.status_code = 0
	return result
}

// ScanPath is a simplified version that scans a single path with default plugins
//
//export ScalibrScanPath
func ScalibrScanPath(path *C.char) *C.ScanResult {
	config := (*C.ScanConfig)(C.malloc(C.size_t(unsafe.Sizeof(C.ScanConfig{}))))
	defer C.free(unsafe.Pointer(config))

	config.root_path = path
	config.plugins = nil
	config.plugins_count = 0
	config.paths_to_extract = nil
	config.paths_count = 0
	config.max_file_size = 0
	config.verbose = 0
	config.offline = 0

	return ScalibrScan(config)
}

func main() {
	// This is required for building as a shared library
}
