
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

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-IaCs"
  location = "West Europe"
}

resource "azurerm_virtual_network" "example" {
  name                = "vnet01"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes       = ["10.10.1.0/24"]
}

resource "azurerm_subnet" "example2" {
  name                 = "Subnet02"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes       = ["10.10.2.0/24"]
}

resource "azurerm_public_ip" "example" {
  name                = "pubpip"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "example" {
  name                = "bastion01"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                 = "IPconfiguration"
    subnet_id            = azurerm_subnet.example.id
    public_ip_address_id = azurerm_public_ip.example.id
  }
}