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
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
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
