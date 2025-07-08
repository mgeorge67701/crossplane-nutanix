# Multi-Platform Build Support

This Crossplane provider supports building for multiple platforms to cover your specific needs.

## Supported Platforms

### 🍎 MacBook (Apple Silicon)
- **Platform**: `darwin/arm64`
- **Build command**: `make build-macbook`
- **Binary**: `bin/provider-darwin-arm64`
- **Use case**: Local development on MacBook

### 🐧 Linux (x86_64)
- **Platform**: `linux/amd64`
- **Build command**: `make build-linux`
- **Binary**: `bin/provider-linux-amd64`
- **Use case**: Standard Linux servers, cloud instances

### 🥧 Raspberry Pi 5
- **Platform**: `linux/arm64`
- **Build command**: `make build-pi5`
- **Binary**: `bin/provider-linux-arm64`
- **Use case**: Raspberry Pi 5, ARM-based servers

## Quick Start

### Build for All Platforms
```bash
make build-all
```

### Build for Specific Platform
```bash
# For your MacBook
make build-macbook

# For Linux servers
make build-linux

# For Raspberry Pi 5
make build-pi5
```

### Custom Platform Build
```bash
# Windows example
GOOS=windows GOARCH=amd64 make build

# Custom Linux ARM
GOOS=linux GOARCH=arm make build
```

## Docker Images

The CI/CD automatically builds multi-platform Docker images:
- `linux/amd64` - for standard Linux
- `linux/arm64` - for ARM-based systems (including Pi5)

Pull the image:
```bash
docker pull ghcr.io/mgeorge67701/provider-nutanix:latest
```

## CI/CD Support

The GitHub Actions workflow automatically:
1. ✅ Builds binaries for all platforms
2. ✅ Creates multi-platform Docker images
3. ✅ Packages for Crossplane
4. ✅ Publishes to GitHub Releases
5. ✅ Publishes to Upbound Marketplace

## Verification

Check what you built:
```bash
# List all binaries
ls -la bin/

# Check binary architectures
file bin/provider-*
```

Expected output:
```
bin/provider-darwin-arm64: Mach-O 64-bit executable arm64
bin/provider-linux-amd64:  ELF 64-bit LSB executable, x86-64, statically linked
bin/provider-linux-arm64:  ELF 64-bit LSB executable, ARM aarch64, statically linked
```

## Help

See all available build targets:
```bash
make help
```
