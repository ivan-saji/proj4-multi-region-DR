#Mention the RSV code

resource "azurerm_recovery_services_vault" "rsv_vault" {
  name                = "rsv-vault"
  location            = azurerm_resource_group.rg_dr.location
  resource_group_name = azurerm_resource_group.rg_dr.name
  sku                 = "Standard"
}