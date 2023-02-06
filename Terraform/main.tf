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
