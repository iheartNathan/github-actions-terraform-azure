terraform {
  required_version = ">= 1.9, < 2.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0, < 4.0.0"
    }
  }

  backend "azurerm" {
    storage_account_name = "tfstate7209"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}


provider "azurerm" {
  features {}
  use_oidc = true
}