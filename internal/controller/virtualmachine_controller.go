package controller

import (
	context "context"
	"encoding/json"
	"fmt"

	"github.com/crossplane/crossplane-runtime/pkg/logging"
	"github.com/crossplane/provider-nutanix/apis/v1alpha1"
	"github.com/crossplane/provider-nutanix/apis/v1beta1"
	"github.com/crossplane/provider-nutanix/internal/nutanix"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/controller"
	"sigs.k8s.io/controller-runtime/pkg/manager"
	"sigs.k8s.io/controller-runtime/pkg/reconcile"
	corev1 "k8s.io/api/core/v1"
)

type VirtualMachineReconciler struct {
	client.Client
	log logging.Logger
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

	// Handle observe
	_, err := ntxCli.GetVM(ctx, vm.Status.VMID)
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
