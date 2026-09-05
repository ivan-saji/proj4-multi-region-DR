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

data "azurerm_managed_disk" "vm_primary_os_disk" {
  name                = azurerm_linux_virtual_machine.vm_primary.os_disk[0].name
  resource_group_name = azurerm_resource_group.rg_primary.name
}
#Mention the replication of VM
resource "azurerm_site_recovery_replicated_vm" "vm-replication" {
  name                                      = "vm-replication"
  resource_group_name                       = azurerm_resource_group.rg_primary.name
  recovery_vault_name                       = azurerm_recovery_services_vault.rsv_vault.name
  source_recovery_fabric_name               = azurerm_site_recovery_fabric.primary.name
  source_recovery_protection_container_name = azurerm_site_recovery_protection_container.primary.name
  source_vm_id                              = azurerm_linux_virtual_machine.vm_primary.id
  recovery_replication_policy_id            = azurerm_site_recovery_replication_policy.policy.id


  target_resource_group_id                = azurerm_resource_group.rg_dr.id
  target_recovery_fabric_id               = azurerm_site_recovery_fabric.dr.id
  target_recovery_protection_container_id = azurerm_site_recovery_protection_container.dr.id
  managed_disk {
    disk_id                    = lower(data.azurerm_managed_disk.vm_primary_os_disk.id)
    staging_storage_account_id = azurerm_storage_account.sa_primary_cache.id
    target_resource_group_id   = azurerm_resource_group.rg_dr.id
    target_disk_type           = "Standard_LRS"
    target_replica_disk_type   = "Standard_LRS"
  }
  network_interface {
    source_network_interface_id = azurerm_network_interface.testvm_nic.id

  }

  depends_on = [
    azurerm_site_recovery_protection_container_mapping.primary_to_dr
  ]
}
