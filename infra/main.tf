# Importing the Azure naming module to ensure resources have unique CAF compliant name.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = " >= 0.4.0"
}


data "azurerm_resource_group" "this" {
  name = var.rg_name
}
