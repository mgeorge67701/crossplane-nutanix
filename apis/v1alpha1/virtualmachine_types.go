package v1alpha1

import (
	xpv1 "github.com/crossplane/crossplane-runtime/apis/common/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/runtime/schema"
	"sigs.k8s.io/controller-runtime/pkg/scheme"
)

// VirtualMachineSpec defines the desired state of a Nutanix VM.
type VirtualMachineSpec struct {
	   Name            string            `json:"name"`
	   LoB             string            `json:"lob,omitempty"`
	   Datacenter      string            `json:"datacenter,omitempty"`
	   AvailabilityZone string           `json:"availabilityZone,omitempty"`
	   NumVCPUs        int               `json:"numVcpus"`
	   MemorySizeMiB   int               `json:"memorySizeMib"`
	   ClusterUUID     string            `json:"clusterUuid,omitempty"`
	   ClusterName     string            `json:"clusterName,omitempty"`
	   SubnetUUID      string            `json:"subnetUuid,omitempty"`
	   SubnetName      string            `json:"subnetName,omitempty"`
	   ImageUUID       string            `json:"imageUuid,omitempty"`
	   ImageName       string            `json:"imageName,omitempty"`
	   AdditionalDisks []DiskSpec        `json:"additionalDisks,omitempty"`
	   ExternalFacts   map[string]string `json:"externalFacts,omitempty"`
}

// DiskSpec defines the disk configuration for a Nutanix VM.
type DiskSpec struct {
	DeviceIndex int    `json:"deviceIndex"`
	SizeGb      int    `json:"sizeGb"`
	ImageUUID   string `json:"imageUuid,omitempty"`
	ImageName   string `json:"imageName,omitempty"`
}

// VirtualMachineStatus defines the observed state of a Nutanix VM.
type VirtualMachineStatus struct {
	xpv1.ConditionedStatus `json:",inline"`
	VMID                   string `json:"vmId,omitempty"`
	State                  string `json:"state,omitempty"`
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
