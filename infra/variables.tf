variable "rg_name" {
  description = "Resource Group name"
  type        = string
}

variable "location" {
  description = "Azure region (e.g., eastus2)"
  type        = string
}

variable "vnet_cidr" {
  description = "VNet address space CIDR (e.g., 10.20.0.0/16)"
  type        = string
}

variable "snet_pe_cidr" {
  description = "Private Endpoint subnet CIDR (e.g., 10.20.1.0/24)"
  type        = string
}

variable "tags" {
  description = "Optional tags to apply to resources"
  type        = map(string)
  default     = {
    platform   = "appservice-internal"
    multi_env  = "true"
    env_scope  = "platform"
  }
}
