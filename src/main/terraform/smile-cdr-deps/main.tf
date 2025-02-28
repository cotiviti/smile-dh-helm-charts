######################################
### IAM/IRSA
######################################

module "smile_cdr_irsa_role" {
  count = local.cdr_iam_role_enabled ? 1 : 0
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.30.2"

  role_name = local.cdr_irsa_role_name

  role_policy_arns = local.scdr_role_policy_arns

  oidc_providers = {
    ex = {
      provider_arn               = local.eks_cluster_oidc_provider_arn
      namespace_service_accounts = local.cdr_namespace_service_accounts
    }
  }
}

# Include policies for:
# Docker Pull Secrets
# RDS Secrets if used
# S3 bucket if required
data "aws_iam_policy_document" "get-secrets" {
  count = local.cdr_iam_role_enabled ? 1 : 0
  version = "2012-10-17"

  dynamic "statement" {
    for_each = local.secrets_enabled ? [1] : []
    content {
      effect = "Allow"
      actions = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
      resources = local.all_secret_arns
    }
  }

  dynamic "statement" {
    for_each = length(local.all_secret_kms_key_arns) > 0 ? [1] : []
    content {
      effect = "Allow"
      actions = [
          "kms:Encrypt",
          "kms:Decrypt"
        ]
      resources = local.all_secret_kms_key_arns
    }
  }
}

resource "aws_iam_policy" "get-secrets" {
  count = local.cdr_iam_role_enabled ? 1 : 0
  name        = "${local.name}-get-secrets-${local.resourcenames_suffix}"
  description = "Smile CDR Policy to get credentials secrets"

  policy = data.aws_iam_policy_document.get-secrets[0].json

  tags = local.tags
}

# Policy used by DB user management Lambda function to get RDS meta data.
data "aws_iam_policy_document" "get-rds-meta" {
  count = local.create_rds_user_mgmt_lambda ? 1 : 0
  version = "2012-10-17"

  dynamic "statement" {
    for_each = local.create_rds_user_mgmt_lambda ? [1] : []
    content {
      effect = "Allow"
      actions = [
          "rds:DescribeDBClusters",
          "rds:DescribeDBInstances"
        ]
      resources = ["*"]
    }
  }
}
resource "aws_iam_policy" "get-rds-meta" {
  count = local.create_rds_user_mgmt_lambda ? 1 : 0
  name        = "${local.name}-get-rds-meta-${local.resourcenames_suffix}"
  description = "Smile CDR Policy to get RDS metadata for updating RDS secrets"
  policy = data.aws_iam_policy_document.get-rds-meta[0].json
  tags = local.tags
}

# Policy for reading from S3 buckets
data "aws_iam_policy_document" "s3-read" {
  count = local.s3_read_buckets_enabled ? 1 : 0
  version = "2012-10-17"

  statement {
    effect = "Allow"
    actions = [
        "s3:GetObject",
        "s3:ListBucket"
      ]
    resources = local.s3_read_bucket_arns
  }
  # dynamic "statement" {
  #   for_each = local.s3_read_buckets_enabled ? [1] : []
  #   content {
  #     effect = "Allow"
  #     actions = [
  #         "s3:GetObject",
  #         "s3:ListBucket"
  #       ]
  #     resources = local.s3_read_bucket_arns
  #   }
  # }
}
resource "aws_iam_policy" "s3-read" {
  count = local.s3_read_buckets_enabled ? 1 : 0
  name        = "${local.name}-s3-read-${local.resourcenames_suffix}"
  description = "Smile CDR Policy to read files from S3 buckets"
  policy = data.aws_iam_policy_document.s3-read[0].json
  tags = local.tags
}

##### Secrets KMS Key
resource "aws_kms_key" "secrets_key" {
  count = local.create_secrets_kms ? 1 : 0
  description             = "${local.name}-secrets-${local.resourcenames_suffix}"
  deletion_window_in_days = var.kms_deletion_window
}

resource "aws_kms_alias" "secrets_key_alias" {
  count = local.create_secrets_kms ? 1 : 0
  name          = "alias/${local.name}-secrets"
  target_key_id = aws_kms_key.secrets_key[0].key_id
}

##### Extra Secrets
resource "aws_secretsmanager_secret" "secrets" {
  for_each = local.secrets_to_create
  kms_key_id              = each.value.kms_key_id
  name                    = each.value.secret_name
  recovery_window_in_days = var.prod_mode ? var.secrets_deletion_window : 0
}

##############################
# Database
##############################
#
# TODO: Allow passing in pre-existing DB.
#       * Need to pass in Secrets Manager secret to the module
#       * Module needs to add this secret to the iam role
#       * Module needs to determine the instance details (From the secret) and
#       * consider any networking for it.
module "managed_database" {
  for_each = {
    for database in var.db_instances:
    database.name => database
  }
  source = "./modules/rdsinstance"

  name = "${local.name}-${each.value.name}"
  resourcenames_suffix = coalesce(each.value.name_suffix, local.resourcenames_suffix)
  clustername_override = each.value.name_override

  vpc_id = local.db_vpc_id
  publicly_accessible = each.value.publicly_accessible
  public_cidr_blocks = each.value.public_cidr_blocks

  # TODO: Parameterise this to allow extra security groups DB access (e.g. DBA access)
  # allowed_security_groups = [local.eks_node_security_group_id, local.lambda_security_group_id]

