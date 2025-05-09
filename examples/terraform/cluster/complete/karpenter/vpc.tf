################################################################################
# VPC creation
################################################################################
#
# This module creates a VPC with 3 subnet tiers, tagged per the documentation at
# <doclink>
#
# If you are creating your VPC through other means, ensure that you are setting
# appropriate tags for Subnet auto-discovery


# VPC related locals

locals {
  vpc_cidr = "10.0.0.0/16"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  count = local.create_vpc ? 1 : 0

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  database_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 96)]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    # Subnets tag for load balancer auto-discovery
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    # Subnets tag for load balancer auto-discovery
    "kubernetes.io/role/internal-elb" = 1
    # Tags subnets for Karpenter auto-discovery
    "karpenter.sh/discovery" = local.name
    # Subnets tag for determining private subnets
    "Tier" = "Private"
  }

  database_subnet_tags = {
    # Subnets tag for determining database subnets
    "Tier" = "Database"
  }

  tags = local.tags
}
