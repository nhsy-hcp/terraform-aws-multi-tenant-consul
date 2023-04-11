#------ general -----

output "region" {
  description = "AWS region"
  value       = var.region
}

#----- admin cluster ------

output "eks_admin_cluster_name" {
  description = "admin cluster name"
  value       = module.eks_admin_cluster.cluster_name
}

output "eks_admin_cluster_endpoint" {
  description = "admin cluster EKS endpoint"
  value       = module.eks_admin_cluster.cluster_endpoint
}

output "eks_cluster_security_group_id_eks_admin_cluster" {
  description = "admin cluster control plane SG"
  value       = module.eks_admin_cluster.cluster_security_group_id
}

output "eks_node_security_group_id_admin_cluster" {
  description = "admin cluster nodes SG"
  value       = module.eks_admin_cluster.node_security_group_id
}

output "ebs_csi_irsa_role_eks_admin_cluster_iam_role_arn" {
  description = "ebs_csi_controller_role_eks_admin_cluster"
  value       = module.ebs_csi_irsa_role_eks_admin_cluster.iam_role_arn
}

output "eks_admin_cluster_kube_context" {
  value = "arn:aws:eks:${var.region}:${var.aws_account_id}:cluster/${var.eks_admin_cluster_name}"
}

#----- user cluster ---------

output "eks_user_cluster_name" {
  description = "user cluster name"
  value       = try(module.eks_user_cluster["enabled"].cluster_name, null)
}

output "eks_user_cluster_endpoint" {
  description = "user cluster EKS endpoint"
  value       = try(module.eks_user_cluster["enabled"].cluster_endpoint, null)
}

output "eks_cluster_security_group_id_user_cluster" {
  description = "user cluster control plane SG"
  value       = try(module.eks_user_cluster["enabled"].cluster_security_group_id, null)
}

output "eks_node_security_group_id_user_cluster" {
  description = "user cluster nodes SG"
  value       = try(module.eks_user_cluster["enabled"].node_security_group_id, null)
}

output "ebs_csi_irsa_role_eks_user_cluster_iam_role_arn" {
  description = "ebs_csi_controller_role_eks_user_cluster"
  value       = try(module.ebs_csi_irsa_role_eks_user_cluster["enabled"].iam_role_arn, null)
}

output "eks_user_cluster_kube_context" {
  value = "arn:aws:eks:${var.region}:${var.aws_account_id}:cluster/${var.eks_user_cluster_name}"
}