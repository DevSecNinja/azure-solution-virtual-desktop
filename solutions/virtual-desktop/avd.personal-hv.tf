# Resource group name is output when execution plan is applied.
locals {
  #purpose = "avd"

  hv_workspace_name               = "${local.config.generic.org.root_id}-personal-hv-workspace"
  hv_workspace_friendly_name      = "${local.config.generic.org.root_name} Personal Hypervisor Workspace"
  hv_hostpool_name                = "${local.config.generic.org.root_id}-personal-hv-host-pool"
  hv_hostpool_friendly_name       = "${local.config.generic.org.root_name} Personal Hypervisor Host Pool"
  hv_dag_name                     = "${local.config.generic.org.root_id}-personal-hv-dag"
  hv_dag_friendly_name            = "${local.config.generic.org.root_name} Personal Hypervisor Desktop Application Group"
  hv_default_desktop_display_name = "Windows Hypervisor"
  hv_host_pool_type               = "Personal"
  hv_dag_type                     = "Desktop"

  hv_subnet_id = "/subscriptions/${data.azurerm_client_config.core.subscription_id}/resourceGroups/${local.config.generic.org.root_id}-connectivity-${local.config.generic.regions.primaryRegion.name}/providers/Microsoft.Network/virtualNetworks/${local.config.generic.org.root_id}-spoke-lz-2-${local.config.generic.regions.primaryRegion.name}/subnets/snet-workload"
}

resource "time_rotating" "avd_hv_registration_expiration" {
  rotation_days = 29
}

# Create AVD workspace
resource "azurerm_virtual_desktop_workspace" "workspace-personal-hv" {
  name                = local.hv_workspace_name
  friendly_name       = local.hv_workspace_friendly_name
  resource_group_name = azurerm_resource_group.avd.name
  location            = azurerm_resource_group.avd.location
  tags                = local.tags
}

# Create AVD host pool
resource "azurerm_virtual_desktop_host_pool" "hostpool-personal-hv" {
  resource_group_name              = azurerm_resource_group.avd.name
  location                         = azurerm_resource_group.avd.location
  name                             = local.hv_hostpool_name
  friendly_name                    = local.hv_hostpool_friendly_name
  validate_environment             = true
  custom_rdp_properties            = "targetisaadjoined:i:1;audiocapturemode:i:1;audiomode:i:0;drivestoredirect:s:*;redirectclipboard:i:1;redirectprinters:i:1;devicestoredirect:s:*;autoreconnection enabled:i:1;screen mode id:i:1;smart sizing:i:1;enablerdsaadauth:i:1;"
  type                             = local.hv_host_pool_type
  personal_desktop_assignment_type = "Automatic"
  load_balancer_type               = "Persistent" #[BreadthFirst DepthFirst Persistent]
  start_vm_on_connect              = true
  tags                             = local.tags
  # maximum_sessions_allowed         = 4 - To prevent updates from 999999
}

resource "azurerm_virtual_desktop_host_pool_registration_info" "registrationinfo-personal-hv" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.hostpool-personal-hv.id
  expiration_date = time_rotating.avd_hv_registration_expiration.rotation_rfc3339
}

# Create AVD DAG
resource "azurerm_virtual_desktop_application_group" "dag-personal-hv" {
  resource_group_name          = azurerm_resource_group.avd.name
  host_pool_id                 = azurerm_virtual_desktop_host_pool.hostpool-personal-hv.id
  location                     = azurerm_resource_group.avd.location
  type                         = local.hv_dag_type
  name                         = local.hv_dag_name
  friendly_name                = local.hv_dag_friendly_name
  default_desktop_display_name = local.hv_default_desktop_display_name
  tags                         = local.tags
}

# Associate Workspace and DAG
resource "azurerm_virtual_desktop_workspace_application_group_association" "ws-dag-personal-hv" {
  application_group_id = azurerm_virtual_desktop_application_group.dag-personal-hv.id
  workspace_id         = azurerm_virtual_desktop_workspace.workspace-personal-hv.id
}

# Assign user to Application Group
resource "azurerm_role_assignment" "avd_hv_user_assignment" {
  scope                = azurerm_virtual_desktop_application_group.dag-personal-hv.id
  role_definition_name = "Desktop Virtualization User"
  principal_id         = data.azuread_user.jean-paul.id
}
