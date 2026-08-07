resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                                = "${var.creator_tag}-${terraform.workspace}-aks"
  location                            = azurerm_resource_group.aks_resource_group.location
  resource_group_name                 = azurerm_resource_group.aks_resource_group.name
  dns_prefix                          = "${var.creator_tag}-${terraform.workspace}"
  kubernetes_version                  = var.aks_kubernetes_version
  private_cluster_enabled             = false
  private_cluster_public_fqdn_enabled = false
  azure_policy_enabled                = false

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

  lifecycle {
    ignore_changes = [
      oidc_issuer_enabled,
    ]
  }
}

# Cleanup ArgoCD applications before destroying infrastructure.
# Deleting app-of-apps triggers a cascade delete (via the resources-finalizer
# baked into the template) of all child apps in reverse sync-wave order, which
# in turn delete their managed resources. This ensures ExternalDNS cleans up
# Cloudflare DNS records as HTTPRoutes are removed, and cloud load balancers
# are deprovisioned.
resource "null_resource" "k8s_cleanup" {
  count = var.deployment.argocd ? 1 : 0

  triggers = {
    cluster_name   = azurerm_kubernetes_cluster.aks_cluster.name
    resource_group = azurerm_resource_group.aks_resource_group.name
  }

  depends_on = [
    github_repository_file.addons_argocd_httproute,
    github_repository_file.addons_certmanager_cloudflare_secret,
    github_repository_file.addons_certmanager_cluster_issuer,
    github_repository_file.addons_envoygateway_gateway,
    github_repository_file.addons_envoygateway_gatewayclass,
    github_repository_file.addons_envoygateway_http_redirect,
    github_repository_file.addons_externaldns_cloudflare_secret,
    github_repository_file.addons_externaldns_predelete_hook,
    github_repository_file.addons_externalsecrets_clustersecretstore,
    github_repository_file.addons_kastendr_policy,
    github_repository_file.addons_kastendr_secret,
    github_repository_file.addons_kastenio_externalsecret,
    github_repository_file.addons_kastenio_httproute,
    github_repository_file.addons_kastenprofiles_infrastructure,
    github_repository_file.addons_kastenprofiles_location,
    github_repository_file.addons_pacman_backup,
    github_repository_file.addons_pacman_httproute,
    github_repository_file.app_of_apps,
    github_repository_file.apps_argocd_gateway,
    github_repository_file.apps_cert_manager,
    github_repository_file.apps_cert_manager_config,
    github_repository_file.apps_envoy_gateway,
    github_repository_file.apps_envoy_gateway_config,
    github_repository_file.apps_external_dns,
    github_repository_file.apps_external_secrets,
    github_repository_file.apps_kasten_dr,
    github_repository_file.apps_kasten_io,
    github_repository_file.apps_kasten_profiles,
    github_repository_file.apps_pacman,
    kubernetes_config_map_v1_data.argocd_cm,
    time_sleep.wait_for_argocd,
  ]

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      az aks get-credentials --resource-group ${self.triggers.resource_group} --name ${self.triggers.cluster_name} --overwrite-existing &&
      kubectl delete application -n argocd app-of-apps --ignore-not-found || true
    EOT
  }
}
