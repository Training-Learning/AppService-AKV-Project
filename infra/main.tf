terraform {
  required_version = "~> 1.8"

  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.8" }
    random  = { source = "hashicorp/random",  version = "~> 3.6" }
  }
}

provider "azurerm" {
  features {}
}

resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

# -------------------------
# Resource Group & Network
# -------------------------
resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-appsvc"
  address_space       = [var.vnet_cidr]     # e.g., 10.20.0.0/16
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_subnet" "snet_pe" {
  name                                      = "snet-private-endpoints"
  resource_group_name                       = azurerm_resource_group.rg.name
  virtual_network_name                      = azurerm_virtual_network.vnet.name
  address_prefixes                          = [var.snet_pe_cidr]  # e.g., 10.20.1.0/24
  # private_endpoint_network_policies_enabled = false
  private_endpoint_network_policies = "Disabled"

}

# -------------------------
# Private DNS for App Service PE
# -------------------------
resource "azurerm_private_dns_zone" "appsvc" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "appsvc_link" {
  name                  = "appsvc-privatelink-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.appsvc.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
}

# -------------------------
# App Service Plan + Linux Web App
# -------------------------
resource "azurerm_service_plan" "plan" {
  name                = "asp-internal"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "B1"   # Basic supports Private Endpoint
  tags                = var.tags
}

resource "azurerm_linux_web_app" "app" {
  name                = "webapp-internal-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.plan.id

  https_only                    = true
  public_network_access_enabled = false  # lock to Private Endpoint only

  identity { type = "SystemAssigned" }

  site_config {
    ftps_state          = "Disabled"
    minimum_tls_version = "1.2"
    always_on           = true
  }

  tags = var.tags
}

# -------------------------
# Private Endpoint (Inbound: /sites)
# -------------------------
resource "azurerm_private_endpoint" "pe" {
  name                = "pe-webapp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.snet_pe.id
  tags                = var.tags

  private_service_connection {
    name                           = "pe-webapp-sites"
    private_connection_resource_id = azurerm_linux_web_app.app.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.appsvc.id]
  }
}
