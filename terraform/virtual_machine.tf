#Create the NIC of VM

resource "azurerm_network_interface" "testvm_nic" {
  name                = "TestVM-nic"
  location            = azurerm_resource_group.rg_primary.location
  resource_group_name = azurerm_resource_group.rg_primary.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.vnet_primary_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Mention the VM in primary region

resource "azurerm_linux_virtual_machine" "vm_primary" {
  name                            = "TestVM"
  resource_group_name             = azurerm_resource_group.rg_primary.name
  location                        = azurerm_resource_group.rg_primary.location
  size                            = "Standard_D2_v4"
  disable_password_authentication = false
  computer_name                   = "testvm"
  admin_username                  = "testadmin"
  admin_password                  = "Password1234!"

  network_interface_ids = [
    azurerm_network_interface.testvm_nic.id,
  ]

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }
  tags = {
    environment = "staging"
  }
}


# ASR VM replication setup

data "azurerm_managed_disk" "vm_primary_os_disk" {
  name                = azurerm_linux_virtual_machine.vm_primary.os_disk[0].name
  resource_group_name = azurerm_resource_group.rg_primary.name
}
#Mention the replication of VM
resource "azurerm_site_recovery_replicated_vm" "vm-replication" {
  name                                      = "vm-replication"
  resource_group_name                       = azurerm_resource_group.rg_dr.name
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
    source_network_interface_id   = azurerm_network_interface.testvm_nic.id
    target_subnet_name            = azurerm_subnet.vnet_dr_subnet.name
  }

  depends_on = [
    azurerm_site_recovery_protection_container_mapping.primary_to_dr,
    azurerm_site_recovery_network_mapping.net_map
  ]
}