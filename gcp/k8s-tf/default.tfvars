# GitHub Settings
github_owner      = "MichaelHaigh"
github_repo       = "kasten-automation"
github_repo_url   = "https://github.com/MichaelHaigh/kasten-automation.git"
github_repo_token = "~/.github/kasten-automation"

# GCP Settings
sa_creds           = "~/.gcp/mhaigh-terraform-1a95c215426d.json"
k10_sa_creds       = "~/.gcp/k10-mhaigh-sa-key.json"
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

# Deployment options (for cert_manager to be true, argocd must be true)
deployment = {
  argocd       = true
  cert_manager = false
}

# ArgoCD / Deployed Apps Settings
argocd_version     = "9.4.17"             # Only relevant if deployment.argocd is true
eso_version        = "1.1.1"             # Only relevant if deployment.argocd is true
kasten_version     = "8.5.5"             # Only relevant if deployment.argocd is true
pacman_version     = "0.1.28"            # Only relevant if deployment.argocd is true
kasten_eula_accept = true                # Only relevant if deployment.argocd is true
email              = "m.haigh@veeam.com" # Only relevant if deployment.argocd is true (also used for Let's Encrypt)

# cert-manager / Gateway API Settings
cert_manager_version  = "1.20.0"               # Only relevant if deployment.cert_manager is true
envoy_gateway_version = "1.7.1"                # Only relevant if deployment.cert_manager is true
external_dns_version  = "1.20.0"               # Only relevant if deployment.cert_manager is true
cloudflare_api_token  = "~/.cloudflare/tf-api" # Only relevant if deployment.cert_manager is true
domain_name           = "k8sbackup.dev"        # Only relevant if deployment.cert_manager is true
letsencrypt_staging   = false                  # Only relevant if deployment.cert_manager is true
