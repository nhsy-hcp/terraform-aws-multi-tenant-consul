# Additional firewall rules for consul communications
resource "aws_security_group_rule" "user_cluster_nodes_to_admin_cluster_nodes" {
  for_each = var.create_eks_user_cluster ? toset(["this"]) : toset([])

  description              = "User cluster nodes to Admin cluster nodes"
  type                     = "ingress"
  source_security_group_id = module.eks_user_cluster["this"].node_security_group_id
  from_port                = 0
  to_port                  = 0
  security_group_id        = module.eks_admin_cluster.node_security_group_id
  protocol                 = "-1"
}

resource "aws_security_group_rule" "admin_cluster_nodes_to_user_cluster_nodes" {
  for_each = var.create_eks_user_cluster ? toset(["this"]) : toset([])

  description              = "Admin cluster nodes to User cluster nodes"
  type                     = "ingress"
  source_security_group_id = module.eks_admin_cluster.node_security_group_id
  from_port                = 0
  to_port                  = 0
  security_group_id        = module.eks_user_cluster["this"].node_security_group_id
  protocol                 = "-1"
}

resource "aws_security_group_rule" "admin_cluster_nodes_to_user_cluster_api" {
  for_each = var.create_eks_user_cluster ? toset(["enabled"]) : toset([])

  description              = "Admin cluster nodes to User cluster API"
  type                     = "ingress"
  source_security_group_id = module.eks_admin_cluster.node_security_group_id
  from_port                = 443
  to_port                  = 443
  security_group_id        = module.eks_user_cluster["this"].cluster_security_group_id
  protocol                 = "tcp"
}

# Very important firewall rule for admission controller webhook
resource "aws_security_group_rule" "user_cluster_api_to_nodes" {
  for_each = var.create_eks_user_cluster ? toset(["enabled"]) : toset([])

  description              = "User cluster API to nodes"
  type                     = "ingress"
  source_security_group_id = module.eks_user_cluster["this"].cluster_security_group_id
  from_port                = 1025
  to_port                  = 65535
  security_group_id        = module.eks_user_cluster["this"].node_security_group_id
  protocol                 = "-1"
}
