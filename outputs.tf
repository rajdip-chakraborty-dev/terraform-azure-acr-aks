output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.resource_group.name
}

output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.network.vnet_id
}

output "aks_subnet_id" {
  description = "ID of the AKS nodes/pods subnet"
  value       = module.network.aks_subnet_id
}

output "agents_subnet_id" {
  description = "ID of the self-hosted ADO agents subnet"
  value       = module.network.agents_subnet_id
}

output "acr_id" {
  description = "Resource ID of the Azure Container Registry"
  value       = module.acr.acr_id
}

output "acr_name" {
  description = "Name of the Azure Container Registry"
  value       = module.acr.acr_name
}

output "acr_login_server" {
  description = "Login server URL for the ACR (use this in ADO Variable Group as 'acrLoginServer')"
  value       = module.acr.login_server
}

output "aks_cluster_id" {
  description = "Resource ID of the AKS cluster"
  value       = module.aks.cluster_id
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = module.aks.cluster_name
}

output "aks_private_fqdn" {
  description = "Private FQDN of the AKS API server (reachable only from within the VNet)"
  value       = module.aks.private_fqdn
}

output "aks_kube_config" {
  description = "Raw kubeconfig for the AKS cluster (sensitive — use 'terraform output -raw aks_kube_config')"
  value       = module.aks.kube_config_raw
  sensitive   = true
}

output "kubelet_identity_object_id" {
  description = "Object ID of the AKS kubelet managed identity (granted AcrPull on the registry)"
  value       = module.aks.kubelet_identity_object_id
}
