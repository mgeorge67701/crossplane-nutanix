# Set default values for GOOS and GOARCH if not provided
GOOS ?= linux
GOARCH ?= amd64

# Default target
.DEFAULT_GOAL := build

# Build for current platform
build:
	@mkdir -p bin
	CGO_ENABLED=0 GOOS=$(GOOS) GOARCH=$(GOARCH) go build -a -ldflags '-extldflags "-static"' -o bin/provider ./cmd/provider

# Build for specific platforms
build-macbook:
	@mkdir -p bin
	CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 go build -a -ldflags '-extldflags "-static"' -o bin/provider-darwin-arm64 ./cmd/provider

build-linux:
	@mkdir -p bin
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -ldflags '-extldflags "-static"' -o bin/provider-linux-amd64 ./cmd/provider

build-pi5:
	@mkdir -p bin
	CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -a -ldflags '-extldflags "-static"' -o bin/provider-linux-arm64 ./cmd/provider

build-all: build-linux build-pi5 build-macbook

# Package targets
package-dir:
	@mkdir -p package

copy-provider: package-dir
	$(MAKE) build GOOS=linux GOARCH=amd64
	cp bin/provider package/
	cp config/crd/nutanix.crossplane.io_*.yaml package/

# Help
help:
	@echo "Available targets:"
	@echo "  build         - Build for current platform (default: linux/amd64)"
	@echo "  build-macbook - Build for MacBook (Apple Silicon)"
	@echo "  build-linux   - Build for Linux (x86_64)"
	@echo "  build-pi5     - Build for Raspberry Pi 5 (ARM64)"
	@echo "  build-all     - Build for all platforms"
	@echo "  copy-provider - Copy provider binary to package directory"

.PHONY: build build-macbook build-linux build-pi5 build-all package-dir copy-provider help
