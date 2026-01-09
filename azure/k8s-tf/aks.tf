resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                                = "${var.creator_tag}-${terraform.workspace}-aks"
  location                            = azurerm_resource_group.aks_resource_group.location
  resource_group_name                 = azurerm_resource_group.aks_resource_group.name
  dns_prefix                          = "${var.creator_tag}-${terraform.workspace}"
  kubernetes_version                  = var.aks_kubernetes_version
  private_cluster_enabled             = false
  private_cluster_public_fqdn_enabled = false

  api_server_access_profile {
    authorized_ip_ranges = var.authorized_networks[*].cidr_block
  }

  default_node_pool {
    name            = "default"
    vnet_subnet_id  = azurerm_subnet.aks_node_subnet.id
    node_count      = var.aks_node_count
    vm_size         = var.aks_image_size
    os_disk_size_gb = var.aks_os_disk_size_gb

    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "${terraform.workspace}"
    creator     = "${var.creator_tag}"
  }

  network_profile {
    network_plugin = "kubenet"
    service_cidr   = var.aks_services_cidr
    pod_cidr       = var.aks_pods_cidr
    dns_service_ip = var.aks_services_dns_ip
  }
}
