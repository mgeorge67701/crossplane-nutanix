#!/bin/bash
set -e

# This script builds and pushes a Docker image with explicit ENTRYPOINT
# to fix the "no command specified" error

# Check if UPBOUND_ACCESS_ID and UPBOUND_TOKEN are set
if [ -z "$UPBOUND_ACCESS_ID" ] || [ -z "$UPBOUND_TOKEN" ]; then
  echo "Error: UPBOUND_ACCESS_ID and UPBOUND_TOKEN environment variables must be set"
  echo "Example: export UPBOUND_ACCESS_ID=your-username"
  echo "         export UPBOUND_TOKEN=your-token"
  exit 1
fi

# Login to Upbound registry
echo "Logging into Upbound registry..."
echo "$UPBOUND_TOKEN" | docker login xpkg.upbound.io -u "$UPBOUND_ACCESS_ID" --password-stdin

# Build the Docker image with explicit ENTRYPOINT
echo "Building Docker image using special Dockerfile..."
docker build -f Dockerfile.fix -t xpkg.upbound.io/mgeorge67701/provider-nutanix:latest .

# Verify the ENTRYPOINT is set correctly
echo "Verifying ENTRYPOINT..."
docker inspect xpkg.upbound.io/mgeorge67701/provider-nutanix:latest | grep -A 5 "Entrypoint"

# Push the image to the registry
echo "Pushing image to registry..."
docker push xpkg.upbound.io/mgeorge67701/provider-nutanix:latest

echo "Done! Image has been pushed with proper ENTRYPOINT."
echo "Now you can reinstall the provider with:"
echo "kubectl delete provider mgeorge67701-provider-nutanix -n crossplane-system"
echo "kubectl apply -f https://raw.githubusercontent.com/mgeorge67701/crossplane-nutanix/main/package/crossplane.yaml"
