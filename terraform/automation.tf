resource "azurerm_automation_account" "asr_automation" {

  name                = "rsv-vault-asr-automation"
  location            = azurerm_resource_group.rg_dr.location
  resource_group_name = azurerm_resource_group.rg_dr.name

  sku_name = "Basic"

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "dr-lab"
    purpose     = "asr-automation"
  }
}