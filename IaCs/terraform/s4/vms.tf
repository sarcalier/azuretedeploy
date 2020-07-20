resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}-vm01"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_DS1_v2"
  zones                 = [1]


  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "vm01"
    admin_username = var.AdminUserName
    admin_password = random_string.pass1.result
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}



resource "azurerm_virtual_machine_extension" "main" {
  name                 = "nginx"
  virtual_machine_id   = azurerm_virtual_machine.main.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "apt-get update && apt-get install -y nginx "
    }
  SETTINGS
  depends_on = [azurerm_virtual_machine.main]
}


resource "azurerm_virtual_machine" "main2" {
  name                  = "${var.prefix}-vm02"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.main2.id]
  vm_size               = "Standard_DS1_v2"
  zones                 = [2]


  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk2"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "vm02"
    admin_username = var.AdminUserName
    admin_password = random_string.pass1.result
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}



resource "azurerm_virtual_machine_extension" "main2" {
  name                 = "nginx"
  virtual_machine_id   = azurerm_virtual_machine.main2.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "apt-get update && apt-get install -y nginx "
    }
  SETTINGS
  depends_on = [azurerm_virtual_machine.main2]
}



resource "azurerm_virtual_machine_extension" "oms_mma1" {
  name                       = "${var.prefix}-OMSExtension1"
  virtual_machine_id         = azurerm_virtual_machine.main.id
  depends_on                 = [azurerm_log_analytics_workspace.main]
  publisher                  = "Microsoft.EnterpriseCloud.Monitoring"
  type                       = "OmsAgentForLinux"
  type_handler_version       = "1.8"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "workspaceId" :  "${azurerm_log_analytics_workspace.main.workspace_id}"
    }
  SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
      "workspaceKey" : "${azurerm_log_analytics_workspace.main.primary_shared_key}"
    }
  PROTECTED_SETTINGS
}


resource "azurerm_virtual_machine_extension" "oms_mma2" {
  name                       = "${var.prefix}-OMSExtension2"
  virtual_machine_id         = azurerm_virtual_machine.main2.id
  depends_on                 = [azurerm_log_analytics_workspace.main]
  publisher                  = "Microsoft.EnterpriseCloud.Monitoring"
  type                       = "OmsAgentForLinux"
  type_handler_version       = "1.8"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "workspaceId" :  "${azurerm_log_analytics_workspace.main.workspace_id}"
    }
  SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
      "workspaceKey" : "${azurerm_log_analytics_workspace.main.primary_shared_key}"
    }
  PROTECTED_SETTINGS
}