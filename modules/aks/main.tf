resource "azurerm_kubernetes_cluster" "this" {
  name                    = var.cluster_name
  location                = var.location
  resource_group_name     = var.resource_group_name
  dns_prefix              = var.dns_prefix
  kubernetes_version      = var.kubernetes_version
  private_cluster_enabled = true

  default_node_pool {
    name            = "systempool"
    node_count      = var.node_count
    vm_size         = var.vm_size
    vnet_subnet_id  = var.aks_subnet_id
    os_disk_size_gb = 50
    type            = "VirtualMachineScaleSets"

    upgrade_settings {
      max_surge = "33%"
    }
  }

  # System-assigned managed identity removes the need to manage service principal credentials
  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
  }

  role_based_access_control_enabled = true

  tags = var.tags
}

# Grant AKS kubelet identity permission to pull images from the private ACR
# This eliminates the need for imagePullSecrets in Kubernetes manifests
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}
