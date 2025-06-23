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

  #   backend "azurerm" {
  #     use_oidc             = true                     # Can also be set via `ARM_USE_OIDC` environment variable.
  #     use_azuread_auth     = true                     # Can also be set via `ARM_USE_AZUREAD` environment variable.
  #     storage_account_name = "tfstate11006"           # Can be passed via `-backend-config=`"storage_account_name=<storage account name>"` in the `init` command.
  #     container_name       = "tfstate"                # Can be passed via `-backend-config=`"container_name=<container name>"` in the `init` command.
  #     key                  = "prod.terraform.tfstate" # Can be passed via `-backend-config=`"key=<blob key name>"` in the `init` command.
  #   }
}