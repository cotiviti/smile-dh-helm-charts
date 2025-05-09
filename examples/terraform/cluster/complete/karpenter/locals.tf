################################################################################
# General Computed Locals
################################################################################
#
# Used in various places in this project

locals {

  debug_output = false

  # Uses `local.subnet_ids` if they are set,
  # otherwise uses the auto-discovered subnets.
  resolved_private_subnet_ids = local.create_vpc ? [] : try(length(local.existing_private_subnet_ids) > 0, false) ? local.existing_private_subnet_ids : try(data.aws_subnets.private_tagged[0].ids,[])

  resolved_all_subnet_ids = distinct(concat(local.resolved_private_subnet_ids))

  private_subnet_ids = try(module.vpc[0].private_subnets,local.resolved_private_subnet_ids)

  cluster_subnet_ids = local.private_subnet_ids

  create_vpc = (local.existing_vpc_id == null || local.existing_vpc_id == "") ? true : false

  vpc_id = try(module.vpc[0].vpc_id, local.existing_vpc_id)

  # If creating a VPC, then all available AZ's will be used
  # If using existing VPC, only AZ's for auto-discovered or manually configured
  #  subnets will be used
  azs = local.create_vpc ? slice(data.aws_availability_zones.available.names, 0, 3) : [
    for subnet in data.aws_subnet.all_existing :
    subnet.availability_zone
  ]

  tags = {
    EnvironmentName = local.name
    CreatedBy       = "CloudFactory-tf"
    GitlabRepo      = "gitlab.com/smilecdr-public/smile-dh-helm-charts"
  }
}
