output "name" {
 value = var.name
}

output "secret_arn" {
  value = aws_secretsmanager_secret.pg_user_db.arn
}

# TODO: Refactor this out
output "secret_version" {
  value = aws_secretsmanager_secret_version.pg_user_db.arn
}

output "helm_secret_config" {
  value = {
    secretType = "Database"
    cdr_modules = var.cdr_modules
    secretArn = aws_secretsmanager_secret.pg_user_db.arn
  }
}

output "auth_type" {
  value = var.auth_type
}

# output "cdr_modules" {
#   value = var.cdr_modules
# }
