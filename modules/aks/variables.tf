variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version. Set to null to use the latest supported version"
  type        = string
  default     = null
}

variable "aks_subnet_id" {
  description = "ID of the subnet for AKS nodes and pods (Azure CNI)"
  type        = string
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 2
}

variable "vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "acr_id" {
  description = "Resource ID of the ACR — used to assign AcrPull role to the kubelet identity"
  type        = string
}

variable "service_cidr" {
  description = "CIDR range for Kubernetes services. Must not overlap with the VNet address space"
  type        = string
  default     = "192.168.0.0/16"
}

variable "dns_service_ip" {
  description = "IP address for the Kubernetes DNS service. Must be within service_cidr"
  type        = string
  default     = "192.168.0.10"
}

variable "tags" {
  description = "Tags to apply to AKS resources"
  type        = map(string)
  default     = {}
}
