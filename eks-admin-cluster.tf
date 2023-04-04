module "eks_admin_cluster" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.12.0"

  cluster_name    = var.eks_admin_cluster_name
  cluster_version = var.eks_k8s_version

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.public_subnets
  cluster_endpoint_public_access = true
  create_cluster_security_group  = true
  create_node_security_group     = true

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
  }

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
      most_recent = true
    }
  }

  eks_managed_node_groups = {
    one = {
      name = var.eks_admin_cluster_name

      instance_types = [var.ec2_nodes_type]

      min_size     = var.number_of_worker_nodes
      max_size     = var.number_of_worker_nodes
      desired_size = var.number_of_worker_nodes

      key_name = var.eks_managed_node_groups_ssh_key_pair
    }
  }
}
# resource "aws_security_group_rule" "eks_to_nodes_admin_cluster" {
#   description              = "From admin cluster EKS to admin cluster nodes"
#   type                     = "ingress"
#   source_security_group_id = module.eks_admin_cluster.cluster_security_group_id
#   from_port                = 1025
#   to_port                  = 10000
#   security_group_id        = module.eks_admin_cluster.node_security_group_id
#   protocol                 = "tcp"
# }
resource "aws_security_group_rule" "admin_cluster_nodes_to_admin_cluster_nodes" {
  description              = "From admin cluster nodes to admin nodes"
  type                     = "ingress"
  source_security_group_id = module.eks_admin_cluster.node_security_group_id
  from_port                = 0
  to_port                  = 0
  security_group_id        = module.eks_admin_cluster.node_security_group_id
  protocol                 = "-1"
}
# resource "aws_security_group_rule" "user_cluster_nodes_to_admin_cluster_nodes" {
#   description              = "From user cluster nodes to admin cluster nodes"
#   type                     = "ingress"
#   source_security_group_id = module.eks_user_cluster.node_security_group_id
#   from_port                = 0
#   to_port                  = 0
#   security_group_id        = module.eks_admin_cluster.node_security_group_id
#   protocol                 = "-1"
# }

# # creates IAM role for ebs-csi-controller and assigns AmazonEBSCSIDriverPolicy policy to it
# module "ebs_csi_controller_role_eks_admin_cluster" {
#   source    = "terraform-aws-modules/iam/aws//modules/iam-eks-role"
#   role_name = "ebs-csi-controller-role-${module.eks_admin_cluster.cluster_name}"
#   cluster_service_accounts = {
#     (module.eks_admin_cluster.cluster_name) = ["kube-system:ebs-csi-controller-sa"]
#   }
#   role_policy_arns = {
#     "arn" = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
#   }
#   depends_on = [
#     module.eks_admin_cluster # implicit dependancy doesn't work for some reason ...
#   ]
# }

# creates IAM role for ebs-csi-controller
module "ebs_csi_irsa_role_eks_admin_cluster" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.16.0"

  role_name             = "ebs-csi-controller-role-${module.eks_admin_cluster.cluster_name}"
  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks_admin_cluster.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  depends_on = [
    module.eks_admin_cluster.cluster_endpoint
  ]
}

resource "kubernetes_annotations" "ebs-csi-controller-sa" {
  provider = kubernetes.eks_admin_cluster

  api_version = "v1"
  kind        = "ServiceAccount"
  metadata {

    name      = "ebs-csi-controller-sa"
    namespace = "kube-system"
  }

  annotations = {
    "eks.amazonaws.com/role-arn" = module.ebs_csi_irsa_role_eks_admin_cluster.iam_role_arn
  }

  depends_on = [
    module.eks_admin_cluster.cluster_endpoint,
    module.eks_admin_cluster.cluster_addons
  ]
}
