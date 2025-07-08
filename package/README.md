# Nutanix Crossplane Provider

This provider enables management of Nutanix infrastructure resources through Crossplane.

## Quick Start

### 1. Create Credentials Secret

```bash
kubectl create secret generic nutanix-creds -n crossplane-system \
  --from-literal=credentials='{"endpoint":"https://prism-central.example.com:9440","username":"admin","password":"your-password"}'
```

### 2. Apply ProviderConfig

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

### 3. Create Virtual Machine

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

## Resources

- **VirtualMachine**: Create and manage Nutanix VMs
- **ProviderConfig**: Configure authentication to Nutanix clusters

## Support

For more examples and documentation, visit: [GitHub Repository](https://github.com/mgeorge67701/provider-nutanix)
