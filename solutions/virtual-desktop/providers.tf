#
# Standard Provider
#


# Declare a standard provider block using your preferred configuration.
# This will target the "default" Subscription and be used for the deployment of all "Core resources".
provider "azurerm" {
  subscription_id = element(local.config.subscriptions.landing_zones.corp.subscriptions, index(local.config.subscriptions.landing_zones.corp.subscriptions.*.name, "jeanpaulv-lz-corp-avd")).id
  features {}
}

# Obtain client configuration from the un-aliased provider
data "azurerm_client_config" "core" {
  provider = azurerm
}

#
# AIRS Management
#

# Declare a standard provider block using your preferred configuration.
# This will be used for the deployment of all "Management resources" to the specified `subscription_id`.
provider "azurerm" {
  alias           = "management"
  subscription_id = local.config.subscriptions.platform.mgmt.id
  features {}
}


# Obtain client configuration from the "management" provider
data "azurerm_client_config" "management" {
  provider = azurerm.management
}

#
# AIRS Connectivity
#

# Declare an aliased provider block using your preferred configuration.
# This will be used for the deployment of all "Connectivity resources" to the specified `subscription_id`.
provider "azurerm" {
  alias           = "connectivity"
  subscription_id = local.config.subscriptions.platform.conn.id
  features {}
}

# Obtain client configuration from the "connectivity" provider
data "azurerm_client_config" "connectivity" {
  provider = azurerm.connectivity
}

#
# AIRS Identity
#

# Declare an aliased provider block using your preferred configuration.
# This will be used for the deployment of all "Identity resources" to the specified `subscription_id`.
provider "azurerm" {
  alias           = "identity"
  subscription_id = local.config.subscriptions.platform.idm.id
  features {}
}

# Obtain client configuration from the "identity" provider
data "azurerm_client_config" "identity" {
  provider = azurerm.identity
}
