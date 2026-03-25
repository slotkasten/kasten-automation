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

# GCP Settings
variable "sa_creds" {
  type        = string
  description = "The Service Account json file path on local machine"
}
variable "k10_sa_creds" {
  type        = string
  description = "The K10 GCP Service Account (with compute.storageAdmin role) file path on local machine"
}
variable "gcp_sa" {
  type        = string
  description = "The name of the GCP Service Account"
}
variable "gcp_project" {
  type        = string
  description = "The GCP Project name"
}
variable "gcp_project_number" {
  type        = string
  description = "The GCP Project number"
}
variable "gcp_region" {
  type        = string
  description = "The GCP Region"
}
variable "gcp_zones" {
  type        = list(string)
  description = "A list of the GCP Zone(s)"
}
variable "creator_label" {
  type        = string
  description = "The value to apply to the 'creator' key label"
}

# VPC Settings
variable "gke_subnetwork_cidr" {
  type        = string
  description = "The subnetwork CIDR for the GKE cluster"
}
variable "gke_ip_range_control" {
  type        = string
  description = "The CIDR IP range for the control plane"
}
variable "gke_ip_range_services" {
  type        = string
  description = "The CIDR IP range for the services"
}
variable "gke_ip_range_pods" {
  type        = string
  description = "The CIDR IP range for the pods"
}

# GKE Cluster Settings
variable "gke_kubernetes_version" {
  type        = string
  description = "The Kubernetes version for the GKE cluster"
}
variable "gke_private_cluster" {
  type        = bool
  description = "Whether the cluster is private or not"
}

# Node Pool Settings
variable "gke_machine_type" {
  type        = string
  description = "The machine type for the default node pool"
}
variable "gke_image_type" {
  type        = string
  description = "The image_type of the node pool machines"
}
variable "gke_initial_node_count" {
  type        = number
  description = "The initial number of nodes (per gcp_region) in the default pool"
}
variable "gke_min_node_count" {
  type        = number
  description = "The minimum number of nodes (per gcp_region) in the default pool"
}
variable "gke_max_node_count" {
  type        = number
  description = "The maximum number of nodes (per gcp_region) in the default pool"
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

# cert-manager / Gateway API Settings
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
