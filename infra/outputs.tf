output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
  description = "Resource Group"
}

output "webapp_name" {
  value       = azurerm_linux_web_app.app.name
  description = "Linux Web App name"
}

output "private_endpoint_ip" {
  value       = azurerm_private_endpoint.pe.private_service_connection[0].private_ip_address
  description = "Private Endpoint IP for the Web App"
}
