locals {
  prefix = "hmcts-backend-${var.environment}"
  tags = {
    project     = "hmcts-backend"
    environment = var.environment
    managed_by  = "terraform"
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.prefix}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_key_vault" "main" {
  name                = "kv-${local.prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  tags                = local.tags
}

resource "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  value        = var.db_admin_password
  key_vault_id = azurerm_key_vault.main.id
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "psql-${local.prefix}"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  version                = "16"
  administrator_login    = var.db_admin_username
  administrator_password = var.db_admin_password
  sku_name               = "B_Standard_B1ms"
  storage_mb             = 32768
  backup_retention_days  = 7
  tags                   = local.tags
}

resource "azurerm_postgresql_flexible_server_database" "app" {
  name      = "devtest"
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

resource "azurerm_container_app_environment" "main" {
  name                = "cae-${local.prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags
}

resource "azurerm_container_app" "backend" {
  name                         = "ca-${local.prefix}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"
  tags                         = local.tags

  template {
    container {
      name   = "backend"
      image  = var.container_image
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "DB_HOST"
        value = azurerm_postgresql_flexible_server.main.fqdn
      }
      env {
        name  = "DB_PORT"
        value = "5432"
      }
      env {
        name  = "DB_NAME"
        value = azurerm_postgresql_flexible_server_database.app.name
      }
      env {
        name  = "DB_USER"
        value = var.db_admin_username
      }
      env {
        name        = "DB_PASSWORD"
        secret_name = "db-password"
      }
    }
  }

  secret {
    name  = "db-password"
    value = var.db_admin_password
  }

  ingress {
    external_enabled = true
    target_port      = 4000
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}
