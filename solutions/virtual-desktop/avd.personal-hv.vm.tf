# To iterate on this module, use:
# for_each = { for id, val in module.avdhv.vm : id => val }
# with: each.value["id"]

module "avdhv" {
  # source = "github.com/DevSecNinja/terraform-azurerm-compute?ref=main"
  source  = "DevSecNinja/compute/azurerm"
  version = "1.1.3"

  ### Important
  instances = 1
  config    = local.config
  purpose   = "avdhv"
  subnet_id = local.subnet_id
  os_type   = "windows"
  tags      = local.tags

  ## Optional
  location                 = local.config.generic.regions.primaryRegion.name
  install_oms_agent        = false
  vm_size                  = "Standard_D8s_v3" # Supports nested virtualization
  enable_jit               = local.config.compute.virtualMachines.linux.just-in-time.enabled
  deploy_public_ip_address = false
  shutdown_policy_enabled  = "true"
  join_in_aad              = true
  disable_backup           = true
  data_disk_size           = 512

  custom_script_extension = {
    enabled = true
    name    = "InstallDeveloperWorkstation",
    script  = "${textencodebase64(file("${path.module}/../../generic/scripts/powershell/module/scripts/Install-DeveloperWorkstation.ps1"), "UTF-16LE")}"
  }

  avd_extension = {
    enabled               = true
    hostPoolName          = azurerm_virtual_desktop_host_pool.hostpool-personal-hv.name
    aadJoin               = true
    registrationInfoToken = azurerm_virtual_desktop_host_pool_registration_info.registrationinfo-personal-hv.token
  }

  providers = {
    azurerm              = azurerm
    azurerm.management   = azurerm.management
    azurerm.connectivity = azurerm.connectivity
  }
}
