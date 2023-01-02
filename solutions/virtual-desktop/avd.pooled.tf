# Resource group name is output when execution plan is applied.
locals {
  #purpose = "avd"

  pooled_workspace_name               = "${local.config.generic.org.root_id}-pooled-workspace"
  pooled_workspace_friendly_name      = "${local.config.generic.org.root_name} Pooled Workspace"
  pooled_hostpool_name                = "${local.config.generic.org.root_id}-pooled-host-pool"
  pooled_hostpool_friendly_name       = "${local.config.generic.org.root_name} Pooled Host Pool"
  pooled_dag_name                     = "${local.config.generic.org.root_id}-pooled-dag"
  pooled_dag_friendly_name            = "${local.config.generic.org.root_name} Pooled Desktop Application Group"
  pooled_default_desktop_display_name = "Windows Pooled"
  pooled_host_pool_type               = "Pooled"
  pooled_dag_type                     = "Desktop"
}

# Create AVD workspace
resource "azurerm_virtual_desktop_workspace" "workspace-pooled" {
  name                = local.pooled_workspace_name
  friendly_name       = local.pooled_workspace_friendly_name
  resource_group_name = azurerm_resource_group.avd.name
  location            = azurerm_resource_group.avd.location
  tags                = local.tags
}

# Create AVD host pool
resource "azurerm_virtual_desktop_host_pool" "hostpool-pooled" {
  resource_group_name      = azurerm_resource_group.avd.name
  location                 = azurerm_resource_group.avd.location
  name                     = local.pooled_hostpool_name
  friendly_name            = local.pooled_hostpool_friendly_name
  validate_environment     = true
  custom_rdp_properties    = "targetisaadjoined:i:1;audiocapturemode:i:1;audiomode:i:0;drivestoredirect:s:*;redirectclipboard:i:1;redirectprinters:i:1;devicestoredirect:s:*;autoreconnection enabled:i:1;screen mode id:i:1;smart sizing:i:1;enablerdsaadauth:i:1;"
  type                     = local.pooled_host_pool_type
  load_balancer_type       = "DepthFirst" #[BreadthFirst DepthFirst Persistent]
  start_vm_on_connect      = true
  maximum_sessions_allowed = 4 # To prevent updates from 999999
  tags                     = local.tags
}

resource "azurerm_virtual_desktop_host_pool_registration_info" "registrationinfo-pooled" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.hostpool-pooled.id
  expiration_date = time_rotating.avd_registration_expiration.rotation_rfc3339
}

# Create AVD DAGs
resource "azurerm_virtual_desktop_application_group" "dag-pooled" {
  resource_group_name          = azurerm_resource_group.avd.name
  host_pool_id                 = azurerm_virtual_desktop_host_pool.hostpool-pooled.id
  location                     = azurerm_resource_group.avd.location
  type                         = local.pooled_dag_type
  name                         = local.pooled_dag_name
  friendly_name                = local.pooled_dag_friendly_name
  default_desktop_display_name = local.pooled_default_desktop_display_name
  tags                         = local.tags
}

resource "azurerm_virtual_desktop_application_group" "dag-pooled-remoteapp" {
  resource_group_name = azurerm_resource_group.avd.name
  host_pool_id        = azurerm_virtual_desktop_host_pool.hostpool-pooled.id
  location            = azurerm_resource_group.avd.location
  type                = "RemoteApp"
  name                = "${local.pooled_dag_name}-remoteapp"
  friendly_name       = "${local.pooled_dag_friendly_name} Remote App"
  tags                = local.tags
}

# # Add Applications
resource "azurerm_virtual_desktop_application" "edge" {
  name                         = "microsoftedge"
  application_group_id         = azurerm_virtual_desktop_application_group.dag-pooled-remoteapp.id
  friendly_name                = "Microsoft Edge"
  description                  = "Chromium based web browser"
  path                         = "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe"
  command_line_argument_policy = "DoNotAllow"
  command_line_arguments       = "--incognito"
  show_in_portal               = true
  icon_path                    = "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe"
  icon_index                   = 0
}

# Associate Workspace and DAG
resource "azurerm_virtual_desktop_workspace_application_group_association" "ws-dag-pooled" {
  application_group_id = azurerm_virtual_desktop_application_group.dag-pooled.id
  workspace_id         = azurerm_virtual_desktop_workspace.workspace-pooled.id
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "ws-dag-pooled-remoteapp" {
  application_group_id = azurerm_virtual_desktop_application_group.dag-pooled-remoteapp.id
  workspace_id         = azurerm_virtual_desktop_workspace.workspace-pooled.id
}

# Assign user to Application Group
resource "azurerm_role_assignment" "avd_user_assignment_pooled" {
  scope                = azurerm_virtual_desktop_application_group.dag-pooled.id
  role_definition_name = "Desktop Virtualization User"
  principal_id         = data.azuread_user.jean-paul.id
}

resource "azurerm_role_assignment" "avd_user_assignment_pooled_remote_app" {
  scope                = azurerm_virtual_desktop_application_group.dag-pooled-remoteapp.id
  role_definition_name = "Desktop Virtualization User"
  principal_id         = data.azuread_user.jean-paul.id
}

# FSLogix Storage
## Create a File Storage Account
resource "azurecaf_name" "fslogix_storage" {
  name          = "fslogix"
  resource_type = "azurerm_storage_account"
  prefixes      = []
  suffixes      = [local.config.generic.org.root_id, "01"]
  clean_input   = true
}

resource "azurerm_storage_account" "fslogix_storage" {
  name                            = azurecaf_name.fslogix_storage.result
  resource_group_name             = azurerm_resource_group.avd.name
  location                        = azurerm_resource_group.avd.location
  min_tls_version                 = "TLS1_2"
  account_tier                    = "Premium"
  account_replication_type        = "ZRS"
  account_kind                    = "FileStorage"
  allow_nested_items_to_be_public = false
  enable_https_traffic_only       = true
  tags                            = local.tags

  network_rules {
    default_action             = "Allow"
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }

  # Kerberos still to be configured: https://learn.microsoft.com/en-us/azure/storage/files/storage-files-identity-auth-azure-active-directory-enable?tabs=azure-portal#enable-azure-ad-kerberos-authentication-for-hybrid-user-accounts
  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account
  share_properties {
    smb {
      authentication_types = ["Kerberos"]
    }
  }

  identity {
    type = "SystemAssigned"
  }

  depends_on = [
    azurerm_resource_group_policy_exemption.avd_fslogix_storage
  ]
}

resource "azurerm_storage_share" "fslogix_share" {
  name             = "fslogix"
  quota            = "100"
  enabled_protocol = "SMB"

  storage_account_name = azurerm_storage_account.fslogix_storage.name
}

## Azure built-in roles
## https://docs.microsoft.com/azure/role-based-access-control/built-in-roles
resource "azurerm_role_assignment" "fslogix_role" {
  scope                = azurerm_storage_account.fslogix_storage.id
  role_definition_name = "Storage File Data SMB Share Contributor"
  principal_id         = data.azuread_user.jean-paul.id
}
