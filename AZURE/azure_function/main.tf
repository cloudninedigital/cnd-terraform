

# Create an App Service Plan for Function App
resource "azurerm_app_service_plan" "main" {
  name                     = "functionapp-serviceplan"
  location                 = var.resource_group_location
  resource_group_name      = var.resource_group_name
  kind                     = "FunctionApp"
  sku {
    tier = "Standard"
    size = "S1"
  }
}

# Create a Storage Account
resource "azurerm_storage_account" "function" {
  name                     = "${var.name}-function"
  resource_group_name       = var.resource_group_name
  location                 = var.resource_group_location
  account_tier              = "Standard"
  account_replication_type = "LRS"
}

# Create the source storage container for the ZIP file
resource "azurerm_storage_container" "function_container" {
  name                  = "function-container"
  storage_account_id    = azurerm_storage_account.function.id
  container_access_type = "private"
}

# Create the Function App
resource "azurerm_function_app" "function" {
  name                       = var.name
  location                 = var.resource_group_location
  resource_group_name      = var.resource_group_name
  app_service_plan_id        = azurerm_app_service_plan.main.id
  storage_account_name      = azurerm_storage_account.function.name
  storage_account_access_key = azurerm_storage_account.function.primary_access_key

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "python"
    "AZURE_STORAGE_CONNECTION_STRING" = azurerm_storage_account.function.primary_connection_string
  }

  site_config {
    linux_fx_version = "PYTHON|${var.python_version}"  # Set the Python version as required
  }

  depends_on = [
    azurerm_app_service_plan.main,
    azurerm_storage_account.function
  ]
}



data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = var.source_dir # Path to your function code directory
  output_path = "${path.module}/functionapp.zip"  # Path to output the ZIP file
}

# Upload Python ZIP file to Blob Storage (Upload the ZIP locally, then specify the path here)
resource "azurerm_storage_blob" "function_zip" {
  name                   = "functionapp.zip"
  storage_account_name   = azurerm_storage_account.function.name
  storage_container_name = azurerm_storage_container.function_container.name
  type                   = "Block"
  source                 = data.archive_file.function_zip.output_path  # Path to your ZIP file
}

# Deploy the Python Function from ZIP (Blob Storage to Function App)
resource "azurerm_function_app_deployment" "example" {
  function_app_id       = azurerm_function_app.function.id
  source                = azurerm_storage_blob.function_zip.url  # URL to your ZIP blob
  type                  = "zip"

  depends_on = [
    azurerm_function_app.function,
    azurerm_storage_blob.function_zip
  ]
}