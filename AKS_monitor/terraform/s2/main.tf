provider "azurerm" {
    # The "feature" block is required for AzureRM provider 2.x. 
    # If you are using version 1.x, the "features" block is not allowed.
    version = "~>2.0"
    features {}
}

resource "random_id" "log_analytics_workspace_name_suffix" {
    byte_length = 8
}


data "azurerm_resource_group" "main" {
  name     = "POC-IaC-AKSmon"
}
