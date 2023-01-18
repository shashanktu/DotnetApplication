#Create Storage Account
terraform {
  required_providers {  
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.11, < 4.0"
    }
  }
}
provider "azurerm" {
  features {}
}
resource "azurerm_storage_account" "projectstorage" {
  count                     = 1
  name                     = "jhgsajhgfhjfas"
  resource_group_name      = "anitham"
  location                 = "eastus"
  account_tier             = "Standard"
  account_replication_type = "GRS"  
  account_kind = "StorageV2"
}

resource "azurerm_service_plan" "app_service_plan" {
  name                = "myappservice-plan"
   resource_group_name      = "anitham"
  location                 = "eastus"
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_app_service" "app_service" {
  name                = "mywebapp-45362jhs1"
   resource_group_name      = "anitham"
  location                 = "eastus"
  app_service_plan_id = azurerm_service_plan.app_service_plan.id

  #(Optional)
  site_config {
  #linux_fx_version = "JAVA|17-java17" # need this to make it v11
  linux_fx_version = "TOMCAT|10.0.20-java17"
  /*
  java_version = "11"
  java_container = "TOMCAT"           #this doesn't work
  java_container_version = "9.0"
  */
  }
  
  #(Optional)
  app_settings = {
    "SOME_KEY" = "some-value"
  }

}

resource "azurerm_app_service" "app_service2" {
  name                = "mywebapp-45362jhs2"
   resource_group_name      = "anitham"
  location                 = "eastus"
  app_service_plan_id = azurerm_service_plan.app_service_plan.id

  #(Optional)
  site_config {
 linux_fx_version = "DOTNETCORE|6.0"
  }
  
  #(Optional)
  app_settings = {
    "SOME_KEY" = "some-value"
  }

}



resource "azurerm_virtual_network" "vnet" {
  name                = "vnet10"
  address_space       = ["10.0.0.0/16"]
  location            = "eastus"
  resource_group_name = "anitham"
}

resource "azurerm_subnet" "subnet" {
  name                 = "internal"
  resource_group_name  = "anitham"
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}
resource "azurerm_public_ip" "public_ip" {
  name                = "vm_public_ip"
  resource_group_name = "anitham"
  location            = "eastus"
  allocation_method   = "Static"
}
resource "azurerm_network_interface" "vmnic" {
  name                = "vm-nic"
  location            = "eastus"
  resource_group_name = "anitham"

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
  resource_group_name = "anitham"

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
  resource_group_name = "anitham"
  location            = "eastus"
  size                = "Standard_B2s"
  admin_username      = "adminuser"

  network_interface_ids = [
    azurerm_network_interface.vmnic.id,
  ]


  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

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
  
  lifecycle {
    ignore_changes = [
      custom_data,
    ]
  }
  
 
  provisioner "remote-exec" {
    inline = [
	  "sudo apt-get -y update && apt-get upgrade",
	  "sudo apt-get -y install tomcat8",
	  "sudo apt-get -y install tomcat8-docs tomcat8-examples tomcat8-admin",
	  #"systemctl start tomcat8",
	  #"systemctl stop tomcat8",
	  #"systemctl restart tomcat8",	  
    ]
	connection {
	type = "ssh"
	host = azurerm_public_ip.public_ip.ip_address
	user = "adminuser"	
	private_key = file("~/.ssh/id_rsa")
  }
  }
 
}


resource "azurerm_kubernetes_cluster" "k8s" {
  location            = "eastus"
  name                = "k8scluster"
  resource_group_name = "anitham"
  dns_prefix          = "k8scluster98794"
  tags                = {
    Environment = "Development"
  }

  default_node_pool {
    name       = "agentpool"
    vm_size    = "Standard_D2_v2"
    node_count = "2"
  }
  linux_profile {
    admin_username = "ubuntu"

    ssh_key {
      key_data = file("~/.ssh/id_rsa.pub")
    }
  }
  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
  }
  identity {
    type = "SystemAssigned"
  }
}
