variable "namespace" {
  type = string
}
variable "grafana_password" {
  type      = string
  sensitive = true
}
variable "environment" {
  type = string
}

terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
  }
}

# kube-prometheus-stack bundles Prometheus, Grafana, Alertmanager, node-exporter
# and a set of default dashboards/alerts. Pinning the chart version is what
# makes upgrades reviewable and reproducible.
resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "61.3.2"
  namespace        = var.namespace
  create_namespace = false
  timeout          = 600

  values = [
    yamlencode({
      grafana = {
        adminPassword = var.grafana_password
        service = { type = "ClusterIP" }
        sidecar = { dashboards = { enabled = true }, datasources = { enabled = true } }
      }
      prometheus = {
        prometheusSpec = {
          retention = "7d"
          additionalScrapeConfigs = []
        }
      }
      alertmanager = {
        config = {
          receivers = [{ name = "null" }]
          route    = { receiver = "null" }
        }
      }
      commonLabels = { environment = var.environment }
    })
  ]
}
