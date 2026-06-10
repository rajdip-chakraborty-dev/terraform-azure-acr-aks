variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
}

variable "aks_subnet_name" {
  description = "Name of the AKS nodes/pods subnet"
  type        = string
}

variable "aks_subnet_prefix" {
  description = "CIDR for the AKS subnet"
  type        = string
}

variable "acr_subnet_name" {
  description = "Name of the ACR private endpoint subnet"
  type        = string
}

variable "acr_subnet_prefix" {
  description = "CIDR for the ACR private endpoint subnet"
  type        = string
}

variable "agents_subnet_name" {
  description = "Name of the self-hosted ADO agents subnet"
  type        = string
}

variable "agents_subnet_prefix" {
  description = "CIDR for the ADO agents subnet"
  type        = string
}

variable "tags" {
  description = "Tags to apply to network resources"
  type        = map(string)
  default     = {}
}
