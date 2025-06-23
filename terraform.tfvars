rg_name  = "vmss-rg-9778"
location = "northeurope"

vnet_address_space = ["10.0.0.0/16"]
vm_subnet_prefix   = ["10.0.1.0/24"]

ssh_port         = 22
application_port = 80
vmss_instance    = 2
admin_username   = "adminuser875" # https://learn.microsoft.com/en-us/rest/api/compute/virtual-machines/create-or-update?view=rest-compute-2025-02-01&tabs=HTTP#osprofile
api_key          = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

