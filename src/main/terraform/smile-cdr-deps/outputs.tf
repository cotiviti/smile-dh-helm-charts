output "name" {
  value = local.name
}

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

output "helm_release_notes" {
  value = try(data.helm_template.smilecdr[0].notes,null)
}

output "iam_users" {
  value = {
    iam_db_users = local.iam_db_users
    db_users = var.db_users
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

# Temporarily adding these to make it easier to install other Helm Charts from the parent
# module. But it may just be easier to 'bring this in' to the module so that the parent chart
# does not need to re-do the EKS cluster discovery.

output "eks_cluster" {
  value = {
    name = local.eks_cluster_name
    endpoint = local.eks_cluster_endpoint
    certificate = local.eks_cluster_ca_certificate
    oidc_provider_arn = local.eks_cluster_oidc_provider_arn
    auth_token = data.aws_eks_cluster_auth.this.token
  }
}
