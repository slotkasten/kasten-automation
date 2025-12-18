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
