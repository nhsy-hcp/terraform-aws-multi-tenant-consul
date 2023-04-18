terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.63.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.9.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.19.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.4"
    }
  }

  required_version = "~> 1.3"
}

