resource "google_secret_manager_secret" "k10_sa_creds" {
  count     = (var.argocd_deployment) ? 1 : 0
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
  count  = (var.argocd_deployment) ? 1 : 0
  secret = google_secret_manager_secret.k10_sa_creds[0].id

  is_secret_data_base64 = true
  secret_data           = filebase64(var.k10_sa_creds)
}

resource "google_secret_manager_secret" "gcp_project" {
  count     = (var.argocd_deployment) ? 1 : 0
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
  count  = (var.argocd_deployment) ? 1 : 0
  secret = google_secret_manager_secret.gcp_project[0].id

  secret_data = var.gcp_project
}

resource "time_sleep" "wait_for_gke" {
  count           = (var.argocd_deployment) ? 1 : 0
  depends_on      = [module.gke]
  create_duration = "2m"
}

resource "kubernetes_secret" "external_secrets_operator" {
  count      = (var.argocd_deployment) ? 1 : 0
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
  count            = (var.argocd_deployment) ? 1 : 0
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_version
  namespace        = "argocd"
  create_namespace = true

  set = [
    {
      name  = "server.service.type"
      value = "LoadBalancer"
    },
    {
      name  = "server.ingress.enabled"
      value = "false"
    }
  ]

  depends_on = [time_sleep.wait_for_gke]
}

resource "time_sleep" "wait_for_argocd" {
  count           = (var.argocd_deployment) ? 1 : 0
  depends_on      = [helm_release.argocd]
  create_duration = "3m"
}

data "kubernetes_service" "argocd_server" {
  count      = (var.argocd_deployment) ? 1 : 0
  depends_on = [time_sleep.wait_for_argocd]
  metadata {
    name      = "argocd-server"
    namespace = "argocd"
  }
}

data "kubernetes_secret" "argocd_admin_secret" {
  count      = (var.argocd_deployment) ? 1 : 0
  depends_on = [time_sleep.wait_for_argocd]
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = "argocd"
  }
}

resource "kubernetes_config_map_v1_data" "argocd_cm" {
  count      = (var.argocd_deployment) ? 1 : 0
  depends_on = [time_sleep.wait_for_argocd]
  metadata {
    name      = "argocd-cm"
    namespace = "argocd"
  }
  data = {
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
  }
}
