output "_1_cloud_kubeconfig_cmd" {
  description = "The gcloud command to run to load kubeconfig credentials"
  value       = "gcloud container clusters get-credentials ${module.gke.name} --region ${var.gcp_zones[0]}"
}
output "_2_argocd_apply_app_of_apps_cmd" {
  description = "The command to run to deploy the app of apps yaml"
  value       = var.argocd_deployment ? "kubectl apply -f ../argocd/app-of-apps.yaml" : "ArgoCD not deployed"
}
output "_3_argocd_endpoint" {
  description = "The URL to access the ArgoCD UI"
  value       = var.argocd_deployment ? "https://${data.kubernetes_service.argocd_server[0].status.0.load_balancer.0.ingress[0].ip}" : "ArgoCD not deployed"
}
output "_4_argocd_admin_secret_copy_cmd" {
  description = "A command to copy the ArgoCD initial admin secret to the clipboard"
  value       = var.argocd_deployment ? "terraform output -raw argocd_admin_secret | pbcopy" : "ArgoCD not deployed"
}
output "_5_kasten_dashboard_cmd" {
  description = "The command to open the Kasten K10 dashboard"
  value       = var.argocd_deployment ? "open http://`kubectl -n kasten-io get svc gateway-ext -ojsonpath='{.status.loadBalancer.ingress[0].ip}'`/k10/" : "ArgoCD not deployed"
}
output "_6_kasten_token_cmd" {
  description = "The command to run to create a token to login to the Kasten Dashboard"
  value       = var.argocd_deployment ? "kubectl --namespace kasten-io create token dashboard-sa --duration=24h" : "ArgoCD not deployed"
}
output "argocd_admin_secret" {
  description = "The ArgoCD initial admin secret"
  sensitive   = true
  value       = var.argocd_deployment ? data.kubernetes_secret.argocd_admin_secret[0].data.password : "ArgoCD not deployed"
}
output "kubernetes_endpoint" {
  sensitive = true
  value     = module.gke.endpoint
}
