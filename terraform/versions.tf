terraform {
  required_version = ">= 1.5.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
  }

  # For a real team, switch this to an S3/GCS backend with state locking:
  # backend "s3" {
  #   bucket         = "company-terraform-state"
  #   key            = "showcase/k8s.tfstate"
  #   region         = "ap-guangzhou"
  #   dynamodb_table = "terraform-lock"
  #   encrypt        = true
  # }
}
