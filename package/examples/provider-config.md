# Provider Configuration Example

Set up authentication with your Nutanix cluster:

```yaml
apiVersion: nutanix.crossplane.io/v1beta1
kind: ProviderConfig
metadata:
  name: nutanix-provider-config
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: nutanix-creds
      key: credentials
```

Create the credentials secret:

```bash
kubectl create secret generic nutanix-creds -n crossplane-system \
  --from-literal=credentials='{"endpoint":"https://prism-central.example.com:9440","username":"admin","password":"your-password"}'
```

Then apply the ProviderConfig:

```bash
kubectl apply -f providerconfig.yaml
```
