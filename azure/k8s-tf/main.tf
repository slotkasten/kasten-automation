terraform {
  required_version = ">= 0.12"
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.7.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.57.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1.1"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.9.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.6.1"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }

  subscription_id = jsondecode(file(var.azr_creds)).subscription_id
}

resource "azurerm_resource_group" "aks_resource_group" {
  name     = "${var.creator_tag}-${terraform.workspace}-rg"
  location = var.azr_region

  tags = {
    environment = "${terraform.workspace}"
    creator     = "${var.creator_tag}"
  }
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks_cluster.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.cluster_ca_certificate)
}

provider "helm" {
  kubernetes = {
    host                   = azurerm_kubernetes_cluster.aks_cluster.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.cluster_ca_certificate)
  }
}

provider "github" {
  owner = var.github_owner
  token = trimspace(file(var.github_repo_token))
}
