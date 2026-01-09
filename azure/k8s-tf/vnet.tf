resource "azurerm_virtual_network" "aks_vnet" {
  name                = "${var.creator_tag}-${terraform.workspace}-vnet"
  location            = azurerm_resource_group.aks_resource_group.location
  resource_group_name = azurerm_resource_group.aks_resource_group.name
  address_space       = [var.aks_vnet_cidr]

  tags = {
    environment = "${terraform.workspace}"
    creator     = "${var.creator_tag}"
  }
}

resource "azurerm_subnet" "aks_node_subnet" {
  name                 = "${var.creator_tag}-${terraform.workspace}-nodesubnet"
  resource_group_name  = azurerm_resource_group.aks_resource_group.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = [var.aks_nodepool_cidr]

  service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]
}

resource "azurerm_network_security_group" "aks_nsg" {
  name                = "${var.creator_tag}-${terraform.workspace}-nsg"
  location            = azurerm_resource_group.aks_resource_group.location
  resource_group_name = azurerm_resource_group.aks_resource_group.name
}

resource "azurerm_subnet_network_security_group_association" "aks_vnet_nsg_assoc" {
  subnet_id                 = azurerm_subnet.aks_node_subnet.id
  network_security_group_id = azurerm_network_security_group.aks_nsg.id
}

resource "azurerm_network_security_rule" "allow_authorized_networks" {
  name                        = "${var.creator_tag}-${terraform.workspace}-allowHomeIps"
  resource_group_name         = azurerm_resource_group.aks_resource_group.name
  network_security_group_name = azurerm_network_security_group.aks_nsg.name
  description                 = "Allow organization and user home IPs addresses"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefixes     = var.authorized_networks[*].cidr_block
  destination_address_prefix  = "*"
}
