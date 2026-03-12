# GitHub Settings
github_owner      = "michaelhaigh"
github_repo       = "kasten-automation"
github_repo_url   = "https://github.com/michaelhaigh/kasten-automation"
github_repo_token = "~/.github/kasten-automation"

# AWS Settings
aws_region               = "us-east-2"
aws_cred_file            = "~/.aws/aws-terraform.json"
availability_zones_count = 2
creator_tag              = "mhaigh"

# VPC Settings
eks_vpc_cidr             = "10.30.0.0/16"
eks_public_subnet_cidrs  = ["10.30.0.0/24", "10.30.1.0/24"]   # len must equal availability_zones_count
eks_private_subnet_cidrs = ["10.30.10.0/24", "10.30.11.0/24"] # len must equal availability_zones_count

# EKS Settings
eks_kubernetes_version = "1.32"
eks_node_count         = 3
eks_node_min           = 2
eks_node_max           = 5
eks_node_volume_size   = 50
eks_instance_type      = "t3.medium"
eks_addons = [
  {
    name    = "kube-proxy"
    version = "v1.32.11-eksbuild.5"
  },
  {
    name    = "vpc-cni"
    version = "v1.19.6-eksbuild.7"
  },
  {
    name    = "coredns"
    version = "v1.11.4-eksbuild.28"
  },
  {
    name    = "aws-ebs-csi-driver"
    version = "v1.56.0-eksbuild.1"
  },
]

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
argocd_deployment           = true
argocd_version              = "9.1.6"  # Only relevant if argocd_deployment is true
eso_version                 = "1.1.1"  # Only relevant if argocd_deployment is true
kasten_version              = "8.5.1"  # Only relevant if argocd_deployment is true
pacman_version              = "0.1.28" # Only relevant if argocd_deployment is true
snapshot_controller_version = "5.0.3"  # Only relevant if argocd_deployment is true
