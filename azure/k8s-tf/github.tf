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
  addons-kasten-dr-policy = templatefile("${path.module}/templates/addons/kasten-dr/dr-policy.tftpl", {
    creator   = var.creator_tag
    workspace = terraform.workspace
  })
  addons-kasten-dr-secret = templatefile("${path.module}/templates/addons/kasten-dr/dr-secret.tftpl", {
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
    cert_manager_deployment = var.deployment.cert_manager
    email                   = var.email
    email_domain            = length(split("@", var.email)) > 1 ? split("@", var.email)[1] : ""
    kasten_eula_accept      = var.kasten_eula_accept
    kasten_version          = var.kasten_version
    targetRevision          = terraform.workspace
    thisRepoURL             = var.github_repo_url
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
    cert_manager_deployment = var.deployment.cert_manager
    pacman_version          = var.pacman_version
    targetRevision          = terraform.workspace
    thisRepoURL             = var.github_repo_url
  })

  # cert-manager / Gateway API app templates
  apps-cert-manager = templatefile("${path.module}/templates/apps/cert-manager.tftpl", {
    cert_manager_version = var.cert_manager_version
    targetRevision       = terraform.workspace
    thisRepoURL          = var.github_repo_url
  })
  apps-cert-manager-config = templatefile("${path.module}/templates/apps/cert-manager-config.tftpl", {
    targetRevision = terraform.workspace
    thisRepoURL    = var.github_repo_url
  })
  apps-envoy-gateway = templatefile("${path.module}/templates/apps/envoy-gateway.tftpl", {
    envoy_gateway_version = var.envoy_gateway_version
    targetRevision        = terraform.workspace
    thisRepoURL           = var.github_repo_url
  })
  apps-envoy-gateway-config = templatefile("${path.module}/templates/apps/envoy-gateway-config.tftpl", {
    targetRevision = terraform.workspace
    thisRepoURL    = var.github_repo_url
  })
  apps-external-dns = templatefile("${path.module}/templates/apps/external-dns.tftpl", {
    external_dns_version = var.external_dns_version
    targetRevision       = terraform.workspace
    thisRepoURL          = var.github_repo_url
    domain_name          = var.domain_name
    workspace            = terraform.workspace
  })
  apps-argocd-gateway = templatefile("${path.module}/templates/apps/argocd-gateway.tftpl", {
    targetRevision = terraform.workspace
    thisRepoURL    = var.github_repo_url
  })

  # cert-manager / Gateway API addon templates
  addons-cert-manager-cloudflare-secret = templatefile(
    "${path.module}/templates/addons/cert-manager-config/cloudflare-secret.tftpl", {}
  )
  addons-cert-manager-cluster-issuer = templatefile(
    "${path.module}/templates/addons/cert-manager-config/cluster-issuer.tftpl", {
      email               = var.email
      letsencrypt_staging = var.letsencrypt_staging
    }
  )
  addons-envoy-gateway-gatewayclass = templatefile(
    "${path.module}/templates/addons/envoy-gateway-config/gatewayclass.tftpl", {}
  )
  addons-envoy-gateway-gateway = templatefile(
    "${path.module}/templates/addons/envoy-gateway-config/gateway.tftpl", {
      workspace           = terraform.workspace
      domain              = var.domain_name
      letsencrypt_staging = var.letsencrypt_staging
    }
  )
  addons-envoy-gateway-http-redirect = templatefile(
    "${path.module}/templates/addons/envoy-gateway-config/http-redirect.tftpl", {
      workspace = terraform.workspace
      domain    = var.domain_name
    }
  )
  addons-external-dns-cloudflare-secret = templatefile(
    "${path.module}/templates/addons/external-dns/cloudflare-secret.tftpl", {}
  )
  addons-argocd-httproute = templatefile(
    "${path.module}/templates/addons/argocd/httproute.tftpl", {
      workspace = terraform.workspace
      domain    = var.domain_name
    }
  )
  addons-kasten-httproute = templatefile(
    "${path.module}/templates/addons/kasten-io/httproute.tftpl", {
      workspace = terraform.workspace
      domain    = var.domain_name
    }
  )
  addons-pacman-httproute = templatefile(
    "${path.module}/templates/addons/pacman/httproute.tftpl", {
      workspace = terraform.workspace
      domain    = var.domain_name
    }
  )
}

