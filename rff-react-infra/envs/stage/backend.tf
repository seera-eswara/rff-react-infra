terraform {
  required_version = ">= 1.6.6"
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "tfstatelzqiaypb"
    container_name       = "tfstate"
    key                  = "rff-react/stage.tfstate"
  }
}
