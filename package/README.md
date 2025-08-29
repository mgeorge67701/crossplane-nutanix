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

## Finding UUIDs

You can still look up UUIDs manually in Prism Central if needed:

- **Cluster UUID**: Prism Central → Home → Infrastructure → Clusters
- **Subnet UUID**: Prism Central → Network & Security → Subnets  
- **Image UUID**: Prism Central → Compute & Storage → Images

## Resources

- **VirtualMachine**: Create and manage Nutanix VMs
- **ProviderConfig**: Configure authentication to Nutanix clusters

## Support

For more examples and documentation, visit: [GitHub Repository](https://github.com/mgeorge67701/provider-nutanix)
