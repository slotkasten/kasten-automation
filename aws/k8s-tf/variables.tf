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

# AWS Settings
variable "aws_region" {
  type        = string
  description = "The AWS Region"
}
variable "aws_cred_file" {
  type        = string
  description = "The file location containing a json of the AWS credentials"
}
variable "availability_zones_count" {
  type        = string
  description = "The number of availability zones to deploy into"
}
variable "creator_tag" {
  type        = string
  description = "The value to apply to the 'creator' key tag"
}
# VPC Settings
variable "eks_vpc_cidr" {
  type        = string
  description = "The CIDR range for the VPC"
}
variable "eks_public_subnet_cidrs" {
  type        = list(any)
  description = "A list of CIDR ranges for the public subnets, length must match 'availability_zones_count'"
}
variable "eks_private_subnet_cidrs" {
  type        = list(any)
  description = "A list of CIDR ranges for the private subnets, length must match 'availability_zones_count'"
}

# EKS Settings
variable "eks_kubernetes_version" {
  type        = string
  description = "The Kubernetes version for the EKS cluster"
}
variable "eks_node_count" {
  type        = number
  description = "The default number of nodes in the node pool"
}
variable "eks_node_min" {
  type        = number
  description = "The minimum number of nodes in the node pool"
}
variable "eks_node_max" {
  type        = number
  description = "The maximum number of nodes in the node pool"
}
variable "eks_node_volume_size" {
  type        = number
  description = "The size of the EBS volume for each node in the node pool"
}
variable "eks_instance_type" {
  type        = string
  description = "The EC2 instance size/type"
}
variable "eks_addons" {
  type = list(object({
    name    = string
    version = string
  }))
  description = "A list of addon names and versions to install"
}

# Authorized Networks
variable "authorized_networks" {
  type        = list(object({ cidr_block = string, display_name = string }))
  description = "List of master authorized networks. If none are provided, disallow external access."
  default     = []
}

# ArgoCD / Deployed Apps Settings
variable "argocd_deployment" {
  type        = bool
  description = "Whether to deploy Argo CD or not"
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
variable "snapshot_controller_version" {
  type        = string
  description = "The Piraeus snapshot-controller Helm chart version to install"
}

