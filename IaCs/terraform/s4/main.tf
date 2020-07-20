provider "azurerm" {
    # The "feature" block is required for AzureRM provider 2.x. 
    # If you are using version 1.x, the "features" block is not allowed.
    version = "~>2.0"
    features {}
}

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-IaCs-tf-s04"
  location = "West Europe"
}

resource "random_string" "pass1" {
  length  = 16
  upper   = true
  lower   = true
  number  = true
  special = true
}

resource "random_string" "hash" {
  length  = 5
  upper   = false
  lower   = true
  number  = true
  special = false
}