resource "google_secret_manager_secret" "k10_sa_creds" {
  count     = (var.deployment.argocd) ? 1 : 0
  secret_id = "${var.creator_label}-${terraform.workspace}-k10-sa"

  labels = {
    creator    = var.creator_label
    managed_by = "terraform"
    workspace  = terraform.workspace
  }

  replication {
    auto {}
  }
}
resource "google_secret_manager_secret_version" "k10_sa_creds_version" {
  count  = (var.deployment.argocd) ? 1 : 0
  secret = google_secret_manager_secret.k10_sa_creds[0].id

  is_secret_data_base64 = true
  secret_data           = filebase64(var.k10_sa_creds)
}

resource "google_secret_manager_secret" "gcp_project" {
  count     = (var.deployment.argocd) ? 1 : 0
  secret_id = "${var.creator_label}-${terraform.workspace}-projectid"

  labels = {
    creator    = var.creator_label
    managed_by = "terraform"
    workspace  = terraform.workspace
  }

  replication {
    auto {}
  }
}
resource "google_secret_manager_secret_version" "gcp_project_version" {
  count  = (var.deployment.argocd) ? 1 : 0
  secret = google_secret_manager_secret.gcp_project[0].id

  secret_data = var.gcp_project
}

resource "google_secret_manager_secret" "cloudflare_api_token" {
  count     = (var.deployment.cert_manager) ? 1 : 0
  secret_id = "${var.creator_label}-${terraform.workspace}-cloudflare-api-token"

  labels = {
    creator    = var.creator_label
    managed_by = "terraform"
    workspace  = terraform.workspace
  }

  replication {
    auto {}
  }
}
resource "google_secret_manager_secret_version" "cloudflare_api_token_version" {
  count  = (var.deployment.cert_manager) ? 1 : 0
  secret = google_secret_manager_secret.cloudflare_api_token[0].id

  secret_data = trimspace(file(var.cloudflare_api_token))
}

resource "time_sleep" "wait_for_gke" {
  count           = (var.deployment.argocd) ? 1 : 0
  depends_on      = [module.gke]
  create_duration = "2m"
}

resource "kubernetes_secret" "external_secrets_operator" {
  count      = (var.deployment.argocd) ? 1 : 0
  depends_on = [time_sleep.wait_for_gke]

  metadata {
    name      = "external-secrets-operator-secret"
    namespace = "kube-system"
  }

  data = {
    "secret-access-credentials" = file(var.sa_creds)
  }
}

resource "helm_release" "argocd" {
  count            = (var.deployment.argocd) ? 1 : 0
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_version
  namespace        = "argocd"
  create_namespace = true

  set = concat([
    {
      name  = "server.service.type"
      value = var.deployment.cert_manager ? "ClusterIP" : "LoadBalancer"
    },
    {
      name  = "server.ingress.enabled"
      value = "false"
    },
    {
      name  = "configs.params.controller\\.sync\\.wave\\.delay\\.seconds"
      value = "15"
      type  = "string"
    }
    ], var.deployment.cert_manager ? [
    {
      name  = "configs.params.server\\.insecure"
      value = "true"
    }
  ] : [])

  depends_on = [time_sleep.wait_for_gke]
}

resource "time_sleep" "wait_for_argocd" {
  count           = (var.deployment.argocd) ? 1 : 0
  depends_on      = [helm_release.argocd]
  create_duration = "3m"
}

data "kubernetes_service" "argocd_server" {
  count      = (var.deployment.argocd && !var.deployment.cert_manager) ? 1 : 0
  depends_on = [time_sleep.wait_for_argocd]
  metadata {
    name      = "argocd-server"
    namespace = "argocd"
  }
}

data "kubernetes_secret" "argocd_admin_secret" {
  count      = (var.deployment.argocd) ? 1 : 0
  depends_on = [time_sleep.wait_for_argocd]
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = "argocd"
  }
}

resource "kubernetes_config_map_v1_data" "argocd_cm" {
  count      = (var.deployment.argocd) ? 1 : 0
  depends_on = [time_sleep.wait_for_argocd]
  metadata {
    name      = "argocd-cm"
    namespace = "argocd"
  }
  data = merge({
    "resource.customizations.health.argoproj.io_Application" = <<-EOT
      hs = {}
      hs.status = "Progressing"
      hs.message = ""
      if obj.status ~= nil then
        if obj.status.health ~= nil then
          hs.status = obj.status.health.status
          if obj.status.health.message ~= nil then
            hs.message = obj.status.health.message
          end
        end
      end
      return hs
      EOT
    }, var.deployment.cert_manager ? {
    "resource.customizations.health.gateway.networking.k8s.io_Gateway" = <<-EOT
      hs = {}
      if obj.status ~= nil and obj.status.conditions ~= nil then
        for i, condition in ipairs(obj.status.conditions) do
          if condition.type == "Accepted" and condition.status == "True" then
            hs.status = "Healthy"
            hs.message = condition.message or "Gateway accepted"
            return hs
          end
          if condition.type == "Accepted" and condition.status == "False" then
            hs.status = "Degraded"
            hs.message = condition.message or "Gateway not accepted"
            return hs
          end
        end
      end
      hs.status = "Progressing"
      hs.message = "Waiting for Gateway to be accepted"
      return hs
      EOT
    "resource.customizations.health.gateway.networking.k8s.io_HTTPRoute" = <<-EOT
      hs = {}
      if obj.status ~= nil and obj.status.parents ~= nil then
        for i, parent in ipairs(obj.status.parents) do
          if parent.conditions ~= nil then
            for j, condition in ipairs(parent.conditions) do
              if condition.type == "Accepted" and condition.status == "True" then
                hs.status = "Healthy"
                hs.message = condition.message or "HTTPRoute accepted"
                return hs
              end
              if condition.type == "Accepted" and condition.status == "False" then
                hs.status = "Degraded"
                hs.message = condition.message or "HTTPRoute not accepted"
                return hs
              end
            end
          end
        end
      end
      hs.status = "Progressing"
      hs.message = "Waiting for HTTPRoute to be accepted"
      return hs
      EOT
  } : {})
}
