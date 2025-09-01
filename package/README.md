# Crossplane Nutanix Provider Package

This package contains the Crossplane provider for managing Nutanix resources.

## Installation

Install using the Crossplane CLI:

```bash
kubectl crossplane install provider mgeorge67701/provider-nutanix:latest
```

Or apply the provider package directly:

```bash
kubectl apply -f https://raw.githubusercontent.com/mgeorge67701/crossplane-nutanix/main/package/crossplane.yaml
```

## Documentation

See the main [README](../README.md) for comprehensive documentation and examples.

## Supported Resources

- **VirtualMachine** (v1alpha1): Nutanix virtual machines with dynamic resource resolution
- **ProviderConfig** (v1beta1): Provider configuration with multi-datacenter support
