resource "azurerm_storage_account" "account" {
  name                     = replace("${var.creator_tag}${terraform.workspace}", "-", "")
  resource_group_name      = azurerm_resource_group.aks_resource_group.name
  location                 = var.azr_region
  account_tier             = "Standard"
  account_replication_type = "LRS"

  network_rules {
    default_action             = "Deny"
    ip_rules                   = [for cidr in var.authorized_networks[*].cidr_block : replace(replace(cidr, "/31", ""), "/32", "")]
    virtual_network_subnet_ids = [azurerm_subnet.aks_node_subnet.id]
  }
}

resource "azurerm_storage_container" "container" {
  name                  = "${var.creator_tag}-${terraform.workspace}-container"
  storage_account_id    = azurerm_storage_account.account.id
  container_access_type = "private"
}
