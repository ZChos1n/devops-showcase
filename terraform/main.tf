provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

locals {
  common_labels = {
    "app.kubernetes.io/part-of" = "devops-showcase"
    "app.kubernetes.io/managed-by" = "terraform"
    environment                  = var.environment
  }
}

# ---- Namespaces -----------------------------------------------------------
resource "kubernetes_namespace_v1" "apps" {
  metadata {
    name   = "showcase-${var.environment}"
    labels = local.common_labels
  }
}

resource "kubernetes_namespace_v1" "monitoring" {
  count = var.install_monitoring ? 1 : 0
  metadata {
    name   = "monitoring"
    labels = local.common_labels
  }
}

# ---- Ingress controller (kind uses the bare-metal flavor with hostPort) ---
resource "helm_release" "ingress_nginx" {
  count      = var.install_ingress ? 1 : 0
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.11.1"
  namespace  = "ingress-nginx"
  create_namespace = true

  set {
    name  = "controller.service.type"
    value = "NodePort"
  }
  set {
    name  = "controller.hostNetwork.enabled"
    value = "true"
  }
  set {
    name  = "controller.hostPort.enabled"
    value = "true"
  }
}

# ---- Monitoring stack (delegated to a reusable module) --------------------
module "monitoring" {
  source   = "./modules/monitoring"
  count    = var.install_monitoring ? 1 : 0

  namespace           = kubernetes_namespace_v1.monitoring[0].metadata[0].name
  grafana_password    = var.grafana_admin_password
  environment         = var.environment

  depends_on = [helm_release.ingress_nginx]
}
