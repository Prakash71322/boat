resource "azurerm_resource_group" "skpresgrp" {
  name     = "skpresgrp${terraform.workspace}"
  location = "East US 2"
}

resource "azurerm_storage_account" "skpstracc" {
  name                     = "skpstracc"
  resource_group_name      = azurerm_resource_group.skpresgrp.name
  location                 = azurerm_resource_group.skpresgrp.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "${terraform.workspace}"
  }
}

resource "azurerm_virtual_network" "skpvirnet" {
  name                = "skp-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.skpresgrp.location
  resource_group_name = azurerm_resource_group.skpresgrp.name
}

resource "azurerm_subnet" "skpsubnet" {
  name                 = "skp-prisubnet"
  resource_group_name  = azurerm_resource_group.skpresgrp.name
  virtual_network_name = azurerm_virtual_network.skpvirnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "skpnic" {
  name                = "skp-nic"
  location            = azurerm_resource_group.skpresgrp.location
  resource_group_name = azurerm_resource_group.skpresgrp.name

  ip_configuration {
    name                          = "skpconfiguration1"
    subnet_id                     = azurerm_subnet.skpsubnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "skpvirmac" {
  name                  = "skp-vm"
  location              = azurerm_resource_group.skpresgrp.location
  resource_group_name   = azurerm_resource_group.skpresgrp.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}