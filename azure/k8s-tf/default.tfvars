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

# ArgoCD / Deployed Apps Settings
argocd_deployment = true
argocd_version    = "9.1.6"  # Only relevant if argocd_deployment is true
eso_version       = "1.1.1"  # Only relevant if argocd_deployment is true
kasten_version    = "8.5.1"  # Only relevant if argocd_deployment is true
pacman_version    = "0.1.26" # Only relevant if argocd_deployment is true
