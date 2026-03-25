# GitHub Settings
github_owner      = "MichaelHaigh"
github_repo       = "kasten-automation"
github_repo_url   = "https://github.com/MichaelHaigh/kasten-automation.git"
github_repo_token = "~/.github/kasten-automation"

# Azure Settings
azr_creds   = "~/.azure/tf-azure.json"
azr_region  = "eastus"
creator_tag = "mhaigh"

# VNet Settings
aks_vnet_cidr       = "10.20.0.0/22"
aks_vnet_dns_ip     = "10.20.3.254"   # must be w/in vnet
aks_nodepool_cidr   = "10.20.0.0/23"  # must be w/in vnet
aks_services_cidr   = "172.16.0.0/16" # must not be w/in vnet
aks_services_dns_ip = "172.16.0.10"   # must be w/in services
aks_pods_cidr       = "172.18.0.0/16" # must not be w/in vnet

# AKS Cluster Settings
aks_kubernetes_version = "1.32"

# Node Pool Settings
aks_node_count = 2
aks_image_size = "Standard_D4s_v3"

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
argocd_version     = "9.1.6"             # Only relevant if deployment.argocd is true
eso_version        = "1.1.1"             # Only relevant if deployment.argocd is true
kasten_version     = "8.5.1"             # Only relevant if deployment.argocd is true
pacman_version     = "0.1.26"            # Only relevant if deployment.argocd is true
kasten_eula_accept = true                # Only relevant if deployment.argocd is true
email              = "m.haigh@veeam.com" # Only relevant if deployment.argocd is true (also used for Let's Encrypt)

# cert-manager / Gateway API Settings
cert_manager_version  = "1.20.0"               # Only relevant if deployment.cert_manager is true
envoy_gateway_version = "1.7.1"                # Only relevant if deployment.cert_manager is true
external_dns_version  = "1.20.0"               # Only relevant if deployment.cert_manager is true
cloudflare_api_token  = "~/.cloudflare/tf-api" # Only relevant if deployment.cert_manager is true
domain_name           = "haigh.cloud"          # Only relevant if deployment.cert_manager is true
letsencrypt_staging   = false                  # Only relevant if deployment.cert_manager is true
