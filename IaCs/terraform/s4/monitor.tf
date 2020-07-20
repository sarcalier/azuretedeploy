resource "azurerm_log_analytics_workspace" "main" {
  name                = "logs-01"
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

