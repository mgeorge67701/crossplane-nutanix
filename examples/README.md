# Crossplane Nutanix Provider Examples

This directory contains comprehensive examples for the Crossplane Nutanix Provider, including both basic usage and advanced patterns.

## Basic Examples (also in package)

- **`providerconfig.yaml`** - Provider configuration with credentials setup
- **`virtualmachine.yaml`** - Basic virtual machine resource example
- **`setup.sh`** - Automated setup script for complete installation

## Advanced Examples

- **`xrd.yaml`** - Composite Resource Definition for reusable VM templates
- **`composition.yaml`** - Composition with size-based VM provisioning (small/medium/large)
- **`claim.yaml`** - Example showing how to use composite resources

## Quick Start

1. **Install the Provider**:

   ```bash
   kubectl apply -f - <<EOF
   apiVersion: pkg.crossplane.io/v1
   kind: Provider
   metadata:
     name: provider-nutanix
   spec:
     package: xpkg.upbound.io/mgeorge67701/provider-nutanix:latest
   EOF
   ```

2. **Run the setup script**:

   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

3. **Or manually configure**:

   ```bash
   # Create credentials
   kubectl create secret generic nutanix-creds -n crossplane-system \
     --from-literal=credentials='{"endpoint":"https://prism-central.example.com:9440","username":"admin","password":"your-password"}'

   # Apply provider configuration
   kubectl apply -f providerconfig.yaml

   # Create a VM (update UUIDs first)
   kubectl apply -f virtualmachine.yaml
   ```

## Advanced Usage

For advanced usage with Compositions and Composite Resources:

1. **Apply the XRD and Composition**:

   ```bash
   kubectl apply -f xrd.yaml
   kubectl apply -f composition.yaml
   ```

2. **Use the Composite Resource**:

   ```bash
   # Update UUIDs in claim.yaml first
   kubectl apply -f claim.yaml
   ```

## Finding Required UUIDs

To find the required UUIDs for your Nutanix environment:

### Cluster UUID

- **API**: `GET /api/nutanix/v3/clusters/list`
- **Prism Central**: Home > Infrastructure > Clusters

### Subnet UUID

- **API**: `GET /api/nutanix/v3/subnets/list`
- **Prism Central**: Network & Security > Subnets

### Image UUID

- **API**: `GET /api/nutanix/v3/images/list`
- **Prism Central**: Compute & Storage > Images

## Additional Resources

- [Crossplane Documentation](https://docs.crossplane.io/)
- [Nutanix Developer Portal](https://www.nutanix.dev/)
- [Provider Source Code](https://github.com/mgeorge67701/provider-nutanix)

## Note on Advanced Examples

The advanced examples (XRD, Composition, Claim) demonstrate how to create reusable templates and abstractions. However, these require additional setup and are not included in the basic provider package to avoid validation issues during package building.
