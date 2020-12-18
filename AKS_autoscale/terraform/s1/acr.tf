resource "azurerm_container_registry" "acr" {
  name                     = "contreg${random_string.hash.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  sku                      = "Premium"
  admin_enabled            = false
  georeplication_locations = ["France Central"]
}