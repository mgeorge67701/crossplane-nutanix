# Crossplane Nutanix Provider Examples

This directory contains example YAML manifests to help you get started with the Crossplane Nutanix Provider.

## Quick Start

1. **Install the Provider**:

   ```bash
   kubectl apply -f - <<EOF
   apiVersion: pkg.crossplane.io/v1
   kind: Provider
   metadata:
     name: provider-nutanix
   spec:
     package: xpkg.upbound.io/mgeorge67701/provider-nutanix:v1.0.3
   EOF
   ```

2. **Configure Provider Credentials**:

   First, create a secret with your Nutanix credentials:

   ```bash
   kubectl create secret generic nutanix-creds -n crossplane-system \
     --from-literal=credentials='{"endpoint":"https://prism-central.example.com:9440","username":"admin","password":"your-password"}'
   ```

   Then apply the provider configuration:

   ```bash
   kubectl apply -f examples/providerconfig.yaml
   ```

3. **Create a Virtual Machine**:

   Update the UUIDs in `examples/virtualmachine.yaml` with your actual Nutanix cluster, subnet, and image UUIDs, then apply:

   ```bash
   kubectl apply -f examples/virtualmachine.yaml
   ```

## Finding Required UUIDs

To find the required UUIDs for your Nutanix environment, you can use the Nutanix REST API or Prism Central UI:

### Cluster UUID

- **API**: `GET /api/nutanix/v3/clusters/list`
- **Prism Central**: Home > Infrastructure > Clusters

### Subnet UUID

- **API**: `GET /api/nutanix/v3/subnets/list`
- **Prism Central**: Network & Security > Subnets

### Image UUID

- **API**: `GET /api/nutanix/v3/images/list`
- **Prism Central**: Compute & Storage > Images

## Files in this Directory

- `providerconfig.yaml` - Provider configuration with credentials
- `virtualmachine.yaml` - Example virtual machine resource
- `composition.yaml` - Example composition for reusable VM templates
- `xrd.yaml` - Example composite resource definition

## Additional Resources

- [Crossplane Documentation](https://docs.crossplane.io/)
- [Nutanix Developer Portal](https://www.nutanix.dev/)
- [Provider Source Code](https://github.com/mgeorge67701/provider-nutanix)
