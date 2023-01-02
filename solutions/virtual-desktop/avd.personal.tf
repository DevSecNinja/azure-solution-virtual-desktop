# Resource group name is output when execution plan is applied.
locals {
  purpose = "avd"

  workspace_name               = "${local.config.generic.org.root_id}-personal-workspace"
  workspace_friendly_name      = "${local.config.generic.org.root_name} Personal Workspace"
  hostpool_name                = "${local.config.generic.org.root_id}-personal-host-pool"
  hostpool_friendly_name       = "${local.config.generic.org.root_name} Personal Host Pool"
  dag_name                     = "${local.config.generic.org.root_id}-personal-dag"
  dag_friendly_name            = "${local.config.generic.org.root_name} Personal Desktop Application Group"
  default_desktop_display_name = "Windows"
  host_pool_type               = "Personal"
  dag_type                     = "Desktop"

  subnet_id = "/subscriptions/${data.azurerm_client_config.core.subscription_id}/resourceGroups/${local.config.generic.org.root_id}-connectivity-${local.config.generic.regions.primaryRegion.name}/providers/Microsoft.Network/virtualNetworks/${local.config.generic.org.root_id}-spoke-lz-2-${local.config.generic.regions.primaryRegion.name}/subnets/snet-workload"
}

resource "time_rotating" "avd_registration_expiration" {
  rotation_days = 29
}

resource "azurecaf_name" "avd" {
  resource_type = "azurerm_resource_group"
  prefixes      = []
  suffixes      = ["win", local.purpose]
  clean_input   = true
}

resource "azurerm_resource_group" "avd" {
  name     = azurecaf_name.avd.result
  location = local.config.generic.regions.primaryRegion.name
  tags     = local.tags
}

# Create AVD workspace
resource "azurerm_virtual_desktop_workspace" "workspace-personal" {
  name                = local.workspace_name
  friendly_name       = local.workspace_friendly_name
  resource_group_name = azurerm_resource_group.avd.name
  location            = azurerm_resource_group.avd.location
  tags                = local.tags
}

# Create AVD host pool
resource "azurerm_virtual_desktop_host_pool" "hostpool-personal" {
  resource_group_name              = azurerm_resource_group.avd.name
  location                         = azurerm_resource_group.avd.location
  name                             = local.hostpool_name
  friendly_name                    = local.hostpool_friendly_name
  validate_environment             = true
  custom_rdp_properties            = "targetisaadjoined:i:1;audiocapturemode:i:1;audiomode:i:0;drivestoredirect:s:*;redirectclipboard:i:1;redirectprinters:i:1;devicestoredirect:s:*;autoreconnection enabled:i:1;screen mode id:i:1;smart sizing:i:1;enablerdsaadauth:i:1;"
  type                             = local.host_pool_type
  personal_desktop_assignment_type = "Automatic"
  load_balancer_type               = "Persistent" #[BreadthFirst DepthFirst Persistent]
  start_vm_on_connect              = true
  tags                             = local.tags
  # maximum_sessions_allowed         = 4 - To prevent updates from 999999
}

resource "azurerm_virtual_desktop_host_pool_registration_info" "registrationinfo-personal" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.hostpool-personal.id
  expiration_date = time_rotating.avd_registration_expiration.rotation_rfc3339
}

# Create AVD DAG
resource "azurerm_virtual_desktop_application_group" "dag-personal" {
  resource_group_name          = azurerm_resource_group.avd.name
  host_pool_id                 = azurerm_virtual_desktop_host_pool.hostpool-personal.id
  location                     = azurerm_resource_group.avd.location
  type                         = local.dag_type
  name                         = local.dag_name
  friendly_name                = local.dag_friendly_name
  default_desktop_display_name = local.default_desktop_display_name
  tags                         = local.tags
}

# Associate Workspace and DAG
resource "azurerm_virtual_desktop_workspace_application_group_association" "ws-dag-personal" {
  application_group_id = azurerm_virtual_desktop_application_group.dag-personal.id
  workspace_id         = azurerm_virtual_desktop_workspace.workspace-personal.id
}

# Assign user to Application Group
resource "azurerm_role_assignment" "avd_user_assignment" {
  scope                = azurerm_virtual_desktop_application_group.dag-personal.id
  role_definition_name = "Desktop Virtualization User"
  principal_id         = data.azuread_user.jean-paul.id
}
