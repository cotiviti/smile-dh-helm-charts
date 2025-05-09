################################################################################
# General Data Sources
################################################################################

data "aws_availability_zones" "available" {}

data "aws_vpc" "vpc" {
  id = local.vpc_id
}

# Get list of private subnets that have tags matching `local.private_subnet_discovery_tags`
# Defaults to the `Tier="Private"` tag if not provided.

data "aws_subnets" "private_tagged" {
  count = local.create_vpc ? 0 : 1
  filter {
    name   = "vpc-id"
    values = [local.existing_vpc_id == null ? "" : local.existing_vpc_id]
  }
  tags = coalesce(local.private_subnet_discovery_tags, { Tier = "Private" })
}

# Get subnet details for all configured subnets
# Used to build the list of AZs

data "aws_subnet" "all_existing" {
  for_each = toset(local.resolved_all_subnet_ids)
  filter {
    name   = "subnet-id"
    values = [each.value]
  }
}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.ecr
}
