variable "kubeconfig_path" {
  description = "Path to the kubeconfig used to talk to the target cluster."
  type        = string
  default     = "~/.kube/config"
}

variable "environment" {
  description = "Logical environment name, used for naming and labels."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of dev, staging, prod."
  }
}

variable "install_monitoring" {
  description = "Whether to install the kube-prometheus-stack via Helm."
  type        = bool
  default     = true
}

variable "install_ingress" {
  description = "Whether to install ingress-nginx (the bare-metal/kind flavor)."
  type        = bool
  default     = true
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana. Override via TF_VAR_ in CI; never commit a real one."
  type        = string
  sensitive   = true
  default     = "admin"
}
