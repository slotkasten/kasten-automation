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
eks_kubernetes_version = "1.35"
eks_node_count         = 3
eks_node_min           = 2
eks_node_max           = 5
eks_node_volume_size   = 50
eks_instance_type      = "t3.medium"
eks_addons = [
  {
    name    = "kube-proxy"
    version = "v1.35.3-eksbuild.17"
  },
  {
    name    = "vpc-cni"
    version = "v1.22.4-eksbuild.3"
  },
  {
    name    = "coredns"
    version = "v1.14.3-eksbuild.3"
  },
  {
    name    = "aws-ebs-csi-driver"
    version = "v1.63.0-eksbuild.1"
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

# Deployment options (for cert_manager to be true, argocd must be true)
deployment = {
  argocd       = true
  cert_manager = false
}

# ArgoCD / Deployed Apps Settings
argocd_version              = "9.4.17"            # Only relevant if deployment.argocd is true
eso_version                 = "1.1.1"             # Only relevant if deployment.argocd is true
kasten_version              = "8.5.5"             # Only relevant if deployment.argocd is true
pacman_version              = "0.1.28"            # Only relevant if deployment.argocd is true
snapshot_controller_version = "5.0.3"             # Only relevant if deployment.argocd is true
kasten_eula_accept          = true                # Only relevant if deployment.argocd is true
email                       = "m.haigh@veeam.com" # Only relevant if deployment.argocd is true (also used for Let's Encrypt)

# cert-manager / Gateway API Settings
cert_manager_version  = "1.20.0"               # Only relevant if deployment.cert_manager is true
envoy_gateway_version = "1.7.1"                # Only relevant if deployment.cert_manager is true
external_dns_version  = "1.20.0"               # Only relevant if deployment.cert_manager is true
cloudflare_api_token  = "~/.cloudflare/tf-api" # Only relevant if deployment.cert_manager is true
domain_name           = "k8sbackup.dev"        # Only relevant if deployment.cert_manager is true
letsencrypt_staging   = false                  # Only relevant if deployment.cert_manager is true
