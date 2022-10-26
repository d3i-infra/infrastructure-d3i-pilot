# Create the Linux App Service Plan
resource "azurerm_service_plan" "appserviceplan" {
  name                = "${lower(var.project_name)}-webapp-asp-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "B1"
}

# Create the web app, pass in the App Service Plan ID
resource "azurerm_linux_web_app" "webapp" {
  name                      = "${lower(var.project_name)}-webapp-${var.environment}"
  location                  = azurerm_resource_group.rg.location
  resource_group_name       = azurerm_resource_group.rg.name
  service_plan_id           = azurerm_service_plan.appserviceplan.id
  virtual_network_subnet_id = azurerm_subnet.webapp.id
  https_only                = true
 

  site_config {
    always_on = true
    application_stack {

      docker_image     = var.dockerimageurl 
      docker_image_tag = var.dockerimagetag
    }
   minimum_tls_version = "1.2"
  
  }

  app_settings = {
    "BUNDLE_DOMAIN" = "${lower(var.project_name)}-webapp-${var.environment}.azurewebsites.net"
    "STATIC_PATH" = "/tmp"
    "DB_NAME"=var.database_name
    "DB_USER"=var.postgres_username
    "DB_PASS"=azurerm_key_vault_secret.postgrespassword.value
    "DB_HOST"=azurerm_postgresql_flexible_server.database.fqdn
    "SECRET_KEY_BASE"="1sdlkfjdhsflkdshjflasjhkslfjhdaslkfjhdsalfkjhsdaflksdjahflsdkajfhf"
    "WEBSITES_PORT"=var.app_listening_port
    "AZURE_BLOB_STORAGE_USER"=azurerm_storage_account.sa.name
    "AZURE_BLOB_STORAGE_PASSWORD"=azurerm_storage_account.sa.primary_access_key
    "AZURE_BLOB_CONTAINER"=azurerm_storage_container.sc.name
    "HTTP_PORT"=var.app_listening_port
  }

  identity {
    type = "SystemAssigned"
  }
  
  logs {
    http_logs {
      file_system {
        retention_in_days = 10
        retention_in_mb = 50
      }
  }
    application_logs {
      file_system_level = "Verbose"
    }
    detailed_error_messages = true
  }

  depends_on = [azurerm_postgresql_flexible_server.database]
}

