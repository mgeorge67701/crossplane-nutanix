# Crossplane Nutanix Provider

A [Crossplane](https://crossplane.io/) provider for managing Nutanix resources. This provider enables you to provision and manage Nutanix virtual machines directly from Kubernetes using Crossplane's declarative approach.

## Features

- **Virtual Machine Management**: Create, update, and delete Nutanix VMs
- **Multi-Datacenter Support**: Configure different Prism Central endpoints for different datacenters
- **Dynamic Resource Resolution**: Automatically resolve cluster, subnet, and image UUIDs from names
- **Flexible Authentication**: Support for datacenter-specific credentials
- **Line of Business (LoB) Validation**: Optional validation of LoB fields for compliance
- **Additional Disks**: Support for attaching multiple disks to VMs
- **External Facts**: Attach custom metadata to VMs

## Quick Start

### 1. Install the Provider

```bash
kubectl apply -f https://raw.githubusercontent.com/mgeorge67701/crossplane-nutanix/main/package/crossplane.yaml
```

### 2. Create a ProviderConfig

Create a secret with your Nutanix credentials:

```bash
kubectl create secret generic nutanix-creds-default \
  --from-literal=credentials='{"username":"admin","password":"your-password"}' \
  -n crossplane-system
```

Apply the ProviderConfig:

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
      name: nutanix-creds-default
      key: credentials
  prismCentralEndpoints:
    dc-alpha: "https://pc-alpha.example.com:9440"
```

### 3. Create a Virtual Machine

```yaml
apiVersion: nutanix.crossplane.io/v1alpha1
kind: VirtualMachine
metadata:
  name: my-vm
spec:
  name: "my-crossplane-vm"
  numVcpus: 2
  memorySizeMib: 4096
  clusterName: "my-cluster"
  datacenter: "dc-alpha"
  imageName: "ubuntu-22.04-cloud"
  subnetName: "my-subnet"
  providerConfigRef:
    name: default
```

## Examples

The `examples/` directory contains comprehensive examples:

### Basic Virtual Machine

- **File**: [`examples/virtualmachine.yaml`](examples/virtualmachine.yaml)
- **Description**: Simple VM with basic configuration

### Advanced Virtual Machine

- **File**: [`examples/virtualmachine-advanced.yaml`](examples/virtualmachine-advanced.yaml)
- **Description**: VM with additional disks and external facts

### Full ProviderConfig

- **File**: [`examples/providerconfig-all-features.yaml`](examples/providerconfig-all-features.yaml)
- **Description**: Complete ProviderConfig showing all available features

### Network Details ConfigMap

- **File**: [`examples/network-details-configmap.yaml`](examples/network-details-configmap.yaml)
- **Description**: Example ConfigMap for network configuration data

## Configuration

### ProviderConfig Options

| Field | Description | Required |
|-------|-------------|----------|
| `credentials` | Default authentication credentials | Yes |
| `allowedLobs` | List of allowed Line of Business values | No |
| `isLobMandatory` | Whether LoB field is required for VMs | No |
| `prismCentralEndpoints` | Map of datacenter names to PC endpoints | No |
| `datacenterCredentials` | Datacenter-specific credentials | No |
| `enableAvailabilityZoneMapping` | Enable AZ to cluster mapping | No |
| `availabilityZoneMappingURL` | URL for AZ mapping CSV | No |

### VirtualMachine Spec Options

| Field | Description | Required |
|-------|-------------|----------|
| `name` | VM name in Nutanix | Yes |
| `numVcpus` | Number of vCPUs | Yes |
| `memorySizeMib` | Memory size in MiB | Yes |
| `clusterName` or `clusterUuid` | Target cluster | Yes (one of) |
| `subnetName` or `subnetUuid` | Network subnet | No |
| `imageName` or `imageUuid` | Base image | No |
| `datacenter` | Datacenter for PC selection | No |
| `lob` | Line of Business | No |
| `additionalDisks` | Extra disks to attach | No |
| `externalFacts` | Custom metadata | No |
| `providerConfigRef` | Reference to ProviderConfig | No |

## Resource Resolution

The provider can dynamically resolve UUIDs from names:

- **Clusters**: Specify `clusterName` instead of `clusterUuid`
- **Subnets**: Specify `subnetName` instead of `subnetUuid`
- **Images**: Specify `imageName` instead of `imageUuid` (supports partial names)

When using names, the provider will query the appropriate Prism Central to find matching resources.

## Multi-Datacenter Support

Configure multiple Prism Central endpoints:

```yaml
spec:
  prismCentralEndpoints:
    dc-alpha: "https://pc-alpha.example.com:9440"
    dc-beta: "https://pc-beta.example.com:9440"
  datacenterCredentials:
    dc-beta:
      source: Secret
      secretRef:
        name: nutanix-creds-beta
        key: credentials
```

VMs can specify which datacenter to use:

```yaml
spec:
  datacenter: "dc-beta"  # Uses pc-beta.example.com and specific credentials
```

## Development

### Prerequisites

- Go 1.21+
- Docker
- kubectl
- Crossplane CLI (`kubectl crossplane`)

### Building

```bash
# Generate CRDs
make generate-crds

# Build provider binary
make build

# Build and push container
make docker-build docker-push IMG=your-registry/provider-nutanix:latest
```

### Testing

```bash
# Run unit tests
make test

# Run controller locally
make run
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Run `make test` and `make lint`
6. Submit a pull request

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/mgeorge67701/crossplane-nutanix/issues)
- **Discussions**: [GitHub Discussions](https://github.com/mgeorge67701/crossplane-nutanix/discussions)
- **Crossplane Community**: [Crossplane Slack](https://slack.crossplane.io/)
