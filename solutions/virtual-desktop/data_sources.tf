#
# Azure AD
#

data "azuread_user" "jean-paul" {
  user_principal_name = local.config.generic.org.owner.email
}
