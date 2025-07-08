package v1alpha1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	xpv1 "github.com/crossplane/crossplane-runtime/apis/common/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/runtime/schema"
	"sigs.k8s.io/controller-runtime/pkg/scheme"
)

// VirtualMachineSpec defines the desired state of a Nutanix VM.
type VirtualMachineSpec struct {
	Name           string `json:"name"`
	NumVCPUs       int    `json:"numVcpus"`
	MemorySizeMiB  int    `json:"memorySizeMib"`
	ClusterUUID    string `json:"clusterUuid"`
	SubnetUUID     string `json:"subnetUuid"`
	ImageUUID      string `json:"imageUuid"`
}

// VirtualMachineStatus defines the observed state of a Nutanix VM.
type VirtualMachineStatus struct {
	xpv1.ConditionedStatus `json:",inline"`
	VMID                  string `json:"vmId,omitempty"`
	State                 string `json:"state,omitempty"`
}

// +kubebuilder:object:root=true
// +kubebuilder:subresource:status

type VirtualMachine struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   VirtualMachineSpec   `json:"spec"`
	Status VirtualMachineStatus `json:"status,omitempty"`
}

func (in *VirtualMachine) DeepCopyObject() runtime.Object {
	// Implemented for controller-runtime compatibility
	return in
}

// +kubebuilder:object:root=true

type VirtualMachineList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []VirtualMachine `json:"items"`
}

func (in *VirtualMachineList) DeepCopyObject() runtime.Object {
	return in
}

var (
	SchemeGroupVersion = schema.GroupVersion{Group: "nutanix.crossplane.io", Version: "v1alpha1"}
	SchemeBuilder      = &scheme.Builder{GroupVersion: SchemeGroupVersion}
	AddToScheme        = SchemeBuilder.AddToScheme
)
