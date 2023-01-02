terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.29.1"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.31.0"
    }

    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "2.0.0-preview3"
    }

    time = {
      source  = "hashicorp/time"
      version = "0.9.1"
    }

    null = {
      source  = "hashicorp/null"
      version = "3.2.1"
    }
  }

  cloud {
    organization = "ravensberg"

    workspaces {
      name = "AzureEnvironment_Solutions_VirtualDesktop"
    }
  }
}

locals {
  # Read the config files
  config_files = fileset(path.module, "../../generic/json/config/*.json")
  config = { for query_file in local.config_files :
    replace(basename(query_file), ".json", "") => jsondecode(file(query_file))
  }

  # Tags
  tags = merge(local.config.generic.tags, {
    terraformWorkspace = "AzureEnvironment_Solutions_VirtualDesktop"
    "owner.name"       = local.config.generic.org.owner.name
    "owner.email"      = local.config.generic.org.owner.email
  })
}
