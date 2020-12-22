#variable "client_id" {
#    description = "Service Principal ID"
#}
#variable "client_secret" {
#    description = "Service Principal password"
#}

variable "agent_count" {
    default = 1
}

#variable "ssh_public_key" {
#    default = "~/.ssh/id_rsa.pub"
#}

variable "dns_prefix" {
    default = "k8spoc3"
}

variable cluster_name {
    default = "k8spoc3"
}

#variable resource_group_name {
#    default = "azure-k8stest"
#}

variable location {
    default = "West Europe"
}

variable log_analytics_workspace_name {
    default = "LogAnalyticsWorkspaceName"
}

# refer https://azure.microsoft.com/global-infrastructure/services/?products=monitor for log analytics available regions
variable log_analytics_workspace_location {
    default = "westeurope"
}

# refer https://azure.microsoft.com/pricing/details/monitor/ for log analytics pricing 
variable log_analytics_workspace_sku {
    default = "PerGB2018"
}