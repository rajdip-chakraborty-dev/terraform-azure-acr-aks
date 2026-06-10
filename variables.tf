variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
  default     = "rg-acr-aks"
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "eastus"
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
  default     = "vnet-acr-aks"
}

variable "vnet_address_space" {
  description = "Address space for the VNet. Must be large enough for AKS (Azure CNI), ACR private endpoint, and agent subnets"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "aks_subnet_name" {
  description = "Name of the AKS nodes/pods subnet"
  type        = string
  default     = "subnet-aks"
}

variable "aks_subnet_prefix" {
  description = "CIDR for AKS subnet. Azure CNI allocates one IP per pod — use /16 for large clusters"
  type        = string
  default     = "10.240.0.0/16"
}

variable "acr_subnet_name" {
  description = "Name of the subnet for the ACR private endpoint"
  type        = string
  default     = "subnet-acr-pe"
}

variable "acr_subnet_prefix" {
  description = "CIDR for the ACR private endpoint subnet"
  type        = string
  default     = "10.241.0.0/24"
}

variable "agents_subnet_name" {
  description = "Name of the subnet for self-hosted ADO build agents"
  type        = string
  default     = "subnet-ado-agents"
}

variable "agents_subnet_prefix" {
  description = "CIDR for the self-hosted ADO agents subnet"
  type        = string
  default     = "10.242.0.0/24"
}

variable "acr_name" {
  description = "Name of the Azure Container Registry. Must be globally unique, 5–50 alphanumeric characters"
  type        = string
  default     = "acracraks001"
}

variable "acr_sku" {
  description = "SKU for the Container Registry. Premium is required for private endpoints"
  type        = string
  default     = "Premium"

  validation {
    condition     = var.acr_sku == "Premium"
    error_message = "ACR SKU must be 'Premium' to enable private endpoints."
  }
}

variable "aks_cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "aks-acr-aks"
}

variable "aks_dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
  default     = "aksacraks"
}

variable "kubernetes_version" {
  description = "Kubernetes version. Set to null to use the latest supported version"
  type        = string
  default     = null
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 2
}

variable "node_vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_DS2_v2"
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
  description = "Tags applied to all resources"
  type        = map(string)
  default = {
    Environment = "Development"
    Project     = "Private-ACR-AKS"
    ManagedBy   = "Terraform"
  }
}
