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

resource "azurerm_resource_group" "vmsspatchrg" {
  name     = "${var.prefix}-VmssPatchPoc"
  location = "West Europe"
}

resource "azurerm_shared_image_gallery" "sig" {
  name                = "vmss_sig"
  resource_group_name = azurerm_resource_group.vmsspatchrg.name
  location            = azurerm_resource_group.vmsspatchrg.location
  description         = "Shared VM images"
}
