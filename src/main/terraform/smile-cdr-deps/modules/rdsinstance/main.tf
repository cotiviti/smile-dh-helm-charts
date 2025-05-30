######################################
### RDS Instances
######################################

# RDS KMS Key

resource "aws_kms_key" "rds_key" {
  count = local.create_rds_kms ? 1 : 0
  description             = "${local.name}-rds-${local.resourcenames_suffix}"
  deletion_window_in_days = var.kms_deletion_window
}

resource "aws_kms_alias" "rds_key_alias" {
  count = local.create_rds_kms ? 1 : 0
  name          = "alias/${local.name}-rds-${local.resourcenames_suffix}"
  target_key_id = aws_kms_key.rds_key[0].key_id
}

# RDS Database - Aurora
module "aurora_database" {
  count = local.rds_aurora ? 1 : 0
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "9.3.1"

  iam_role_permissions_boundary = var.permission_boundary_arn

  name           = lower(local.clustername)
  # cluster_use_name_prefix = true
  engine         = local.rds_aurora_engine
  engine_version = local.rds_aurora_engine_version


  engine_mode    = local.engine_mode
  instance_class = local.instance_class

  # TODO: Parameterise this
  instances = {
    one = {}
    # two = {}
  }

  serverlessv2_scaling_configuration = local.rds_aurora_serverlessv2_scaling_configuration

  master_username = local.rds_master_username
  database_name = can(regex("^postgres$",local.rds_dbname))  ? null : local.rds_dbname
  manage_master_user_password = var.manage_master_user_password
  master_user_secret_kms_key_id = var.secrets_kms_key_arn

  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  # We are opinionated: Storage encryption should be enforced
  storage_encrypted = true
  kms_key_id = local.rds_kms_arn



  # Only for dev. Make this conditional
  # TODO: Parameterise this
  apply_immediately   = true
  skip_final_snapshot = true

  monitoring_interval = 60
  vpc_id                 = local.vpc_id
  create_db_subnet_group = local.create_db_subnet_group
  db_subnet_group_name   = local.db_subnet_group_name
  subnets = local.db_subnet_ids

  create_security_group  = true
  publicly_accessible = local.publicly_accessible

  security_group_rules = local.security_group_rules

  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = var.tags
}

# ##### RDS Master Secret
resource "aws_secretsmanager_secret" "rds_master" {
  count                   = var.manage_master_user_password ? 0 : 1
  kms_key_id              = var.secrets_kms_key_arn
  name                    = var.secrets_rds_master_name_override != null ? var.secrets_rds_master_name_override : "${local.secrets_rds_master_name}-${local.resourcenames_suffix}"
  recovery_window_in_days = var.secrets_deletion_window
}

resource "aws_secretsmanager_secret_version" "rds_master" {
  count                   = var.manage_master_user_password ? 0 : 1
  secret_id               = aws_secretsmanager_secret.rds_master[0].arn
  # Secrets must be stored in appropriate format. See:
  # https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_secret_json_structure.html#reference_secret_json_structure_rds-postgres
  secret_string           = jsonencode(
                          {
                            username  = local.rds_master_username
                            password  = local.rds_initial_master_password
                            engine    = "postgres"
                            host      = local.rds_endpoint
                            dbname    = local.rds_dbname
                          }
  )
  lifecycle {
    ignore_changes = [secret_string]
  }
}

# Resource Name Generation
resource "random_id" "resourcenames_suffix" {
  keepers = {
    # Generate a new id each time we switch to a new name
    name  = var.name
  }

  byte_length = 8
}
