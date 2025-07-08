package controller

import (
	"context"
	"encoding/json"
	"fmt"
	"os"

	"github.com/crossplane/crossplane-runtime/pkg/logging"
	"github.com/mgeorge67701/provider-nutanix/apis/v1alpha1"
	"github.com/mgeorge67701/provider-nutanix/apis/v1beta1"
	"github.com/mgeorge67701/provider-nutanix/internal/nutanix"
	corev1 "k8s.io/api/core/v1"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/controller"
	"sigs.k8s.io/controller-runtime/pkg/manager"
	"sigs.k8s.io/controller-runtime/pkg/reconcile"
)

type VirtualMachineReconciler struct {
	client.Client
	log logging.Logger
}

// Function to fetch cluster UUID dynamically from Nutanix
func fetchClusterUUID(ntxCli *nutanix.Client, clusterName string) (string, error) {
	clusters, err := ntxCli.ListClusters()
	if err != nil {
		return "", err
	}
	for _, cluster := range clusters {
		if cluster.Name == clusterName {
			return cluster.UUID, nil
		}
	}
	return "", fmt.Errorf("cluster with name %s not found", clusterName)
}

// Function to dynamically select and parse JSON file based on cluster name
func readClusterDetailsByName(clusterName string) (map[string]string, error) {
	filePath := fmt.Sprintf("/etc/provider/%s.json", clusterName)
	data, err := os.ReadFile(filePath)
	if err != nil {
		return nil, err
	}
	var details map[string]string
	if err := json.Unmarshal(data, &details); err != nil {
		return nil, err
	}
	return details, nil
}

func (r *VirtualMachineReconciler) Reconcile(ctx context.Context, req reconcile.Request) (reconcile.Result, error) {
	r.log.Debug("Reconciling Nutanix VirtualMachine", "name", req.NamespacedName)

	var vm v1alpha1.VirtualMachine
	if err := r.Get(ctx, req.NamespacedName, &vm); err != nil {
		return reconcile.Result{}, client.IgnoreNotFound(err)
	}

	// Load ProviderConfig
	var pc v1beta1.ProviderConfig
	if err := r.Get(ctx, client.ObjectKey{Name: "default"}, &pc); err != nil {
		return reconcile.Result{}, err
	}
	if pc.Spec.Credentials.Source != "Secret" {
		return reconcile.Result{}, fmt.Errorf("only Secret credentials source is supported")
	}
	ref := pc.Spec.Credentials.SecretRef
	var secret corev1.Secret
	if err := r.Get(ctx, client.ObjectKey{Namespace: ref.Namespace, Name: ref.Name}, &secret); err != nil {
		return reconcile.Result{}, err
	}
	creds := struct {
		Endpoint string `json:"endpoint"`
		Username string `json:"username"`
		Password string `json:"password"`
		Insecure bool   `json:"insecure"`
	}{}
	if err := json.Unmarshal(secret.Data[ref.Key], &creds); err != nil {
		return reconcile.Result{}, err
	}
	ntxCli := nutanix.NewClient(creds.Endpoint, creds.Username, creds.Password, creds.Insecure)

	if !vm.DeletionTimestamp.IsZero() {
		// Handle delete
		if err := ntxCli.DeleteVM(ctx, vm.Status.VMID); err != nil {
			r.log.Debug("Failed to delete VM", "error", err)
			return reconcile.Result{}, err
		}
		return reconcile.Result{}, nil
	}

	if vm.Status.VMID == "" {
		// Handle create
		id, err := ntxCli.CreateVM(ctx, vm.Spec)
		if err != nil {
			r.log.Debug("Failed to create VM", "error", err)
			return reconcile.Result{}, err
		}
		vm.Status.VMID = id
		vm.Status.State = "Created"
		if err := r.Status().Update(ctx, &vm); err != nil {
			return reconcile.Result{}, err
		}
		return reconcile.Result{}, nil
	}

	// Assume cluster name is provided in the VirtualMachine spec
	clusterName := vm.Spec.ClusterName
	if clusterName == "" {
		r.log.Debug("Cluster name not specified in VirtualMachine spec")
		return reconcile.Result{}, fmt.Errorf("cluster name is required")
	}

	// Fetch cluster details dynamically from JSON file
	clusterDetails, err := readClusterDetailsByName(clusterName)
	if err != nil {
		r.log.Debug("Failed to read cluster details", "error", err)
		return reconcile.Result{}, err
	}

	// Use extracted values dynamically
	vm.Spec.ClusterUUID = clusterDetails["clusterUuid"]
	vm.Spec.SubnetUUID = clusterDetails["subnetUuid"]
	vm.Spec.ImageUUID = clusterDetails["imageUuid"]

	// Handle observe
	_, err = ntxCli.GetVM(ctx, vm.Status.VMID)
	if err != nil {
		r.log.Debug("Failed to get VM", "error", err)
		return reconcile.Result{}, err
	}
	return reconcile.Result{}, nil
}

func SetupVirtualMachine(mgr manager.Manager, l logging.Logger) error {
	_, err := controller.New("virtualmachine-controller", mgr, controller.Options{
		Reconciler: &VirtualMachineReconciler{
			Client: mgr.GetClient(),
			log:    l,
		},
	})
	return err
}
