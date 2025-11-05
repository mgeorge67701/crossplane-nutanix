/*
Copyright 2024 The Crossplane Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

// +kubebuilder:object:generate=true
// +groupName=nutanix.crossplane.io

package v1alpha1

import (
	xpv1 "github.com/crossplane/crossplane-runtime/apis/common/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime/schema"
	"sigs.k8s.io/controller-runtime/pkg/scheme"
)

// VirtualMachineSpec defines the desired state of a Nutanix VM.
type VirtualMachineSpec struct {
	// +kubebuilder:validation:Required
	Name string `json:"name"`

	// +kubebuilder:validation:Optional
	LoB string `json:"lob,omitempty"`

	// +kubebuilder:validation:Optional
	Datacenter string `json:"datacenter,omitempty"`

	// +kubebuilder:validation:Optional
	AvailabilityZone string `json:"availabilityZone,omitempty"`

	// +kubebuilder:validation:Required
	// +kubebuilder:validation:Minimum=1
	NumVCPUs int `json:"numVcpus"`

	// +kubebuilder:validation:Required
	// +kubebuilder:validation:Minimum=512
	MemorySizeMiB int `json:"memorySizeMib"`

	// +kubebuilder:validation:Optional
	ClusterUUID string `json:"clusterUuid,omitempty"`

	// +kubebuilder:validation:Optional
	ClusterName string `json:"clusterName,omitempty"`

	// +kubebuilder:validation:Optional
	SubnetUUID string `json:"subnetUuid,omitempty"`

	// +kubebuilder:validation:Optional
	// Name of the ConfigMap containing network details for this VM
	Network string `json:"network,omitempty"`

	// +kubebuilder:validation:Optional
	ImageUUID string `json:"imageUuid,omitempty"`

	// +kubebuilder:validation:Optional
	ImageName string `json:"imageName,omitempty"`

	// +kubebuilder:validation:Optional
	AdditionalDisks []DiskSpec `json:"additionalDisks,omitempty"`

	// +kubebuilder:validation:Optional
	ExternalFacts map[string]string `json:"externalFacts,omitempty"`

	// Reference to a ProviderConfig
	// +kubebuilder:validation:Optional
	ProviderConfigReference *xpv1.Reference `json:"providerConfigRef,omitempty"`
}

// DiskSpec defines the disk configuration for a Nutanix VM.
type DiskSpec struct {
	// +kubebuilder:validation:Required
	// +kubebuilder:validation:Minimum=0
	DeviceIndex int `json:"deviceIndex"`

	// +kubebuilder:validation:Required
	// +kubebuilder:validation:Minimum=1
	SizeGb int `json:"sizeGb"`

	// +kubebuilder:validation:Optional
	ImageUUID string `json:"imageUuid,omitempty"`

	// +kubebuilder:validation:Optional
	ImageName string `json:"imageName,omitempty"`
}

// VirtualMachineStatus defines the observed state of a Nutanix VM.
type VirtualMachineStatus struct {
	xpv1.ConditionedStatus `json:",inline"`

	// +kubebuilder:validation:Optional
	VMID string `json:"vmId,omitempty"`

	// +kubebuilder:validation:Optional
	State string `json:"state,omitempty"`
}

// +kubebuilder:object:root=true
// +kubebuilder:subresource:status
// +kubebuilder:printcolumn:name="READY",type="string",JSONPath=".status.conditions[?(@.type=='Ready')].status"
// +kubebuilder:printcolumn:name="SYNCED",type="string",JSONPath=".status.conditions[?(@.type=='Synced')].status"
// +kubebuilder:printcolumn:name="VM-ID",type="string",JSONPath=".status.vmId"
// +kubebuilder:printcolumn:name="STATE",type="string",JSONPath=".status.state"
// +kubebuilder:printcolumn:name="AGE",type="date",JSONPath=".metadata.creationTimestamp"
// +kubebuilder:resource:scope=Cluster,categories={crossplane,managed,nutanix}

// VirtualMachine is the Schema for the virtualmachines API
type VirtualMachine struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   VirtualMachineSpec   `json:"spec"`
	Status VirtualMachineStatus `json:"status,omitempty"`
}

// +kubebuilder:object:root=true

// VirtualMachineList contains a list of VirtualMachine
type VirtualMachineList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []VirtualMachine `json:"items"`
}

var (
	// SchemeGroupVersion is group version used to register these objects
	SchemeGroupVersion = schema.GroupVersion{Group: "nutanix.crossplane.io", Version: "v1alpha1"}

	// SchemeBuilder is used to add go types to the GroupVersionKind scheme
	SchemeBuilder = &scheme.Builder{GroupVersion: SchemeGroupVersion}

	// AddToScheme adds the types in this group-version to the given scheme.
	AddToScheme = SchemeBuilder.AddToScheme
)

func init() {
	SchemeBuilder.Register(&VirtualMachine{}, &VirtualMachineList{})
}
