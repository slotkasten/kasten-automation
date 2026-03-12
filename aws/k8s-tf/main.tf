terraform {
  required_version = ">= 0.12"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.35.1"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3.5"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.8.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1.1"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.9.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13.1"
    }
  }
}

provider "aws" {
  region = var.aws_region

  access_key = jsondecode(file(var.aws_cred_file)).aws_access_key_id
  secret_key = jsondecode(file(var.aws_cred_file)).aws_secret_access_key
}

data "aws_availability_zones" "available" {
  state = "available"
}

provider "helm" {
  kubernetes = {
    host                   = aws_eks_cluster.eks_cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.eks_cluster.name, "--region", var.aws_region]
    }
  }
}

provider "github" {
  owner = var.github_owner
  token = trimspace(file(var.github_repo_token))
}

provider "kubernetes" {
  host                   = aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.eks_cluster.name, "--region", var.aws_region]
  }
}
