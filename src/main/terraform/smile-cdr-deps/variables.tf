variable "eks_cluster_name" {
  description = "Name of the EKS cluster to install Smile CDR"
  type        = string
  # default     = "myEKSCluster"
  nullable    = false

}

variable "eks_cluster_oidc_provider_url" {
  description = "Override auto-detected EKS OIDC Provider URL e.g., https://oidc.eks.<region.amazonaws.com/id/<ID>"
  type        = string
  default     = null
}

variable "eks_cluster_oidc_provider_arn" {
  description = "Override auto-detected EKS OIDC Provider ARN e.g., arn:aws:iam::<ACCOUNT-ID>:oidc-provider/<var.eks_oidc_provider>"
  type        = string
  default     = null
}

variable "eks_cluster_endpoint" {
  description = "Override auto-detected EKS Cluster endpoint"
  type        = string
  default     = null
}

variable "eks_cluster_ca_certificate" {
  description = "Override auto-detected EKS Cluster CA Certificate. This must be a base64 encoded certificate."
  type        = string
  default     = null
}

variable "eks_cluster_version" {
  description = "Override auto-detected EKS Cluster version"
  type        = string
  default     = null
}

variable "enable_irsa" {
  description = "Override auto-detected EKS Cluster version"
  type        = bool
  default     = null
}

variable "eks_cluster_security_group_id" {
  description = "Security group ID for EKS Cluster"
  type        = string
  default = null
}

variable "db_vpc_id" {
  description = "ID of VPC to create Database in. Uses the same VPC as the EKS cluster by default"
  type        = string
  default = null
}

variable "name" {
  description = "Unique identifier for this Smile CDR instance"
  type        = string
}

variable "resourcenames_suffix" {
  description = "Set suffix on generated resource names. Will generate random suffix if not set."
  type        = string
  default     = null
}

variable "namespace" {
  description = "The Namespace this will be deployed in"
  type        = string
  default     = null
}

variable "cdr_service_account_name" {
  description = "Override auto-generated service account name"
  type        = string
  default     = null
}

variable "helm_deploy" {
  description = "Deploy using the Smile CDR Helm Chart"
  type        = bool
  default     = true
  nullable = false
}

variable "helm_release_name" {
  description = "The release name used in the Smile CDR Helm Chart"
  type        = string
  default     = "smilecdr"
  nullable    = false
}

variable "helm_repository" {
  description = "The Helm Repo where the Smile CDR Helm Chart is hosted"
  type        = string
  default     = "https://gitlab.com/api/v4/projects/40759898/packages/helm/stable"
  nullable    = false
}

variable "helm_chart" {
  description = "The name of the Smile CDR Helm Chart in the repository"
  type        = string
  default     = "smilecdr"
  nullable    = false
}

variable "helm_chart_version" {
  description = "The version of the Smile CDR Helm Chart to use. If set to `null`, the latest chart version will be selected based on the use of the `helm_chart_devel` option"
  type        = string
  default     = "1.1.1"
  nullable    = true
}

variable "helm_chart_devel" {
  description = "If set to true, and if `helm_chart_version` is set to `null`, the latest pre-release chart version will be used"
  type        = bool
  default     = false
  nullable    = false
}

variable "helm_chart_values" {
  description = "List of raw yaml values files to pass in to the Helm Chart. These will be merged into the final Helm Values."
  type        = list(string)
  default     = []
  nullable = false
}

variable "helm_chart_values_set_overrides" {
  description = "Individual values overrides to pass in to the Helm Chart. Each item in the provided map is equivalent to using the --set option with the helm command."
  type        = map(string)
  default     = {}
  nullable = false
}

variable "helm_chart_mapped_files" {
  description = "List of files & data to include in the classes & customerlib directories."
  type        = list(object(
    {
      name     = string
      data     = string
      location = string
    }
  ))
  default     = []
  nullable = false
}
# variable "helm_chart_classes_files" {
#   description = "List of files & data to include in the classes directory."
#   type        = list(object(
#     {
#       name    = string
#       data   = string
#     }
#   ))
#   default     = []
#   nullable = false
# }

variable "helm_service_account_suffix" {
  description = "The suffix used for ServiceAccount in the Smile CDR Helm Chart"
  type        = string
  default     = "-smilecdr"
}

variable "secrets_kms_key_arn" {
  description = "ARN for KMS key used for Secrets. If not specified, one will be created"
  type        = string
  nullable    = true
  default     = null
}

variable "enable_cdr_rds_secrets" {
  description = "Use AWS Secrets Manager for RDS Secrets"
  type        = bool
  nullable    = false
  default     = true
}

variable "cdr_regcred_secret_arn" {
  description = "ARN for existing AWS Secrets Manager secret for registry credentials. If not specified, a secret will be created"
  type        = string
  default     = null
}

variable "cdr_regcred_secret_kms_arn" {
  description = "ARN for KMS key for existing AWS Secrets Manager secret for registry credentials."
  type        = string
  default     = null
}

