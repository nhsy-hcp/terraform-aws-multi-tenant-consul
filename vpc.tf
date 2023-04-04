module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"

  name = "eks-vpc"

  cidr = "10.64.0.0/16"
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnets = ["10.64.0.0/24", "10.64.1.0/24", "10.64.2.0/24"]
  public_subnets  = ["10.64.4.0/24", "10.64.5.0/24", "10.64.6.0/24"]

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
