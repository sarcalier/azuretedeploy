data "azurerm_public_ip" "lb_ip" {
  name                = azurerm_public_ip.pip01.name
  resource_group_name = azurerm_resource_group.main.name

  depends_on = [azurerm_public_ip.pip01]
}

output "LbPublicIP" {
  value = data.azurerm_public_ip.lb_ip.ip_address
}


output "VMResourceGroup" {
  value = azurerm_resource_group.main.name
}

output "VMAdminUserName" {
  value = var.AdminUserName
}

output "VMAdminPassword" {
  value = random_string.pass1.result
}

output "ContainerRegistry" {
  value = azurerm_container_registry.acr.name
}