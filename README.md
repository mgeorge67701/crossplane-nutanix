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
  clusterName: "aza-ntnx-01"  # Specify the cluster name to fetch details dynamically
```

The provider will automatically fetch the `clusterUuid`, `subnetUuid`, and `imageUuid` from the JSON file corresponding to the specified `clusterName`. Ensure the JSON file is mounted in the provider pod at `/etc/provider/<cluster-name>.json`.

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
