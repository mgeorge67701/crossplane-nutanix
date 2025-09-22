package v1alpha1

import (
	"testing"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

func TestVirtualMachineDeepCopy(t *testing.T) {
	original := &VirtualMachine{
		TypeMeta: metav1.TypeMeta{
			APIVersion: "nutanix.crossplane.io/v1alpha1",
			Kind:       "VirtualMachine",
		},
		ObjectMeta: metav1.ObjectMeta{
			Name:      "test-vm",
			Namespace: "default",
		},
		Spec: VirtualMachineSpec{
			Name:          "test-vm",
			NumVCPUs:      2,
			MemorySizeMiB: 4096,
		},
		Status: VirtualMachineStatus{
			VMID:  "vm-123",
			State: "Running",
		},
	}

	// Test DeepCopy
	copied := original.DeepCopy()
	if copied == nil {
		t.Fatal("DeepCopy returned nil")
	}

	// Verify the copy is not the same object
	if copied == original {
		t.Error("DeepCopy returned the same object")
	}

	// Verify the values are copied correctly
	if copied.Name != original.Name {
		t.Errorf("Name not copied correctly: got %q, want %q", copied.Name, original.Name)
	}

	if copied.Spec.NumVCPUs != original.Spec.NumVCPUs {
		t.Errorf("NumVCPUs not copied correctly: got %d, want %d", copied.Spec.NumVCPUs, original.Spec.NumVCPUs)
	}

	if copied.Status.VMID != original.Status.VMID {
		t.Errorf("VMID not copied correctly: got %q, want %q", copied.Status.VMID, original.Status.VMID)
	}
}

func TestVirtualMachineListDeepCopy(t *testing.T) {
	original := &VirtualMachineList{
		TypeMeta: metav1.TypeMeta{
			APIVersion: "nutanix.crossplane.io/v1alpha1",
			Kind:       "VirtualMachineList",
		},
		Items: []VirtualMachine{
			{
				ObjectMeta: metav1.ObjectMeta{Name: "vm1"},
				Spec:       VirtualMachineSpec{Name: "vm1", NumVCPUs: 2},
			},
			{
				ObjectMeta: metav1.ObjectMeta{Name: "vm2"},
				Spec:       VirtualMachineSpec{Name: "vm2", NumVCPUs: 4},
			},
		},
	}

	copied := original.DeepCopy()
	if copied == nil {
		t.Fatal("DeepCopy returned nil")
	}

	if len(copied.Items) != len(original.Items) {
		t.Errorf("Items length not copied correctly: got %d, want %d", len(copied.Items), len(original.Items))
	}

	// Verify items are deep copied
	if len(copied.Items) > 0 && &copied.Items[0] == &original.Items[0] {
		t.Error("Items not deep copied")
	}
}