# Addons files
resource "github_repository_file" "addons_externalsecrets_clustersecretstore" {
  count               = (var.deployment.argocd) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/addons/external-secrets/cluster-secret-store.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.addons-cluster-secret-store)
  commit_message      = "automated(${terraform.workspace}): update addons/external-secrets/cluster-secret-store.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "addons_kastenio_externalsecret" {
  count               = (var.deployment.argocd) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/addons/kasten-io/external-secret.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.addons-external-secret)
  commit_message      = "automated(${terraform.workspace}): update addons/kasten-io/external-secret.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "addons_kastenprofiles_infrastructure" {
  count               = (var.deployment.argocd) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/addons/kasten-profiles/infrastructure.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.addons-infrastructure)
  commit_message      = "automated(${terraform.workspace}): update addons/kasten-profiles/infrastructure.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "addons_kastendr_policy" {
  count               = (var.deployment.argocd) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/addons/kasten-dr/dr-policy.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.addons-kasten-dr-policy)
  commit_message      = "automated(${terraform.workspace}): update addons/kasten-dr/dr-policy.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "addons_kastendr_secret" {
  count               = (var.deployment.argocd) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/addons/kasten-dr/dr-secret.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.addons-kasten-dr-secret)
  commit_message      = "automated(${terraform.workspace}): update addons/kasten-dr/dr-secret.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "addons_kastenprofiles_location" {
  count               = (var.deployment.argocd) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/addons/kasten-profiles/location.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.addons-location)
  commit_message      = "automated(${terraform.workspace}): update addons/kasten-profiles/location.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "addons_pacman_backup" {
  count               = (var.deployment.argocd) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/addons/pacman/pacman-backup.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.addons-pacman-backup)
  commit_message      = "automated(${terraform.workspace}): update addons/pacman/pacman-backup.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}

# Apps files
resource "github_repository_file" "app_of_apps" {
  count               = (var.deployment.argocd) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/app-of-apps.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.app-of-apps)
  commit_message      = "automated(${terraform.workspace}): update app-of-apps.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "apps_external_secrets" {
  count               = (var.deployment.argocd) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/apps/external-secrets.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.apps-external-secrets)
  commit_message      = "automated(${terraform.workspace}): update apps/external-secret.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "apps_kasten_io" {
  count               = (var.deployment.argocd) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/apps/kasten-io.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.apps-kasten-io)
  commit_message      = "automated(${terraform.workspace}): update apps/kasten-io.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "apps_kasten_profiles" {
  count               = (var.deployment.argocd) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/apps/kasten-profiles.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.apps-kasten-profiles)
  commit_message      = "automated(${terraform.workspace}): update apps/kasten-profiles.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "apps_kasten_dr" {
  count               = (var.deployment.argocd) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/apps/kasten-dr.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.apps-kasten-dr)
  commit_message      = "automated(${terraform.workspace}): update apps/kasten-dr.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "apps_pacman" {
  count               = (var.deployment.argocd) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/apps/pacman.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.apps-pacman)
  commit_message      = "automated(${terraform.workspace}): update apps/pacman.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}

