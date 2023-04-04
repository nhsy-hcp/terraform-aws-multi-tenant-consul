variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "eks_k8s_version" {
  type    = string
  default = "1.24"
}

variable "eks_admin_cluster_name" {
  type    = string
  default = "eks-admin"
}
variable "eks_user_cluster_name" {
  type    = string
  default = "eks-user"
}
# Managed nodes group parameters
variable "number_of_worker_nodes" {
  type    = number
  default = 3
}
variable "ec2_nodes_type" {
  type    = string
  default = "t3.small"
}
variable "eks_managed_node_groups_ssh_key_pair" {
  type    = string
  default = ""
}

# IAM for ebs-csi-controller
variable "ebs_csi_controller_role_name" {
  type    = string
  default = "ebs-csi-controller-role"
}

variable "aws_account_id" {
  type = string
}

variable "owner" {
  type = string
}