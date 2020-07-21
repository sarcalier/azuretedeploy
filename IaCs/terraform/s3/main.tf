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


resource "azurerm_log_analytics_workspace" "main" {
  name                = "logs-01-${random_string.hash.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
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

resource "azurerm_monitor_scheduled_query_rules_alert" "main" {
  name                = format("%s-queryrule", var.prefix)
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  action {
    action_group           = [azurerm_monitor_action_group.main.id]
  }
  data_source_id = azurerm_log_analytics_workspace.main.id
  description    = "Alert when total results cross threshold"
  enabled        = true
  # Count all requests with server error result code grouped into 5-minute bins
  query       = <<-QUERY
    Heartbeat
    | where Computer contains "vm01"
  QUERY
  severity    = 1
  frequency   = 5
  time_window = 5
  trigger {
    operator  = "LessThan"
    threshold = 1
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert" "main2" {
  name                = format("%s-queryrule2", var.prefix)
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  action {
    action_group           = [azurerm_monitor_action_group.main.id]
  }
  data_source_id = azurerm_log_analytics_workspace.main.id
  description    = "Alert when total results cross threshold"
  enabled        = true
  # Count all requests with server error result code grouped into 5-minute bins
  query       = <<-QUERY
    Heartbeat
    | where Computer contains "vm02"
  QUERY
  severity    = 1
  frequency   = 5
  time_window = 5
  trigger {
    operator  = "LessThan"
    threshold = 1
  }
}
