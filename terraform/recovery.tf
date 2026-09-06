#Mention the RSV code

resource "azurerm_recovery_services_vault" "rsv_vault" {
  name                = "rsv-vault"
  location            = azurerm_resource_group.rg_dr.location
  resource_group_name = azurerm_resource_group.rg_dr.name
  sku                 = "Standard"
}

#Creating site recovery fabrics

resource "azurerm_site_recovery_fabric" "primary" {
  name                = "primary-fabric"
  resource_group_name = azurerm_resource_group.rg_dr.name
  recovery_vault_name = azurerm_recovery_services_vault.rsv_vault.name
  location            = azurerm_resource_group.rg_primary.location
}

resource "azurerm_site_recovery_fabric" "dr" {
  name                = "dr-fabric"
  resource_group_name = azurerm_resource_group.rg_dr.name
  recovery_vault_name = azurerm_recovery_services_vault.rsv_vault.name
  location            = azurerm_resource_group.rg_dr.location
}

#Creating site recovery protection container
resource "azurerm_site_recovery_protection_container" "primary" {
  name                 = "primary-container"
  resource_group_name  = azurerm_resource_group.rg_dr.name
  recovery_vault_name  = azurerm_recovery_services_vault.rsv_vault.name
  recovery_fabric_name = azurerm_site_recovery_fabric.primary.name
}

resource "azurerm_site_recovery_protection_container" "dr" {
  name                 = "dr-container"
  resource_group_name  = azurerm_resource_group.rg_dr.name
  recovery_vault_name  = azurerm_recovery_services_vault.rsv_vault.name
  recovery_fabric_name = azurerm_site_recovery_fabric.dr.name
}

#Creating site recovery policy
resource "azurerm_site_recovery_replication_policy" "policy" {
  name                = "replication-policy"
  resource_group_name = azurerm_resource_group.rg_dr.name
  recovery_vault_name = azurerm_recovery_services_vault.rsv_vault.name

  recovery_point_retention_in_minutes                  = 3 * 60
  application_consistent_snapshot_frequency_in_minutes = 1 * 60
}

#Creating Map
resource "azurerm_site_recovery_protection_container_mapping" "primary_to_dr" {
  name                                      = "primary-to-dr"
  resource_group_name                       = azurerm_resource_group.rg_dr.name
  recovery_vault_name                       = azurerm_recovery_services_vault.rsv_vault.name
  recovery_fabric_name                      = azurerm_site_recovery_fabric.primary.name
  recovery_source_protection_container_name = azurerm_site_recovery_protection_container.primary.name
  recovery_target_protection_container_id   = azurerm_site_recovery_protection_container.dr.id
  recovery_replication_policy_id            = azurerm_site_recovery_replication_policy.policy.id
}

# 6. Optional ASR Network Mapping (Ensures matching NIC target subnet on Failover)
resource "azurerm_site_recovery_network_mapping" "net_map" {
  name                         = "primary-to-dr-netmap"
  resource_group_name          = azurerm_resource_group.rg_dr.name
  recovery_vault_name          = azurerm_recovery_services_vault.rsv_vault.name
  source_recovery_fabric_name  = azurerm_site_recovery_fabric.primary.name
  target_recovery_fabric_name  = azurerm_site_recovery_fabric.dr.name
  source_network_id            = azurerm_virtual_network.vnet_primary.id
  target_network_id            = azurerm_virtual_network.vnet_dr.id
}

