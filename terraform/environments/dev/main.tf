terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    # Backend configuration will be provided via backend config file
    # or command line arguments during terraform init
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy       = true
      recover_soft_deleted_key_vaults    = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

data "azurerm_client_config" "current" {}

# Random suffix for globally unique resources
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = local.common_tags
}

# Private DNS Zone for PostgreSQL
resource "azurerm_private_dns_zone" "postgres" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name

  tags = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "postgres-vnet-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = module.networking.vnet_id

  tags = local.common_tags
}

# Networking Module
module "networking" {
  source = "../../modules/networking"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  vnet_name           = var.vnet_name

  tags = local.common_tags
}

# Database Module
module "database" {
  source = "../../modules/database"

  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  server_name            = var.postgres_server_name
  database_name          = var.database_name
  administrator_login    = var.postgres_admin_login
  administrator_password = var.postgres_admin_password
  delegated_subnet_id    = module.networking.database_subnet_id
  private_dns_zone_id    = azurerm_private_dns_zone.postgres.id

  tags = local.common_tags

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.postgres
  ]
}

# Storage Module
module "storage" {
  source = "../../modules/storage"

  resource_group_name  = azurerm_resource_group.main.name
  location             = azurerm_resource_group.main.location
  storage_account_name = "${var.storage_account_prefix}${random_string.suffix.result}"

  tags = local.common_tags
}

# App Service Module (needs to be created before monitoring and key vault)
module "app_service" {
  source = "../../modules/app-service"

  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  app_service_plan_name = var.app_service_plan_name
  app_service_name      = var.app_service_name
  subnet_id             = module.networking.app_subnet_id

  # Initial app settings (will be updated after monitoring and key vault)
  app_settings = {
    "NODE_ENV" = var.environment
    "PORT"     = "8080"
  }

  tags = local.common_tags
}

# Monitoring Module
module "monitoring" {
  source = "../../modules/monitoring"

  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  log_analytics_workspace_name = var.log_analytics_workspace_name
  application_insights_name    = var.application_insights_name
  action_group_name            = var.action_group_name
  alert_email                  = var.alert_email
  app_service_id               = module.app_service.app_service_id
  database_server_id           = module.database.server_id

  tags = local.common_tags
}

# Key Vault Module
module "key_vault" {
  source = "../../modules/key-vault"

  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  key_vault_name           = "${var.key_vault_prefix}${random_string.suffix.result}"
  tenant_id                = data.azurerm_client_config.current.tenant_id
  app_service_principal_id = module.app_service.principal_id

  secrets = {
    "postgres-admin-password"   = var.postgres_admin_password
    "storage-connection-string" = module.storage.primary_connection_string
    "database-url"              = "postgresql://${var.postgres_admin_login}:${var.postgres_admin_password}@${module.database.server_fqdn}:5432/${var.database_name}?sslmode=require"
  }

  tags = local.common_tags

  depends_on = [
    module.app_service,
    module.storage,
    module.database
  ]
}
