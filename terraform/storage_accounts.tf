resource "random_integer" "storage_suffix" {

  min = 100000
  max = 999999
}

#Create a storage account with LRS for caching for site recovery in primary region

resource "azurerm_storage_account" "sa_primary_cache" {
  name = "stasrprimary${random_integer.storage_suffix.result}"
  resource_group_name      = azurerm_resource_group.rg_primary.name
  location                 = azurerm_resource_group.rg_primary.location
  account_tier             = "Standard"
  account_kind             = "StorageV2"

  account_replication_type = "LRS"
}