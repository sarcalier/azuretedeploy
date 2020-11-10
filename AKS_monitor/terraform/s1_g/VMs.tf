resource "azurerm_virtual_machine" "vm01" {
  name                  = "vm01"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.nic01.id]
  vm_size               = "Standard_B2s"


  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18_04-lts-gen2"
    version   = "latest"
  }
  storage_os_disk {
    name              = "vm01_OSdsk"
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
}


resource "azurerm_virtual_machine_extension" "vmext01" {
  name                 = "docker_install"
  virtual_machine_id   = azurerm_virtual_machine.vm01.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

#  settings = <<SETTINGS
#    {
#        "commandToExecute": "apt-get update && apt-get install -y docker.io && systemctl start docker && systemctl enable docker"
#    }
#  SETTINGS

  settings = <<SETTINGS
    {
        "fileUris": ["https://raw.githubusercontent.com/sarcalier/azuretedeploy/master/AKS_monitor/scripts/post_depl_g.sh"],
        "commandToExecute": "sh post_depl_g.sh"
    }
  SETTINGS

  depends_on = [azurerm_virtual_machine.vm01]
}
