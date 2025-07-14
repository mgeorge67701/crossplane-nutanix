/*
Copyright 2023 The Crossplane Authors.

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

package v1beta1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"

	xpv1 "github.com/crossplane/crossplane-runtime/apis/common/v1"
)

// ProviderConfig configures a Nutanix provider.
// +kubebuilder:printcolumn:name="AGE",type="date",JSONPath=".metadata.creationTimestamp"
// +kubebuilder:printcolumn:name="SECRET-NAME",type="string",JSONPath=".spec.credentials.secretRef.name",priority=1
// +kubebuilder:resource:scope=Cluster,categories={crossplane,provider,nutanix}
type ProviderConfig struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   ProviderConfigSpec        `json:"spec"`
	Status xpv1.ProviderConfigStatus `json:"status,omitempty"`
}

// ProviderConfigSpec defines the desired state of a ProviderConfig.
type ProviderConfigSpec struct {
	// Credentials required to authenticate to this provider.
	Credentials ProviderCredentials `json:"credentials"`

	// AllowedLoBs is the list of allowed Line of Business values for VMs.
	// +optional
	AllowedLoBs []string `json:"allowedLobs,omitempty"`

	// IsLoBMandatory specifies whether the LoB field is mandatory for VMs.
	// +optional
	IsLoBMandatory bool `json:"isLobMandatory,omitempty"`

	// PrismCentralEndpoints maps datacenter names to their Prism Central endpoints.
	// This allows dynamic selection of the Prism Central based on the datacenter specified in the VM spec.
	// +optional
	PrismCentralEndpoints map[string]string `json:"prismCentralEndpoints,omitempty"`

	   // DatacenterCredentials maps datacenter names to their specific credentials.
	   // This allows using different credentials for different Prism Central instances.
	   // +optional
	   DatacenterCredentials map[string]ProviderCredentials `json:"datacenterCredentials,omitempty"`

	   // EnableAvailabilityZoneMapping controls whether the provider should use the availability zone mapping feature.
	   // If true, the provider will use the mapping URL to map availabilityZone to clusterName. If false or omitted, the feature is disabled.
	   // +optional
	   EnableAvailabilityZoneMapping bool `json:"enableAvailabilityZoneMapping,omitempty"`

	   // AvailabilityZoneMappingURL is the URL to fetch the availability zone to cluster mapping CSV.
	   // If specified and the feature is enabled, this will be used to map availabilityZone to clusterName in VM specs.
	   // +optional
	   AvailabilityZoneMappingURL string `json:"availabilityZoneMappingURL,omitempty"`
}

// ProviderCredentials required to authenticate.
type ProviderCredentials struct {
	// Source of the provider credentials.
	// +kubebuilder:validation:Enum=None;Secret;InjectedIdentity;Environment;Filesystem
	Source xpv1.CredentialsSource `json:"source"`

	xpv1.CommonCredentialSelectors `json:",inline"`
}

//+kubebuilder:object:root=true

// ProviderConfigList contains a list of ProviderConfig.
type ProviderConfigList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []ProviderConfig `json:"items"`
}

func (in *ProviderConfig) DeepCopyObject() runtime.Object {
	return in
}

func (in *ProviderConfigList) DeepCopyObject() runtime.Object {
	return in
}

// GetCondition of this ProviderConfig.
func (in *ProviderConfig) GetCondition(ct xpv1.ConditionType) xpv1.Condition {
	return in.Status.GetCondition(ct)
}

// SetConditions of this ProviderConfig.
func (in *ProviderConfig) SetConditions(c ...xpv1.Condition) {
	in.Status.SetConditions(c...)
}
