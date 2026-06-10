output "cluster_id" {
  description = "Resource ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.id
}

output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.name
}

output "kube_config_raw" {
  description = "Raw kubeconfig for the AKS cluster (sensitive)"
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}

output "host" {
  description = "Kubernetes API server private endpoint (reachable only from within the VNet)"
  value       = azurerm_kubernetes_cluster.this.kube_config[0].host
  sensitive   = true
}

output "kubelet_identity_object_id" {
  description = "Object ID of the AKS kubelet managed identity (used for the AcrPull role assignment)"
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

output "private_fqdn" {
  description = "Private FQDN of the AKS API server"
  value       = azurerm_kubernetes_cluster.this.private_fqdn
}
