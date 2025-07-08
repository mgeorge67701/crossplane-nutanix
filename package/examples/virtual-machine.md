# Virtual Machine Example

Create a virtual machine on your Nutanix cluster:

```yaml
apiVersion: nutanix.crossplane.io/v1alpha1
kind: VirtualMachine
metadata:
  name: example-vm
spec:
  name: "crossplane-vm-example"
  numVcpus: 2
  memorySizeMib: 4096
  clusterUuid: "12345678-1234-1234-1234-123456789abc"  # Replace with your cluster UUID
  subnetUuid: "87654321-4321-4321-4321-cba987654321"   # Replace with your subnet UUID  
  imageUuid: "abcdef12-3456-7890-abcd-ef1234567890"    # Replace with your image UUID
```

Apply the virtual machine:

```bash
kubectl apply -f virtualmachine.yaml
```

Check the status:

```bash
kubectl get virtualmachines
kubectl describe virtualmachine example-vm
```
