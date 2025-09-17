########################################
# Resource Group
########################################
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.default_tags
}

########################################
# Networking (VNet/Subnet)
########################################
resource "azurerm_virtual_network" "vnet" {
  name                = "opa-demo-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.20.0.0/16"]
  tags                = var.default_tags
}

resource "azurerm_subnet" "subnet" {
  name                 = "workload"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.20.1.0/24"]
}

########################################
# NSG (demo rule: SSH allowed from allowed_ssh_cidr)
########################################
resource "azurerm_network_security_group" "nsg" {
  name                = "opa-demo-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.allowed_ssh_cidr
    destination_address_prefix = "*"
  }

  tags = var.default_tags
}

########################################
# Instance matrix: 8 VMs (fmt-stable)
########################################
locals {
  instances = {
    vm01 = {
      name = "opa-az-vm-01"
      env  = "dev"
      size = "Standard_B1s"
    }
    vm02 = {
      name = "opa-az-vm-02"
      env  = "dev"
      size = "Standard_B1s"
    }
    vm03 = {
      name = "opa-az-vm-03"
      env  = "qa"
      size = "Standard_B1s"
    }
    vm04 = {
      name = "opa-az-vm-04"
      env  = "qa"
      size = "Standard_B1s"
    }
    vm05 = {
      name = "opa-az-vm-05"
      env  = "stage"
      size = "Standard_B1ms"
    }
    vm06 = {
      name = "opa-az-vm-06"
      env  = "stage"
      size = "Standard_B1ms"
    }
    vm07 = {
      name = "opa-az-vm-07"
      env  = "prod"
      size = "Standard_B2s"
    }
    vm08 = {
      name = "opa-az-vm-08"
      env  = "prod"
      size = "Standard_B2s"
    }
  }
}

########################################
# Public IPs (optional for demo)
########################################
resource "azurerm_public_ip" "pip" {
  for_each            = local.instances
  name                = "${each.value.name}-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.default_tags
}

########################################
# NICs
########################################
resource "azurerm_network_interface" "nic" {
  for_each            = local.instances
  name                = "${each.value.name}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip[each.key].id
  }

  tags = var.default_tags
}

########################################
# Associate NSG to NICs
########################################
resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  for_each                  = local.instances
  network_interface_id      = azurerm_network_interface.nic[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

#######################################
# 8 Linux VMs
########################################
resource "azurerm_linux_virtual_machine" "vm" {
  for_each              = local.instances
  name                  = each.value.name
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  size                  = each.value.size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.nic[each.key].id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  tags = merge(
    var.default_tags,
    {
      Name        = each.value.name
      Environment = each.value.env
    }
  )
}
