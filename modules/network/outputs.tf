output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.this.name
}

output "aks_subnet_id" {
  description = "ID of the AKS nodes/pods subnet"
  value       = azurerm_subnet.aks.id
}

output "acr_subnet_id" {
  description = "ID of the ACR private endpoint subnet"
  value       = azurerm_subnet.acr.id
}

output "agents_subnet_id" {
  description = "ID of the self-hosted ADO agents subnet"
  value       = azurerm_subnet.agents.id
}

output "acr_private_dns_zone_id" {
  description = "ID of the private DNS zone for ACR (privatelink.azurecr.io)"
  value       = azurerm_private_dns_zone.acr.id
}

output "acr_private_dns_zone_name" {
  description = "Name of the private DNS zone for ACR"
  value       = azurerm_private_dns_zone.acr.name
}
