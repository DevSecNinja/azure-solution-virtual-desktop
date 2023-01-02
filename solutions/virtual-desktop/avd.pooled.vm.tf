# To iterate on this module, use:
# for_each = { for id, val in module.avdhv.vm : id => val }
# with: each.value["id"]

module "avdpo" {
  # source = "github.com/DevSecNinja/terraform-azurerm-compute?ref=main"
  source  = "DevSecNinja/compute/azurerm"
  version = "1.1.3"

  ### Important
  instances = 1
  config    = local.config
  purpose   = "avdpo"
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
    hostPoolName          = azurerm_virtual_desktop_host_pool.hostpool-pooled.name
    aadJoin               = true
    registrationInfoToken = azurerm_virtual_desktop_host_pool_registration_info.registrationinfo-pooled.token
  }

  providers = {
    azurerm              = azurerm
    azurerm.management   = azurerm.management
    azurerm.connectivity = azurerm.connectivity
  }
}

# Configure FSLogix
# TODO: Check if FSLogix works...
# TODO: Move inline command to proper script
resource "null_resource" "FSLogix" {
  provisioner "local-exec" {
    command = "az account set --subscription ${data.azurerm_client_config.core.subscription_id} && az vm run-command invoke --command-id RunPowerShellScript --name ${module.avdpo.vm[0].name} -g ${module.avdpo.vm[0].resource_group_name} --scripts 'New-Item -Path HKLM:\\SOFTWARE\\FSLogix -ErrorAction SilentlyContinue -Force; New-Item -Path HKLM:\\SOFTWARE\\FSLogix\\Profiles -ErrorAction SilentlyContinue -Force; New-ItemProperty -Path HKLM:\\SOFTWARE\\FSLogix\\Profiles -Name VHDLocations -Value \\\\${azurerm_storage_account.fslogix_storage.primary_file_endpoint}\\avdprofiles -PropertyType MultiString -Force;New-ItemProperty -Path HKLM:\\SOFTWARE\\FSLogix\\Profiles -Name Enabled -Value 1 -PropertyType DWORD;New-ItemProperty -Path HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Lsa\\Kerberos\\Parameters -Name CloudKerberosTicketRetrievalEnabled -Value 1 -PropertyType DWORD;New-Item -Path HKLM:\\Software\\Policies\\Microsoft\\ -Name AzureADAccount;New-ItemProperty -Path HKLM:\\Software\\Policies\\Microsoft\\AzureADAccount -Name LoadCredKeyFromProfile -Value 1 -PropertyType DWORD;Restart-Computer'"
  }
}
