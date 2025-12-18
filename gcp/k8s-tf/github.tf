# Update the application and addons YAML within templates/ directory, not ../argocd/addons directory
locals {
  addons-cluster-secret-store = templatefile("${path.module}/templates/addons/external-secrets/cluster-secret-store.tftpl", {
    gcp_project = var.gcp_project
  })
  addons-external-secret = templatefile("${path.module}/templates/addons/kasten-io/external-secret.tftpl", {
    creator_label = var.creator_label
    workspace     = terraform.workspace
  })
  addons-infra = templatefile("${path.module}/templates/addons/kasten-profiles/infra.tftpl", {
    creator_label = var.creator_label
    workspace     = terraform.workspace
  })
  addons-location = templatefile("${path.module}/templates/addons/kasten-profiles/location.tftpl", {
    bucket        = google_storage_bucket.backup_target.name
    creator_label = var.creator_label
    region        = var.gcp_region
    workspace     = terraform.workspace
  })
  addons-pacman-backup = templatefile("${path.module}/templates/addons/pacman/pacman-backup.tftpl", {
    creator_label = var.creator_label
    workspace     = terraform.workspace
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
  file                = "gcp/argocd/addons/external-secrets/cluster-secret-store.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.addons-cluster-secret-store)
  commit_message      = "automated(${terraform.workspace}): update addons/external-secrets/cluster-secret-store.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "addons_kastenio_externalsecret" {
  count               = (var.argocd_deployment) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "gcp/argocd/addons/kasten-io/external-secret.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.addons-external-secret)
  commit_message      = "automated(${terraform.workspace}): update addons/kasten-io/external-secret.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "addons_kastenprofiles_infra" {
  count               = (var.argocd_deployment) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "gcp/argocd/addons/kasten-profiles/infra.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.addons-infra)
  commit_message      = "automated(${terraform.workspace}): update addons/kasten-profiles/infra.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "addons_kastenprofiles_location" {
  count               = (var.argocd_deployment) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "gcp/argocd/addons/kasten-profiles/location.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.addons-location)
  commit_message      = "automated(${terraform.workspace}): update addons/kasten-profiles/location.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "addons_pacman_backup" {
  count               = (var.argocd_deployment) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "gcp/argocd/addons/pacman/pacman-backup.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.addons-pacman-backup)
  commit_message      = "automated(${terraform.workspace}): update addons/pacman/pacman-backup.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}

# Apps files
resource "github_repository_file" "apps_external_secrets" {
  count               = (var.argocd_deployment) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "gcp/argocd/apps/external-secrets.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.apps-external-secrets)
  commit_message      = "automated(${terraform.workspace}): update apps/external-secret.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "apps_kasten_io" {
  count               = (var.argocd_deployment) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "gcp/argocd/apps/kasten-io.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.apps-kasten-io)
  commit_message      = "automated(${terraform.workspace}): update apps/kasten-io.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "apps_kasten_profiles" {
  count               = (var.argocd_deployment) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "gcp/argocd/apps/kasten-profiles.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.apps-kasten-profiles)
  commit_message      = "automated(${terraform.workspace}): update apps/kasten-profiles.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "apps_pacman" {
  count               = (var.argocd_deployment) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "gcp/argocd/apps/pacman.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.apps-pacman)
  commit_message      = "automated(${terraform.workspace}): update apps/pacman.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
