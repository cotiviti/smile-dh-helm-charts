module "loki_irsa_role" {
  count = local.loki_iam_role_enabled ? 1 : 0
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.30.2"

  role_name = local.loki_irsa_role_name

  role_policy_arns = local.loki_role_policy_arns

  oidc_providers = {
    ex = {
      provider_arn               = local.eks_cluster_oidc_provider_arn
      namespace_service_accounts = local.loki_namespace_service_accounts
    }
  }
}

# Policy for reading from S3 buckets
data "aws_iam_policy_document" "loki-s3" {
  count = local.loki_s3_enabled ? 1 : 0
  version = "2012-10-17"

  statement {
    effect = "Allow"
    actions = [
        "s3:ListBucket",
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ]
    resources = local.loki_s3_bucket_arns
    
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
resource "aws_iam_policy" "loki-s3" {
  count = local.loki_s3_enabled ? 1 : 0
  name        = "${local.name}-loki-s3-${local.resourcenames_suffix}"
  description = "Policy for Loki to read & write files in S3 buckets"
  policy = data.aws_iam_policy_document.loki-s3[0].json
  tags = local.tags
}

variable "loki_s3_buckets" {
  type = map(string)
  nullable    = false
  # default     = []
  default     = {
    chunks = "myLokiBucket"
  }
}

variable "loki_service_account_name" {
  description = "Override auto-generated service account name for Loki"
  type        = string
  default     = null
}

variable "helm_loki_service_account_suffix" {
  description = "The suffix used for Loki ServiceAccount in the Smile CDR Helm Chart"
  type        = string
  default     = "-loki"
}

locals {

  # IAM module expects map of objects
  loki_role_policy_arns = merge(
    length(aws_iam_policy.loki-s3) > 0 ? { LokiS3Buckets = aws_iam_policy.loki-s3[0].arn } : {}
  )

  helm_loki_service_account_suffix = var.helm_loki_service_account_suffix
  loki_service_account_name = var.loki_service_account_name == null ? "${local.helm_release_name}${local.helm_loki_service_account_suffix}" : var.loki_service_account_name
  loki_namespace_service_accounts = ["${local.helm_namespace}:${local.loki_service_account_name}"]

  # Loki
  loki_enabled = true
  loki_storage = "s3"
  loki_s3_enabled = (local.loki_enabled && local.loki_storage == "s3" ? true:false)

  # Enable reading from S3 'staging' buckets, i.e. for CopyFiles functions
  loki_s3_buckets_enabled = length(var.loki_s3_buckets) > 0 ? true : false


#   loki_s3_enabled = local.loki_s3_read_buckets_enabled || local.s3_write_buckets_enabled

  loki_s3_bucket_arns = concat([
      for bucket in var.loki_s3_buckets:
        "arn:aws:s3:::${bucket}"
    ],
    [
      for bucket in var.loki_s3_buckets:
        "arn:aws:s3:::${bucket}/*"
    ])

  # IAM for Loki
  loki_iam_role_enabled = local.loki_s3_enabled
  loki_iam_role = local.loki_iam_role_enabled ? module.loki_irsa_role[0] : null
  loki_iam_role_arn = local.loki_iam_role.iam_role_arn
  loki_irsa_role_name = "${local.name}-loki-${local.resourcenames_suffix}"
  
  loki_helm_config = {
    observability = {
      services = {
        logging = {
          loki = {
            # enabled = local.loki_enabled
            serviceAccount = {
              create = true
              annotations = {
                "eks.amazonaws.com/role-arn" = local.loki_iam_role_arn
              }
            }
            bucketNames = var.loki_s3_buckets
          }
        }
      }
    }
  }
}

output "loki_service_account_name" {
  value = local.loki_service_account_name
}

output "loki_iam_role" {
  value = local.loki_iam_role
}