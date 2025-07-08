# Help target
help:
	@echo "Available targets:"
	@echo "  build         - Build for current platform (default: linux/amd64)"
	@echo "  build-macbook - Build for MacBook (Apple Silicon/darwin-arm64)"
	@echo "  build-linux   - Build for Linux (x86_64/linux-amd64)"
	@echo "  build-pi5     - Build for Raspberry Pi 5 (ARM64/linux-arm64)"
	@echo "  build-all     - Build for all supported platforms"
	@echo "  generate      - Generate code (placeholder)"
	@echo "  package-dir   - Create package directory"
	@echo "  copy-provider - Copy provider binary to package directory"
	@echo ""
	@echo "Environment variables:"
	@echo "  GOOS          - Target operating system (default: linux)"
	@echo "  GOARCH        - Target architecture (default: amd64)"
	@echo ""
	@echo "Examples:"
	@echo "  make build-macbook    # Build for your MacBook"
	@echo "  make build-pi5        # Build for Raspberry Pi 5"
	@echo "  make build-all        # Build for all platforms"
	@echo "  GOOS=windows GOARCH=amd64 make build  # Custom platform"

generate:
	@echo "No code generation needed"

# Set default values for GOOS and GOARCH if not provided
GOOS ?= linux
GOARCH ?= amd64

build:
	@mkdir -p bin
	CGO_ENABLED=0 GOOS=$(GOOS) GOARCH=$(GOARCH) go build -a -ldflags '-extldflags "-static"' -o bin/provider ./cmd/provider

# Build for specific platforms
build-macbook:
	@echo "Building for MacBook (Apple Silicon)..."
	@mkdir -p bin
	CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 go build -a -ldflags '-extldflags "-static"' -o bin/provider-darwin-arm64 ./cmd/provider
	@echo "✅ Built binary for MacBook: bin/provider-darwin-arm64"

build-linux:
	@echo "Building for Linux (x86_64)..."
	@mkdir -p bin
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -ldflags '-extldflags "-static"' -o bin/provider-linux-amd64 ./cmd/provider
	@echo "✅ Built binary for Linux: bin/provider-linux-amd64"

build-pi5:
	@echo "Building for Raspberry Pi 5 (ARM64)..."
	@mkdir -p bin
	CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -a -ldflags '-extldflags "-static"' -o bin/provider-linux-arm64 ./cmd/provider
	@echo "✅ Built binary for Pi5: bin/provider-linux-arm64"

build-all:
	@echo "Building for all supported platforms..."
	@mkdir -p bin
	$(MAKE) build-linux
	$(MAKE) build-pi5
	$(MAKE) build-macbook
	@echo "✅ Built binaries for all platforms"

package-dir:
	@if [ -f package ]; then rm -f package; fi
	@mkdir -p package

copy-provider: package-dir
	@echo "Building Linux/amd64 binary for package..."
	$(MAKE) build GOOS=linux GOARCH=amd64
	cp bin/provider package/
	cp config/crd/nutanix.crossplane.io_*.yaml package/
	@echo "✅ Examples included as markdown files in package/examples/"
