output "kubeconfig" {
  value     = azurerm_kubernetes_cluster.aks_cluster.kube_config_raw
  sensitive = true
}
output "_1_cloud_kubeconfig_cmd" {
  description = "The az command to run to load kubeconfig credentials"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.aks_resource_group.name} --name ${azurerm_kubernetes_cluster.aks_cluster.name}"
}
output "_2_argocd_apply_app_of_apps_cmd" {
  description = "The command to run to deploy the app of apps yaml"
  value       = var.deployment.argocd ? "kubectl apply -f ../argocd/app-of-apps.yaml" : "ArgoCD not deployed"
}
output "_3_argocd_endpoint" {
  description = "The URL to access the ArgoCD UI"
  value       = var.deployment.argocd ? (var.deployment.cert_manager ? "https://argocd.${terraform.workspace}.${var.domain_name} # once Gateway is up" : "https://${data.kubernetes_service.argocd_server[0].status.0.load_balancer.0.ingress[0].ip}") : "ArgoCD not deployed"
}
output "_4_argocd_admin_secret_copy_cmd" {
  description = "A command to copy the ArgoCD initial admin secret to the clipboard"
  value       = var.deployment.argocd ? "terraform output -raw argocd_admin_secret | pbcopy" : "ArgoCD not deployed"
}
output "_5_kasten_dashboard_cmd" {
  description = "The command to open the Kasten K10 dashboard"
  value       = var.deployment.argocd ? (var.deployment.cert_manager ? "open https://kasten.${terraform.workspace}.${var.domain_name}/k10/" : "open http://`kubectl -n kasten-io get svc gateway-ext -ojsonpath='{.status.loadBalancer.ingress[0].ip}'`/k10/") : "ArgoCD not deployed"
}
output "_6_kasten_token_cmd" {
  description = "The command to run to create a token to login to the Kasten Dashboard"
  value       = var.deployment.argocd ? "kubectl --namespace kasten-io create token dashboard-sa --duration=24h" : "ArgoCD not deployed"
}
output "_7_pacman_url" {
  description = "The URL to access the Pacman app"
  value       = (var.deployment.argocd && var.deployment.cert_manager) ? "https://pacman.${terraform.workspace}.${var.domain_name}" : "cert-manager not deployed"
}
output "argocd_admin_secret" {
  description = "The ArgoCD initial admin secret"
  sensitive   = true
  value       = var.deployment.argocd ? data.kubernetes_secret.argocd_admin_secret[0].data.password : "ArgoCD not deployed"
}
output "argocd_port_forward_cmd" {
  description = "Port-forward command to access ArgoCD UI locally before Gateway is available"
  value       = (var.deployment.argocd && var.deployment.cert_manager) ? "open http://localhost:8080; kubectl port-forward svc/argocd-server -n argocd 8080:80" : "Not needed (ArgoCD has LoadBalancer)"
}
