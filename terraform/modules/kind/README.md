# Cluster bootstrap module — design note

This directory documents **where the cluster itself comes from**. We deliberately
do not manage the kind cluster with Terraform, because provider initialization
creates a chicken-and-egg problem (the Kubernetes provider needs a kubeconfig
that does not exist yet).

| Layer | Local (this repo) | Production equivalent |
|-------|-------------------|-----------------------|
| Cluster lifecycle | `kind create cluster` via `make cluster` | EKS / ACK / GKE module, or Cluster API |
| Node pools | kind config (`3 workers`) | Managed node groups / autoscaling groups |
| Ingress | ingress-nginx (hostPort) | Cloud LB + ingress-nginx / gateway API |
| Storage | hostPath (ephemeral) | CSI driver (EBS-CSI / CBS-CSI) |
| Workload + addons | Terraform + Helm (root module) | same Terraform code |

To go production, write an EKS/ACK module that outputs `kubeconfig` and feed its
output into the root module's `kubeconfig_path`. The workload layer stays unchanged.
This separation — **cluster plumbing vs. in-cluster state** — is exactly what you
want to be able to explain in an interview.
