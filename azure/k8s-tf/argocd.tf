resource "time_sleep" "wait_for_aks" {
  count           = (var.deployment.argocd) ? 1 : 0
  depends_on      = [azurerm_kubernetes_cluster.aks_cluster]
  create_duration = "2m"
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

  depends_on = [time_sleep.wait_for_aks]
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
