resource "azurerm_resource_group" "skpresgrp" {
  name     = "skpresgrp${terraform.workspace}"
  location = "West US 2"
}


resource "azurerm_storage_account" "skpstracc" {
  name                     = "${var.stracc_name}${terraform.workspace}"
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
    name                          = "skpnicipconfig"
    subnet_id                     = azurerm_subnet.skpsubnet.id
    private_ip_address_allocation = "Dynamic"
  }
}


resource "azurerm_virtual_machine" "skpvirmac" {
  name                  = "skp-vm"
  location              = azurerm_resource_group.skpresgrp.location
  resource_group_name   = azurerm_resource_group.skpresgrp.name
  network_interface_ids = [azurerm_network_interface.skpnic.id]
  vm_size               = "Standard_DS1_v2"
  delete_data_disks_on_termination = true


  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  storage_os_disk {
    name              = "skposdisk1"
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


resource "azurerm_network_security_group" "skpnsg" {
  name                = "skpnsg${terraform.workspace}"
  location            = azurerm_resource_group.skpresgrp.location
  resource_group_name = azurerm_resource_group.skpresgrp.name

  dynamic "security_rule" {
    for_each = var.nsg_ports
    content {
        name                       = "InRule${security_rule.value}"
        priority                   = security_rule.value
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "${security_rule.key}"
        destination_port_range     = "${security_rule.key}"
        source_address_prefix      = var.ip_address_allowed
        destination_address_prefix = var.ip_address_allowed
    }
  }
  
  dynamic "security_rule" {
    for_each = var.nsg_ports
    content {
      name                       = "EORule${security_rule.value}"
      priority                   = security_rule.value
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "${security_rule.key}"
      destination_port_range     = "${security_rule.key}"
      source_address_prefix      = var.ip_address_allowed
      destination_address_prefix = var.ip_address_allowed
    }
  }
}


resource "azurerm_network_interface_security_group_association" "skpnsgasc" {
  network_interface_id = azurerm_network_interface.skpnic.id
  network_security_group_id = azurerm_network_security_group.skpnsg.id
}