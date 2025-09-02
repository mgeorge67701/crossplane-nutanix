# Crossplane Nutanix Provider Examples

This directory contains example manifests for using the Nutanix provider.

## Prerequisites

Before applying the examples, you need to create a Kubernetes secret containing your Nutanix Prism Central credentials.

1. **Create a `credentials.txt` file:**

    This file should contain your Prism Central username and password in the following format:

    ```ini
    [default]
    username = <YOUR_USERNAME>
    password = <YOUR_PASSWORD>
    ```

2. **Create the Kubernetes Secret:**

    Run the following command to create a secret named `nutanix-creds` from the file:

    ```sh
    kubectl create secret generic nutanix-creds --from-file=credentials=./credentials.txt -n crossplane-system
    ```

    > **Note:** The examples assume the secret is created in the `crossplane-system` namespace.

## Usage

The examples are designed to be applied in a specific order.

1. **ProviderConfig:**

    The `providerconfig-all-features.yaml` manifest configures the Nutanix provider. It tells the provider how to authenticate with your Nutanix cluster by referencing the `nutanix-creds` secret you created.

    Before applying, you **must** update the `endpoint` field in `providerconfig-all-features.yaml` to point to your Prism Central IP address or fully-qualified domain name.

    ```yaml
    # examples/providerconfig-all-features.yaml
    apiVersion: nutanix.crossplane.io/v1beta1
    kind: ProviderConfig
    metadata:
      name: nutanix-provider-all-features
    spec:
      endpoint: "<YOUR_PRISM_CENTRAL_IP>" # <-- UPDATE THIS
      insecure: true
      credentials:
        source: Secret
        secretRef:
          namespace: crossplane-system
          name: nutanix-creds
          key: credentials
    ```

    Apply the manifest:

    ```sh
    kubectl apply -f examples/providerconfig-all-features.yaml
    ```

2. **VirtualMachine:**

    The `virtualmachine.yaml` manifest creates a new virtual machine. It references the `ProviderConfig` created in the previous step.

    Apply the manifest:
    ```sh
    kubectl apply -f examples/virtualmachine.yaml
    ```

    You can then check the status of your new VM:

    ```sh
    kubectl get virtualmachine
    ```

## Detailed Configuration Examples

This section provides a more detailed look at the configuration options available in the example manifests.

### `providerconfig-all-features.yaml`

This manifest demonstrates advanced `ProviderConfig` features, allowing for multi-datacenter and multi-credential setups.

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

### `virtualmachine.yaml` (Basic Example)

This is a basic example of a `VirtualMachine` resource. The provider will dynamically look up the UUIDs for `imageName` and `subnetName`.

```yaml
apiVersion: nutanix.crossplane.io/v1alpha1
kind: VirtualMachine
metadata:
  name: example-vm
spec:
  # --- Core VM Specifications ---
  name: "my-crossplane-vm"
  numVcpus: 2
  memorySizeMib: 4096

  # --- Nutanix-Specific Details ---
  # The provider will dynamically find the UUID for this cluster.
  clusterName: "aza-ntnx-01"

  # The provider will dynamically find the latest image matching this name.
  # Can be a full or partial name (e.g., "rhel8", "win2022").
  imageName: "ubuntu-22.04-cloud"

  # The provider will dynamically find the UUID for this subnet.
  subnetName: "my-network-subnet"

  # --- ProviderConfig and Multi-Datacenter ---
  # Specifies which datacenter to use from the ProviderConfig's prismCentralEndpoints map.
  datacenter: "dc-alpha"

  # A reference to the ProviderConfig to use for this VM.
  providerConfigRef:
    name: all-features-config

  # --- Business Logic (Optional) ---
  # Line of Business tag. Must be one of the 'allowedLobs' in the ProviderConfig.
  lob: "CLOUD"
```

### `virtualmachine-advanced.yaml`

This example shows how to add additional data disks and external facts to a VM.

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
  datacenter: "dc-beta"
  imageName: "rhel8" # Example: partial image name, provider selects latest RHEL 8
  subnetName: "my-network-subnet"
  lob: "SECURITY"
  providerConfigRef:
    name: all-features-config

  # --- Additional Disks ---
  # A list of additional data disks to attach to the VM.
  additionalDisks:
    - deviceIndex: 1
      sizeGb: 50
      # Optional: create the disk from an existing image template.
      imageName: "data-disk-template"
    - deviceIndex: 2
      sizeGb: 100

  # --- External Facts ---
  # A key-value map of metadata to be passed to external systems like Puppet or Foreman.
  externalFacts:
    environment: "production"
    application: "webserver"
    owner: "devops-team"
```

### `network-details-configmap.yaml`

This `ConfigMap` is used to store network configuration details that can be consumed by other processes or automation for post-provisioning steps.

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
