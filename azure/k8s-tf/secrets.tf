resource "azurerm_key_vault" "kasten_key_vault" {
  name                        = "${var.creator_tag}-${terraform.workspace}-kv"
  location                    = var.azr_region
  resource_group_name         = azurerm_resource_group.aks_resource_group.name
  enabled_for_disk_encryption = true
  tenant_id                   = jsondecode(file(var.azr_creds)).tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true
  rbac_authorization_enabled  = true

  sku_name = "standard"

  tags = {
    environment = "${terraform.workspace}"
    creator     = "${var.creator_tag}"
  }

  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    ip_rules                   = var.authorized_networks[*].cidr_block
    virtual_network_subnet_ids = [azurerm_subnet.aks_node_subnet.id]
  }
}

resource "azurerm_role_assignment" "kubelet_vault_assignment" {
  principal_id         = azurerm_kubernetes_cluster.aks_cluster.kubelet_identity[0].object_id
  role_definition_name = "Key Vault Secrets User"
  scope                = azurerm_key_vault.kasten_key_vault.id
}

resource "azurerm_role_assignment" "user_vault_assignment" {
  principal_id         = jsondecode(file(var.azr_creds)).user_id
  role_definition_name = "Key Vault Administrator"
  scope                = azurerm_key_vault.kasten_key_vault.id
}

resource "azurerm_key_vault_secret" "storage_account" {
  depends_on      = [azurerm_role_assignment.user_vault_assignment]
  name            = "azure-storage-account-id"
  value           = azurerm_storage_account.account.name
  key_vault_id    = azurerm_key_vault.kasten_key_vault.id
  expiration_date = timeadd(timestamp(), "8760h")
}

resource "azurerm_key_vault_secret" "storage_environment" {
  depends_on      = [azurerm_role_assignment.user_vault_assignment]
  name            = "azure-storage-environment"
  value           = "AzurePublicCloud"
  key_vault_id    = azurerm_key_vault.kasten_key_vault.id
  expiration_date = timeadd(timestamp(), "8760h")
}

resource "azurerm_key_vault_secret" "storage_key" {
  depends_on      = [azurerm_role_assignment.user_vault_assignment]
  name            = "azure-storage-key"
  value           = azurerm_storage_account.account.primary_access_key
  key_vault_id    = azurerm_key_vault.kasten_key_vault.id
  expiration_date = timeadd(timestamp(), "8760h")
}

resource "random_password" "kasten_dr_passphrase" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_key_vault_secret" "kasten_dr_passphrase" {
  depends_on      = [azurerm_role_assignment.user_vault_assignment]
  name            = "kasten-dr-passphrase"
  value           = random_password.kasten_dr_passphrase.result
  key_vault_id    = azurerm_key_vault.kasten_key_vault.id
  expiration_date = timeadd(timestamp(), "8760h")
}

resource "azurerm_key_vault_secret" "kasten_dr_url" {
  depends_on      = [azurerm_role_assignment.user_vault_assignment]
  name            = "kasten-dr-url"
  value           = azurerm_key_vault.kasten_key_vault.vault_uri
  key_vault_id    = azurerm_key_vault.kasten_key_vault.id
  expiration_date = timeadd(timestamp(), "8760h")
}

resource "azurerm_key_vault_secret" "kasten_dr_key" {
  depends_on      = [azurerm_role_assignment.user_vault_assignment]
  name            = "kasten-dr-key"
  value           = "kasten-dr-passphrase"
  key_vault_id    = azurerm_key_vault.kasten_key_vault.id
  expiration_date = timeadd(timestamp(), "8760h")
}

resource "azurerm_key_vault_secret" "kasten_dr_source" {
  depends_on      = [azurerm_role_assignment.user_vault_assignment]
  name            = "kasten-dr-source"
  value           = "azure"
  key_vault_id    = azurerm_key_vault.kasten_key_vault.id
  expiration_date = timeadd(timestamp(), "8760h")
}

resource "azurerm_key_vault_secret" "cloudflare_api_token" {
  count           = var.deployment.cert_manager ? 1 : 0
  depends_on      = [azurerm_role_assignment.user_vault_assignment]
  name            = "cloudflare-api-token"
  value           = trimspace(file(var.cloudflare_api_token))
  key_vault_id    = azurerm_key_vault.kasten_key_vault.id
  expiration_date = timeadd(timestamp(), "8760h")
}
