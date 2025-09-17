terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"                   # <-- make sure this exists (workflow ensures)
    storage_account_name = "akuphetfstate1234"            # <-- globally unique, lowercase
    container_name       = "tfstate"
    key                  = "azure-compliance/terraform.tfstate"
    use_azuread_auth     = true
  }
}
