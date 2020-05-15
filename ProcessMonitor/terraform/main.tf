##########
########## Process monitor on linux VM via Dependency Agent
##########


provider "azurerm" {
    # The "feature" block is required for AzureRM provider 2.x. 
    # If you are using version 1.x, the "features" block is not allowed.
    version = "~>2.0"
    features {}
}


variable "prefix" {
  #default = "ProcMon01"
}

locals {
  AdminUserName = "tstadmin"
}

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-TerraformAuto"
  location = "westeurope"
}


resource "azurerm_automation_account" "main" {
  name                = "${var.prefix}-AutomationAccount"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name             = "Basic"
}

resource "azurerm_automation_runbook" "main" {
  name                    = "HelloRunbook"
  location                = azurerm_resource_group.main.location
  resource_group_name     = azurerm_resource_group.main.name
  automation_account_name = azurerm_automation_account.main.name
  log_verbose             = "true"
  log_progress            = "true"
  description             = "This is an example runbook"
  runbook_type            = "PowerShell"

  publish_content_link {
    uri = "https://raw.githubusercontent.com/sarcalier/azuretedeploy/master/ProcessMonitor/HelloRunbook.ps1"
  }
}


resource "random_string" "token1" {
  length  = 10
  upper   = true
  lower   = true
  number  = true
  special = false
}

resource "random_string" "token2" {
  length  = 31
  upper   = true
  lower   = true
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
  webhookUri = "https://s2events.azure-automation.net/webhooks?token=%2b${random_string.token1.result}%2b${random_string.token2.result}%3d"
  webhookName = "hellowebhook"
}

resource "azurerm_template_deployment" "AA_webhook" {
  name                = "hello_webhook"
  resource_group_name = azurerm_resource_group.main.name
  deployment_mode     = "Incremental"
  template_body = <<DEPLOY
{
  "$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "resources": [
    {
      "name": "${azurerm_automation_account.main.name}/${local.webhookName}",
      "type": "Microsoft.Automation/automationAccounts/webhooks",
      "apiVersion": "2015-10-31",
      "properties": {
        "isEnabled": true,
        "uri": "${local.webhookUri}",
        "expiryTime": "2028-01-01T00:00:00.000+00:00",
        "parameters": {},
        "runbook": {
          "name": "${azurerm_automation_runbook.main.name}"
        }
      }
    }
  ]
}
DEPLOY
}


resource "azurerm_monitor_action_group" "main" {
  name                = "CriticalAlertsAction"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "p0action"

  automation_runbook_receiver {
    name                    = "action_1"
    automation_account_id   = azurerm_automation_account.main.id
    runbook_name            = azurerm_automation_runbook.main.name
    webhook_resource_id     = "${azurerm_automation_account.main.id}/webhooks/${local.webhookName}"
    is_global_runbook       = true
    service_uri             = local.webhookUri
    use_common_alert_schema = true
  }

}




resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.prefix}-LA-workspace"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}


resource "azurerm_log_analytics_linked_service" "main" {
  resource_group_name = azurerm_resource_group.main.name
  workspace_name      = azurerm_log_analytics_workspace.main.name
  resource_id         = azurerm_automation_account.main.id
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
  VMBoundPort
    | where ProcessName == "sshd" and TimeGenerated > ago(2m)
  QUERY
  severity    = 1
  frequency   = 5
  time_window = 1440
  trigger {
    operator  = "LessThan"
    threshold = 1
  }
}



resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefix       = "10.0.2.0/24"
}



# Create public IPs
resource "azurerm_public_ip" "main" {
  name                         = "${var.prefix}-PubIP"
  location                     = azurerm_resource_group.main.location
  resource_group_name          = azurerm_resource_group.main.name
  allocation_method            = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-MyNSG"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
    
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



resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}


# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "main" {
    network_interface_id      = azurerm_network_interface.main.id
    network_security_group_id = azurerm_network_security_group.main.id
}


resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}-vm"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "procmonvm"
    admin_username = local.AdminUserName
    admin_password = random_string.pass1.result
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}



