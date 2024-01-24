locals {
  name            = var.name

  resourcenames_suffix = var.resourcenames_suffix != null ? var.resourcenames_suffix : "${random_id.resourcenames_suffix.hex}"

  secrets_rds_master_name = "${local.name}-${var.secrets_rds_master_name}"

  clustername = var.clustername_override != null ? var.clustername_override : "${local.name}-${local.resourcenames_suffix}"

  ###################
  # RDS general
  ###################

  rds_instance_name = var.name
  rds_engine_version = var.engine_version
  rds_master_username = var.master_username
  rds_dbname = var.dbname
  rds_dbport = var.dbport

  ####################
  # RDS type selection
  ########################################
  #
  # Currently only supports:
  # * "aurora-postgresql-serverless-v2"
  #   Provisions an RDS Aurora PostgreSQL DB with serverless V2

  rds_aurora = can(regex("^(aurora-)",var.engine))
  # Rather misleadingly, Serverless V2 uses 'provisioned' rather than 'serverless'
  #  (hint: it's not really 'serverless'. It's just very good autoscaling.
  #   It still creates a provisioned primary cluster instance)
  # TODO: Rework this logic when adding RDS types
  engine_mode = can(regex("(-serverless-v2)$",var.engine)) ? "provisioned" : null
  instance_class = can(regex("(-serverless-v2)$",var.engine)) ? "db.serverless" : null
  # Set engine to "aurora-postgresql"
  rds_engine = try(regex("^aurora-postgresql",var.engine),"aurora-postgresql")

  ########################################
  # RDS Networking
  ########################################



  vpc_id                  = var.vpc_id

  # Creation of db_subnet_group depends on whether or not we are passing in subnet ids.
  # If we are passing them in, then create the subnet group. The name is auto-generated unless database_subnet_group_name is passed in.
  # If we are NOT passing them in, then use the existing subnet group, which MUST be provided.
  create_db_subnet_group  = length(local.db_subnet_ids) > 0 ? true:false
  db_subnet_group_name = var.db_subnet_group_name == null ? lower(var.name) : var.db_subnet_group_name

  # allowed_security_groups = var.allowed_security_groups

  # By default, this module will attempt to autodiscover database subnets in the following order:
  #  * Subnets with the tag: "Tier=Database"
  #  * If public access is not enabled, then Subnets with the tag: "Tier=Private"
  #  * If public access is enabled, then Subnets with the tag: "Tier=Public"
  #
  # The auto-discovery tag can be overriden with `db_instance_defaults.db_subnet_discovery_tags`. The resulting subnets
  # will take precedence over any other auto-discovery.
  #
  # Finally, if none can be auto-discovered, subnets must be provided.
  #
  # If existing subnets are provided, they will be used and all auto-discovery will be disabled.
  # If an existing db_subnet_group_name is provided, but db subnets are auto discovered, autodiscovery may need to be disabled to avoid a naming clash error.

  autodiscovered_db_tier_subnets = data.aws_subnets.db_subnets.ids
  autodiscovered_private_tier_subnets = local.publicly_accessible ? [] : data.aws_subnets.private_subnets.ids
  autodiscovered_public_tier_subnets = local.publicly_accessible ? data.aws_subnets.public_subnets.ids : []
  autodiscovered_tagged_subnets = var.db_subnet_discovery_tags == null ? [] : data.aws_subnets.tagged_db_subnets.ids

  # The final list of subnets should be one of the above, using the following priority:
  # * Provided subnets
  # * Custom tagged subnets
  # * DB Tier subnets
  # * Private Tier subnets
  # * Public Tier subnets

  db_subnet_ids = try(coalescelist(
                    var.db_subnet_ids,
                    var.db_subnet_discovery_enabled ? try(coalescelist(
                            local.autodiscovered_tagged_subnets,
                            local.autodiscovered_db_tier_subnets,
                            local.autodiscovered_private_tier_subnets,
                            local.autodiscovered_public_tier_subnets
                          ),[]) : []
                  ),[])

  publicly_accessible     = (var.publicly_accessible) && (length(var.public_cidr_blocks) > 0)
  public_cidrs            = var.public_cidr_blocks


  # Add security group rules for external access
  security_group_rules = merge(
    var.security_group_rules,  # Existing rules from the calling module
    local.publicly_accessible ? {
      external = {
        description = "External DB access",
        cidr_blocks = var.public_cidr_blocks
        }
      } : {}
  )

  ########################################
  # RDS KMS
  ########################################
  # Create RDS KMS key if none was provided
  # Otherwise use the provided key
  create_rds_kms = var.rds_kms_arn == null ? true:false
  rds_kms_arn = local.create_rds_kms ? aws_kms_key.rds_key[0].arn : var.rds_kms_arn

  ########################################
  # RDS post-creation values
  ########################################
  # TODO: Add logic here when adding new database types (i.e. using a different DB module)
  #       There will only be one DB module used, and the below code should coalesce outputs
  #       from whichever one was created
  rds_initial_master_password = try(module.aurora_database[0].cluster_master_password, null)
  rds_endpoint = try(module.aurora_database[0].cluster_endpoint, null)
}
