# Importing the Azure naming module to ensure resources have unique CAF compliant names.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = " >= 0.4.0"
}


resource "azurerm_resource_group" "this" {
  location = var.location
  name     = var.rg_name
}


data "azurerm_resource_group" "this" {
  name = var.rg_name
}
