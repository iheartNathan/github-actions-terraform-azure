variable "rg_name" {
  description = "Rescource group to deploy resources"
  type        = string
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  validation {
    condition     = can(regex("^[a-z]+[a-z0-9]+$", var.location))
    error_message = "Location must be a valid Azure region string in lowercase."
  }
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
}


variable "vm_subnet_prefix" {
  description = "Address prefix for the VM subnet"
  type        = list(string)
}


variable "bastion_subnet_prefix" {
  description = "Address prefix for the Azure Bastion subnet"
  type        = list(string)
}

variable "ssh_port" {
  description = "Port number for SSH access"
  type        = number
}

variable "kubernetes_api_port" {
  description = "Port number for Kubernetes API server"
  type        = number
}

variable "etcd_ports" {
  description = "List of ports used by etcd on control plane nodes"
  type        = list(string)
}

variable "kubelet_ports" {
  description = "List of ports used by kubelet, scheduler, and controller-manager"
  type        = list(string)
}

variable "nodeport_range" {
  description = "Port range for Kubernetes NodePort services"
  type        = string
}


variable "application_port" {
  description = "Port number for application hosted on the VMSS instances"
  type        = number
}

variable "vmss_instance" {
  description = "Number of VM instances in the VMSS"
  type        = number
}

variable "admin_username" {
  description = "VMSS instances admin username"
  type        = string
}

variable "api_key" {
  description = "API key for application hosted on the VMSS instances"
  type        = string
}