resource "azurerm_virtual_machine_extension" "oms_mma" {
  name                       = "${var.prefix}-OMSExtension"
  virtual_machine_id         = azurerm_virtual_machine.main.id
  #location                   = azurerm_resource_group.main.name.location
  #resource_group_name        = azurerm_resource_group.main.name
  #virtual_machine_name       = azurerm_resource_group.main.name.location
  depends_on                 = [azurerm_log_analytics_workspace.main]
  publisher                  = "Microsoft.EnterpriseCloud.Monitoring"
  type                       = "OmsAgentForLinux"
  type_handler_version       = "1.8"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "workspaceId" :  "${azurerm_log_analytics_workspace.main.workspace_id}"
    }
  SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
      "workspaceKey" : "${azurerm_log_analytics_workspace.main.primary_shared_key}"
    }
  PROTECTED_SETTINGS
}


resource "azurerm_virtual_machine_extension" "DAAgentForLinux" {

#  count                      = var.dependancyAgent == null ? 0 : 1
  name                       = "DAAgentForLinux"
  virtual_machine_id         = azurerm_virtual_machine.main.id
  #location                   = azurerm_resource_group.main.location
  #resource_group_name        = azurerm_resource_group.main.name
  #virtual_machine_name       = azurerm_virtual_machine.main.name
  publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
  type                       = "DependencyAgentLinux"
  type_handler_version       = "9.5"
  auto_upgrade_minor_version = true
  depends_on                 = [azurerm_virtual_machine_extension.oms_mma]
  #tags = var.tags
}


