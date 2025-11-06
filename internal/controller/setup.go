package controller

import (
	"github.com/crossplane/crossplane-runtime/pkg/logging"
	"sigs.k8s.io/controller-runtime/pkg/manager"
)

func Setup(mgr manager.Manager, l logging.Logger) error {
	if err := SetupVirtualMachine(mgr, l); err != nil {
		return err
	}
	return nil
}
