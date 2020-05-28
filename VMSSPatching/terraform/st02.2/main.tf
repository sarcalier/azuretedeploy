
provider "azurerm" {
    # The "feature" block is required for AzureRM provider 2.x. 
    # If you are using version 1.x, the "features" block is not allowed.
    version = "~>2.0"
    features {}
}

variable "prefix" {
  description = "Type in the prefix to name resources in this deployment "
  default = "RuslanG-RG"
}

data "azurerm_resource_group" "vmsspatchrg" {
  name     = "${var.prefix}-VmssPatchPocRes"
}

resource "random_string" "token1" {
  length  = 3
  upper   = false
  lower   = false
  number  = true
  special = false
}

resource "random_string" "pass1" {
  length  = 16
  upper   = true
  lower   = true
  number  = true
  special = true
}

locals {
  AdminUserName = "tstadmin"
}

data "azurerm_shared_image_version" "second" {
  name                = "1.0.1"
  image_name          = "ubuntu_nginx"
  gallery_name        = "vmss_imgal"
  resource_group_name = "${var.prefix}-VmssPatchPocImg"
}


data "azurerm_virtual_network" "vmss" {
  name                = "vmss-vnet"
  resource_group_name = data.azurerm_resource_group.vmsspatchrg.name

}


data "azurerm_subnet" "vmssbpatch2" {
  name                 = "vmss-subnet2"
  resource_group_name  = data.azurerm_resource_group.vmsspatchrg.name
  virtual_network_name = data.azurerm_virtual_network.vmss.name
}

data "azurerm_lb" "vmssbpatch" {
  name                = "vmss-lb"
  resource_group_name = data.azurerm_resource_group.vmsspatchrg.name
}


data "azurerm_lb_backend_address_pool" "bpepool2" {
  name            = "BackEndAddressPool02"
  loadbalancer_id = data.azurerm_lb.vmssbpatch.id
}


resource "azurerm_virtual_machine_scale_set" "vmss2" {
  name                = "${lower(var.prefix)}-vmss02"
  location            = data.azurerm_resource_group.vmsspatchrg.location
  resource_group_name = data.azurerm_resource_group.vmsspatchrg.name
  upgrade_policy_mode = "Manual"

  sku {
    name     = "Standard_DS1_v2"
    tier     = "Standard"
    capacity = 2
  }

  storage_profile_image_reference {
    id=data.azurerm_shared_image_version.second.id
    #publisher = "Canonical"
    #offer     = "UbuntuServer"
    #sku       = "18.04-LTS"
    #version   = "latest"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_profile_data_disk {
    lun          = 0
    caching        = "ReadWrite"
    create_option  = "Empty"
    disk_size_gb   = 10
  }

  os_profile {
    computer_name_prefix = "vmlab"
    admin_username       = local.AdminUserName
    admin_password       = random_string.pass1.result
  }

  os_profile_linux_config {
    disable_password_authentication = false

#    ssh_keys {
#      path     = "/home/azureuser/.ssh/authorized_keys"
#      key_data = file("ssh_key/id_rsa.pub")
#    }
  }

  network_profile {
    name    = "terraformnetworkprofile2"
    primary = true

    ip_configuration {
      name                                   = "IPConfiguration2"
      subnet_id                              = data.azurerm_subnet.vmssbpatch2.id
      load_balancer_backend_address_pool_ids = [data.azurerm_lb_backend_address_pool.bpepool2.id]
      primary = true
    }
  }
  
}