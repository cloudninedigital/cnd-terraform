resource "azurerm_storage_account" "example" {
  name                     = "${var.name}sa"
  resource_group_name      = var.resource_group_name
  location                 = var.resource_group_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "example" {
  name                = "${var.name}-service-plan"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  os_type             = "Windows"
  sku_name            = "S1"
}

resource "azurerm_linux_function_app" "example" {
  name                = "${var.name}-function-app"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.example.id

  storage_account_name       = azurerm_storage_account.example.name
  storage_account_access_key = azurerm_storage_account.example.primary_access_key

    site_config {
    linux_fx_version = "PYTHON|${var.python_version}"  # Dynamically set Python version here
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "python"  # Specify Python as the runtime
  }
}

resource "azurerm_function_app_function" "example" {
  name            = "${var.name}-function"
  function_app_id = azurerm_linux_function_app.example.id
  language        = "Python"

  file {
    name    = "run.py"
    content = file(var.source_file)
  }
  file {
    name    = "requirements.txt"
    content = file(var.requirements_source_file)
  }

  test_data = jsonencode({
    "name" = "Azure"
  })

    config_json = jsonencode({
    "bindings" = [
      {
        "authLevel" = "function"
        "direction" = "in"
        "methods" = [
          "get",
          "post",
        ]
        "name" = "req"
        "type" = "httpTrigger"
      },
      {
        "direction" = "out"
        "name"      = "$return"
        "type"      = "http"
      },
      {
        "authLevel" = "function"
        "direction" = "in"
        "name"      = "timer"
        "type"      = "timerTrigger"
        "schedule"  = "0 0 0 * * *"  # This cron expression triggers the function daily at midnight UTC
      }
    ]
  })
}
