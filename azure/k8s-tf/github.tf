# Update the application and addons YAML within templates/ directory, not ../argocd/addons directory
locals {
  addons-cluster-secret-store = templatefile("${path.module}/templates/addons/external-secrets/cluster-secret-store.tftpl", {
    client_id = azurerm_kubernetes_cluster.aks_cluster.kubelet_identity[0].client_id
    vault_url = azurerm_key_vault.kasten_key_vault.vault_uri
  })
  addons-external-secret = templatefile("${path.module}/templates/addons/kasten-io/external-secret.tftpl", {
    creator   = var.creator_tag
    workspace = terraform.workspace
  })
  addons-kasten-dr = templatefile("${path.module}/templates/addons/kasten-profiles/kasten-dr.tftpl", {
    creator   = var.creator_tag
    workspace = terraform.workspace
  })
  addons-kasten-dr-secret = templatefile("${path.module}/templates/addons/kasten-profiles/kasten-dr-secret.tftpl", {
    creator   = var.creator_tag
    workspace = terraform.workspace
  })
  addons-infrastructure = templatefile("${path.module}/templates/addons/kasten-profiles/infrastructure.tftpl", {
    creator        = var.creator_tag
    resourceGroup  = azurerm_resource_group.aks_resource_group.name
    subscriptionID = jsondecode(file(var.azr_creds)).subscription_id
    workspace      = terraform.workspace
  })
  addons-location = templatefile("${path.module}/templates/addons/kasten-profiles/location.tftpl", {
    container = azurerm_storage_container.container.name
    creator   = var.creator_tag
    workspace = terraform.workspace
  })
  addons-pacman-backup = templatefile("${path.module}/templates/addons/pacman/pacman-backup.tftpl", {
    creator   = var.creator_tag
    workspace = terraform.workspace
  })
  app-of-apps = templatefile("${path.module}/templates/app-of-apps.tftpl", {
    targetRevision = terraform.workspace
    thisRepoURL    = var.github_repo_url
  })
  apps-external-secrets = templatefile("${path.module}/templates/apps/external-secrets.tftpl", {
    eso_version    = var.eso_version
    targetRevision = terraform.workspace
    thisRepoURL    = var.github_repo_url
  })
  apps-kasten-io = templatefile("${path.module}/templates/apps/kasten-io.tftpl", {
    kasten_version = var.kasten_version
    targetRevision = terraform.workspace
    thisRepoURL    = var.github_repo_url
  })
  apps-kasten-profiles = templatefile("${path.module}/templates/apps/kasten-profiles.tftpl", {
    targetRevision = terraform.workspace
    thisRepoURL    = var.github_repo_url
  })
  apps-pacman = templatefile("${path.module}/templates/apps/pacman.tftpl", {
    pacman_version = var.pacman_version
    targetRevision = terraform.workspace
    thisRepoURL    = var.github_repo_url
  })
}

# Addons files
resource "github_repository_file" "addons_externalsecrets_clustersecretstore" {
  count               = (var.argocd_deployment) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/addons/external-secrets/cluster-secret-store.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.addons-cluster-secret-store)
  commit_message      = "automated(${terraform.workspace}): update addons/external-secrets/cluster-secret-store.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "addons_kastenio_externalsecret" {
  count               = (var.argocd_deployment) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/addons/kasten-io/external-secret.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.addons-external-secret)
  commit_message      = "automated(${terraform.workspace}): update addons/kasten-io/external-secret.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "addons_kastenprofiles_infrastructure" {
  count               = (var.argocd_deployment) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/addons/kasten-profiles/infrastructure.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.addons-infrastructure)
  commit_message      = "automated(${terraform.workspace}): update addons/kasten-profiles/infrastructure.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "addons_kastenprofiles_kastendr" {
  count               = (var.argocd_deployment) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/addons/kasten-profiles/kasten-dr.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.addons-kasten-dr)
  commit_message      = "automated(${terraform.workspace}): update addons/kasten-profiles/kasten-dr.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "addons_kastenprofiles_kastendrsecret" {
  count               = (var.argocd_deployment) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/addons/kasten-profiles/kasten-dr-secret.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.addons-kasten-dr-secret)
  commit_message      = "automated(${terraform.workspace}): update addons/kasten-profiles/kasten-dr-secret.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "addons_kastenprofiles_location" {
  count               = (var.argocd_deployment) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/addons/kasten-profiles/location.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.addons-location)
  commit_message      = "automated(${terraform.workspace}): update addons/kasten-profiles/location.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "addons_pacman_backup" {
  count               = (var.argocd_deployment) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/addons/pacman/pacman-backup.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.addons-pacman-backup)
  commit_message      = "automated(${terraform.workspace}): update addons/pacman/pacman-backup.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}

# Apps files
resource "github_repository_file" "app_of_apps" {
  count               = (var.argocd_deployment) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/app-of-apps.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.app-of-apps)
  commit_message      = "automated(${terraform.workspace}): update app-of-apps.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "apps_external_secrets" {
  count               = (var.argocd_deployment) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/apps/external-secrets.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.apps-external-secrets)
  commit_message      = "automated(${terraform.workspace}): update apps/external-secret.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "apps_kasten_io" {
  count               = (var.argocd_deployment) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/apps/kasten-io.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.apps-kasten-io)
  commit_message      = "automated(${terraform.workspace}): update apps/kasten-io.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "apps_kasten_profiles" {
  count               = (var.argocd_deployment) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/apps/kasten-profiles.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.apps-kasten-profiles)
  commit_message      = "automated(${terraform.workspace}): update apps/kasten-profiles.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "apps_pacman" {
  count               = (var.argocd_deployment) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/apps/pacman.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.apps-pacman)
  commit_message      = "automated(${terraform.workspace}): update apps/pacman.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
