terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.117.0"
    }
  }

  backend "local" {
    path = "demo.tfstate"
  }
}

provider "azurerm" {
  subscription_id            = var.subscription_id
  skip_provider_registration = true
  features {}
}
