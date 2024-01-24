output "secrets_cdr_regcred" {
  value = {
    arn = try(aws_secretsmanager_secret.secrets["regcred"].arn,null)
  }
}

output "secrets_kms_key" {
  value = {
    arn = try(aws_kms_key.secrets_key[0].arn ,null)
  }
}

output "helm_sa_annotation" {
  value = {
    annotation = "eks.amazonaws.com/role-arn"
    value = try(module.smile_cdr_irsa_role[0].iam_role_arn,null)
  }
}

output "helm_secret_configs" {
    value = concat([
      {
        secretType = "Image Pull Secret"
        secretArn = try(aws_secretsmanager_secret.secrets["regcred"].arn,null)
      }
    ],
    [
      {
        secretType = "Smile CDR License"
        secretArn = try(aws_secretsmanager_secret.secrets["cdr_license"].arn,null)
      }
    ],
    [
      for dbuser in module.postgres_db_user:
      dbuser.helm_secret_config
    ])
}

output "url" {
  value = local.public_fqdn
}