  # Refactor to make it a map. This way we can have the rules make more sense.
  security_group_rules = merge(
      {
        eks_node = {
          source_security_group_id = local.eks_cluster_security_group_id
          description = "Ingress from the EKS cluster"
        }
      },
      # Conditionally add SG for Lambda
      local.create_rds_user_mgmt_lambda ? {
        lambda = {
          source_security_group_id = local.lambda_security_group_id
          description = "Ingress from the user & DB creation Lambda"
        }
      } : {}

    )

  db_subnet_ids         = try(each.value.db_subnet_ids, local.default_db_subnet_ids)
  db_subnet_group_name  = try(coalesce(each.value.db_subnet_group_name, local.default_db_subnet_group_name),null)
  db_subnet_discovery_enabled = coalesce(each.value.db_subnet_discovery_enabled, var.db_instance_defaults.db_subnet_discovery_enabled)
  db_subnet_discovery_tags = try(coalesce(each.value.db_subnet_discovery_tags, var.db_instance_defaults.db_subnet_discovery_tags),null)

  # Use a per-db KMS key if specified, or use the module-global one if specified.
  # If var.rds_kms_arn was not specified, the managed_database module will create one.
  rds_kms_arn = try(each.value.rds_kms_arn, var.rds_kms_arn)

  engine = coalesce(each.value.engine, var.db_instance_defaults.engine)
  serverless_configuration = coalesce(each.value.serverless_configuration, var.db_instance_defaults.serverless_configuration)

  kms_deletion_window = try(each.value.kms_deletion_window, var.kms_deletion_window)
  secrets_kms_key_arn = try(each.value.secrets_kms_key_arn, local.secrets_kms_key_arn)


  master_username = coalesce(each.value.master_username, "cdrmaster")
  manage_master_user_password = coalesce(each.value.manage_master_user_password, true)
  dbname = try(each.value.dbname, "postgres")
  dbport = try(each.value.dbport, 5432)
  default_auth_type = each.value.default_auth_type
  iam_database_authentication_enabled = try(each.value.default_auth_type,"password") == "iam" || length(local.iam_db_users) > 0 || each.value.default_auth_type == "iam"
  tags = local.tags
}

module "existing_db_subnet_groups" {
  for_each = {
    for database in module.managed_database:
    database.db_subnet_group_name => database
    if database.existing_subnet_group
  }
  source = "./modules/data_db_subnet_group"
  # We ONLY call this for any EXISTING subnet groups, otherwise the module will fail (unless the db subnet group truly does not exist)
  db_subnet_group_name = each.value.db_subnet_group_name

}

module "postgres_db_user" {
  for_each = {
    for dbuser in var.db_users:
    dbuser.name => dbuser
  }
  source = "./modules/pgdb"

  name = "${local.name}-${try(each.value.db_instance_name, "")}-${try(each.value.name, "")}"
  cdr_modules = each.value.cdr_modules == null ? [each.value.name] : each.value.cdr_modules
  resourcenames_suffix = try(each.value.resourcenames_suffix,local.resourcenames_suffix)
  username = try(each.value.dbusername, null)
  dbname = try(each.value.dbname, null)
  force_secret_update = try(each.value.force_secret_update, null)

  secrets_kms_key_arn = local.secrets_kms_key_arn
  secrets_deletion_window = var.prod_mode ? var.secrets_deletion_window : 0

  db_host = module.managed_database[each.value.db_instance_name].db_endpoint
  master_secret_arn = module.managed_database[each.value.db_instance_name].master_secret_arn
  auth_type = coalesce(each.value.auth_type, module.managed_database[each.value.db_instance_name].default_auth_type)
}

# This policy includes the 'rds-db:connect' action that is needed for any
# DB users configured to use IAM Authentication
# Including all users in one policy, as opposed to a policy-per-user,
# as it keeps the token size down.
# See: https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/UsingWithRDS.IAMDBAuth.html

data "aws_iam_policy_document" "rds_iam_auth" {
  count = length(local.iam_db_user_arns) > 0 ? 1 : 0
  version = "2012-10-17"

  statement {
    effect = "Allow"
    actions = [
        "rds-db:connect"
      ]
    resources = local.iam_db_user_arns
  }
}

# Policy that enabled RDS IAM auth for all users in var.db_users
resource "aws_iam_policy" "rds_iam_auth" {
  count = length(local.iam_db_user_arns) > 0 ? 1 : 0
  name        = "${local.name}-rds-iam-auth-${local.resourcenames_suffix}"
  description = "Smile CDR Policy to authenticate with RDS using IAM Roles"

  policy = data.aws_iam_policy_document.rds_iam_auth[0].json

  tags = local.tags
}


# Resource Name Generation
resource "random_id" "resourcenames_suffix" {
  keepers = {
    # Generate a new id each time we switch to a new name
    name  = local.name
  }

  byte_length = 8
}

resource "aws_route53_record" "publicdns" {
  count = var.ingress_config.public.route53_create_record ? 1 : 0
  zone_id = data.aws_route53_zone.this[0].zone_id

  name          = local.public_fqdn
  type          = "A"
  alias {
      name                   = data.aws_lb.ingress-nginx[0].dns_name
      zone_id                = data.aws_lb.ingress-nginx[0].zone_id
      evaluate_target_health = false
  }
}
