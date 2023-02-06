terraform {
  required_version = ">= 0.11" 
 backend "azurerm" {
  storage_account_name = "__terraformstorageaccount__"
    container_name       = "tfvm"
    key                  = "terraform.tfstate"
	access_key  ="__storagekey__"
	}

	}
  
  provider "azurerm" {
  features {}
  }

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet10"
  address_space       = ["10.0.0.0/16"]
  location            = "eastus"
  resource_group_name = "DCS_assets_storage"
}

resource "azurerm_subnet" "subnet" {
  name                 = "internal"
  resource_group_name  = "DCS_assets_storage"
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}
resource "azurerm_public_ip" "public_ip" {
  name                = "vm_public_ip"
  resource_group_name = "DCS_assets_storage"
  location            = "eastus"
  allocation_method   = "Static"
}
resource "azurerm_network_interface" "vmnic" {
  name                = "vm-nic"
  location            = "eastus"
  resource_group_name = "DCS_assets_storage"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }
}
resource "azurerm_network_security_group" "nsg" {
  name                = "ssh_nsg"
  location            = "eastus"
  resource_group_name = "DCS_assets_storage"

  security_rule {
    name                       = "allow_ssh_sg"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow_allin"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow_allout"
    priority                   = 102
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  #add new rule to access internet
}
resource "azurerm_network_interface_security_group_association" "association" {
  network_interface_id      = azurerm_network_interface.vmnic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "myvm1"
  resource_group_name = "DCS_assets_storage"
  location            = "eastus"
  size                = "Standard_B2s"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"

  network_interface_ids = [
    azurerm_network_interface.vmnic.id,
  ]

  os_disk {
	name                 = "myvm1-os"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  
 
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  