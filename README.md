# Nutanix Provider for Crossplane

This repository contains a Crossplane provider for Nutanix infrastructure. It enables the provisioning and management of Nutanix resources through Kubernetes APIs.

## Features

- **Virtual Machines**: Create and manage Nutanix VMs
- **Storage**: Manage storage containers and volumes
- **Networks**: Configure virtual networks and subnets
- **Images**: Manage VM images and templates

## Quick Start

### Prerequisites

- Kubernetes cluster with Crossplane installed
- Nutanix Prism Central credentials

### Installation

1. Install the provider:
```bash
kubectl crossplane install provider crossplane/provider-nutanix:latest
```

2. Create a ProviderConfig:
```yaml
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-nutanix
spec:
  package: crossplane/provider-nutanix:latest
```

### Configuration

Create a secret with your Nutanix credentials:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: nutanix-creds
  namespace: crossplane-system
type: Opaque
data:
  credentials: |
    {
      "endpoint": "https://your-prism-central:9440",
      "username": "your-username",
      "password": "your-password",
      "insecure": true
    }
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
  forProvider:
    name: "crossplane-vm"
    numVcpus: 2
    memorySizeMib: 4096
    powerState: "ON"
    clusterReference:
      kind: "cluster"
      uuid: "your-cluster-uuid"
    diskList:
    - deviceProperties:
        deviceType: "DISK"
        diskAddress:
          deviceIndex: 0
          adapterType: "SCSI"
      diskSizeBytes: 107374182400  # 100GB
    nicList:
    - subnetReference:
        kind: "subnet"
        uuid: "your-subnet-uuid"
  providerConfigRef:
    name: default
```

## Development

### Building

```bash
make build
```

### Running Locally

```bash
make run
```

### Testing

```bash
make test
```

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
