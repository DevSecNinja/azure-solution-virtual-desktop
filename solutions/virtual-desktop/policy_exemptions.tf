resource "azurerm_resource_group_policy_exemption" "avd_fslogix_storage" {
  name                 = "avd_policy_exemption_sa"
  display_name         = "Allow creation of Storage Account with Public Network Access for AVD"
  resource_group_id    = azurerm_resource_group.avd.id
  policy_assignment_id = "/providers/Microsoft.Management/managementGroups/${local.config.generic.org.root_id}-corp/providers/Microsoft.Authorization/policyAssignments/Deny-Public-Endpoints"
  exemption_category   = "Waiver"
}
