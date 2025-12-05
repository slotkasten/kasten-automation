resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_version
  namespace        = var.argocd_namespace
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

  depends_on = []
}

data "kubernetes_service" "argocd_server" {
  depends_on = [helm_release.argocd]
  metadata {
    name      = "argocd-server"
    namespace = var.argocd_namespace
  }
}

data "kubernetes_secret" "argocd_admin_secret" {
  depends_on = [helm_release.argocd]
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = var.argocd_namespace
  }
}
