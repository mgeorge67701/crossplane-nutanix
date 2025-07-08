generate:
	@echo "No code generation needed"

build:
	go build -o bin/provider ./cmd/provider

package-dir:
	@if [ -f package ]; then rm -f package; fi
	@mkdir -p package
