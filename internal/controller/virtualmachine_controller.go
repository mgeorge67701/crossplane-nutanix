package controller

import (
	"context"
	"encoding/csv"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
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

// Fetches the mapping from a CSV URL and returns a map[AvailabilityZone]ClusterName for only enabled zones
// Also returns a set of all zones and a map of zone->enabled for error reporting
func fetchAvailabilityZoneMapping(url string) (map[string]string, map[string]bool, error) {
	resp, err := http.Get(url)
	if err != nil {
		return nil, nil, err
	}
	defer func() {
		cerr := resp.Body.Close()
		if cerr != nil {
			fmt.Printf("warning: error closing response body: %v\n", cerr)
		}
	}()

	   reader := csv.NewReader(resp.Body)
	   mapping := make(map[string]string)
	   enabledMap := make(map[string]bool)
	   // Read header
	   header, err := reader.Read()
	   if err != nil {
			   return nil, nil, err
	   }
	   // Find column indexes
	   var (
			   idxCluster, idxZone, idxEnabled int
			   foundCluster, foundZone, foundEnabled bool
	   )
	   for i, col := range header {
			   switch col {
			   case "Cluster Name":
					   idxCluster, foundCluster = i, true
			   case "AvailabilityZone":
					   idxZone, foundZone = i, true
			   case "Enabled":
					   idxEnabled, foundEnabled = i, true
			   }
	   }
	   if !foundCluster || !foundZone || !foundEnabled {
			   return nil, nil, fmt.Errorf("CSV must have 'Cluster Name', 'AvailabilityZone', and 'Enabled' columns")
	   }
	   for {
			   record, err := reader.Read()
			   if err == io.EOF {
					   break
			   }
			   if err != nil {
					   return nil, nil, err
			   }
			   if len(record) <= idxEnabled {
					   continue
			   }
			   clusterName := record[idxCluster]
			   availabilityZone := record[idxZone]
			   enabled := record[idxEnabled]
			   if clusterName == "" || availabilityZone == "" {
					   continue
			   }
			   enabledMap[availabilityZone] = (enabled == "enabled")
			   if enabled == "enabled" {
					   mapping[availabilityZone] = clusterName
			   }
	   }
	   return mapping, enabledMap, nil
}
// ...existing code...

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

// Function to dynamically select and parse JSON file based on a resource name (e.g., cluster name)
func readDetailsByName(resourceType, resourceName string) (map[string]interface{}, error) {
	filePath := fmt.Sprintf("/etc/provider/%s-%s.json", resourceType, resourceName)
	data, err := os.ReadFile(filePath)
	if err != nil {
		return nil, err
	}
	var details map[string]interface{}
	if err := json.Unmarshal(data, &details); err != nil {
		return nil, err
	}
	return details, nil
}

// Helper to get a value by key from the details map
func getValue(details map[string]interface{}, key string) (string, error) {
	if v, ok := details[key]; ok {
		if s, ok := v.(string); ok {
			return s, nil
		}
		return "", fmt.Errorf("value for key '%s' is not a string", key)
	}
	return "", fmt.Errorf("key '%s' not found in details", key)
}


func (r *VirtualMachineReconciler) Reconcile(ctx context.Context, req reconcile.Request) (reconcile.Result, error) {
	   r.log.Debug("Reconciling Nutanix VirtualMachine", "name", req.NamespacedName)

	   var vm v1alpha1.VirtualMachine
	   if err := r.Get(ctx, req.NamespacedName, &vm); err != nil {
			   return reconcile.Result{}, client.IgnoreNotFound(err)
	   }

	   // Load ProviderConfig
	   var pc v1beta1.ProviderConfig
	   // Assuming the provider config is named "default", adjust if necessary
	   if err := r.Get(ctx, client.ObjectKey{Name: "default"}, &pc); err != nil {
			   return reconcile.Result{}, err
	   }

	   // If availabilityZone is specified and mapping is enabled, fetch mapping from ProviderConfig's URL and map it to clusterName
	   if vm.Spec.AvailabilityZone != "" && pc.Spec.EnableAvailabilityZoneMapping {
			   mappingURL := pc.Spec.AvailabilityZoneMappingURL
			   if mappingURL == "" {
					   return reconcile.Result{}, fmt.Errorf("availabilityZone specified but ProviderConfig does not have availabilityZoneMappingURL set")
			   }
			   mapping, enabledMap, err := fetchAvailabilityZoneMapping(mappingURL)
			   if err != nil {
					   return reconcile.Result{}, fmt.Errorf("failed to fetch availability zone mapping: %v", err)
			   }
			   enabled, found := enabledMap[vm.Spec.AvailabilityZone]
			   if !found {
					   allowed := make([]string, 0, len(enabledMap))
					   for k := range enabledMap {
							   allowed = append(allowed, k)
					   }
					   return reconcile.Result{}, fmt.Errorf("availabilityZone '%s' is not recognized. Allowed values: %v", vm.Spec.AvailabilityZone, allowed)
			   }
			   if !enabled {
					   return reconcile.Result{}, fmt.Errorf("availabilityZone '%s' is currently disabled and cannot be used for VM deployment", vm.Spec.AvailabilityZone)
			   }
			   cluster, ok := mapping[vm.Spec.AvailabilityZone]
			   if !ok {
					   return reconcile.Result{}, fmt.Errorf("internal error: enabled availabilityZone '%s' not mapped to a cluster", vm.Spec.AvailabilityZone)
			   }
			   vm.Spec.ClusterName = cluster
	   }

	// LoB validation logic
	if pc.Spec.IsLoBMandatory && vm.Spec.LoB == "" {
		return reconcile.Result{}, fmt.Errorf("LoB is mandatory but not provided")
	}
	if vm.Spec.LoB != "" {
		found := false
		for _, allowedLoB := range pc.Spec.AllowedLoBs {
			if vm.Spec.LoB == allowedLoB {
				found = true
				break
			}
		}
		if !found {
			return reconcile.Result{}, fmt.Errorf("LoB value '%s' is not in the allowed list: %v", vm.Spec.LoB, pc.Spec.AllowedLoBs)
		}
	}


	   // Enforce datacenter validation: only allow datacenters listed in ProviderConfig.PrismCentralEndpoints
	   var currentCreds v1beta1.ProviderCredentials
	   if vm.Spec.Datacenter != "" {
			   if len(pc.Spec.PrismCentralEndpoints) == 0 {
					   return reconcile.Result{}, fmt.Errorf("datacenter specified in VM spec, but no PrismCentralEndpoints configured in ProviderConfig")
			   }
			   if _, ok := pc.Spec.PrismCentralEndpoints[vm.Spec.Datacenter]; !ok {
					   // Build allowed datacenter list for error message
					   allowed := make([]string, 0, len(pc.Spec.PrismCentralEndpoints))
					   for k := range pc.Spec.PrismCentralEndpoints {
							   allowed = append(allowed, k)
					   }
					   return reconcile.Result{}, fmt.Errorf("datacenter '%s' is not allowed. Allowed values: %v", vm.Spec.Datacenter, allowed)
			   }
			   // Only allow datacenters that are present in PrismCentralEndpoints
			   if dcCreds, ok := pc.Spec.DatacenterCredentials[vm.Spec.Datacenter]; ok {
					   currentCreds = dcCreds
			   } else {
					   currentCreds = pc.Spec.Credentials
			   }
	   } else {
			   // Use default credentials if no datacenter is specified
			   currentCreds = pc.Spec.Credentials
	   }

	if currentCreds.Source != "Secret" {
		return reconcile.Result{}, fmt.Errorf("only Secret credentials source is supported")
	}
	secretRef := currentCreds.SecretRef

	var secret corev1.Secret
	if err := r.Get(ctx, client.ObjectKey{Namespace: secretRef.Namespace, Name: secretRef.Name}, &secret); err != nil {
		return reconcile.Result{}, err
	}
	creds := struct {
		Endpoint string `json:"endpoint"`
		Username string `json:"username"`
		Password string `json:"password"`
		Insecure bool   `json:"insecure"`
	}{}
	if err := json.Unmarshal(secret.Data[secretRef.Key], &creds); err != nil {
		return reconcile.Result{}, err
	}

	// Determine the Prism Central endpoint to use
	var prismCentralEndpoint string
	if vm.Spec.Datacenter != "" {
		if len(pc.Spec.PrismCentralEndpoints) == 0 {
			return reconcile.Result{}, fmt.Errorf("datacenter specified in VM spec, but no PrismCentralEndpoints configured in ProviderConfig")
		}
		var ok bool
		prismCentralEndpoint, ok = pc.Spec.PrismCentralEndpoints[vm.Spec.Datacenter]
		if !ok {
			return reconcile.Result{}, fmt.Errorf("datacenter '%s' not found in ProviderConfig's PrismCentralEndpoints map", vm.Spec.Datacenter)
		}
	} else if creds.Endpoint != "" {
		// Fallback to direct endpoint from credentials if no datacenter is specified
		prismCentralEndpoint = creds.Endpoint
	} else {
		return reconcile.Result{}, fmt.Errorf("no datacenter specified in VM spec and no default endpoint in credentials")
	}

	ntxCli := nutanix.NewClient(prismCentralEndpoint, creds.Username, creds.Password, creds.Insecure)

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
	clusterDetails, err := readDetailsByName("cluster", clusterName)
	if err != nil {
		r.log.Debug("Failed to read cluster details", "error", err)
		return reconcile.Result{}, err
	}
	clusterUuid, err := getValue(clusterDetails, "uuid")
	if err != nil {
		r.log.Debug("Failed to get cluster uuid from details", "error", err)
		return reconcile.Result{}, err
	}
	vm.Spec.ClusterUUID = clusterUuid

	// If ImageUUID is not set but ImageName is, resolve the latest matching image
	if vm.Spec.ImageUUID == "" && vm.Spec.ImageName != "" {
		images, err := ntxCli.ListImages(ctx)
		if err != nil {
			r.log.Debug("Failed to list images", "error", err)
			return reconcile.Result{}, err
		}
		var latestImage *nutanix.ImageInfo
		for _, img := range images {
			if img.Name != "" && vm.Spec.ImageName != "" && containsIgnoreCase(img.Name, vm.Spec.ImageName) {
				if latestImage == nil || img.CreatedTime > latestImage.CreatedTime {
					latestImage = &img
				}
			}
		}
		if latestImage == nil {
			r.log.Debug("No matching image found for partial name", "imageName", vm.Spec.ImageName)
			return reconcile.Result{}, fmt.Errorf("no image found matching name: %s", vm.Spec.ImageName)
		}
		vm.Spec.ImageUUID = latestImage.UUID
	}

	// If SubnetUUID is not set but SubnetName is, resolve the latest matching subnet
	if vm.Spec.SubnetUUID == "" && vm.Spec.SubnetName != "" {
		subnets, err := ntxCli.ListSubnets(ctx)
		if err != nil {
			r.log.Debug("Failed to list subnets", "error", err)
			return reconcile.Result{}, err
		}
		var latestSubnet *nutanix.SubnetInfo
		for _, sn := range subnets {
			if sn.Name != "" && vm.Spec.SubnetName != "" && containsIgnoreCase(sn.Name, vm.Spec.SubnetName) {
				if latestSubnet == nil || sn.CreatedTime > latestSubnet.CreatedTime {
					latestSubnet = &sn
				}
			}
		}
		if latestSubnet == nil {
			r.log.Debug("No matching subnet found for partial name", "subnetName", vm.Spec.SubnetName)
			return reconcile.Result{}, fmt.Errorf("no subnet found matching name: %s", vm.Spec.SubnetName)
		}

		// Enforce allowed_repos restriction from subnet JSON file
		// Use label 'repo' on the VM as the repo identifier
		repoName := ""
		if val, ok := vm.Labels["repo"]; ok {
			repoName = val
		}
		details, err := readDetailsByName("network", latestSubnet.Name)
		if err == nil {
			if allowed, ok := details["allowed_repos"]; ok {
				if allowedList, ok := allowed.([]interface{}); ok {
					if len(allowedList) > 0 {
						repoAllowed := false
						if repoName != "" {
							for _, v := range allowedList {
								if s, ok := v.(string); ok && s == repoName {
									repoAllowed = true
									break
								}
							}
						}
						if !repoAllowed {
							return reconcile.Result{}, fmt.Errorf("repo '%s' is not allowed to use subnet '%s'", repoName, latestSubnet.Name)
						}
					} // else: allowed_repos is empty, allow any repo
				}
			}
		}

		vm.Spec.SubnetUUID = latestSubnet.UUID
	}

	// If ClusterUUID is not set but ClusterName is, resolve the latest matching cluster
	if vm.Spec.ClusterUUID == "" && vm.Spec.ClusterName != "" {
		clusterUUID, err := fetchClusterUUID(ntxCli, vm.Spec.ClusterName)
		if err != nil {
			r.log.Debug("No matching cluster found for name", "clusterName", vm.Spec.ClusterName, "error", err)
			return reconcile.Result{}, fmt.Errorf("no cluster found matching name: %s", vm.Spec.ClusterName)
		}
		vm.Spec.ClusterUUID = clusterUUID
	}

	// Resolve additionalDisks image UUIDs if needed
	for i, disk := range vm.Spec.AdditionalDisks {
		if disk.ImageUUID == "" && disk.ImageName != "" {
			images, err := ntxCli.ListImages(ctx)
			if err != nil {
				r.log.Debug("Failed to list images for additional disk", "error", err)
				return reconcile.Result{}, err
			}
			var latestImage *nutanix.ImageInfo
			for _, img := range images {
				if img.Name != "" && disk.ImageName != "" && containsIgnoreCase(img.Name, disk.ImageName) {
					if latestImage == nil || img.CreatedTime > latestImage.CreatedTime {
						latestImage = &img
					}
				}
			}
			if latestImage == nil {
				r.log.Debug("No matching image found for additional disk partial name", "imageName", disk.ImageName)
				return reconcile.Result{}, fmt.Errorf("no image found matching name for additional disk: %s", disk.ImageName)
			}
			vm.Spec.AdditionalDisks[i].ImageUUID = latestImage.UUID
		}
	}

	// Handle observe
	_, err = ntxCli.GetVM(ctx, vm.Status.VMID)
	if err != nil {
		r.log.Debug("Failed to get VM", "error", err)
		return reconcile.Result{}, err
	}
	return reconcile.Result{}, nil
}

// containsIgnoreCase checks if s contains substr, case-insensitive
func containsIgnoreCase(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr || (len(substr) > 0 && containsIgnoreCase(s[1:], substr))) ||
		(len(substr) > 0 && (len(s) > 0 && (s[0]|32) == (substr[0]|32) && containsIgnoreCase(s[1:], substr[1:])))
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
