module "eks_user_cluster" {
  for_each = var.create_eks_user_cluster ? toset(["this"]) : toset([])

  source  = "terraform-aws-modules/eks/aws"
  version = "19.13.0"

  cluster_name    = var.eks_user_cluster_name
  cluster_version = var.eks_k8s_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access = true

  # restrict access to management ip address
  cluster_endpoint_public_access_cidrs = [local.management_ip]

  create_cluster_security_group = true
  create_node_security_group    = true

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
  }

  cluster_enabled_log_types              = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cloudwatch_log_group_retention_in_days = 1

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_irsa_role_eks_user_cluster["this"].iam_role_arn
    }
  }

  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
  }

  eks_managed_node_groups = {
    one = {
      name = var.eks_user_cluster_name

      instance_types = var.eks_user_cluster_ec2_nodes_types
      capacity_type  = var.ec2_nodes_capacity_type

      min_size     = var.eks_user_cluster_workers["min_size"]
      max_size     = var.eks_user_cluster_workers["max_size"]
      desired_size = var.eks_user_cluster_workers["desired_size"]

      key_name = var.eks_managed_node_groups_ssh_key_pair
    }
  }
}

# creates IAM role for ebs-csi-controller
module "ebs_csi_irsa_role_eks_user_cluster" {
  for_each = var.create_eks_user_cluster ? toset(["this"]) : toset([])

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.16.0"

  role_name             = "ebs-csi-controller-role-${var.eks_user_cluster_name}"
  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks_user_cluster["this"].oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

#resource "kubernetes_annotations" "ebs_csi_controller_sa_eks_user_cluster" {
#  for_each = var.create_eks_user_cluster ? toset(["enabled"]) : toset([])
#
#  provider = kubernetes.eks_user_cluster
#
#  api_version = "v1"
#  kind        = "ServiceAccount"
#  metadata {
#
#    name      = "ebs-csi-controller-sa"
#    namespace = "kube-system"
#  }
#
#  annotations = {
#    "eks.amazonaws.com/role-arn" = module.ebs_csi_irsa_role_eks_user_cluster["this"].iam_role_arn
#  }
#
#  #  depends_on = [
#  #    module.eks_user_cluster[each.key].cluster_endpoint,
#  #    module.eks_user_cluster[each.key].cluster_addons
#  #  ]
#}
