# Nutanix Crossplane Provider

A Crossplane provider for managing Nutanix infrastructure resources through Kubernetes APIs.

[![CI](https://github.com/mgeorge67701/provider-nutanix/actions/workflows/ci.yml/badge.svg)](https://github.com/mgeorge67701/provider-nutanix/actions/workflows/ci.yml)
[![Upbound Marketplace](https://img.shields.io/badge/Upbound-Marketplace-blue)](https://marketplace.upbound.io/providers/mgeorge67701/provider-nutanix)

## Table of Contents
- [Features](#features)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage Examples](#usage-examples)
- [FAQ](#faq)
- [Development](#development)
- [CI/CD](#cicd)
- [Marketplace](#marketplace)
- [Contributing](#contributing)
- [License](#license)
- [Contact & Support](#contact--support)
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

Create a secret with your Nutanix credentials (e.g., `nutanix-creds-default`):

```bash
kubeclt create secret generic nutanix-creds-default -n crossplane-system --from-literal=credentials='{"endpoint":"https://<default-prism-central-endpoint>:9440","username":"<default-username>","password":"<default-password>","insecure":true}'
```

For datacenter-specific credentials (e.g., for `dc-alpha`):

```bash
kubeclt create secret generic nutanix-creds-alpha -n crossplane-system \
  --from-literal=credentials='{"endpoint":"https://pc-alpha.example.com:9440","username":"admin-alpha","password":"your-password-alpha","insecure":true}'
```

Create a ProviderConfig that combines all features, including LoB validation, dynamic endpoint selection, datacenter-specific credentials, and availability zone mapping. Here is a comprehensive example:

```yaml
apiVersion: nutanix.crossplane.io/v1beta1
kind: ProviderConfig
metadata:
  name: all-features-config
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: nutanix-creds-default
      key: credentials
  prismCentralEndpoints:
    dc-alpha:
      endpoint: https://pc-alpha.example.com:9440
      credentialsSecretRef:
        namespace: crossplane-system
        name: nutanix-creds-alpha
        key: credentials
    dc-beta:
      endpoint: https://pc-beta.example.com:9440
      credentialsSecretRef:
        namespace: crossplane-system
        name: nutanix-creds-beta
        key: credentials
  defaultDatacenter: dc-alpha
  allowedLoBs:
    - CLOUD
    - SECURITY
    - FINANCE
  isLoBMandatory: true
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
  # Optional: Enable dynamic availability zone mapping (set to true to use the mapping feature)
  enableAvailabilityZoneMapping: true
  # Optional: URL to a CSV file mapping availabilityZone to clusterName
  availabilityZoneMappingURL: https://example.com/az-to-cluster.csv
```


## Usage Examples

### Complete VirtualMachine Example

Below is a full example of a VirtualMachine resource using all common fields, including dynamic datacenter selection, LoB, additional disks, and external facts. You do **not** need to provide UUIDs or JSON files for normal use—just use names or partial names, and the provider will resolve everything automatically.

```yaml
apiVersion: nutanix.crossplane.io/v1alpha1
kind: VirtualMachine
metadata:
  name: example-vm
spec:
  providerConfigRef:
    name: all-features-config         # Reference to your ProviderConfig
  datacenter: dc-alpha               # (Optional) Must match a datacenter in ProviderConfig; otherwise, an error is returned
  name: my-crossplane-vm             # Name of the VM in Nutanix
  numVcpus: 4                        # Number of vCPUs
  memorySizeMib: 8192                # Memory in MiB (8 GB)
  # You can specify either availabilityZone or clusterName. If availabilityZone is set, it will be mapped to the correct cluster name automatically.
  availabilityZone: aza-ntnx-01 # (Optional) Will be mapped to clusterName automatically
  # clusterName: ch-08-vn-nutanix01  # (Optional) You can specify this directly instead
  subnetName: prod-subnet            # Subnet name (must match the network JSON/ConfigMap file name)
  imageName: ubuntu-22.04-cloud      # Image name (partial or full, provider picks latest match)
  lob: CLOUD                         # Line of Business (must match allowed values if validation enabled)
  additionalDisks:                   # (Optional) Attach extra disks
    - deviceIndex: 1
      sizeGb: 50
    - deviceIndex: 2
      sizeGb: 100
  externalFacts:                     # (Optional) Arbitrary key-value pairs for automation/config
    bt_product: inf
    environment: production
    owner: alice@example.com
```




**How it works:**

- `providerConfigRef.name`: Reference to your ProviderConfig (with credentials and endpoint info).
- `datacenter`: (Optional) If using multi-datacenter, selects which Prism Central to use.
- `availabilityZone`: (Optional) If set and `enableAvailabilityZoneMapping` is true, will be mapped to the correct cluster name automatically using the mapping CSV. If both `availabilityZone` and `clusterName` are set, `availabilityZone` takes precedence.
- `clusterName`, `imageName`: Use human-friendly names or partial names; the provider resolves UUIDs automatically.
- `subnetName`: The name of the subnet to use. This must match the network JSON/ConfigMap file name (e.g., `network-prod-subnet.json` for `subnetName: prod-subnet`). The provider will read the corresponding file for subnet details and access control (such as `allowed_repos`).
  - **All fields in the JSON file** (e.g., `gateway`, `nameserver`, `domain`, etc.) will be used to configure the VM's network if present, allowing you to fully define network settings per subnet.
- `lob`: Specify a valid Line of Business if required by your ProviderConfig.
- `additionalDisks` and `externalFacts`: Optional, for advanced VM customization.

**No JSON file is needed** for this example unless you want to provide custom network details or access control. If you do, ensure the file is mounted and named to match the `subnetName`.

---

> **Note:**
> - The dynamic availability zone mapping feature is opt-in. Set `enableAvailabilityZoneMapping: true` and provide a valid `availabilityZoneMappingURL` to use it. If not set, the provider defaults to normal behavior and expects `clusterName` to be specified directly.
> - This makes the provider general-purpose and not tied to any specific company or environment.

---

### ProviderConfig Example (Multi-Datacenter)

> 
> `datacenter 'dc-gamma' is not allowed. Allowed values: [dc-alpha dc-beta]`

```yaml
apiVersion: nutanix.crossplane.io/v1beta1
kind: ProviderConfig
metadata:
  name: all-features-config
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: nutanix-creds-default
      key: credentials
  prismCentralEndpoints:
    dc-alpha:
      endpoint: https://pc-alpha.example.com:9440
      credentialsSecretRef:
        namespace: crossplane-system
        name: nutanix-creds-alpha
        key: credentials
    dc-beta:
      endpoint: https://pc-beta.example.com:9440
      credentialsSecretRef:
        namespace: crossplane-system
        name: nutanix-creds-beta
        key: credentials
  defaultDatacenter: dc-alpha
  allowedLoBs:
    - CLOUD
    - SECURITY
    - FINANCE
  isLoBMandatory: true
  # Optional: URL to a CSV file mapping availabilityZone to clusterName
  availabilityZoneMappingURL: https://example.com/az-to-cluster.csv
```

> **Note:**
> - Only datacenters listed under `prismCentralEndpoints` are allowed. If you specify a `datacenter` in your VM spec that is not listed here, the provider will return an error like:
>   `datacenter 'dc-gamma' is not allowed. Allowed values: [dc-alpha dc-beta]`
> - If you set `availabilityZone` in your VM spec, the provider will fetch the mapping from the URL specified in `availabilityZoneMappingURL` and automatically set the correct `clusterName`. If both `availabilityZone` and `clusterName` are set, `availabilityZone` takes precedence.

---


## FAQ

**Q: How does the provider know which Prism Central to use?**
A: By the `datacenter` field in your VM spec, which must match one of the keys in your ProviderConfig's `prismCentralEndpoints`. If you specify a datacenter not listed, the provider will return an error and the VM will not be created.

**Q: How does availabilityZone mapping work?**
A: If you set `availabilityZone` in your VM spec, the provider will fetch a mapping table from the URL specified in `availabilityZoneMappingURL` in your ProviderConfig. It will then set the correct `clusterName` for you. If both `availabilityZone` and `clusterName` are set, `availabilityZone` takes precedence.

**Q: Do I need to specify UUIDs?**
A: No, just use names or partial names; the provider will resolve UUIDs automatically.

**Q: Do I need to mount a JSON file?**
A: No, unless you have a special use case for dynamic values or network details.

---

### More Examples

See the [`examples/`](./examples) directory for:
- [`providerconfig-all-features.yaml`](./examples/providerconfig-all-features.yaml): Full ProviderConfig with LoB validation and multi-datacenter.
- [`virtualmachine.yaml`](./examples/virtualmachine.yaml): Basic VM.
- [`virtualmachine-advanced.yaml`](./examples/virtualmachine-advanced.yaml): Advanced VM with disks and facts.

### Examples

Complete examples demonstrating all features are available in the [`examples/`](./examples) directory:

- [`providerconfig-all-features.yaml`](./examples/providerconfig-all-features.yaml): A comprehensive ProviderConfig example showcasing LoB validation, dynamic endpoint selection, and datacenter-specific credentials.
- [`virtualmachine.yaml`](./examples/virtualmachine.yaml): A basic VirtualMachine example.
- [`virtualmachine-advanced.yaml`](./examples/virtualmachine-advanced.yaml): An advanced VirtualMachine example including additional disks and external facts.

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

## Using a JSON File for Dynamic Values

You can store various dynamic values such as `clusterUuid`, `subnetUuid`, `imageUuid`, and others in a JSON file and mount it into the provider pod. The provider will read this file at runtime.

#### Example JSON File

```json
{
  "clusterUuid": "00000000-0000-0000-0000-000000000000",
  "subnetUuid": "11111111-1111-1111-1111-111111111111",
  "imageUuid": "22222222-2222-2222-2222-222222222222",
  "networkUuid": "33333333-3333-3333-3333-333333333333",
  "storageUuid": "44444444-4444-4444-4444-444444444444"
}
```

#### Mounting the JSON File

Create a ConfigMap with the JSON file:

```bash
kubectl create configmap dynamic-values -n crossplane-system \
  --from-file=dynamic-values.json=/path/to/dynamic-values.json
```

Update the provider deployment to mount the ConfigMap:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: provider-nutanix
spec:
  template:
    spec:
      containers:
      - name: provider
        volumeMounts:
        - name: dynamic-values
          mountPath: /etc/provider
      volumes:
      - name: dynamic-values
        configMap:
          name: dynamic-values
```

The provider will automatically read the JSON file from `/etc/provider/dynamic-values.json` and use the values dynamically.

## Using a JSON File for Network Details

You can store network-related values such as `domain`, `nameserver`, `gateway`, `network`, and others in a JSON file and mount it into the provider pod. The provider will read this file at runtime.


#### Example JSON File for Network Details (with Subnet Access Control)

```json
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

#### Subnet Access Control with `allowed_repos`

- If the `allowed_repos` field is present and contains one or more repo names, **only** VirtualMachine resources with a matching `repo` label (e.g., `repo: test1`) can use this subnet.
- If `allowed_repos` is missing or is an empty list, **any repo** (or a VM with no `repo` label) can use the subnet.
- If a VM tries to use a subnet with a non-matching `repo` label, the operation will be denied with an error.

**Example VirtualMachine with repo label:**

```yaml
apiVersion: nutanix.crossplane.io/v1alpha1
kind: VirtualMachine
metadata:
  name: example-vm
  labels:
    repo: test1   # This must match an entry in allowed_repos for the subnet
spec:
  subnetName: example-subnet
  # ...other fields...
```

**Summary:**
- Use `allowed_repos` in your subnet JSON to restrict which repos can deploy to that subnet.
- Omit or leave `allowed_repos` empty to allow all repos.

#### Mounting the JSON File for Network Details

Create a ConfigMap with the JSON file:

```bash
kubectl create configmap network-details -n crossplane-system \
  --from-file=network-details.json=/path/to/network-details.json
```

Update the provider deployment to mount the ConfigMap:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: provider-nutanix
spec:
  template:
    spec:
      containers:
      - name: provider
        volumeMounts:
        - name: network-details
          mountPath: /etc/provider
      volumes:
      - name: network-details
        configMap:
          name: network-details
```

The provider will automatically read the JSON file from `/etc/provider/network-details.json` and use the values dynamically.

## Nutanix Prism v3 API Calls

The Nutanix Prism v3 API provides a comprehensive set of endpoints for managing Nutanix infrastructure. Below are some key API calls:

### Virtual Machines

- **Create a VM**: `POST /vms`

- **Get VM Details**: `GET /vms/{uuid}`

- **Update a VM**: `PUT /vms/{uuid}`

- **Delete a VM**: `DELETE /vms/{uuid}`

### Subnets

- **Create a Subnet**: `POST /subnets`

- **Get Subnet Details**: `GET /subnets/{uuid}`

- **Update a Subnet**: `PUT /subnets/{uuid}`

- **Delete a Subnet**: `DELETE /subnets/{uuid}`

### Clusters

- **Get Cluster Details**: `GET /clusters/{uuid}`

- **List Clusters**: `POST /clusters/list`

### Images

- **Create an Image**: `POST /images`

- **Get Image Details**: `GET /images/{uuid}`

- **Update an Image**: `PUT /images/{uuid}`

- **Delete an Image**: `DELETE /images/{uuid}`

### VPN Gateways

- **Create a VPN Gateway**: `POST /vpn_gateways`

- **Get VPN Gateway Details**: `GET /vpn_gateways/{uuid}`

- **Update a VPN Gateway**: `PUT /vpn_gateways/{uuid}`

- **Delete a VPN Gateway**: `DELETE /vpn_gateways/{uuid}`

### Recovery Plans

- **Create a Recovery Plan**: `POST /recovery_plans`

- **Get Recovery Plan Details**: `GET /recovery_plans/{uuid}`

- **Update a Recovery Plan**: `PUT /recovery_plans/{uuid}`

- **Delete a Recovery Plan**: `DELETE /recovery_plans/{uuid}`

### User Management

- **Create a User**: `POST /users`

- **Get User Details**: `GET /users/{uuid}`

- **Update a User**: `PUT /users/{uuid}`

- **Delete a User**: `DELETE /users/{uuid}`

### Additional Resources

For a complete list of API calls, refer to the [Nutanix Prism v3 API Documentation](https://www.nutanix.dev/api_reference/apis/prism_v3.html).

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

## Contact & Support

For questions, issues, or support, please open an issue in the [GitHub repository](https://github.com/mgeorge67701/provider-nutanix/issues) or contact the maintainer via the repository Discussions page. We welcome feedback and contributions from the community!

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
