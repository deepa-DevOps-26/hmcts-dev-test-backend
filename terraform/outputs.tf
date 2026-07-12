output "app_url" {
  description = "Public URL of the Container App."
  value       = "https://${azurerm_container_app.backend.ingress[0].fqdn}"
}

output "db_fqdn" {
  description = "PostgreSQL server FQDN."
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "key_vault_name" {
  description = "Name of the Key Vault."
  value       = azurerm_key_vault.main.name
}
