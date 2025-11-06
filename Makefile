# Crossplane Nutanix Provider Makefile

# Variables
REGISTRY ?= ghcr.io/mgeorge67701
PROJECT_NAME ?= provider-nutanix
VERSION ?= latest
PLATFORMS ?= linux/amd64,linux/arm64

# Docker images
IMG ?= $(REGISTRY)/$(PROJECT_NAME):$(VERSION)
CONTROLLER_IMG ?= $(REGISTRY)/$(PROJECT_NAME):$(VERSION)-controller

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
build: ## Build the provider binary
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
		-ldflags='-w -s -extldflags "-static"' \
		-a -installsuffix cgo \
		-o provider ./cmd/provider

.PHONY: docker-build
docker-build: ## Build the Docker image
	docker build -t $(IMG) .

.PHONY: docker-push
docker-push: ## Push the Docker image
	docker push $(IMG)

.PHONY: docker-buildx
docker-buildx: ## Build and push multi-platform controller image
	docker buildx build --platform $(PLATFORMS) -t $(CONTROLLER_IMG) --push .

##@ Crossplane Package

.PHONY: xpkg-build
xpkg-build: ## Build the Crossplane package
	up xpkg build --package-root=crossplane-package --controller=$(CONTROLLER_IMG) -o $(XPKG_FILE)

.PHONY: xpkg-push
xpkg-push: ## Push the Crossplane package
	up xpkg push $(IMG) -f $(XPKG_FILE)

##@ Release

.PHONY: release
release: docker-buildx xpkg-build xpkg-push ## Build and push everything for a release
	@echo "Released controller: $(CONTROLLER_IMG)"
	@echo "Released package: $(IMG)"

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