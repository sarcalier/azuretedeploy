variable "prefix" {
  description = "Type in the prefix to name resources in this deployment "
#  default = "VmssPOC"
}


variable "location" {
  description = "The location where resources are created"
  default     = "westeurope"
}

#variable "resource_group_name" {
#  description = "The name of the resource group in which the resources are created"
#  default     = "RuslanG-RG-TerraformVMSS"
#}


variable "application_port" {
    description = "The port that you want to expose to the external load balancer"
    default     = 80
}




variable "TimeZone" {
#  default = "Russian Standard Time"
  description = "Time Zone to define Working Hours"
}

variable "WorkingHours" {
  type        = number
  description = "Define Working Hours.1='8:00-17:00'; 2='9:00-18:00'; 3='10:00-19:00'"

#  validation {
#    # regex(...) fails if it cannot find a match
#    condition     = can(regex("1-3", var.WorkingHours))
#    error_message = "The input value must be in between 1-3."
#  }
}
