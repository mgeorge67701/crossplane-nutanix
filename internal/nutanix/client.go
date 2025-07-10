package nutanix

import (
	"context"
	"fmt"
	"reflect"

	"github.com/mgeorge67701/provider-nutanix/apis/v1alpha1"
)

// Client is a stub for the Nutanix Prism API client.
type Client struct {
	Endpoint string
	Username string
	Password string
	Insecure bool
}

// NewClient creates a new Nutanix API client.
func NewClient(endpoint, username, password string, insecure bool) *Client {
	return &Client{
		Endpoint: endpoint,
		Username: username,
		Password: password,
		Insecure: insecure,
	}
}

// CreateVM creates a VM with additional disks using the Nutanix API.
// Update CreateVM to accept VirtualMachineSpec and handle additionalDisks
func (c *Client) CreateVM(ctx context.Context, spec interface{}) (string, error) {
	// Accepts v1alpha1.VirtualMachineSpec
	var vmSpec v1alpha1.VirtualMachineSpec
	switch s := spec.(type) {
	case v1alpha1.VirtualMachineSpec:
		vmSpec = s
	case *v1alpha1.VirtualMachineSpec:
		vmSpec = *s
	case map[string]interface{}:
		// fallback for unstructured
		return "stub-vm-id", nil
	default:
		return "", fmt.Errorf("unsupported spec type: %v", reflect.TypeOf(spec))
	}

	// Build disks payload
	disks := []map[string]interface{}{}
	// Boot disk (main image)
	if vmSpec.ImageUUID != "" {
		disks = append(disks, map[string]interface{}{
			"deviceIndex": 0,
			"sizeGb":      vmSpec.MemorySizeMiB, // Example, real size should be from image or spec
			"imageUuid":   vmSpec.ImageUUID,
		})
	}
	// Additional disks
	for _, disk := range vmSpec.AdditionalDisks {
		entry := map[string]interface{}{
			"deviceIndex": disk.DeviceIndex,
			"sizeGb":      disk.SizeGb,
		}
		if disk.ImageUUID != "" {
			entry["imageUuid"] = disk.ImageUUID
		}
		disks = append(disks, entry)
	}

	// Build external facts payload if present
	var externalFacts map[string]string
	if vmSpec.ExternalFacts != nil {
		externalFacts = vmSpec.ExternalFacts
	}

	// TODO: Replace with actual Nutanix API call to create VM with disks and external facts
	fmt.Printf("[DEBUG] Creating VM: name=%s, disks=%v, externalFacts=%v\n", vmSpec.Name, disks, externalFacts)
	return "stub-vm-id", nil
}

// GetVM is a stub for getting a VM.
func (c *Client) GetVM(ctx context.Context, vmID string) (interface{}, error) {
	// TODO: Implement actual Nutanix API call
	return nil, nil
}

// DeleteVM is a stub for deleting a VM.
func (c *Client) DeleteVM(ctx context.Context, vmID string) error {
	// TODO: Implement actual Nutanix API call
	return nil
}

// ListClusters fetches the list of clusters from Nutanix Prism Central.
func (c *Client) ListClusters() ([]struct {
	Name string
	UUID string
}, error) {
	// TODO: Implement actual Nutanix API call to fetch clusters
	return []struct {
		Name string
		UUID string
	}{
		{Name: "ch01-aza-ntnx-01", UUID: "00000000-0000-0000-0000-000000000000"},
		{Name: "ch02-aza-ntnx-02", UUID: "11111111-1111-1111-1111-111111111111"},
	}, nil
}

// ImageInfo represents a Nutanix image.
type ImageInfo struct {
	Name        string
	UUID        string
	CreatedTime int64 // Unix timestamp
}

// ListImages fetches the list of images from Nutanix Prism Central.
func (c *Client) ListImages(ctx context.Context) ([]ImageInfo, error) {
	// TODO: Implement actual Nutanix API call to fetch images
	return []ImageInfo{
		{Name: "ubuntu-22.04-cloud", UUID: "img-uuid-1", CreatedTime: 1710000000},
		{Name: "rhel8-latest", UUID: "img-uuid-2", CreatedTime: 1720000000},
		{Name: "rhel8-2024-06", UUID: "img-uuid-3", CreatedTime: 1730000000},
		{Name: "win2022-2025-01", UUID: "img-uuid-4", CreatedTime: 1740000000},
	}, nil
}

// SubnetInfo represents a Nutanix subnet.
type SubnetInfo struct {
	Name        string
	UUID        string
	CreatedTime int64 // Unix timestamp
}

// ListSubnets fetches the list of subnets from Nutanix Prism Central.
func (c *Client) ListSubnets(ctx context.Context) ([]SubnetInfo, error) {
	// TODO: Implement actual Nutanix API call to fetch subnets
	return []SubnetInfo{
		{Name: "prod-subnet", UUID: "subnet-uuid-1", CreatedTime: 1710000000},
		{Name: "dev-subnet", UUID: "subnet-uuid-2", CreatedTime: 1720000000},
		{Name: "rhel8-subnet", UUID: "subnet-uuid-3", CreatedTime: 1730000000},
	}, nil
}
