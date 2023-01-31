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

resource "azurerm_kubernetes_cluster" "k8s" {
  location            = "eastus"
  name                = "k8scluster"
  resource_group_name = "DCS_assets"
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
    admin_username = "admin"

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
