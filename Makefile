# Crossplane Nutanix Provider Makefile
#
# Usage examples:
#   make multi-build                    # Build v0.3.6 (default version)
#   make multi-build VERSION=v0.3.7     # Build with custom version
#   make version-info                   # Show current version settings

# Variables
REGISTRY ?= ghcr.io/mgeorge67701
PROJECT_NAME ?= provider-nutanix
VERSION ?= v0.3.6
PLATFORMS ?= linux/amd64,linux/arm64

# Docker images
IMG ?= $(REGISTRY)/$(PROJECT_NAME):$(VERSION)
CONTROLLER_IMG ?= $(REGISTRY)/$(PROJECT_NAME):$(VERSION)

# Crossplane package
XPKG_FILE ?= $(PROJECT_NAME)-$(VERSION).xpkg

.PHONY: help
help: ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Development

.PHONY: test
test: ## Run unit tests
	go test ./...

.PHONY: fmt
fmt: ## Format Go code
	go fmt ./...

.PHONY: vet
vet: ## Run go vet
	go vet ./...

.PHONY: lint
lint: ## Run golangci-lint (requires golangci-lint to be installed)
	golangci-lint run

.PHONY: run
run: ## Run the provider locally
	go run cmd/provider/main.go --debug

##@ Building

.PHONY: build
build: ## Build the provider binary for current platform
	CGO_ENABLED=0 go build \
		-ldflags='-w -s -extldflags "-static"' \
		-a -installsuffix cgo \
		-o provider ./cmd/provider

.PHONY: build-linux-amd64
build-linux-amd64: ## Build the provider binary for Linux AMD64
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
		-ldflags='-w -s -extldflags "-static"' \
		-a -installsuffix cgo \
		-o provider-linux-amd64 ./cmd/provider

.PHONY: build-linux-arm64
build-linux-arm64: ## Build the provider binary for Linux ARM64
	CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build \
		-ldflags='-w -s -extldflags "-static"' \
		-a -installsuffix cgo \
		-o provider-linux-arm64 ./cmd/provider

.PHONY: docker-build
docker-build: ## Build the Docker image for current platform
	docker build -t $(IMG) .

.PHONY: docker-build-multiplatform
docker-build-multiplatform: ## Build multi-platform image without pushing
	docker buildx build --platform $(PLATFORMS) -t $(IMG) .

.PHONY: docker-push
docker-push: ## Push the Docker image
	docker push $(IMG)

.PHONY: docker-buildx
docker-buildx: ## Build and push multi-platform controller image
	docker buildx build --platform $(PLATFORMS) -t $(CONTROLLER_IMG) --push .

.PHONY: docker-buildx-load
docker-buildx-load: ## Build multi-platform image and load to local Docker
	docker buildx build --platform $(PLATFORMS) -t $(IMG) --load .

.PHONY: docker-buildx-inspect
docker-buildx-inspect: ## Inspect the multi-platform image
	docker buildx imagetools inspect $(IMG)

##@ Crossplane Package

.PHONY: xpkg-build
xpkg-build: ## Build the Crossplane package
	up xpkg build --package-root=crossplane-package --controller=$(CONTROLLER_IMG) -o $(XPKG_FILE)

.PHONY: xpkg-push
xpkg-push: ## Push the Crossplane package to GHCR
	up xpkg push $(IMG) -f $(XPKG_FILE)

.PHONY: xpkg-push-upbound
xpkg-push-upbound: ## Push the Crossplane package to Upbound Registry
	up xpkg push xpkg.upbound.io/mgeorge67701/provider-nutanix:$(VERSION) -f $(XPKG_FILE)

.PHONY: xpkg-push-all
xpkg-push-all: xpkg-push xpkg-push-upbound ## Push the Crossplane package to both registries

##@ Multi-Platform

.PHONY: build-all-platforms
build-all-platforms: build-linux-amd64 build-linux-arm64 ## Build binaries for all platforms

.PHONY: multi-build
multi-build: docker-build-multiplatform ## Build multi-platform Docker images (no push)

.PHONY: multi-build-push
multi-build-push: docker-buildx ## Build and push multi-platform Docker images

.PHONY: multi-build-test
multi-build-test: ## Build multi-platform images and test locally
	docker buildx build --platform $(PLATFORMS) -t $(IMG)-test --load .
	docker run --rm $(IMG)-test --version || echo "Testing image functionality"

.PHONY: multi-inspect
multi-inspect: ## Inspect multi-platform image details
	docker buildx imagetools inspect $(IMG) || echo "Image not found in registry"

.PHONY: version-info
version-info: ## Show current version information
	@echo "Current version: $(VERSION)"
	@echo "Registry: $(REGISTRY)"
	@echo "Image: $(IMG)"
	@echo "Controller Image: $(CONTROLLER_IMG)"
	@echo "Package File: $(XPKG_FILE)"

##@ Release

.PHONY: release
release: docker-buildx xpkg-build xpkg-push-all ## Build and push everything for a release
	@echo "Released controller: $(CONTROLLER_IMG)"
	@echo "Released package: $(IMG)"
	@echo "Released to Upbound: xpkg.upbound.io/mgeorge67701/provider-nutanix:$(VERSION)"

.PHONY: release-local
release-local: build-all-platforms docker-build-multiplatform ## Build everything locally without pushing
	@echo "Built for platforms: $(PLATFORMS)"
	@echo "Local image: $(IMG)"

##@ Installation

.PHONY: install
install: ## Install the provider in Kubernetes
	kubectl apply -f - <<EOF
	apiVersion: pkg.crossplane.io/v1
	kind: Provider
	metadata:
	  name: mgeorge67701-provider-nutanix
	spec:
	  package: $(IMG)
	  packagePullPolicy: Always
	EOF

.PHONY: uninstall
uninstall: ## Uninstall the provider from Kubernetes
	kubectl delete provider.pkg.crossplane.io mgeorge67701-provider-nutanix

.PHONY: status
status: ## Check provider status
	@echo "=== Provider Status ==="
	kubectl get providers.pkg.crossplane.io -n crossplane-system
	@echo "=== Provider Revisions ==="
	kubectl get providerrevisions.pkg.crossplane.io -o wide
	@echo "=== Provider Pods ==="
	kubectl get pods -n crossplane-system | grep nutanix
	@echo "=== CRDs ==="
	kubectl get crd | grep nutanix

##@ Cleanup

.PHONY: clean
clean: ## Clean build artifacts
	rm -f provider *.xpkg