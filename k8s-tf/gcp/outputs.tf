output "argocd_admin_secret" {
  description = "The ArgoCD initial admin secret"
  sensitive   = true
  value       = data.kubernetes_secret.argocd_admin_secret.data.password
}
output "argocd_admin_secret_copy_cmd" {
  description = "A command to copy the ArgoCD initial admin secret to the clipboard"
  value       = "terraform output -raw argocd_admin_secret | pbcopy"
}
output "argocd_endpoint" {
  description = "The URL to access the ArgoCD UI"
  value       = "https://${data.kubernetes_service.argocd_server.status.0.load_balancer.0.ingress[0].ip}"
}
output "client_token" {
  sensitive = true
  value     = base64encode(data.google_client_config.default.access_token)
}
output "cloud_kubeconfig_cmd" {
  description = "The gcloud command to run to load kubeconfig credentials"
  value       = "gcloud container clusters get-credentials ${module.gke.name} --region ${var.gcp_zones[0]}"
}
output "kubernetes_endpoint" {
  sensitive = true
  value     = module.gke.endpoint
}
