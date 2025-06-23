provider "azurerm" {
  subscription_id = "2329876a-dd1e-4d17-9d7e-6504024dd500"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}