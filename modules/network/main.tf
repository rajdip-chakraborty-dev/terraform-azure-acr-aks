resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# AKS nodes and pods (Azure CNI — one IP per pod)
resource "azurerm_subnet" "aks" {
  name                 = var.aks_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.aks_subnet_prefix]
}

# ACR private endpoint — network policies must be disabled for private endpoints to attach
resource "azurerm_subnet" "acr" {
  name                 = var.acr_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.acr_subnet_prefix]

  private_endpoint_network_policies_enabled = false
}

# Self-hosted ADO agents — must reside in this VNet to reach private AKS and ACR endpoints
resource "azurerm_subnet" "agents" {
  name                 = var.agents_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.agents_subnet_prefix]
}

# NSG for AKS subnet — AKS manages its own rules; attach an empty NSG so it is addressable
resource "azurerm_network_security_group" "aks" {
  name                = "nsg-${var.aks_subnet_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks.id
}

# NSG for ADO agents subnet — block unsolicited inbound Internet traffic
resource "azurerm_network_security_group" "agents" {
  name                = "nsg-${var.agents_subnet_name}"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "deny-internet-inbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "agents" {
  subnet_id                 = azurerm_subnet.agents.id
  network_security_group_id = azurerm_network_security_group.agents.id
}

# Private DNS zone so all resources in this VNet resolve ACR's private endpoint address
resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  name                  = "pdns-vnet-link-acr"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = azurerm_virtual_network.this.id
  registration_enabled  = false
  tags                  = var.tags
}
