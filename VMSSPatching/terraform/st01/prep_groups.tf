provider "azurerm" {
    # The "feature" block is required for AzureRM provider 2.x. 
    # If you are using version 1.x, the "features" block is not allowed.
    version = "~>2.0"
    features {}
}
/*
variable "prefix" {
  description = "Type in the prefix to name resources in this deployment "
  default = "RuslanG-RG"
}
*/
resource "azurerm_resource_group" "vmsspatchimgrg" {
  name     = "imgResourceGroup"
  location = "West Europe"
}


resource "azurerm_shared_image_gallery" "sig" {
  name                = "vmss_imgal"
  resource_group_name = azurerm_resource_group.vmsspatchimgrg.name
  location            = azurerm_resource_group.vmsspatchimgrg.location
  description         = "Shared VM images"
}


resource "azurerm_shared_image" "vmssimg" {
  name                = "ubuntu_nginx"
  gallery_name        = azurerm_shared_image_gallery.sig.name
  resource_group_name = azurerm_resource_group.vmsspatchimgrg.name
  location            = azurerm_resource_group.vmsspatchimgrg.location
  os_type             = "Linux"

  identifier {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
  }
}

