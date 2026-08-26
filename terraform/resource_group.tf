#Mention the Resource Groups

#Primary Resource Grup

resource "azurerm_resource_group" "rg_primary" {
  name     = "rg-primary"
  location = "Central India"
}

#DR Resource Group
resource "azurerm_resource_group" "rg_dr" {
  name     = "rg-dr"
  location = "South India"
}