variable "enable_cdr_regcred_secret" {
  description = "Disable handling of secrets for registry credentials"
  type        = bool
  default     = true
  nullable    = false
}
variable "cdr_regcred_secret_name" {
  description = "Name to use when creating secret for Docker pull"
  type        = string
  default     = "regcred"
}

variable "cdr_regcred_secret_name_override" {
  description = "Set true to prevent random suffix on Docker pull secret name"
  type        = bool
  nullable    = false
  default     = false
}

variable "enable_cdr_license_secret" {
  description = "Use AWS Secrets Manager for Smile CDR License Secret"
  type        = bool
  nullable    = false
  default     = false
}

variable "cdr_license_secret_arn" {
  description = "ARN for AWS Secret for Smile CDR License. If not specified, a secret will be created"
  type        = string
  nullable    = true
  default     = null
}

variable "cdr_license_secret_kms_arn" {
  description = "ARN for KMS key for existing AWS Secrets Manager secret for Smile CDR License."
  type        = string
  default     = null
}

variable "cdr_license_secret_name" {
  description = "Name to use when creating secret for Smile CDR License"
  type        = string
  default     = "license"
}

variable "cdr_license_secret_name_override" {
  description = "Set true to prevent random suffix on Smile CDR License secret name"
  type        = bool
  nullable    = false
  default     = false
}

variable "kms_deletion_window" {
  description = "Deletion Window for KMS. Set from 7 to 30"
  type        = number
  default     = 7
}

variable "secrets_deletion_window" {
  description = "Deletion Window for Secrets. Set to 0 for dev environments, or set from 7 to 30"
  type        = number
  default     = 7
}

variable "rds_kms_arn" {
  description = "ARN for KMS key used for RDS. If not specified, one will be created"
  type        = string
  nullable    = true
  default     = null
}

