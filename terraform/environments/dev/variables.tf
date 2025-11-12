variable "environment" { type = string; default = "dev" }
variable "location" { type = string; default = "westeurope" }
variable "resource_group_name" { type = string; default = "rg-mindful-moments-dev" }
variable "vnet_name" { type = string; default = "vnet-mindful-moments-dev" }
variable "app_service_plan_name" { type = string; default = "asp-mindful-moments-dev" }
variable "app_service_name" { type = string; default = "app-mindful-moments-dev" }
variable "postgres_server_name" { type = string; default = "psql-mindful-moments-dev" }
variable "database_name" { type = string; default = "mindfuldb" }
variable "postgres_admin_login" { type = string; default = "psqladmin" }
variable "postgres_admin_password" { type = string; sensitive = true }
variable "storage_account_prefix" { type = string; default = "stmindful" }
variable "key_vault_prefix" { type = string; default = "kv-mindful" }
variable "log_analytics_workspace_name" { type = string; default = "log-mindful-moments-dev" }
variable "application_insights_name" { type = string; default = "appi-mindful-moments-dev" }
variable "action_group_name" { type = string; default = "ag-mindful-moments-dev" }
variable "alert_email" { type = string }
variable "project" { type = string; default = "mindful-moments" }
variable "owner" { type = string; default = "alberto.lacambra" }
