# Nutanix Provider Examples

## ProviderConfig

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

## Virtual Machine

```yaml
apiVersion: nutanix.crossplane.io/v1alpha1
kind: VirtualMachine
metadata:
  name: example-vm
spec:
  name: "my-vm"
  numVcpus: 2
  memorySizeMib: 4096
  clusterUuid: "your-cluster-uuid"
  subnetUuid: "your-subnet-uuid"  
  imageUuid: "your-image-uuid"
```

## Setup

1. Create credentials secret:
```bash
kubectl create secret generic nutanix-creds -n crossplane-system \
  --from-literal=credentials='{"endpoint":"https://your-pc:9440","username":"admin","password":"password"}'
```

2. Apply the ProviderConfig and VirtualMachine manifests above
