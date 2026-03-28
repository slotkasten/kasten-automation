data "google_client_config" "default" {}

# GKE Config
module "gke" {

  source                  = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  project_id              = var.gcp_project
  name                    = "${var.creator_label}-${terraform.workspace}-gke"
  regional                = false
  region                  = var.gcp_region
  zones                   = var.gcp_zones
  network                 = google_compute_network.gke_network.name
  subnetwork              = google_compute_subnetwork.gke_subnetwork.name
  kubernetes_version      = var.gke_kubernetes_version
  ip_range_pods           = google_compute_subnetwork.gke_subnetwork.secondary_ip_range[0].range_name
  ip_range_services       = google_compute_subnetwork.gke_subnetwork.secondary_ip_range[1].range_name
  master_ipv4_cidr_block  = var.gke_ip_range_control
  create_service_account  = false
  service_account         = var.gcp_sa
  enable_private_endpoint = false
  enable_private_nodes    = var.gke_private_cluster
  deletion_protection     = false

  node_pools = [
    {
      name               = "default-node-pool"
      auto_upgrade       = true
      machine_type       = var.gke_machine_type
      initial_node_count = var.gke_initial_node_count
      min_count          = var.gke_min_node_count
      max_count          = var.gke_max_node_count
      local_ssd_count    = 0
      disk_size_gb       = 100
      disk_type          = "pd-standard"
      image_type         = var.gke_image_type
    },
  ]

  master_authorized_networks = var.gke_private_cluster ? var.authorized_networks : [
    {
      cidr_block   = "0.0.0.0/0"
      display_name = "Internet"
    }
  ]

  add_master_webhook_firewall_rules = true
  firewall_inbound_ports            = ["8443"]

  node_pools_labels = {
    all = {
      creator = var.creator_label
    }
  }

  cluster_resource_labels = {
    creator = var.creator_label
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
    cluster_name = module.gke.name
    zone         = var.gcp_zones[0]
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
    github_repository_file.addons_kastenio_externalsecret,
    github_repository_file.addons_kastenio_httproute,
    github_repository_file.addons_kastenprofiles_infra,
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
    github_repository_file.apps_kasten_io,
    github_repository_file.apps_kasten_profiles,
    github_repository_file.apps_pacman,
    google_compute_router_nat.gke_nat,
    kubernetes_config_map_v1_data.argocd_cm,
    kubernetes_secret.external_secrets_operator,
    time_sleep.wait_for_argocd,
  ]

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      gcloud container clusters get-credentials ${self.triggers.cluster_name} --zone ${self.triggers.zone} &&
      kubectl delete application -n argocd app-of-apps --ignore-not-found || true
    EOT
  }
}
