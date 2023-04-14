module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"

  name = "eks-vpc"

  cidr = var.vpc_cidr

  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnets = [
    cidrsubnet(var.vpc_cidr, 8, 0),
    cidrsubnet(var.vpc_cidr, 8, 1),
    cidrsubnet(var.vpc_cidr, 8, 2)
  ]

  public_subnets = [
    cidrsubnet(var.vpc_cidr, 8, 4),
    cidrsubnet(var.vpc_cidr, 8, 5),
    cidrsubnet(var.vpc_cidr, 8, 6)
  ]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.eks_admin_cluster_name}" = "shared"
    "kubernetes.io/cluster/${var.eks_user_cluster_name}"  = "shared"
    "kubernetes.io/role/elb"                              = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.eks_admin_cluster_name}" = "shared"
    "kubernetes.io/cluster/${var.eks_user_cluster_name}"  = "shared"
    "kubernetes.io/role/internal-elb"                     = 1
  }
}
