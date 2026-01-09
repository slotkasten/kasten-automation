resource "time_sleep" "wait_for_aks" {
  count           = (var.argocd_deployment) ? 1 : 0
  depends_on      = [azurerm_kubernetes_cluster.aks_cluster]
  create_duration = "2m"
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

  depends_on = [time_sleep.wait_for_aks]
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
