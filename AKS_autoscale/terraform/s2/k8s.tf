resource "azurerm_kubernetes_cluster" "k8s" {
    name                = var.cluster_name
    location            = data.azurerm_resource_group.main.location
    resource_group_name = data.azurerm_resource_group.main.name
    dns_prefix          = var.dns_prefix

    linux_profile {
        admin_username = "ubuntu"

        ssh_key {
            key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEA1DuuaaD0nhNW71BoMx8flaJtDxshCyHyGMkvFfWudcKCKQN+N8IiVlQFIPTj9uochVg9t5ReqgktzuXA1t2Lk0We73TTc3imF+r2IuFakyvHI3ZNmHjYMIGgqJb7oXTdNOiC6Va1NzDm12CilSO5WwYXlGecISGpGqw+FwBJJMxTpJ1llHJay/h85Fa7JPXnyHPxfyTAad1UQ2E0MhZXV8T2VHik7mKddPiUHo5WlanuKQ5DSxDX4KyAdAw0yjVdmurUmxSd9Fo6UgxIGa/SHoS33F197scnLCPgCanoVQfO8QR6ckGBlpUmSeLrBXDxn3E9fcF5mNTmYnGx9f6ySQ=="
        }
    }

    default_node_pool {
        name                = "agentpool"
        node_count          = var.agent_count
        vm_size             = "Standard_D2_v2"
        enable_auto_scaling = true
        min_count           = "1"
        max_count           = "3"
        max_pods            = "31"

    }

#    service_principal {
#        client_id     = var.client_id
#        client_secret = var.client_secret
#    }


    identity {
        type = "SystemAssigned"
    }

    addon_profile {
        oms_agent {
        enabled                    = true
        log_analytics_workspace_id = azurerm_log_analytics_workspace.test.id
        }
    }

    network_profile {
    load_balancer_sku = "Standard"
    network_plugin = "kubenet"
    }

    tags = {
        Environment = "Development"
    }
}