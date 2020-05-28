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

variable "imgRGname" {
  description = "Where the images lie"
  default = "RuslanG-RG-VmssPatchPocImg"
}

resource "azurerm_resource_group" "vmsspatchrg" {
  name     = "${var.prefix}-VmssPatchPocRes"
  location = "West Europe"
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


data "azurerm_shared_image_version" "first" {
  name                = "1.0.0"
  image_name          = "ubuntu_nginx"
  gallery_name        = "vmss_imgal"
  resource_group_name = var.imgRGname
}

data "azurerm_shared_image_version" "second" {
  name                = "1.0.1"
  image_name          = "ubuntu_nginx"
  gallery_name        = "vmss_imgal"
  resource_group_name = var.imgRGname
}



resource "azurerm_public_ip" "vmss" {
  name                         = "vmss-public-ip"
  location                     = azurerm_resource_group.vmsspatchrg.location
  resource_group_name          = azurerm_resource_group.vmsspatchrg.name
  allocation_method            = "Static"
  domain_name_label            = "${lower(var.prefix)}-${random_string.token1.result}"
  sku                          = "Standard"
}


resource "azurerm_virtual_network" "vmss" {
  name                = "vmss-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.vmsspatchrg.location
  resource_group_name = azurerm_resource_group.vmsspatchrg.name

}


resource "azurerm_subnet" "vmssbpatch" {
  name                 = "vmss-subnet"
  resource_group_name  = azurerm_resource_group.vmsspatchrg.name
  virtual_network_name = azurerm_virtual_network.vmss.name
  address_prefixes       = ["10.0.4.0/24"]
}

resource "azurerm_subnet" "vmssbpatch2" {
  name                 = "vmss-subnet2"
  resource_group_name  = azurerm_resource_group.vmsspatchrg.name
  virtual_network_name = azurerm_virtual_network.vmss.name
  address_prefixes       = ["10.0.5.0/24"]
}

resource "azurerm_lb" "vmssbpatch" {
  name                = "vmss-lb"
  location            = azurerm_resource_group.vmsspatchrg.location
  resource_group_name = azurerm_resource_group.vmsspatchrg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.vmss.id
  }

}

resource "azurerm_lb_backend_address_pool" "bpepool" {
  resource_group_name = azurerm_resource_group.vmsspatchrg.name
  loadbalancer_id     = azurerm_lb.vmssbpatch.id
  name                = "BackEndAddressPool01"
}

resource "azurerm_lb_backend_address_pool" "bpepool2" {
  resource_group_name = azurerm_resource_group.vmsspatchrg.name
  loadbalancer_id     = azurerm_lb.vmssbpatch.id
  name                = "BackEndAddressPool02"
}

resource "azurerm_lb_probe" "vmsspatch" {
  resource_group_name = azurerm_resource_group.vmsspatchrg.name
  loadbalancer_id     = azurerm_lb.vmssbpatch.id
  name                = "http-running-probe"
  port                = 80
}

resource "azurerm_lb_rule" "lbnatrulehttp" {
  resource_group_name            = azurerm_resource_group.vmsspatchrg.name
  loadbalancer_id                = azurerm_lb.vmssbpatch.id
  name                           = "http"
  protocol                       = "Tcp"
  frontend_port                  = "80"
  backend_port                   = "80"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.bpepool.id
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = azurerm_lb_probe.vmsspatch.id
}


resource "azurerm_lb_rule" "lbnatrulessh" {
  resource_group_name            = azurerm_resource_group.vmsspatchrg.name
  loadbalancer_id                = azurerm_lb.vmssbpatch.id
  name                           = "ssh"
  protocol                       = "Tcp"
  frontend_port                  = "22"
  backend_port                   = "22"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.bpepool.id
  frontend_ip_configuration_name = "PublicIPAddress"
  #probe_id                       = azurerm_lb_probe.vmsspatch.id
}



resource "azurerm_network_security_group" "vmsspatch" {
  name                = "${var.prefix}-NSG"
  location            = azurerm_resource_group.vmsspatchrg.location
  resource_group_name = azurerm_resource_group.vmsspatchrg.name
    
  security_rule {
      name                       = "SSH"
      priority                   = 1001
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
  }

    security_rule {
      name                       = "HTTP"
      priority                   = 1002
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
  }

}

resource "azurerm_subnet_network_security_group_association" "nsg1" {
  subnet_id                 = azurerm_subnet.vmssbpatch.id
  network_security_group_id = azurerm_network_security_group.vmsspatch.id
}

resource "azurerm_subnet_network_security_group_association" "nsg2" {
  subnet_id                 = azurerm_subnet.vmssbpatch2.id
  network_security_group_id = azurerm_network_security_group.vmsspatch.id
}

#scale set built from Packer image
resource "azurerm_virtual_machine_scale_set" "vmss" {
  name                = "${lower(var.prefix)}-vmss01"
  location            = azurerm_resource_group.vmsspatchrg.location
  resource_group_name = azurerm_resource_group.vmsspatchrg.name
  upgrade_policy_mode = "Manual"

  sku {
    name     = "Standard_DS1_v2"
    tier     = "Standard"
    capacity = 2
  }

  storage_profile_image_reference {
    id=data.azurerm_shared_image_version.first.id
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
    name    = "terraformnetworkprofile"
    primary = true

    ip_configuration {
      name                                   = "IPConfiguration"
      subnet_id                              = azurerm_subnet.vmssbpatch.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bpepool.id]
      primary = true
    }
  }
  
}


/*

resource "azurerm_virtual_machine_scale_set" "vmss2" {
  name                = "${lower(var.prefix)}-vmss02"
  location            = azurerm_resource_group.vmsspatchrg.location
  resource_group_name = azurerm_resource_group.vmsspatchrg.name
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
      subnet_id                              = azurerm_subnet.vmssbpatch2.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bpepool2.id]
      primary = true
    }
  }
  
}

*/

data "azurerm_public_ip" "vmss" {
  name                = azurerm_public_ip.vmss.name
  resource_group_name = azurerm_resource_group.vmsspatchrg.name
}

output "VmssPublicIP" {
  value = data.azurerm_public_ip.vmss.ip_address
}

output "VmssPublicFQDN" {
  value = data.azurerm_public_ip.vmss.fqdn
}

output "VMResourceGroup" {
  value = azurerm_resource_group.vmsspatchrg.name
}

output "VMAdminUserName" {
  value = local.AdminUserName
}

output "VMAdminPassword" {
  value = random_string.pass1.result
}
