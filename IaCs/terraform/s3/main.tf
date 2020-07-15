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

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-IaCs-tf-s03"
  location = "West Europe"
}

resource "azurerm_virtual_network" "main" {
  name                = "vpc01"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}



resource "azurerm_subnet" "sub01" {
  name                 = "subnet01"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.10.4.0/24"]
  service_endpoints    = ["Microsoft.Sql"]
}

resource "azurerm_subnet" "sub02" {
  name                 = "subnet02"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.10.5.0/24"]
  service_endpoints    = ["Microsoft.Sql"]
}


resource "azurerm_monitor_action_group" "main" {
  name                = "CriticalAlertsAction"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "p0action"

  email_receiver {
    name                    = "sendtodevops"
    email_address           = "devops@contoso.com"
    use_common_alert_schema = true
  }

}