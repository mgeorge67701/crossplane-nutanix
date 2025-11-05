# Crossplane Nutanix Provider

![Provider Logo](icons/icon.svg)

A [Crossplane](https://crossplane.io/) provider for managing Nutanix resources. This provider enables you to provision and manage Nutanix virtual machines directly from Kubernetes using Crossplane's declarative approach.

## Features

- **Virtual Machine Management**: Create, update, and delete Nutanix VMs
- **Multi-Architecture Support**: Native support for AMD64 and ARM64 platforms (Intel/AMD, Apple Silicon, AWS Graviton, Raspberry Pi 5)
- **Multi-Registry Publishing**: Available on both GitHub Container Registry and Upbound Marketplace
- **Multi-Datacenter Support**: Configure different Prism Central endpoints for different datacenters
- **Dynamic Resource Resolution**: Automatically resolve cluster, subnet, and image UUIDs from names
- **Flexible Authentication**: Support for datacenter-specific credentials
- **Line of Business (LoB) Validation**: Optional validation of LoB fields for compliance
- **Additional Disks**: Support for attaching multiple disks to VMs
- **External Facts**: Attach custom metadata to VMs

## Quick Start

### 1. Install the Provider

**Option 1: From Upbound Marketplace (Recommended for Community)**

```bash
kubectl crossplane install provider xpkg.upbound.io/mgeorge67701/provider-nutanix:v0.3.6
```

**Option 2: From GitHub Container Registry**

```bash
kubectl crossplane install provider ghcr.io/mgeorge67701/provider-nutanix:v0.3.6
```

**Option 3: Using kubectl manifest**

```bash
kubectl apply -f - <<EOF
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-nutanix
spec:
  package: xpkg.upbound.io/mgeorge67701/provider-nutanix:v0.3.6
  packagePullPolicy: Always
EOF
```

**Verify Installation**

```bash
# Check provider status
kubectl get providers.pkg.crossplane.io -n crossplane-system

# Check provider pod is running
kubectl get pods -n crossplane-system | grep nutanix

# Check CRDs are installed
kubectl get crd | grep nutanix
```

Expected output:
```
NAME                            INSTALLED   HEALTHY   PACKAGE
mgeorge67701-provider-nutanix   True        True      ghcr.io/mgeorge67701/provider-nutanix:v0.3.0

providerconfigs.nutanix.crossplane.io
virtualmachines.nutanix.crossplane.io
```

### 2. Create a ProviderConfig

Create a secret with your Nutanix credentials for each prism central endpoint.

```bash
kubectl create secret generic nutanix-creds-alpha \
  --from-literal=credentials='{"username":"admin-alpha","password":"alpha-password"}' \
  -n crossplane-system

kubectl create secret generic nutanix-creds-beta \
  --from-literal=credentials='{"username":"admin-beta","password":"beta-password"}' \
  -n crossplane-system
```

or

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: nutanix-creds-alpha
  namespace: crossplane-system
type: Opaque
stringData:
  credentials: '{"username":"admin-alpha","password":"alpha-password"}'

apiVersion: v1
kind: Secret
metadata:
  name: nutanix-creds-beta
  namespace: crossplane-system
 type: Opaque
 stringData:
   credentials: '{"username":"admin-beta","password":"beta-password"}'
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
    dc-beta: "https://pc-beta.example.com:9440"
  # Define datacenter-specific credentials
  datacenterCredentials:
    dc-alpha:
      source: Secret
      secretRef:
        namespace: crossplane-system
        name: nutanix-creds-alpha
        key: credentials
    dc-beta:
      source: Secret
      secretRef:
        namespace: crossplane-system
        name: nutanix-creds-beta
        key: credentials
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
  network: "network-details" # References the ConfigMap named 'network-details'
  providerConfigRef:
    name: default
```

## Examples

The `examples/` directory contains comprehensive examples.

### Basic Virtual Machine

**File**: `examples/virtualmachine.yaml`
**Description**: Simple VM with basic configuration.

```yaml
apiVersion: nutanix.crossplane.io/v1alpha1
kind: VirtualMachine
metadata:
  name: example-vm
spec:
  name: "my-crossplane-vm"
  numVcpus: 2
  memorySizeMib: 4096
  clusterName: "aza-ntnx-01"  # Specify the cluster name to fetch details dynamically
  datacenter: "dc-alpha" # Specify the datacenter for Prism Central endpoint selection
  imageName: "ubuntu-22.04-cloud" # Can be a full or partial image name (e.g., "rhel8", "win2022"). The provider will dynamically resolve the image UUID from Nutanix Prism Central, selecting the latest matching image if a partial name is provided.
  network: "network-details" # The provider will fetch network details from the ConfigMap named 'network-details'.
  lob: "CLOUD" # Must be one of the allowedLobs in ProviderConfig if mandatory
  providerConfigRef:
    name: all-features-config
```

### Advanced Virtual Machine

**File**: `examples/virtualmachine-advanced.yaml`
**Description**: VM with additional disks and external facts.

```yaml
apiVersion: nutanix.crossplane.io/v1alpha1
kind: VirtualMachine
metadata:
  name: example-vm-advanced
spec:
  name: "my-advanced-crossplane-vm"
  numVcpus: 4
  memorySizeMib: 8192
  clusterName: "aza-ntnx-01"
  datacenter: "dc-beta" # Specify the datacenter for Prism Central endpoint selection
  imageName: "rhel8" # Example: partial image name, provider selects latest RHEL 8
  network: "network-details"
  lob: "SECURITY" # Example: another valid LoB from ProviderConfig
  additionalDisks:
    - deviceIndex: 1
      sizeGb: 50
      imageName: "data-disk-template" # Optional: use an image for the disk
    - deviceIndex: 2
      sizeGb: 100
  externalFacts:
    environment: "production"
    application: "webserver"
    owner: "devops-team"
  providerConfigRef:
    name: all-features-config
```

### Full ProviderConfig

**File**: `examples/providerconfig-all-features.yaml`
**Description**: Complete ProviderConfig showing all available features.

```yaml
apiVersion: nutanix.crossplane.io/v1beta1
kind: ProviderConfig
metadata:
  name: all-features-config
spec:
  # Default credentials for the provider. These are used if no datacenter-specific
  # credentials are provided or if no datacenter is specified in the VM spec.
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: nutanix-creds-default
      key: credentials

  # Configure LoB (Line of Business) validation for VirtualMachines.
  # If 'isLobMandatory' is true, the 'lob' field in VirtualMachine spec is required.
  # If 'lob' is provided, its value must be one of the 'allowedLobs'.
  allowedLobs:
    - CLOUD
    - SECURITY
    - DEV
    - PROD
  isLobMandatory: true # Set to false if LoB field should be optional

  # Define Prism Central endpoints for different datacenters.
  # The provider will use the 'datacenter' field in the VirtualMachine spec
  # to select the appropriate endpoint from this map.
  prismCentralEndpoints:
    dc-alpha: "https://pc-alpha.example.com:9440"
    dc-beta: "https://pc-beta.example.com:9440"
    dc-gamma: "https://pc-gamma.example.com:9440"

  # Define datacenter-specific credentials.
  # These credentials will override the default 'credentials' for the specified datacenter.
  # If a datacenter is specified in the VM, the provider will first look for
  # credentials here. If not found, it falls back to the default credentials.
  datacenterCredentials:
    dc-alpha:
      source: Secret
      secretRef:
        namespace: crossplane-system
        name: nutanix-creds-alpha
        key: credentials
    dc-beta:
      source: Secret
      secretRef:
        namespace: crossplane-system
        name: nutanix-creds-beta
        key: credentials
```

### Network Details ConfigMap

**File**: `examples/network-details-configmap.yaml`
**Description**: Example ConfigMap for network configuration data.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: network-details
  namespace: crossplane-system
data:
  network-details.json: |
    {
      "domain": "example.com",
      "nameserver": "192.168.1.1",
      "gateway": "192.168.1.254",
      "network": "192.168.1.0/24",
      "subnet": "example-subnet",
      "email": "admin@example.com",
      "puppet_master": "puppet.example.com",
      "network_management_server": "nms.example.com",
      "foreman_host": "foreman.example.com",
      "allowed_repos": [
        "test1",
        "test2"
      ]
    }
```

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

## Architecture Diagram

Below is the architecture of the Crossplane Nutanix Provider:

![Architecture Diagram](icons/architecture.png)

This diagram shows how Crossplane, your custom Nutanix provider controller, and Kubernetes resources interact to provision Nutanix VMs. The controller reads custom resources and network details, validates and resolves them, and provisions VMs via Nutanix Prism Central APIs.

---

## Development

### Prerequisites

- Go 1.21+
- Docker
- kubectl
- Crossplane CLI (`kubectl crossplane`)

### Multi-Architecture Building

This provider supports **AMD64** and **ARM64** architectures, working natively on Intel/AMD systems, Apple Silicon Macs, AWS Graviton instances, and Raspberry Pi 5.

#### Quick Build Commands

```bash
# Build multi-arch images locally (no push)
make multi-build

# Build and push to registry
make multi-build-push

# Test multi-arch build
make multi-build-test

# Show version info
make version-info
```

#### Manual Multi-Architecture Build

```bash
# Set your version
export VERSION=v0.3.6

# Build and push multi-arch image
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag ghcr.io/mgeorge67701/provider-nutanix:${VERSION} \
  --push .

# Build Crossplane package
up xpkg build \
  --package-root=package \
  --controller=ghcr.io/mgeorge67701/provider-nutanix:${VERSION} \
  -o provider-nutanix-${VERSION}.xpkg

# Push to both registries
up xpkg push ghcr.io/mgeorge67701/provider-nutanix:${VERSION} \
  -f provider-nutanix-${VERSION}.xpkg
up xpkg push xpkg.upbound.io/mgeorge67701/provider-nutanix:${VERSION} \
  -f provider-nutanix-${VERSION}.xpkg
```

#### Verify Multi-Architecture Support

```bash
# Inspect multi-arch manifest
docker buildx imagetools inspect ghcr.io/mgeorge67701/provider-nutanix:v0.3.6

# Should show both:
# Platform: linux/amd64
# Platform: linux/arm64
```

#### Supported Platforms

- **linux/amd64** - Intel/AMD 64-bit (traditional servers, desktops)
- **linux/arm64** - ARM 64-bit (Apple Silicon, AWS Graviton, Raspberry Pi 5)

When deployed to Kubernetes, the correct architecture is automatically selected for each node.

### Testing

```bash
# Run unit tests
go test ./...

# Run controller locally (requires Kubernetes cluster and KUBECONFIG)
go run cmd/provider/main.go --debug
```

### Releasing

**Automated Release (Recommended):**
```bash
# Create and push a version tag - CI/CD handles the rest
git tag v1.0.0
git push origin v1.0.0
```

**Manual Release:**
```bash
# Build and push to both registries
export VERSION=v1.0.0
make release VERSION=${VERSION}

# Or step by step:
make multi-build-push VERSION=${VERSION}
make xpkg-build VERSION=${VERSION}
make xpkg-push-all VERSION=${VERSION}  # Pushes to both GHCR and Upbound
```

**Registry Locations:**
- **GitHub Container Registry**: `ghcr.io/mgeorge67701/provider-nutanix:VERSION`
- **Upbound Marketplace**: `xpkg.upbound.io/mgeorge67701/provider-nutanix:VERSION`

The GitHub Actions workflow automatically builds multi-architecture images and publishes to both registries when you push a version tag, making the provider available to the community through the Upbound Marketplace.

#### Setting up Upbound Credentials

To enable automatic publishing to Upbound Marketplace, add these GitHub repository secrets:

1. Go to your GitHub repository → Settings → Secrets and Variables → Actions
2. Add these secrets:
   - `UPBOUND_ACCESS_ID`: Your Upbound access ID
   - `UPBOUND_TOKEN`: Your Upbound token

Get your credentials from [Upbound Console](https://console.upbound.io/) → Account → API Tokens.

## Troubleshooting

### Provider Pod Shows "CreateContainerError: no command specified"

This error occurs when the Crossplane package (xpkg) is built incorrectly. The issue is usually:

1. **Hardcoded controller image in crossplane.yaml**: The `spec.controller.image` field should NOT be present in `package/crossplane.yaml`
2. **Incorrect xpkg build**: Use `up xpkg build --controller=<image>` to properly reference the controller image
3. **Broken Docker image**: Ensure your Dockerfile has proper `ENTRYPOINT` and `CMD` instructions
4. **Pipeline overwrites controller image**: In CI/CD, the xpkg build can overwrite the controller image if not done properly

**Solution (Multi-Architecture - Recommended)**:
```bash
# Use the multi-architecture build process (see Manual Building section above)
export VERSION=v0.3.0
make docker-buildx VERSION=${VERSION}  # Multi-arch controller image
make xpkg-build VERSION=${VERSION}     # Package with proper controller reference
make xpkg-push VERSION=${VERSION}      # Push package
```

**Solution (Single Architecture)**:
```bash
# 1. Remove spec.controller.image from package/crossplane.yaml
# 2. Build Docker image first
docker build -t ghcr.io/mgeorge67701/provider-nutanix:v1.0.0 .

# 3. Build xpkg with --controller flag
up xpkg build --package-root=package --controller=ghcr.io/mgeorge67701/provider-nutanix:v1.0.0 -o provider.xpkg

# 4. Push both
docker push ghcr.io/mgeorge67701/provider-nutanix:v1.0.0
up xpkg push ghcr.io/mgeorge67701/provider-nutanix:v1.0.0 -f provider.xpkg
```

### Provider Shows as Unhealthy

Check the provider revision status:
```bash
kubectl get providerrevisions.pkg.crossplane.io -o wide
kubectl describe providerrevision <revision-name>
```

### CRDs Not Installing

Ensure your CRD files are in the correct location and referenced properly in `package/crossplane.yaml`.

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
