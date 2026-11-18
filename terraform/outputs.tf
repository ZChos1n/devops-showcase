output "apps_namespace" {
  description = "Namespace where the showcase app is deployed."
  value       = kubernetes_namespace_v1.apps.metadata[0].name
}

output "grafana_url" {
  description = "How to reach Grafana locally (port-forward helper in Makefile)."
  value       = var.install_monitoring ? "make grafana  # http://localhost:3000" : "monitoring disabled"
}

output "prometheus_url" {
  description = "How to reach Prometheus locally."
  value       = var.install_monitoring ? "make prometheus  # http://localhost:9090" : "monitoring disabled"
}
