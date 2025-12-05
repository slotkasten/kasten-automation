# GCP Settings
sa_creds           = "~/.gcp/mhaigh-terraform-1a95c215426d.json"
gcp_sa             = "mhaigh-terraform@rich-access-174020.iam.gserviceaccount.com"
gcp_project        = "rich-access-174020"
gcp_project_number = "215900857647"
gcp_region         = "us-central1"
gcp_zones          = ["us-central1-b", "us-central1-c"]
creator_label      = "mhaigh"

# VPC Settings
gke_subnetwork_cidr   = "10.10.0.0/23"
gke_ip_range_control  = "172.16.0.0/28"
gke_ip_range_services = "172.17.0.0/16"
gke_ip_range_pods     = "172.18.0.0/16"

# GKE Cluster Settings
gke_kubernetes_version = "1.32"
gke_private_cluster    = true

# Node Pool Settings
gke_machine_type       = "e2-medium"
gke_image_type         = "COS_CONTAINERD"
gke_initial_node_count = 1 # per-zone
gke_min_node_count     = 1 # per-zone
gke_max_node_count     = 3 # per-zone

# Authorized Networks
authorized_networks = [
  {
    cidr_block   = "198.51.100.0/24"
    display_name = "company_range"
  },
  {
    cidr_block   = "203.0.113.30/32"
    display_name = "home_address"
  },
]

# ArgoCD Settings
argocd_namespace = "argocd"
argocd_version   = "9.1.6"
