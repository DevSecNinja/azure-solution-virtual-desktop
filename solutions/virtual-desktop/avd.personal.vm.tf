# To iterate on this module, use:
# for_each = { for id, val in module.avdhv.vm : id => val }
# with: each.value["id"]

module "avdpe" {
  # source = "github.com/DevSecNinja/terraform-azurerm-compute?ref=main"
  source  = "DevSecNinja/compute/azurerm"
  version = "1.1.4"

  ### Important
  instances = 1
  config    = local.config
  purpose   = "avdpe"
  subnet_id = local.subnet_id
  os_type   = "windows"
  tags      = local.tags

  ## Optional
  location                 = local.config.generic.regions.primaryRegion.name
  install_oms_agent        = false
  enable_jit               = local.config.compute.virtualMachines.linux.just-in-time.enabled
  deploy_public_ip_address = false
  shutdown_policy_enabled  = "true"
  join_in_aad              = true
  disable_backup           = true

  avd_extension = {
    enabled               = true
    hostPoolName          = azurerm_virtual_desktop_host_pool.hostpool-personal.name
    aadJoin               = true
    registrationInfoToken = azurerm_virtual_desktop_host_pool_registration_info.registrationinfo-personal.token
  }

  providers = {
    azurerm              = azurerm
    azurerm.management   = azurerm.management
    azurerm.connectivity = azurerm.connectivity
  }
}
