resource "azurerm_container_registry" "this" {
  name                          = var.acr_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = var.sku
  admin_enabled                 = false
  public_network_access_enabled = false

  # Allow trusted Azure services (e.g., AKS nodes via managed identity) to bypass the network restriction
  network_rule_bypass_option = "AzureServices"

  tags = var.tags
}

resource "azurerm_private_endpoint" "acr" {
  name                = "pe-${var.acr_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.acr_subnet_id

  private_service_connection {
    name                           = "psc-${var.acr_name}"
    private_connection_resource_id = azurerm_container_registry.this.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdns-zone-group-acr"
    private_dns_zone_ids = [var.acr_private_dns_zone_id]
  }

  tags = var.tags
}
