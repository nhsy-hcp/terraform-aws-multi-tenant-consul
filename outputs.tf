#------ general -----

output "region" {
  description = "AWS region"
  value       = var.region
}

#----- cluster-a ------

output "admin_cluster_name" {
  description = "admin cluster name"
  value       = module.eks_admin_cluster.cluster_name
}

output "admin_cluster_endpoint" {
  description = "admin cluster EKS endpoint"
  value       = module.eks_admin_cluster.cluster_endpoint
}

output "cluster_security_group_id_eks_admin_cluster" {
  description = "admin cluster control plane SG"
  value       = module.eks_admin_cluster.cluster_security_group_id
}

output "node_security_group_id_admin_cluster" {
  description = "admin cluster nodes SG"
  value       = module.eks_admin_cluster.cluster_security_group_id
}

output "iam_ebs_csi_controller_role_admin_cluster" {
  description = "ebs-csi-controller_role_admin_cluster"
  value       = module.ebs_csi_controller_role_eks_admin_cluster.iam_role_arn
}

#----- cluster-b ---------

output "user_cluster_name" {
  description = "user cluster name"
  value       = module.eks_user_cluster.cluster_name
}

output "user_cluster_endpoint" {
  description = "user cluster EKS endpoint"
  value       = module.eks_user_cluster.cluster_endpoint
}

output "cluster_security_group_id_user_cluster" {
  description = "user cluster control plane SG"
  value       = module.eks_user_cluster.cluster_security_group_id
}

output "node_security_group_id_user_cluster" {
  description = "user cluster nodes SG"
  value       = module.eks_user_cluster.cluster_security_group_id
}

output "iam_ebs_csi_controller_role_user_cluster" {
  description = "ebs_csi_controller_role_user_cluster"
  value       = module.ebs_csi_controller_role_eks_user_cluster.iam_role_arn
}