#hopefully enabling Azure Monitor for the VM
resource "azurerm_template_deployment" "main" {
  name                = "enableVMmonitor"
  resource_group_name = azurerm_resource_group.main.name

  template_body = <<DEPLOY
{
    "$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "VmName": {
            "type": "string",
            "metadata": {
                "description": "The Virtual Machine Name."
            }
        },
        "VmLocation": {
            "type": "string",
            "metadata": {
                "description": "The Virtual Machine Location."
            }
        },
        "VmResourceId": {
            "type": "string",
            "metadata": {
                "description": "VM Resource ID."
            }
        },
        "VmType": {
            "type": "string",
            "metadata": {
                "description": "VM type: 1. virtualMachines, 2 virtualMachineScaleSets."
            }
        },
        "OsType": {
            "type": "string",
            "metadata": {
                "description": "Operating System. Example Windows or Linux"
            }
        },
        "DaExtensionName": {
            "type": "string",
            "metadata": {
                "description": "The name will be Windows: DependencyAgentWindows, Linux: DependencyAgentLinux."
            }
        },
        "DaExtensionType": {
            "type": "string",
            "metadata": {
                "description": "Dependency Agent Extension Type, Windows: DependencyAgentWindows, Linux: DependencyAgentLinux."
            }
        },
        "DaExtensionVersion": {
            "type": "string",
            "metadata": {
                "description": "Dependency Agent Extension Version."
            }
        },
        "MmaAgentName": {
            "type": "string",
            "metadata": {
                "description": "The name will be Windows: MMAExtension, Linux: OMSExtension."
            }
        },
        "MmaExtensionType": {
            "type": "string",
            "metadata": {
                "description": "MMA Extension Type, Windows: MicrosoftMonitoringAgent, Linux: OmsAgentForLinux."
            }
        },
        "MmaExtensionVersion": {
            "type": "string",
            "metadata": {
                "description": "MMA/OMS Extension Version."
            }
        },
        "WorkspaceId": {
            "type": "string",
            "metadata": {
                "description": "Workspace ID."
            }
        },
        "WorkspaceResourceId": {
            "type": "string",
            "metadata": {
                "description": "Workspace Resource ID."
            }
        },
        "WorkspaceLocation": {
            "type": "string",
            "metadata": {
                "description": "Workspace Location."
            }
        },
        "OmsWorkspaceSku": {
            "defaultValue": "perGB2018",
            "allowedValues": [
                "free",
                "standalone",
                "pernode",
                "perGB2018"
            ],
            "type": "string",
            "metadata": {
                "description": "Select the SKU for your workspace."
            }
        },
        "DeploymentNameSuffix": {
            "type": "string",
            "metadata": {
                "description": "Deployment Name Suffix."
            }
        }
    },
    "variables": {
        "workloadType": "BaseOS",
        "resourceName": "[concat(toLower(parameters('VmName')), '_', toLower(variables('workloadType')))]",
        "stopOnMultipleConnections": "[if(equals(toUpper(parameters('OsType')), 'WINDOWS'), 'false', 'true')]"
    },
    "resources": [
        {
            "type": "Microsoft.Resources/deployments",
            "apiVersion": "2017-05-10",
            "name": "[concat('VMInsightsSolutionDeployment', parameters('DeploymentNameSuffix'))]",
            "properties": {
                "mode": "Incremental",
                "template": {
                    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
                    "contentVersion": "1.0.0.0",
                    "parameters": {},
                    "variables": {},
                    "resources": [
                        {
                            "apiVersion": "2015-11-01-preview",
                            "type": "Microsoft.OperationsManagement/solutions",
                            "location": "[parameters('WorkspaceLocation')]",
                            "name": "[concat('VMInsights', '(', split(parameters('WorkspaceResourceId'),'/')[8], ')')]",
                            "properties": {
                                "workspaceResourceId": "[parameters('WorkspaceResourceId')]"
                            },
                            "plan": {
                                "name": "[concat('VMInsights', '(', split(parameters('WorkspaceResourceId'),'/')[8], ')')]",
                                "product": "[concat('OMSGallery/', 'VMInsights')]",
                                "promotionCode": "",
                                "publisher": "Microsoft"
                            }
                        }
                    ]
                }
            },
            "subscriptionId": "[split(parameters('WorkspaceResourceId'),'/')[2]]",
            "resourceGroup": "[split(parameters('WorkspaceResourceId'),'/')[4]]"
        }
    ],
    "outputs": {}
}
DEPLOY


  # these key-value pairs are passed into the ARM Template's `parameters` block
  parameters = {
    VmName = azurerm_virtual_machine.main.name
    VmLocation = azurerm_resource_group.main.location
    VmResourceId = azurerm_virtual_machine.main.id
    VmType = "virtualMachines"
    OsType = "Linux"
    DaExtensionName = "DAAgentForLinux"
    DaExtensionType = "DependencyAgentLinux"
    DaExtensionVersion = "9.10"
    MmaAgentName = "${var.prefix}-OMSExtension"
    MmaExtensionType = "OmsAgentForLinux"
    MmaExtensionVersion = "1.7"
    WorkspaceId = azurerm_log_analytics_workspace.main.workspace_id
    WorkspaceResourceId = azurerm_log_analytics_workspace.main.id
    WorkspaceLocation = azurerm_resource_group.main.location
    OmsWorkspaceSku = "perGB2018"
    DeploymentNameSuffix = "-2020-04-10T17.25.32.229Z"


    #"WorkspaceResourceId" = azurerm_log_analytics_workspace.main.workspace_id
    #"WorkspaceLocation" = azurerm_resource_group.main.location
    #"DeploymentNameSuffix" = ""
  }

  deployment_mode = "Incremental"
  depends_on = [azurerm_virtual_machine.main]
}

#output "storageAccountName" {
#  value = azurerm_template_deployment.example.outputs["storageAccountName"]
#}

resource "azurerm_virtual_machine_extension" "main" {
  name                 = "procmonvm"
  #location             = azurerm_resource_group.main.location
  #resource_group_name  = azurerm_resource_group.main.name
  #virtual_machine_name = azurerm_virtual_machine.main.name
  virtual_machine_id   = azurerm_virtual_machine.main.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "apt-get update && apt-get install -y nginx "
    }
  SETTINGS
  depends_on = [azurerm_virtual_machine.main]
}


data "azurerm_public_ip" "main" {
  name                = azurerm_public_ip.main.name
  resource_group_name = azurerm_virtual_machine.main.resource_group_name
}

output "VmPublicIP" {
  value = data.azurerm_public_ip.main.ip_address
}

output "VmPublicFQDN" {
  value = azurerm_public_ip.main.fqdn
}

output "VMAdminUserName" {
  value = local.AdminUserName
}

output "VMAdminPassword" {
  value = random_string.pass1.result
}

output "VMResourceGroup" {
  value = azurerm_resource_group.main.name
}