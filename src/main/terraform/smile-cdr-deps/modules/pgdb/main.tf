###########################
# DB User Secrets
###########################


resource "aws_secretsmanager_secret" "pg_user_db" {
  kms_key_id              = var.secrets_kms_key_arn
  # name_prefix             = var.name_override ? null : var.name
  name                    = var.resourcenames_suffix != "" ? "${var.name}-${local.resourcenames_suffix}" : var.name
  recovery_window_in_days = var.secrets_deletion_window
  tags = merge(
    var.tags,
    {
      auth_type = local.auth_type
    }
  )
}

data "aws_secretsmanager_random_password" "db_password" {
  password_length = 15
  # TODO: set up special character exclusion/inclusion. Should be parameterized.
  #   exclude_numbers = true
}

# TODO: Refactor this out
resource "aws_secretsmanager_secret_version" "pg_user_db" {
  secret_id               = aws_secretsmanager_secret.pg_user_db.arn
  # Secrets must be stored in appropriate format. See:
  # https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_secret_json_structure.html#reference_secret_json_structure_rds-postgres
  secret_string           = jsonencode(
                          {
                            # Warning, if you change any of these, you will need to remove the lifecycle.ignore_changes so that the secret can be
                            # updated
                            username  = var.username
                            password  = data.aws_secretsmanager_random_password.db_password.random_password
                            engine    = "postgres"
                            host      = var.db_host
                            dbname    = var.dbname
                            masterarn = var.master_secret_arn
                            port      = var.dbport
                          }
  )
  # This stops Terraform trying to update the secret on every run.
  # The secret SHOULD be rotated after the initial creation to make this secure.

  # Unfortunately, there seems to be no way to make this configurable...
  # lifecycle {
  #   ignore_changes = var.force_secret_update ? [] : [secret_string]
  # }
  lifecycle {
    ignore_changes = [secret_string]
  }
}

# Storing connection configuration in Parameter Store.
# This only makes sense when using IAM authentication as you then don't need
# to store a password...
# resource "aws_ssm_parameter" "pg_user_db" {
#   name  = "foo"
#   type  = "String"
#   value = "bar"
# }

# TODO: Enable secret rotation, but it needs to be considered with the application.
# Using the multi-user rotation mechanism will be a safe way to do this, so long as the Smile CDR pods can be recycled at some point during the
# rotation window.
# resource "aws_secretsmanager_secret_rotation" "pg_user_db" {
#   # Disabled for now
#   count = 0
#   secret_id           = aws_secretsmanager_secret.pg_user_db
#   rotation_lambda_arn = aws_lambda_function.example.arn

#   rotation_rules {
#     automatically_after_days = 30
#   }
# }

# Resource Name Generation
resource "random_id" "resourcenames_suffix" {
  keepers = {
    # Generate a new id each time we switch to a new name
    name  = var.name
  }

  byte_length = 8
}
