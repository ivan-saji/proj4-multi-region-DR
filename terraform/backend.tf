terraform {
  backend "azurerm" {
    resource_group_name  = "rg01-backend"
    storage_account_name = "rg01st01backend"
    container_name       = "tfstate"
    key                  = "infra.tfstate4"
  }
}
