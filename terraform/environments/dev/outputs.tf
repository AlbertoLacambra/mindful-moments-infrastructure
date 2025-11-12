output "resource_group_name" { value = azurerm_resource_group.main.name }
output "app_service_url" { value = "https://${module.app_service.app_service_default_hostname}" }
output "postgres_server_fqdn" { value = module.database.server_fqdn }
output "database_name" { value = module.database.database_name }
output "storage_account_name" { value = module.storage.storage_account_name }
output "key_vault_uri" { value = module.key_vault.key_vault_uri }
output "application_insights_connection_string" { value = module.monitoring.application_insights_connection_string; sensitive = true }
output "app_service_principal_id" { value = module.app_service.principal_id }
