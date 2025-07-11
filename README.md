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

Create a secret with your Nutanix credentials (e.g., `nutanix-creds-default`):

```bash
kubeclt create secret generic nutanix-creds-default -n crossplane-system \
  --from-literal=credentials='{"endpoint":"https://default-pc.example.com:9440","username":"admin","password":"your-password","insecure":true}'
```

For datacenter-specific credentials (e.g., for `dc-alpha`):

```bash
kubeclt create secret generic nutanix-creds-alpha -n crossplane-system \
  --from-literal=credentials='{"endpoint":"https://pc-alpha.example.com:9440","username":"admin-alpha","password":"your-password-alpha","insecure":true}'
```

Create a ProviderConfig that combines all features, including LoB validation, dynamic endpoint selection, and datacenter-specific credentials. A comprehensive example is available in [`examples/providerconfig-all-features.yaml`](./examples/providerconfig-all-features.yaml).

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
  # ... (rest of the configuration as in examples/providerconfig-all-features.yaml)
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
  clusterName: "aza-ntnx-01"  # Specify the cluster name to fetch details dynamically
  imageName: "ubuntu-22.04-cloud"
  lob: "CLOUD" # Example: Specify the Line of Business
```

The provider will automatically resolve the `clusterUuid`, `subnetUuid`, and `imageUuid` from the names you provide in the spec. You can specify either the UUID or a partial name for each resource (cluster, subnet, image). If you specify a partial name (e.g., `clusterName`, `subnetName`, `imageName`), the provider will search Nutanix Prism Central for resources whose names contain the given string and select the latest available match. You do **not** need to mount or manage any JSON files for UUID lookup; all lookups are performed dynamically using the Nutanix API.

### Line of Business (LoB) Validation

The `VirtualMachine` resource includes an optional `lob` field in its `spec`. This field allows you to associate a Line of Business with your virtual machines. The validation rules for this field are configured in the `ProviderConfig`.

Refer to the `allowedLoBs` and `isLoBMandatory` fields in the [`examples/providerconfig-all-features.yaml`](./examples/providerconfig-all-features.yaml) for a comprehensive example of how to configure LoB validation.

### Specifying the Image

You can specify the image by name in your `VirtualMachine` spec. The provider will automatically fetch the corresponding image UUID from Nutanix Prism Central using the API, so you do not need to specify the UUID directly.

```yaml
spec:
  clusterName: "aza-ntnx-01"
  imageName: "ubuntu-22.04-cloud"
```

The provider will use the `imageName` to look up the image UUID at runtime, just like it does for the cluster name. This makes your manifests more portable and easier to maintain.

> **Note:** The image UUID will be resolved automatically; you only need to provide the image name.

### Specifying the Image (Automatic Latest Selection)

You can specify a partial image name (e.g., `rhel8`, `rhel9`, `win2022`, `win2019`) in your `VirtualMachine` spec. The provider will automatically search for images in Nutanix Prism Central whose names contain the given string and select the latest available image (by creation date or version) for you.

```yaml
spec:
  clusterName: "aza-ntnx-01"
  imageName: "rhel8"   # Will pick the latest RHEL 8 image available
```

You can use this for any OS family or version:
- `imageName: "rhel9"` will pick the latest RHEL 9 image
- `imageName: "win2022"` will pick the latest Windows Server 2022 image
- `imageName: "win2019"` will pick the latest Windows Server 2019 image

> **Note:** The provider will resolve the latest matching image automatically. You do not need to specify the full image name or UUID.

### Specifying Additional Disks

You can specify additional disks for your Virtual Machine in the `additionalDisks` section of the spec. Each disk can have a `deviceIndex` and `sizeGb` specified.

```yaml
apiVersion: nutanix.crossplane.io/v1alpha1
kind: VirtualMachine
metadata:
  name: example-vm
spec:
  name: "my-crossplane-vm"
  numVcpus: 2
  memorySizeMib: 4096
  clusterName: "aza-ntnx-01"
  imageName: "ubuntu-22.04-cloud"
  additionalDisks:
    - deviceIndex: 1
      sizeGb: 20
    - deviceIndex: 2
      sizeGb: 100
  externalFacts:
    bt_product: "inf"
    another_fact: "value"
```

In this example, two additional disks are specified: one with `deviceIndex` 1 and size 20 GB, and another with `deviceIndex` 2 and size 100 GB. The `deviceIndex` specifies the order in which the disks are attached to the VM.

In this example, `externalFacts` allows you to pass arbitrary key-value pairs to the VM, similar to Terraform's `external_facts` map. These facts can be used for configuration management or automation tools running inside the VM.

### Dynamic Prism Central Endpoint Selection

The provider supports dynamic selection of the Prism Central endpoint and associated credentials based on a `datacenter` field specified in the `VirtualMachine` spec. This allows you to manage VMs across multiple Nutanix environments from a single Crossplane provider instance.

Refer to the `prismCentralEndpoints` and `datacenterCredentials` fields in the [`examples/providerconfig-all-features.yaml`](./examples/providerconfig-all-features.yaml) for a comprehensive example of how to configure dynamic endpoint and credential selection.

## Finding UUIDs

You can still look up UUIDs manually in Prism Central if needed:

- **Cluster UUID**: Prism Central → Home → Infrastructure → Clusters
- **Subnet UUID**: Prism Central → Network & Security → Subnets
- **Image UUID**: Prism Central → Compute & Storage → Images

## Example: Fetching Cluster, Subnet, and Image UUIDs from Nutanix

You only need to provide the partial name in your `VirtualMachine` spec. The provider will automatically fetch the corresponding UUID from Nutanix Prism Central using the API, so you do not need to specify the UUID in any JSON file.

```yaml
spec:
  clusterName: "aza-ntnx-01"
  subnetName: "prod-subnet"
  imageName: "rhel8"
```

The provider will use the partial names to look up the UUIDs at runtime. This is similar to how Terraform data sources work, where you reference a resource by name and the provider resolves the UUID for you.

> **Note:** You do not need to create or mount a JSON file for cluster, subnet, or image UUID lookup. The provider will fetch the UUIDs directly from Nutanix using the names you specify in your resource spec.

## Examples

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

### Example JSON File

```json
{
  "clusterUuid": "00000000-0000-0000-0000-000000000000",
  "subnetUuid": "11111111-1111-1111-1111-111111111111",
  "imageUuid": "22222222-2222-2222-2222-222222222222",
  "networkUuid": "33333333-3333-3333-3333-333333333333",
  "storageUuid": "44444444-4444-4444-4444-444444444444"
}
```

### Mounting the JSON File

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

### Example JSON File for Network Details

```json
{
    "domain": "saas-p.com",
    "nameserver": "10.222.1.210",
    "gateway": "10.222.192.1",
    "network": "10.222.192.0/24",
    "subnet": "ch01_BTIQ_App",
    "email": "globalengineering-teamatlasbottomline.com@bottomline.com",
    "puppet_master": "puppet-ch01-pr.saas-p.com",
    "network_management_server": "us-00-vl-mgt001.saas-p.com",
    "foreman_host": "ch01vlfrmn01.saas-p.com"
}
```

### Mounting the JSON File for Network Details

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

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
