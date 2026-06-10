variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "acr_name" {
  description = "Name of the Azure Container Registry (globally unique, 5–50 alphanumeric chars)"
  type        = string
}

variable "sku" {
  description = "SKU of the Container Registry. Must be Premium for private endpoints"
  type        = string
  default     = "Premium"
}

variable "acr_subnet_id" {
  description = "ID of the subnet where the ACR private endpoint will be created"
  type        = string
}

variable "acr_private_dns_zone_id" {
  description = "ID of the private DNS zone (privatelink.azurecr.io) for ACR name resolution"
  type        = string
}

variable "tags" {
  description = "Tags to apply to ACR resources"
  type        = map(string)
  default     = {}
}
