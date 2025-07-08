#!/bin/bash

# Complete setup script for Crossplane Nutanix Provider
# This script demonstrates a complete setup from installation to VM creation

set -e

echo "🚀 Setting up Crossplane Nutanix Provider..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Please install kubectl and configure access to your cluster."
    exit 1
fi

# Check if we can access the cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot access Kubernetes cluster. Please check your kubeconfig."
    exit 1
fi

echo "✅ Kubernetes cluster access verified"

# Install Crossplane if not already installed
if ! kubectl get pods -n crossplane-system | grep -q crossplane; then
    echo "📦 Installing Crossplane..."
    kubectl create namespace crossplane-system || true
    helm repo add crossplane-stable https://charts.crossplane.io/stable
    helm repo update
    helm install crossplane crossplane-stable/crossplane \
        --namespace crossplane-system \
        --create-namespace \
        --wait
    echo "✅ Crossplane installed"
else
    echo "✅ Crossplane already installed"
fi

# Install the Nutanix Provider
echo "📦 Installing Nutanix Provider..."
kubectl apply -f - <<EOF
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-nutanix
spec:
  package: xpkg.upbound.io/mgeorge67701/provider-nutanix:v1.0.3
EOF

echo "⏳ Waiting for provider to be ready..."
kubectl wait --for=condition=Healthy provider/provider-nutanix --timeout=300s

echo "✅ Nutanix Provider installed successfully"

# Check if credentials secret exists
if kubectl get secret nutanix-creds -n crossplane-system &> /dev/null; then
    echo "✅ Nutanix credentials secret already exists"
else
    echo "🔑 Creating Nutanix credentials..."
    echo "Please provide your Nutanix credentials:"
    read -p "Prism Central Endpoint (e.g., https://prism-central.example.com:9440): " ENDPOINT
    read -p "Username: " USERNAME
    read -s -p "Password: " PASSWORD
    echo

    # Create credentials JSON
    CREDS_JSON=$(cat <<EOF
{
  "endpoint": "$ENDPOINT",
  "username": "$USERNAME", 
  "password": "$PASSWORD"
}
EOF
)

    # Create the secret
    kubectl create secret generic nutanix-creds \
        -n crossplane-system \
        --from-literal=credentials="$CREDS_JSON"
    
    echo "✅ Nutanix credentials secret created"
fi

# Apply ProviderConfig
echo "⚙️  Applying ProviderConfig..."
kubectl apply -f examples/providerconfig.yaml

echo "⏳ Waiting for ProviderConfig to be ready..."
kubectl wait --for=condition=Ready providerconfig/nutanix-provider-config --timeout=60s

echo "✅ ProviderConfig ready"

# Apply XRD and Composition for advanced usage
echo "📋 Setting up Composite Resource Definition and Composition..."
kubectl apply -f examples/xrd.yaml
kubectl apply -f examples/composition.yaml

echo "⏳ Waiting for XRD to be established..."
kubectl wait --for=condition=Established xrd/xnutanixvms.platform.example.com --timeout=60s

echo "✅ XRD and Composition ready"

echo ""
echo "🎉 Setup complete! You can now:"
echo ""
echo "1. Create a simple VM:"
echo "   kubectl apply -f examples/virtualmachine.yaml"
echo ""
echo "2. Create a VM using the Composition (after updating UUIDs):"
echo "   kubectl apply -f examples/claim.yaml"
echo ""
echo "3. Check VM status:"
echo "   kubectl get virtualmachines"
echo "   kubectl get nutanixvms"
echo ""
echo "📚 For more information, check the README in the examples/ directory"
