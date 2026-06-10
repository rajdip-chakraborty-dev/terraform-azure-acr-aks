terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # Uncomment and configure to store state in Azure Blob Storage (recommended for teams)
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "<globally-unique-storage-account-name>"
  #   container_name       = "tfstate"
  #   key                  = "azure-acr-aks/terraform.tfstate"
  # }
}

provider "azurerm" {
  features {}
  # Authentication via environment variables (preferred for CI/CD):
  #   ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID
  # Or interactively: az login
}

data "azurerm_client_config" "current" {}

module "resource_group" {
  source   = "./modules/resource_group"
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

module "network" {
  source               = "./modules/network"
  resource_group_name  = module.resource_group.name
  location             = var.location
  vnet_name            = var.vnet_name
  vnet_address_space   = var.vnet_address_space
  aks_subnet_name      = var.aks_subnet_name
  aks_subnet_prefix    = var.aks_subnet_prefix
  acr_subnet_name      = var.acr_subnet_name
  acr_subnet_prefix    = var.acr_subnet_prefix
  agents_subnet_name   = var.agents_subnet_name
  agents_subnet_prefix = var.agents_subnet_prefix
  tags                 = var.tags
}

module "acr" {
  source                  = "./modules/acr"
  resource_group_name     = module.resource_group.name
  location                = var.location
  acr_name                = var.acr_name
  sku                     = var.acr_sku
  acr_subnet_id           = module.network.acr_subnet_id
  acr_private_dns_zone_id = module.network.acr_private_dns_zone_id
  tags                    = var.tags
}

module "aks" {
  source              = "./modules/aks"
  resource_group_name = module.resource_group.name
  location            = var.location
  cluster_name        = var.aks_cluster_name
  dns_prefix          = var.aks_dns_prefix
  kubernetes_version  = var.kubernetes_version
  aks_subnet_id       = module.network.aks_subnet_id
  node_count          = var.node_count
  vm_size             = var.node_vm_size
  acr_id              = module.acr.acr_id
  service_cidr        = var.service_cidr
  dns_service_ip      = var.dns_service_ip
  tags                = var.tags
}
