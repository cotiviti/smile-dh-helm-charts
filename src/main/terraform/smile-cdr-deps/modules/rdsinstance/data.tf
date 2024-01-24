# IMPORTANT
# TODO: Each data source must have a proxy and a "mock_data" variable defined so that offline unit tests can be run

data "aws_subnets" "private_subnets" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }

  tags = {
    Tier = "Private"
  }
}

data "aws_subnets" "public_subnets" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }

  tags = {
    Tier = "Public"
  }
}

data "aws_subnets" "db_subnets" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }

  tags = {
    Tier = "Database"
  }
}

data "aws_subnets" "tagged_db_subnets" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }

  tags = var.db_subnet_discovery_tags == null ? {NA="na"} : var.db_subnet_discovery_tags
}

# Need to have another crack at this using count or for_each
# data "aws_db_subnet_group" "this" {
#     # count = 0
#     # for_each = {
#     #     key = "value"
#     # }
#     name = "boop"
# }
