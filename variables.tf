variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.64.0.0/16"
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
variable "eks_admin_cluster_workers" {
  type = object({
    min_size     = number
    max_size     = number
    desired_size = number
  })

  default = {
    min_size     = 3
    max_size     = 3
    desired_size = 3
  }
}

variable "eks_user_cluster_workers" {
  type = object({
    min_size     = number
    max_size     = number
    desired_size = number
  })

  default = {
    min_size     = 3
    max_size     = 6
    desired_size = 3
  }
}

variable "eks_admin_cluster_ec2_nodes_types" {
  type    = list(string)
  default = ["t3.small", "t2.small"]
}


variable "eks_user_cluster_ec2_nodes_types" {
  type    = list(string)
  default = ["t3.medium", "t2.medium"]
}

variable "ec2_nodes_capacity_type" {
  type    = string
  default = "ON_DEMAND"
}

variable "eks_managed_node_groups_ssh_key_pair" {
  type    = string
  default = null
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

variable "create_eks_user_cluster" {
  type    = bool
  default = true
}