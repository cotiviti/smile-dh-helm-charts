output "master_secret_arn" {
#  value = aws_secretsmanager_secret.rds_master.arn
 value = var.manage_master_user_password ? (
    module.aurora_database[0].cluster_master_user_secret[0].secret_arn) : (
    aws_secretsmanager_secret.rds_master[0].arn)
}

output "master_secret_kms_key_id" {
 value = var.manage_master_user_password ? (
    module.aurora_database[0].cluster_master_user_secret[0].kms_key_id) : (
    aws_secretsmanager_secret.rds_master[0].kms_key_id)
}

output "db_endpoint" {
 value = module.aurora_database[0].cluster_endpoint
}
output "cluster_resource_id" {
 value = module.aurora_database[0].cluster_resource_id
}
output "db_arn" {
 value = module.aurora_database[0].cluster_arn
}

output "name" {
 value = var.name
}

output "validate_subnet_group" {
  description = "Null output to validate db subnet group configuration"
  value = null

  precondition {
    condition     = length(local.db_subnet_ids) > 0 || local.db_subnet_group_name != null
    error_message = "You must provide a valid existing db_subnet_group_name, provide db_subnet_ids, or enable DB subnet auto-discovery."
  }
}

output "db_subnet_group_name" {
  description = "Returns the generated DB Subnet Group name"
  value = local.db_subnet_group_name
}
output "existing_subnet_group" {
  description = "Returns true if this DB used an existing db subnet group"
  value = ! local.create_db_subnet_group
}

output "db_subnet_ids" {
  description = "Returns the effective subnets after auto-discovery and db security group configuration. Empty list if using existing subnet group."
  value = local.create_db_subnet_group ? local.db_subnet_ids : []
}

output "debug_output" {
  description = "Various object outputs for debugging purposes"
  value = {
    db_subnets = local.db_subnet_ids
    autodiscovered_subnets = {
        tagged      = local.autodiscovered_tagged_subnets
        db          = local.autodiscovered_db_tier_subnets
        private     = local.autodiscovered_private_tier_subnets
        public      = local.autodiscovered_public_tier_subnets
    }
  }
}

output "default_auth_type" {
  description = "The default authentication for users using this DB instance"
  value = var.default_auth_type
}
