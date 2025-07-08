generate:
	@echo "No code generation needed"

build:
	go build -o bin/provider ./cmd/provider

package-dir:
	@if [ -f package ]; then rm -f package; fi
	@mkdir -p package

copy-provider: package-dir build
	cp bin/provider package/
	cp config/crd/nutanix.crossplane.io_*.yaml package/
	@if [ -d package/examples ]; then \
		echo "Examples already present in package directory"; \
	else \
		echo "Examples directory not found but will be included in package"; \
	fi
