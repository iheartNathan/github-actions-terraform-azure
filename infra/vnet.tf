module "virtual_network" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.8.1"

  name                = module.naming.virtual_network.name_unique
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  address_space       = var.vnet_address_space

  subnets = {
    vm_subnet = {
      name           = "${module.naming.subnet.name_unique}-vm"
      address_prefix = var.vm_subnet_prefix[0]
      network_security_group = {
        id = azurerm_network_security_group.vm_nsg.id
      }
    }
  }
}


resource "azurerm_network_security_group" "vm_nsg" {
  name                = module.naming.network_security_group.name_unique
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = var.application_port
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}



