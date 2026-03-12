# Update the application and addons YAML within templates/ directory, not ../argocd/addons directory
locals {
  addons-cluster-secret-store = templatefile("${path.module}/templates/addons/external-secrets/cluster-secret-store.tftpl", {
    region = var.aws_region
  })
  addons-aws-credential = templatefile("${path.module}/templates/addons/kasten-profiles/aws-credential.tftpl", {
    access_key_id_secret     = aws_secretsmanager_secret.kasten_access_key_id.name
    secret_access_key_secret = aws_secretsmanager_secret.kasten_secret_access_key.name
  })
  addons-infrastructure = templatefile("${path.module}/templates/addons/kasten-profiles/infrastructure.tftpl", {
    creator   = var.creator_tag
    workspace = terraform.workspace
  })
  addons-location = templatefile("${path.module}/templates/addons/kasten-profiles/location.tftpl", {
    bucket    = aws_s3_bucket.backup_target.bucket
    creator   = var.creator_tag
    region    = var.aws_region
    workspace = terraform.workspace
  })
  addons-kasten-dr-policy = templatefile("${path.module}/templates/addons/kasten-dr/dr-policy.tftpl", {
    creator   = var.creator_tag
    workspace = terraform.workspace
  })
  addons-kasten-dr-secret = templatefile("${path.module}/templates/addons/kasten-dr/dr-secret.tftpl", {
    passphrase_secret_name = aws_secretsmanager_secret.kasten_dr_passphrase.name
    region                 = var.aws_region
    source                 = "aws"
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
    eso_role_arn   = aws_iam_role.eks_eso.arn
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
  apps-kasten-dr = templatefile("${path.module}/templates/apps/kasten-dr.tftpl", {
    targetRevision = terraform.workspace
    thisRepoURL    = var.github_repo_url
  })
  apps-pacman = templatefile("${path.module}/templates/apps/pacman.tftpl", {
    pacman_version = var.pacman_version
    targetRevision = terraform.workspace
    thisRepoURL    = var.github_repo_url
  })
  apps-snapshot-controller = templatefile("${path.module}/templates/apps/snapshot-controller.tftpl", {
    snapshot_controller_version = var.snapshot_controller_version
  })
}

# Addons files
resource "github_repository_file" "addons_externalsecrets_clustersecretstore" {
  count               = (var.argocd_deployment) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "aws/argocd/addons/external-secrets/cluster-secret-store.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.addons-cluster-secret-store)
  commit_message      = "automated(${terraform.workspace}): update addons/external-secrets/cluster-secret-store.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "addons_kastenprofiles_aws_credential" {
  count               = (var.argocd_deployment) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "aws/argocd/addons/kasten-profiles/aws-credential.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.addons-aws-credential)
  commit_message      = "automated(${terraform.workspace}): update addons/kasten-profiles/aws-credential.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "addons_kastenprofiles_infrastructure" {
  count               = (var.argocd_deployment) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "aws/argocd/addons/kasten-profiles/infrastructure.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.addons-infrastructure)
  commit_message      = "automated(${terraform.workspace}): update addons/kasten-profiles/infrastructure.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "addons_kastenprofiles_location" {
  count               = (var.argocd_deployment) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "aws/argocd/addons/kasten-profiles/location.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.addons-location)
  commit_message      = "automated(${terraform.workspace}): update addons/kasten-profiles/location.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "addons_kastendr_policy" {
  count               = (var.argocd_deployment) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "aws/argocd/addons/kasten-dr/dr-policy.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.addons-kasten-dr-policy)
  commit_message      = "automated(${terraform.workspace}): update addons/kasten-dr/dr-policy.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "addons_kastendr_secret" {
  count               = (var.argocd_deployment) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "aws/argocd/addons/kasten-dr/dr-secret.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.addons-kasten-dr-secret)
  commit_message      = "automated(${terraform.workspace}): update addons/kasten-dr/dr-secret.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "addons_pacman_backup" {
  count               = (var.argocd_deployment) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "aws/argocd/addons/pacman/pacman-backup.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.addons-pacman-backup)
  commit_message      = "automated(${terraform.workspace}): update addons/pacman/pacman-backup.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}

# Apps files
resource "github_repository_file" "app_of_apps" {
  count               = (var.argocd_deployment) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "aws/argocd/app-of-apps.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.app-of-apps)
  commit_message      = "automated(${terraform.workspace}): update app-of-apps.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "apps_external_secrets" {
  count               = (var.argocd_deployment) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "aws/argocd/apps/external-secrets.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.apps-external-secrets)
  commit_message      = "automated(${terraform.workspace}): update apps/external-secret.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "apps_kasten_io" {
  count               = (var.argocd_deployment) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "aws/argocd/apps/kasten-io.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.apps-kasten-io)
  commit_message      = "automated(${terraform.workspace}): update apps/kasten-io.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "apps_kasten_profiles" {
  count               = (var.argocd_deployment) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "aws/argocd/apps/kasten-profiles.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.apps-kasten-profiles)
  commit_message      = "automated(${terraform.workspace}): update apps/kasten-profiles.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "apps_kasten_dr" {
  count               = (var.argocd_deployment) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "aws/argocd/apps/kasten-dr.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.apps-kasten-dr)
  commit_message      = "automated(${terraform.workspace}): update apps/kasten-dr.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "apps_snapshot_controller" {
  count               = (var.argocd_deployment) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "aws/argocd/apps/snapshot-controller.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.apps-snapshot-controller)
  commit_message      = "automated(${terraform.workspace}): update apps/snapshot-controller.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "apps_pacman" {
  count               = (var.argocd_deployment) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "aws/argocd/apps/pacman.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.apps-pacman)
  commit_message      = "automated(${terraform.workspace}): update apps/pacman.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
