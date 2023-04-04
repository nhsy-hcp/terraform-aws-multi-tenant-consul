provider "kubernetes" {
  alias = "eks_admin_cluster"

  host                   = module.eks_admin_cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_admin_cluster.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks_admin_cluster.cluster_name]
    command     = "aws"
  }
}

# provider "kubernetes" {
#   alias = "eks_user_cluster"

#   host                   = module.eks_user_cluster.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.eks_user_cluster.cluster_certificate_authority_data)
#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     args        = ["eks", "get-token", "--cluster-name", module.eks_user_cluster.cluster_name]
#     command     = "aws"
#   }
# }

provider "helm" {
  alias = "eks_admin_cluster"
  kubernetes {
    host                   = module.eks_admin_cluster.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_admin_cluster.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks_admin_cluster.cluster_name]
      command     = "aws"
    }
  }
}

# provider "helm" {
#   alias = "eks_user_cluster"
#   kubernetes {
#     host                   = module.eks_user_cluster.cluster_endpoint
#     cluster_ca_certificate = base64decode(module.eks_user_cluster.cluster_certificate_authority_data)
#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       args        = ["eks", "get-token", "--cluster-name", module.eks_user_cluster.cluster_name]
#       command     = "aws"
#     }
#   }
# }

provider "aws" {
  region              = var.region
  allowed_account_ids = [var.aws_account_id]
  default_tags {
    tags = {
      owner : var.owner
    }
  }
}

data "aws_availability_zones" "available" {}