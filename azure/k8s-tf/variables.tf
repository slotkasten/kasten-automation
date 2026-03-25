# GitHub Settings
variable "github_owner" {
  type        = string
  description = "The owner (user or organization) of the GitHub repository"
}
variable "github_repo" {
  type        = string
  description = "The name of the GitHub repository"
}
variable "github_repo_url" {
  type        = string
  description = "The HTTPS URL of the GitHub repository"
}
variable "github_repo_token" {
  type        = string
  description = "The file path on the local machine containing a read/write GitHub repository token"
}

# Azure Settings
variable "azr_creds" {
  type        = string
  description = "The path of a local json file which contains the Azure Subscription ID"
}
variable "azr_region" {
  type        = string
  description = "The Azure region"
}
variable "creator_tag" {
  type        = string
  description = "The value to apply to the 'creator' key tag"
}

# VNet Settings
variable "aks_vnet_cidr" {
  type        = string
  description = "The CIDR IP range for the VNet"
}
variable "aks_vnet_dns_ip" {
  type        = string
  description = "The DNS IP for the VNet"
}
variable "aks_nodepool_cidr" {
  type        = string
  description = "The CIDR IP range for the nodepool VMs"
}
variable "aks_services_cidr" {
  type        = string
  description = "The CIDR IP range for the services"
}
variable "aks_services_dns_ip" {
  type        = string
  description = "The IP of the DNS Service, must be within the aks_services_cidr CIDR"
}
variable "aks_pods_cidr" {
  type        = string
  description = "The CIDR IP range for the pods"
}

# AKS Cluster Settings
variable "aks_kubernetes_version" {
  type        = string
  description = "The Kubernetes version of the AKS cluster"
}

# Node Pool Settings
variable "aks_node_count" {
  type        = number
  description = "The initial node count for the default_node_pool"
}
variable "aks_image_size" {
  type        = string
  description = "The VM / image size for the default_node_pool"
}
variable "aks_os_disk_size_gb" {
  type        = string
  description = "The VM / image OS disk size for the default_node_pool"
  default     = 30
}

# Authorized Networks
variable "authorized_networks" {
  type        = list(object({ cidr_block = string, display_name = string }))
  description = "List of master authorized networks. If none are provided, disallow external access."
  default     = []
}

# ArgoCD / Deployed Apps Settings
variable "deployment" {
  type = object({
    argocd       = bool
    cert_manager = bool
  })
  description = "Controls which optional components are deployed. cert_manager requires argocd to be true."
  default = {
    argocd       = true
    cert_manager = false
  }

  validation {
    condition     = !(var.deployment.cert_manager && !var.deployment.argocd)
    error_message = "cert_manager requires argocd to be true"
  }
}
variable "argocd_version" {
  type        = string
  description = "The Argo CD helm version to install"
}
variable "eso_version" {
  type        = string
  description = "The External Secrets Operator version to install"
}
variable "kasten_version" {
  type        = string
  description = "The Kasten.io version to install"
}
variable "pacman_version" {
  type        = string
  description = "The Pacman app version to install"
}
variable "email" {
  type        = string
  description = "Email address for Kasten EULA acceptance and Let's Encrypt registration"
  default     = ""
}
variable "kasten_eula_accept" {
  type        = bool
  description = "Accept the Kasten EULA (https://www.veeam.com/eula.html)"
  default     = false
}
variable "cert_manager_version" {
  type        = string
  description = "The cert-manager Helm chart version to install"
}
variable "envoy_gateway_version" {
  type        = string
  description = "The Envoy Gateway Helm chart version to install"
}
variable "external_dns_version" {
  type        = string
  description = "The ExternalDNS Helm chart version to install"
}
variable "cloudflare_api_token" {
  type        = string
  description = "The file path on the local machine containing a Cloudflare API token with Zone:DNS:Edit and Zone:Zone:Read permissions"
  default     = ""
}
variable "domain_name" {
  type        = string
  description = "The base domain name for TLS-enabled subdomains (e.g. example.com)"
  default     = ""
}
variable "letsencrypt_staging" {
  type        = bool
  description = "Use the Let's Encrypt staging server (recommended for testing to avoid rate limits)"
  default     = true
}
