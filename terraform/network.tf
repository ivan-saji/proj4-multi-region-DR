# Primary Network here

#mention the VNet of Primary network

resource "azurerm_virtual_network" "vnet_primary" {
  name                = "vnet-primary"
  resource_group_name = azurerm_resource_group.rg_primary.name
  location            = azurerm_resource_group.rg_primary.location
  address_space       = ["10.0.0.0/16"]
}

#Subnet in primary vnet
resource "azurerm_subnet" "vnet_primary_subnet" {
  name                 = "vnet_primary_subnet"
  resource_group_name  = azurerm_resource_group.rg_primary.name
  virtual_network_name = azurerm_virtual_network.vnet_primary.name
  address_prefixes     = ["10.0.1.0/24"]
}

#----------------------------------------------------------------------

#Virtual Network in DR
resource "azurerm_virtual_network" "vnet_dr" {
  name                = "vnet-dr"
  resource_group_name = azurerm_resource_group.rg_dr.name
  location            = azurerm_resource_group.rg_dr.location
  address_space       = ["10.10.0.0/16"]
}

#Subnet in VNet 2
resource "azurerm_subnet" "vnet_dr_subnet" {
  name                 = "vnet_dr_subnet"
  resource_group_name  = azurerm_resource_group.rg_dr.name
  virtual_network_name = azurerm_virtual_network.vnet_dr.name
  address_prefixes     = ["10.10.1.0/24"]
}