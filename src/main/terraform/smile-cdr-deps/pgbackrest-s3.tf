module "s3_bucket_pgo_backrest" {
  count = (local.crunchy_pgo_backrest_s3_enabled && local.crunchy_pgo_backrest_s3_create_bucket) ? 1 : 0
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = local.crunchy_pgo_backrest_s3_bucket_name
  # bucket_prefix = local.crunchy_pgo_backrest_s3_bucket_name
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  force_destroy            = try(!var.crunchy_pgo_config.pgbackrest.s3.retain_on_destroy, true)

  versioning = {
    enabled = true
  }
}

data "aws_s3_bucket" "s3_bucket_pgo_backrest" {
  count = (local.crunchy_pgo_backrest_s3_enabled && !local.crunchy_pgo_backrest_s3_create_bucket) ? 1 : 0
  bucket = local.crunchy_pgo_backrest_s3_bucket_name
}

######################################
### IAM/IRSA for Crunchy PGO
######################################

module "pgo_irsa_role" {
  count = local.crunchy_pgo_backrest_s3_enabled ? 1 : 0
  # count = 0
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.30.2"

  role_name = local.pgo_irsa_role_name

  role_policy_arns = {
    S3PGOBackRest = aws_iam_policy.s3_pgo_backrest[0].arn
  }
  oidc_providers = {
    ex = {
      provider_arn               = local.eks_cluster_oidc_provider_arn
      namespace_service_accounts = local.pgo_namespace_service_accounts
    }
  }
}

# Policy for pgBackRest backups management
# Derived from: https://pgbackrest.org/user-guide.html#s3-support
data "aws_iam_policy_document" "s3_pgo_backrest" {
  count = local.crunchy_pgo_backrest_s3_enabled ? 1 : 0
  version = "2012-10-17"

  statement {
    effect = "Allow"
    actions = [
        "s3:ListBucket"
      ]
    resources = [
        "${local.crunchy_pgo_backrest_s3_bucket_arn}"
      ]
    condition {
      test     = "StringEquals"
      variable = "s3:prefix"

      values = [
        local.crunchy_pgo_backrest_s3_prefix
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:delimiter"

      values = [
        "/"
      ]
    }
  }

  statement {
    effect = "Allow"
    actions = [
        "s3:ListBucket"
      ]
    resources = [
        "${local.crunchy_pgo_backrest_s3_bucket_arn}"
      ]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"

      values = [
        "${local.crunchy_pgo_backrest_s3_prefix}/*"
      ]
    }
  }

  statement {
    effect = "Allow"
    actions = [
        "s3:PutObject",
        "s3:PutObjectTagging",
        "s3:GetObject",
        "s3:DeleteObject"
      ]
    resources = [
        "${local.crunchy_pgo_backrest_s3_bucket_arn}/*"
      ]
  }
}

resource "aws_iam_policy" "s3_pgo_backrest" {
  count = local.crunchy_pgo_backrest_s3_enabled ? 1 : 0
  name        = "${local.name}-s3-pgo-backrest-${local.resourcenames_suffix}"
  description = "Smile CDR Policy for CrunchyData PGO to manage S3 DB backups."
  policy = data.aws_iam_policy_document.s3_pgo_backrest[0].json
  tags = local.tags
}
