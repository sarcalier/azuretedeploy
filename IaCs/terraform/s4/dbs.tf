resource "azurerm_sql_server" "sqlserver_1" {
  name                         = "azuresqlserver1-${random_string.hash.result}"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = "4dm1n157r470r"
  administrator_login_password = random_string.pass1.result
}


resource "azurerm_sql_server" "sqlserver_2" {
  name                         = "azuresqlserver2-${random_string.hash.result}"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = "4dm1n157r470r"
  administrator_login_password = random_string.pass1.result
}

resource "azurerm_sql_virtual_network_rule" "sqlvnetrule1" {
  name                = "sql-vnet-rule"
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_sql_server.sqlserver_1.name
  subnet_id           = azurerm_subnet.sub01.id
}

resource "azurerm_sql_virtual_network_rule" "sqlvnetrule2" {
  name                = "sql-vnet-rule2"
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_sql_server.sqlserver_2.name
  subnet_id           = azurerm_subnet.sub02.id
}