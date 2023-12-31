terraform {
  required_version = ">= 0.11" 
  backend "azurerm" {
  storage_account_name = "__terraformstorageaccount__"
    container_name       = "terraformakscontainer"
    key                  = "terraform.tfstate"
	access_key  ="__storagekey__"
	}
	}
  provider "azurerm" {
  features {}
}

variable "ssh_public_key" {
  default = "~/.ssh/id_rsa.pub"
}

resource "azurerm_resource_group" "dev" {
  name     = "DCS_assets_terraform"
  location = "East US"
}


resource "azurerm_kubernetes_cluster" "k8s" {
  location            = "eastus"
  name                = "k8scluster"
  resource_group_name = "DCS_assets_terraform"
  dns_prefix          = "k8scluster98794"
  tags                = {
    Environment = "Development"
  }

  default_node_pool {
    name       = "agentpool"
    vm_size    = "Standard_D2_v2"
    node_count = "2"
  }
  
  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
  }
  identity {
    type = "SystemAssigned"
  }
}