# cert-manager / Gateway API apps files
resource "github_repository_file" "apps_cert_manager" {
  count               = (var.deployment.cert_manager) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/apps/cert-manager.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.apps-cert-manager)
  commit_message      = "automated(${terraform.workspace}): update apps/cert-manager.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "apps_cert_manager_config" {
  count               = (var.deployment.cert_manager) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/apps/cert-manager-config.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.apps-cert-manager-config)
  commit_message      = "automated(${terraform.workspace}): update apps/cert-manager-config.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "apps_envoy_gateway" {
  count               = (var.deployment.cert_manager) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/apps/envoy-gateway.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.apps-envoy-gateway)
  commit_message      = "automated(${terraform.workspace}): update apps/envoy-gateway.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "apps_envoy_gateway_config" {
  count               = (var.deployment.cert_manager) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/apps/envoy-gateway-config.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.apps-envoy-gateway-config)
  commit_message      = "automated(${terraform.workspace}): update apps/envoy-gateway-config.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "apps_external_dns" {
  count               = (var.deployment.cert_manager) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/apps/external-dns.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.apps-external-dns)
  commit_message      = "automated(${terraform.workspace}): update apps/external-dns.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "apps_argocd_gateway" {
  count               = (var.deployment.cert_manager) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/apps/argocd-gateway.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.apps-argocd-gateway)
  commit_message      = "automated(${terraform.workspace}): update apps/argocd-gateway.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}

# cert-manager / Gateway API addons files
resource "github_repository_file" "addons_certmanager_cloudflare_secret" {
  count               = (var.deployment.cert_manager) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/addons/cert-manager-config/cloudflare-secret.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.addons-cert-manager-cloudflare-secret)
  commit_message      = "automated(${terraform.workspace}): update addons/cert-manager-config/cloudflare-secret.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "addons_certmanager_cluster_issuer" {
  count               = (var.deployment.cert_manager) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/addons/cert-manager-config/cluster-issuer.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.addons-cert-manager-cluster-issuer)
  commit_message      = "automated(${terraform.workspace}): update addons/cert-manager-config/cluster-issuer.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "addons_envoygateway_gatewayclass" {
  count               = (var.deployment.cert_manager) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/addons/envoy-gateway-config/gatewayclass.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.addons-envoy-gateway-gatewayclass)
  commit_message      = "automated(${terraform.workspace}): update addons/envoy-gateway-config/gatewayclass.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "addons_envoygateway_gateway" {
  count               = (var.deployment.cert_manager) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/addons/envoy-gateway-config/gateway.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.addons-envoy-gateway-gateway)
  commit_message      = "automated(${terraform.workspace}): update addons/envoy-gateway-config/gateway.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "addons_envoygateway_http_redirect" {
  count               = (var.deployment.cert_manager) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/addons/envoy-gateway-config/http-redirect.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.addons-envoy-gateway-http-redirect)
  commit_message      = "automated(${terraform.workspace}): update addons/envoy-gateway-config/http-redirect.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "addons_externaldns_cloudflare_secret" {
  count               = (var.deployment.cert_manager) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/addons/external-dns/cloudflare-secret.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.addons-external-dns-cloudflare-secret)
  commit_message      = "automated(${terraform.workspace}): update addons/external-dns/cloudflare-secret.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "addons_argocd_httproute" {
  count               = (var.deployment.cert_manager) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/addons/argocd/httproute.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.addons-argocd-httproute)
  commit_message      = "automated(${terraform.workspace}): update addons/argocd/httproute.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "addons_kastenio_httproute" {
  count               = (var.deployment.cert_manager) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/addons/kasten-io/httproute.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.addons-kasten-httproute)
  commit_message      = "automated(${terraform.workspace}): update addons/kasten-io/httproute.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
resource "github_repository_file" "addons_pacman_httproute" {
  count               = (var.deployment.cert_manager) ? 1 : 0
  repository          = var.github_repo
  branch              = terraform.workspace
  file                = "azure/argocd/addons/pacman/httproute.yaml"
  content             = format("# Auto-generated file, do not edit directly\n%s", local.addons-pacman-httproute)
  commit_message      = "automated(${terraform.workspace}): update addons/pacman/httproute.yaml via 'terraform apply/destroy'"
  overwrite_on_create = true
}
