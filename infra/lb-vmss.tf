resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ssh_private_key" {
  filename = "${path.module}/key.pem"
  content  = tls_private_key.ssh.private_key_pem
}

module "loadbalancer" {
  source  = "Azure/loadbalancer/azurerm"
  version = "4.4.0"

  resource_group_name = data.azurerm_resource_group.this.name
  type                = "public"
  pip_sku             = "Standard"
  allocation_method   = "Static"
  lb_sku              = "Standard"
  name                = module.naming.lb.name_unique

  lb_port = {
    http = ["80", "Tcp", "${var.application_port}"]
  }

  lb_probe = {
    http = ["Http", "${var.application_port}", "/"]
  }

  depends_on = [azurerm_resource_group.this]
}


resource "azurerm_linux_virtual_machine_scale_set" "linux_vmss" {
  name                = module.naming.linux_virtual_machine_scale_set.name_unique
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  sku                 = "Standard_F2"
  instances           = var.vmss_instance
  admin_username      = var.admin_username

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.ssh.public_key_openssh
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name                      = module.naming.network_interface.name_unique
    primary                   = true
    network_security_group_id = azurerm_network_security_group.vm_nsg.id

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = module.virtual_network.subnets["vm_subnet"].resource_id
      load_balancer_backend_address_pool_ids = [module.loadbalancer.azurerm_lb_backend_address_pool_id]
    }
  }

  health_probe_id = module.loadbalancer.azurerm_lb_probe_ids[0]

  user_data = base64encode(templatefile("${path.module}/templates/custom_data.tpl", {
    admin_username = var.admin_username
    port           = var.application_port
    api_key        = var.api_key
  }))

  depends_on = [module.loadbalancer]
}