variable "db_subnet_ids" {
  description = "Subnet IDs where the Database will be located. If this is left null then an existing db_seubnet_group MUST be provided with db_subnet_group_name."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "db_use_old_helm_schema" {
  description = "DEPRECATED: Use database connection configuration schema from v1.0.0-pre.121 and earlier."
  type        = bool
  default     = false
  nullable    = true
}

variable "db_instance_defaults" {
  description = "Default configuration for databases."
  type        = object({
    db_subnet_discovery_tags      = optional(map(string))
    db_subnet_discovery_enabled   = optional(bool,true)
    db_subnet_ids                 = optional(list(string))
    db_subnet_group_name          = optional(string)
    engine                        = optional(string,"aurora-postgresql-serverless-v2")
    enable_cdr_rds_secrets        = optional(bool,true)
    publicly_accessible           = optional(bool,false)
    serverless_configuration      = optional(map(string))


  })
  default     = {
    engine = "aurora-postgresql-serverless-v2"
    enable_cdr_rds_secrets        = true
    serverless_configuration      = {
      min_capacity = 0.5
      max_capacity = 10
    }
  }
  nullable    = false
}

variable "db_instances" {
  type        = list(object({
    name                          = string
    db_subnet_discovery_tags      = optional(map(string))
    db_subnet_discovery_enabled   = optional(bool)
    db_subnet_ids                 = optional(list(string))
    db_subnet_group_name          = optional(string)
    engine                        = optional(string)
    enable_cdr_rds_secrets        = optional(bool)
    name_suffix                   = optional(string)
    name_override                 = optional(string)
    publicly_accessible           = optional(bool)
    public_cidr_blocks            = optional(list(string))
    rds_kms_arn                   = optional(string)
    kms_deletion_window           = optional(number)
    secrets_kms_key_arn           = optional(string)
    master_username               = optional(string)
    manage_master_user_password   = optional(bool)
    dbname                        = optional(string)
    dbport                        = optional(number)
    default_auth_type             = optional(string)
    serverless_configuration      = optional(map(string))

  }))
  nullable    = false
  default     = []
}

variable "db_users" {
  type = list(object({
    db_instance_name              = string
    name                          = string
    cdr_modules                   = optional(list(string))
    dbusername                    = optional(string)
    dbname                        = optional(string)
    auth_type                     = optional(string,"password")

  }))
  nullable    = false
  default     = []
}

variable "crunchy_pgo_config" {
  description   = "CrunchyData PGO backup & restore configuration"
  type        = object({
    enabled                       = optional(bool)
    helm_autoconf                 = optional(bool,true)
    pgbackrest                    = optional(object({
      enabled                     = optional(bool,false)
      volume                      = optional(object({
        backupsSize               = optional(string,"1Gi")
        retention_full            = optional(number,3)
        retention_incremental     = optional(number)
        retention_differential    = optional(number)
        manual_backup             = optional(string)
      }))
      s3                          = optional(object({
        enabled                   = optional(bool,false)
        use_existing_bucket       = optional(bool,false)
        bucket_name               = optional(string)
        bucket_name_prefix        = optional(string)
        bucket_prefix             = optional(string,"pgbackrest")
        reponumber                = optional(number,2)
        reponame                  = optional(string)
        retain_on_destroy         = optional(bool,false)
        retention_full            = optional(number,10)
        retention_incremental     = optional(number)
        retention_differential    = optional(number)
        manual_backup             = optional(string)
      }),{enabled=false})
      schedules                   = optional(object({
        full                      = optional(string)
        incremental               = optional(string)
        differential              = optional(string)
      }))
    }))
    restore                       = optional(object({
      enabled                     = optional(bool,false)
      source                      = optional(string)
      type                        = optional(string,"time")
      restore_time                = optional(string)
    }))
    datasource                    = optional(any)
  })

  # validation {
  #   condition = (
  #     # If using an existing bucket, we MUST provide the name.
  #     # Without these, we cannot determine the full DNS name to use.
  #     length(split(".", var.ingress_config.public.parent_domain)) > 1 ||
  #     length(split(".", var.ingress_config.public.hostname)) > 2
  #   )
  #   error_message = "You must provide parent_domain, or provide the full DNS name in hostname"
  # }
  default     = {
    pgbackrest = {
      enabled = false
    }
  }
  nullable    = false
}

variable "extra_secrets" {
  type = list(any)
  nullable    = false
  default     = []
}

variable "create_copyfiles_bucket" {
  description = "Enable creation of S3 bucket suitable for CopyFiles function"
  type        = bool
  nullable    = false
  default     = false
}

variable "s3_read_buckets" {
  type = list(any)
  nullable    = false
  default     = []
}

variable "s3_write_buckets" {
  type = list(any)
  nullable    = false
  default     = []
}


variable "extra_iam_policies" {
  type = map(map(any))
  nullable    = true
  default     = {}
}

variable "unit_testing" {
  description = "Use mock_* vars instead of data sources for unit testing"
  type = bool
  default     = false
  nullable    = false
}

variable "mock_data_aws_eks_cluster" {
  description = "Mock unit-testing data for aws_eks_cluster data source "
  # Note that this type definition needs to match the output from the appropriate version of the eks_cluster data source
  # Reference: https://github.com/hashicorp/terraform-provider-aws/blob/v5.33.0/internal/service/eks/cluster_data_source.go#L22
  type = object(
    {
      arn                               = optional(string)
      access_config                     = optional(list(object(
        {
          authentication_mode           = string
        }
      )))
      certificate_authority             = optional(list(object(
        {
          data                          = string
        }
      )))
      created_at                        = optional(string)
      enabled_cluster_log_types         = optional(set(string))
      endpoint                          = optional(string)
      id                                = optional(string)
      cluster_id                        = optional(string)
      identity                          = optional(list(object(
        {
          oidc=list(object(
            {
              issuer                    = string
            }
          ))
        }
      )))
      kubernetes_network_config         = optional(list(object(
        {
          ip_family                     = string
          service_ipv4_cidr             = string
          service_ipv6_cidr             = string
        }
      )))
      name                              = optional(string)
      outpost_config                    = optional(list(object(
        {
          control_plane_instance_type   = string
          control_plane_placement       = list(object(
            {
              group_name                = string
            }
          ))
          outpost_arns                  = set(string)
        }
      )))
      platform_version                  = optional(string)
      role_arn                          = optional(string)
      status                            = optional(string)
      version                           = optional(string)
      vpc_config                        = optional(list(object(
        {
          cluster_security_group_id     = string
          endpoint_private_access       = optional(bool)
          endpoint_public_access        = optional(bool)
          public_access_cidrs           = optional(set(string))
          security_group_ids            = optional(set(string))
          subnet_ids                    = optional(set(string))
          vpc_id                        = string
        }
      )))
      tags                              = optional(object({}))
    }
  )
  default = {}
}

variable "mock_data_aws_iam_openid_connect_provider" {
  description = "Mock unit-testing data for aws_iam_openid_connect_provider data source "
  # Note that this type definition needs to match the output from the appropriate version of the eks_cluster data source
  # Reference: https://github.com/hashicorp/terraform-provider-aws/blob/85b0843d0b3963876fcff0c5f55259239de8a558/internal/service/iam/openid_connect_provider_data_source.go#L27
  type = object(
    {
      arn                               = optional(string)
      client_id_list                    = optional(list(string))
      thumbprint_list                   = optional(list(string))
      id                                = optional(string)
      url                               = optional(string)
      tags                              = optional(map(string))
    }
  )
  default = {}
}

variable "ingress_config" {
  description = "Configuration for DNS"
  type = map(object(
    {
      hostname                = optional(string,"")
      parent_domain           = optional(string,"")
      route53_create_record   = optional(bool,true)
      route53_zone_name       = optional(string)
    }
  ))
  default = {}
  nullable = false
  validation {
    condition = (
      # We must have EITHER, parent_domain with 2 or more parts or hostname with 3 or more parts.
      # Without these, we cannot determine the full DNS name to use.
      length(split(".", var.ingress_config.public.parent_domain)) > 1 ||
      length(split(".", var.ingress_config.public.hostname)) > 2
    )
    error_message = "You must provide parent_domain, or provide the full DNS name in hostname"
  }
}
variable "prod_mode" {
  description = "Sets some sane defaults for environments being deployed into production"
  type = bool
  default = true
  nullable = false
}

variable "tags" {
  description = "Tags to add to infrastructure resources"
  type = map(string)
  default = {}
  nullable = false
}
