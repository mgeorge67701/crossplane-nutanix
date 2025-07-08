# Nutanix Crossplane Provider

A Crossplane provider for managing Nutanix infrastructure resources through Kubernetes APIs.

[![CI](https://github.com/mgeorge67701/provider-nutanix/actions/workflows/ci.yml/badge.svg)](https://github.com/mgeorge67701/provider-nutanix/actions/workflows/ci.yml)
[![Upbound Marketplace](https://img.shields.io/badge/Upbound-Marketplace-blue)](https://marketplace.upbound.io/providers/mgeorge67701/provider-nutanix)

## Features

- **Virtual Machines**: Create and manage Nutanix VMs with configurable CPU, memory, and storage
- **Provider Configuration**: Secure authentication with Nutanix Prism Central
- **Crossplane Integration**: Full integration with Crossplane compositions and composite resources

## Quick Start

### Prerequisites

- Kubernetes cluster with [Crossplane](https://crossplane.io/) installed
- Nutanix Prism Central access with admin credentials

### Installation

Install the provider from Upbound Marketplace:

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

### Configuration

Create a secret with your Nutanix credentials:

```bash
kubectl create secret generic nutanix-creds -n crossplane-system \
  --from-literal=credentials='{"endpoint":"https://prism-central.example.com:9440","username":"admin","password":"your-password"}'
```

Create a ProviderConfig:

```yaml
apiVersion: nutanix.crossplane.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: nutanix-creds
      key: credentials
```

## Usage Examples

### Create a Virtual Machine

```yaml
apiVersion: nutanix.crossplane.io/v1alpha1
kind: VirtualMachine
metadata:
  name: example-vm
spec:
  name: "my-crossplane-vm"
  numVcpus: 2
  memorySizeMib: 4096
  clusterUuid: "00000000-0000-0000-0000-000000000000"  # Replace with your cluster UUID
  subnetUuid: "11111111-1111-1111-1111-111111111111"   # Replace with your subnet UUID
  imageUuid: "22222222-2222-2222-2222-222222222222"    # Replace with your image UUID
```

## Finding UUIDs

To find the required UUIDs for your Nutanix environment:

- **Cluster UUID**: Prism Central → Home → Infrastructure → Clusters
- **Subnet UUID**: Prism Central → Network & Security → Subnets
- **Image UUID**: Prism Central → Compute & Storage → Images

## Examples

Complete examples are available in the [`examples/`](./examples) directory:

- Basic VirtualMachine and ProviderConfig examples
- Advanced Composition and XRD patterns
- Automated setup script for quick installation

## Resources

### VirtualMachine

The VirtualMachine resource allows you to create and manage Nutanix VMs with the following specifications:

- **CPU**: Configure number of vCPUs
- **Memory**: Set memory size in MiB
- **Networking**: Connect to specific subnets
- **Storage**: Use specific disk images

### ProviderConfig

The ProviderConfig resource configures authentication to your Nutanix cluster:

- **Secret-based credentials**: Secure credential storage
- **Endpoint configuration**: Prism Central URL
- **Multiple configurations**: Support for multiple Nutanix environments

## Development

### Building the Provider

```bash
make build
```

### Testing

```bash
make test
```

### Creating a Package

```bash
make copy-provider
up xpkg build --package-root=package --output=provider-nutanix.xpkg
```

## CI/CD

This provider includes a comprehensive CI/CD pipeline that:

- ✅ **Lints and tests** Go code
- ✅ **Builds multi-platform binaries** (Linux, macOS on amd64/arm64)
- ✅ **Creates Crossplane packages** (.xpkg files)
- ✅ **Publishes to GitHub Releases** with automated release notes
- ✅ **Publishes to Upbound Marketplace** for easy installation

## Marketplace

This provider is available on Upbound Marketplace:

🏪 **[Upbound Marketplace](https://marketplace.upbound.io/providers/mgeorge67701/provider-nutanix)**

Install directly with:
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

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
