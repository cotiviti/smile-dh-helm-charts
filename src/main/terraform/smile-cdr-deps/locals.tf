locals {

  context = {
    # Data resources
    aws_region_name = data.aws_region.current.name
    # aws_caller_identity
    aws_caller_identity_account_id = data.aws_caller_identity.current.account_id
    aws_caller_identity_arn        = data.aws_caller_identity.current.arn
    # aws_partition
    aws_partition_id         = data.aws_partition.current.id
    aws_partition_dns_suffix = data.aws_partition.current.dns_suffix
  }

  name            = var.name

  resourcenames_suffix = var.resourcenames_suffix != null ? var.resourcenames_suffix : random_id.resourcenames_suffix.hex

  # Determining the name of the AWS Load Balancer is not directly possible from Terraform as the Load Balancer was deployed indirectly
  # via the AWS Load Balancer Controller.
  # To get the load balancer name, we must do the following:
  # - Get the hostname from the LoadBalancer Service in Kubernetes
  # - Determine the Load Balancer name from that.

  # Get the hostname from the K8s LB Service
  ingress_nginx_lb_fqdn = try(data.kubernetes_service.ingress-nginx[0].status.0.load_balancer.0.ingress.0.hostname,"")
  # Extract `load-balancer-name-suffix` from `load-balancer-name-suffix.elb.<region>.amazonaws.com`
  ingress_nginx_lb_hostname = split(".", local.ingress_nginx_lb_fqdn)[0]
  # Extract `load-balancer-name` from `load-balancer-name-suffix`
  ingress_nginx_lb_hostname_parts = split("-", local.ingress_nginx_lb_hostname)
  ingress_nginx_lb_name = join("-", slice(local.ingress_nginx_lb_hostname_parts, 0, (length(local.ingress_nginx_lb_hostname_parts) - 1)))

  # Hostname is either passed in or derived from the main `name`
  full_hostname = lower(coalesce(var.ingress_config.public.hostname, var.name))

  # Parent domain is either derived from the provided hostname or provided directly. If not provided in either, we will fail (non-gracefully)
  full_hostname_parts = split(".",local.full_hostname)
  parent_domain = length(local.full_hostname_parts) > 2 ? join(".", slice(local.full_hostname_parts,1,length(local.full_hostname_parts))) : var.ingress_config.public.parent_domain
  hostname = local.full_hostname_parts[0]

  route53_zone_name = coalesce(var.ingress_config.public.route53_zone_name,local.parent_domain)
  public_fqdn = join(".", [local.hostname, local.parent_domain])

  # Helm

  helm_namespace    = coalesce(var.namespace, lower(local.name))
  helm_release_name = coalesce(var.helm_release_name, lower(local.name))
  helm_service_account_suffix = var.helm_service_account_suffix
  helm_repository_default = "https://gitlab.com/api/v4/projects/40759898/packages/helm"
  helm_repository_stable_channel = "next-major"
  
  helm_chart = var.helm_chart

  helm_use_default_repo = local.helm_repository_default == var.helm_repository
  helm_use_stable_channel = local.helm_use_default_repo && local.helm_repository_stable_channel == var.helm_repository_release_channel
  
  # If using the default repo, then the final URL is `repo/channel`, otherwise just use the repo that was provided
  helm_repository = local.helm_use_default_repo ? "${var.helm_repository}/${var.helm_repository_release_channel}/" : var.helm_repository

  ## Determine Helm Chart version ##
  
  # This needs to be updated during a release!
  helm_chart_default_version = "v4.0.0-next-major.2"
  
  ### NOTE: Due to what seems like a bug in the helm_release module, setting `devel` to true can cause terraform to always update even if there are no changes
  ### To circumvent this for now, we will manually set the version to ">0.0.0-0" rather than setting `devel`
  ### The below logic can be replaced once the upstream bug is fixed
  
  # #######################################################################
  # Delete this section once bug is fixed.
  # helm_autoconf_devel_version is used if not using stable channel.
  # It will be ">0.0.0-0" unless version has been explicitly set.
  # This is functionally equivalent to setting devel, while avoiding the bug
  helm_autoconf_devel_version = var.helm_chart_version != null ? var.helm_chart_version : ">0.0.0-0"
  helm_autoconf_version = local.helm_use_stable_channel ? local.helm_chart_default_version : local.helm_autoconf_devel_version
  # Use var.helm_chart_version mode if provided, otherwise use the autoconf version
  helm_chart_version = var.helm_chart_version != null ? var.helm_chart_version : local.helm_autoconf_version
  # Use var.helm_chart_version mode if provided, otherwise use null and rely on the autoconf version being set for devel mode
  helm_chart_devel = var.helm_chart_devel != null ? var.helm_chart_devel : null
  # #######################################################################

  # #######################################################################
  # Uncomment this section once bug is fixed.
  # # The autoconfigured helm version (used when var.helm_chart_version is null) depends on the channel being used.
  # # Note that you need to set an empty string rather than using null, in case version was previously set. `null` will not unset it.
  # helm_autoconf_version = local.helm_use_stable_channel ? local.helm_chart_default_version : ""
  # # If autoconf version ends up empty, then we autoconf devel mode so that it picks up the latest prerelease
  # helm_chart_autoconf_devel = local.helm_chart_version == "" ? true : false
  # # Use var.helm_chart_version mode if provided, otherwise use the autoconf version
  # helm_chart_version = var.helm_chart_version != null ? var.helm_chart_version : local.helm_autoconf_version
  # # Use var.helm_chart_version mode if provided, otherwise use the autoconf devel mode
  # helm_chart_devel = var.helm_chart_devel != null ? var.helm_chart_devel : local.helm_chart_autoconf_devel
  # #######################################################################

  cdr_service_account_name = var.cdr_service_account_name == null ? "${local.helm_release_name}${local.helm_service_account_suffix}" : var.cdr_service_account_name
  cdr_namespace_service_accounts = ["${local.helm_namespace}:${local.cdr_service_account_name}"]

  helm_chart_values_provided = try(yamldecode(var.helm_chart_values[0]),null)
  helm_chart_values = concat(
    var.helm_chart_values,
    [
      yamlencode(
        merge(
          # Include image pull secrets config
          can(local.all_secrets["regcred"].arn) ?
            {
              image = {
                imagePullSecrets = [
                  {
                    type = "sscsi"
                    provider = "aws"
                    secretArn = local.all_secrets["regcred"].arn
                  }
                ]
              }
            } : {},

          # Include license secrets config
          can(local.all_secrets[var.cdr_license_secret_name].arn) ?
            {
              license = {
                type = "sscsi"
                provider = "aws"
                secretArn = local.all_secrets[var.cdr_license_secret_name].arn
              }
            } : {},

          # Configure CDR ServiceAccount if IAM role is enabled
          local.cdr_iam_role_enabled ?
            {
              serviceAccount =  {
                create = true
                name = local.cdr_service_account_name
                annotations = {
                    "eks.amazonaws.com/role-arn" = local.iam_role_arn
                }
              }
            } : {},

          # Configure external DB credentials if enabled
          length(var.db_users) > 0 ?
            {
              database = {
                # Legacy DB configuration, before chart version xxx
                # external = var.db_use_old_helm_schema ? local.helm_config_external_db_old : local.helm_config_external_db
                external = merge(
                  var.db_use_old_helm_schema ? local.helm_config_external_db_old : null,
                  var.db_use_old_helm_schema ? null : local.helm_config_external_db
                )
              }
            } : {},

          # Include CrunchyPGO Helm Configs
          local.crunchy_pgo_helm_config,

          # Add classpath files
          length(var.helm_chart_mapped_files) > 0 ?
            {
              mappedFiles = {
                for mapped_file in var.helm_chart_mapped_files:
                   mapped_file.name => {
                    data = mapped_file.data
                    path = format("/home/smile/smilecdr/%s",mapped_file.location)
                   }
                }
            } : {},
        )
      )
    ],
  )

  # This is for setting individual Helm Values overrides.
  # Suitable for sparse overrides, but not for large blocks of configuration.
  # To override entire blocks of values, uses the helm_chart_values above
  helm_chart_values_set_overrides = merge(
    {
      # "database.crunchypgo.enabled" = "true"
      # "database.crunchypgo.internal" = "true"
      "specs.hostname" = local.public_fqdn
      "replicaCount" = try(local.helm_chart_values_provided.replicaCount,(var.prod_mode ? 3 : 1))
    },
    var.helm_chart_values_set_overrides
  )

  tags = merge(
    {
      terraform_module = "SmileCDR_Helm_Dependencies"
      terraform_module_version = "v3.0.0"
      # terraform_module_sha = "000000"
    },
    var.tags
  )

  # IAM for SCDR
  cdr_iam_role_enabled = var.enable_irsa == null ? (local.secrets_enabled || local.s3_enabled ? true:false) : var.enable_irsa
  iam_role = local.cdr_iam_role_enabled ? module.smile_cdr_irsa_role[0] : null
  iam_role_arn = local.iam_role.iam_role_arn
  cdr_irsa_role_name = "${local.name}-smilecdr-${local.resourcenames_suffix}"

  ###################
  # Secrets
  ###################

  # For each secret, we need to either create it, reference an existing one, or disable it...

  create_cdr_regcred_secret = var.enable_cdr_regcred_secret ? (var.cdr_regcred_secret_arn == null ? true:false) : false
  create_cdr_license_secret = var.enable_cdr_license_secret ? (var.cdr_license_secret_arn == null ? true:false) : false

  create_secrets = local.secrets_enabled && (
                        local.create_cdr_regcred_secret ||
                        local.create_cdr_license_secret ||
                        local.enable_cdr_rds_secrets
                      )

  # Secrets KMS
  create_secrets_kms = local.create_secrets && var.secrets_kms_key_arn == null ? true:false
  secrets_kms_key_arn = local.create_secrets_kms ? aws_kms_key.secrets_key[0].arn : var.secrets_kms_key_arn

  # Registry Credentials Secret
  # Only populated if regcred secret is enabled
  cdr_regcred_secret = var.enable_cdr_regcred_secret ? {
    name = var.cdr_regcred_secret_name
    name_override = try(var.cdr_regcred_secret_name_override,false)
    existing_arn = try(var.cdr_regcred_secret_arn,null)
    existing_kms_arn = var.cdr_regcred_secret_kms_arn
  } : {}

  # Smile CDR License Secret
  # Only populated if license secret is enabled
  cdr_license_secret = var.enable_cdr_license_secret ? {
    name = var.cdr_license_secret_name
    name_override = try(var.cdr_license_secret_name_override,false)
    existing_arn = try(var.cdr_license_secret_arn,null)
    existing_kms_arn = try(var.cdr_license_secret_kms_arn,null)
  } : {}

  ##### RDS AutoGenerated secrets

  # Enable rds secrets if not disabled and if db users have been defined
  enable_cdr_rds_secrets = var.enable_cdr_rds_secrets ? (length(var.db_users) > 0 ? true : false) : false
  # Master user secrets
  rds_master_users_secrets = [
    for db in module.managed_database:
      merge(
        db,
        {
          existing_arn = db.master_secret_arn
          kms_key_id = db.master_secret_kms_key_id
          arn = db.master_secret_arn
        }
      )
  ]

  rds_db_users_secrets = [
    for user in module.postgres_db_user:
      merge(
        user,
        {
          existing_arn = user.secret_arn
          arn = user.secret_arn
        }
      )
  ]

  # DB user secret versions
  # TODO: Refactor this out
  secret_versions_db_users = [
    for db_user in module.postgres_db_user:
      db_user.secret_version
  ]

  rds_secrets = concat(local.rds_master_users_secrets,local.rds_db_users_secrets)

  # The following two locals split the list of secrets into those with an 'existing_arn' and those without.
  # Those without an existing arn need to be created. Those with the arn are simply referenced in the generated
  # IAM policies.

  secrets_to_create = {
    for secret in concat(
        length(local.cdr_regcred_secret) > 0 ? [local.cdr_regcred_secret] : [],
        length(local.cdr_license_secret) > 0 ? [local.cdr_license_secret] : [],
        var.extra_secrets
      ):
      secret.name => merge(
        secret,
        {
          secret_name = try(secret.name_override, false) ? secret.name : "${local.name}-${secret.name}-${local.resourcenames_suffix}"
          # Set the existing KMS Key ARN for the secret if provided. Otherwise a new KMS key may be created
          kms_key_id  = secret.existing_kms_arn == null ? local.secrets_kms_key_arn : secret.existing_kms_arn
        }
      )
      if try(secret.existing_arn, null) == null
  }

  # This represents all secrets that were created outside of this module. This includes any rds secrets.
  existing_secrets = {
    # Convert list into map
    for secret in concat(
        [local.cdr_regcred_secret, local.cdr_license_secret],
        local.rds_secrets,
      ):
      # Use secret.name as the map key name. Merge the secret object with the new values:
      # * kms_key_id
      # * arn
      secret.name => merge(
        secret,
        {
          # Set the KMS Key ARN for the existing secret if provided. Otherwise leave it out and the default KMS key will be used
          kms_key_id  = try(secret.kms_key_id, secret.existing_kms_arn, null)
          arn = secret.existing_arn
        }
      )
      if try(secret.existing_arn, null) != null
  }

  all_secrets = merge(local.existing_secrets,resource.aws_secretsmanager_secret.secrets)

  all_secret_arns = [
    for secret in local.all_secrets:
      secret.arn
  ]

  # Get list of all KMS key ARNs used for secrets
  all_secret_kms_key_arns = distinct(compact([
    # for secret in merge(local.secrets_to_create,local.existing_secrets):
    for secret in merge(aws_secretsmanager_secret.secrets,local.existing_secrets):
      secret.kms_key_id
      if can(secret.kms_key_id)
  ]))

  secrets_enabled = var.enable_cdr_regcred_secret || var.enable_cdr_license_secret || local.enable_cdr_rds_secrets  ? true:false

  # Determine if there are users with IAM auth explicitly configured
  # This is so we can auto-enable IAM in the instance if required.
  iam_db_users = [
    for db_user in var.db_users :
      try(db_user.auth_type, "password") == "iam" ? db_user : null
    if try(db_user.auth_type, "password") == "iam"
  ]

  # DB user ARNs (For IAM Auth)
  iam_db_user_arns = [
    for db_user in local.iam_db_users:
      format("arn:aws:rds-db:%s:%s:dbuser:%s/%s",
        local.context.aws_region_name,
        local.context.aws_caller_identity_account_id,
        module.managed_database[lookup(db_user, "db_instance_name")].cluster_resource_id,
        coalesce(db_user.dbusername, db_user.name))
  ]

  create_rds_user_mgmt_lambda = length(var.db_users) > 0 ? true : false
  rds_iam_auth_enabled = length(local.iam_db_users) > 0 ? true : false

  helm_config_external_db = {
    enabled = "true"
    defaults = {
      connectionConfigSource = {
        source = "sscsi"
        provider = "aws"
      }
      connectionConfig = {
        authentication = {
          # type = "pass"
          provider = "aws"
        }
      }
    }
    databases = [
      for db_user in module.postgres_db_user:
      {
        name = db_user.name
        modules = db_user.helm_secret_config.cdr_modules

        connectionConfigSource = {
          source = "sscsi"
          secretName = replace(lower(db_user.name), "_", "-")
          secretArn = db_user.helm_secret_config.secretArn
        }
        connectionConfig = {
          authentication = {
            type = db_user.auth_type
          }
        }
      }
    ]
  }

  helm_config_external_db_old = {
    enabled = "true"
    credentials = {
      type = "sscsi"
      provider = "aws"
    }
    databases = [
      for db_user in module.postgres_db_user:
      {
        secretName = replace(lower(db_user.name), "_", "-")
        module = db_user.helm_secret_config.cdr_modules[0]
        secretArn = db_user.helm_secret_config.secretArn
      }
    ]
  }

  # IAM module expects map of objects
  scdr_role_policy_arns = merge(
    length(aws_iam_policy.get-secrets) > 0 ? { SmileCDR = aws_iam_policy.get-secrets[0].arn } : {},
    length(aws_iam_policy.s3-read) > 0 ? { S3ReadBuckets = aws_iam_policy.s3-read[0].arn } : {},
    length(aws_iam_policy.rds_iam_auth) > 0 ? { RDSIAMAuth = aws_iam_policy.rds_iam_auth[0].arn } : {}
  )

  # Lambda module expects list of policy arns
  lambda_role_policy_arns = concat(
    length(aws_iam_policy.get-secrets) > 0 ? [aws_iam_policy.get-secrets[0].arn] : [],
    length(aws_iam_policy.get-rds-meta) > 0 ? [aws_iam_policy.get-rds-meta[0].arn] : [],
    length(aws_iam_policy.rds_iam_auth) > 0 ? [aws_iam_policy.rds_iam_auth[0].arn] : [],
    length(aws_iam_policy.lambda_assume_self) > 0 ? [aws_iam_policy.lambda_assume_self[0].arn] : []
  )

  # We need to manually specify the Lambda role name to avoid circular dependencies. This is done
  lambda_function_name = "${local.name}-db-mgmt-${local.resourcenames_suffix}"
  lambda_role_name = local.lambda_function_name
  lambda_role_arn = "arn:aws:iam::${local.context.aws_caller_identity_account_id}:role/${local.lambda_role_name}"


  # RDS Networking

  default_db_subnet_ids = var.db_instance_defaults.db_subnet_ids
  default_db_subnet_group_name = var.db_instance_defaults.db_subnet_group_name == null ? null : lower(var.db_instance_defaults.db_subnet_group_name)

  all_db_subnets = flatten(concat(
    [
      for db_subnet_group in module.existing_db_subnet_groups:
        db_subnet_group.db_subnet_ids
    ],
    [
    for managed_database in module.managed_database:
        managed_database.db_subnet_ids
    ]))

  #   for db_instance in module.managed_database:
  #     db_instance.
  #     format("arn:aws:rds-db:%s:%s:dbuser:%s/%s",
  #       local.context.aws_region_name,
  #       local.context.aws_caller_identity_account_id,
  #       module.managed_database[lookup(db_user, "db_instance_name")].cluster_resource_id,
  #       db_user.dbusername)
  # ]


  ###################
  # S3
  ###################

  # Enable reading from S3 'staging' buckets, i.e. for CopyFiles functions
  s3_read_buckets_enabled = length(var.s3_read_buckets) > 0 ? true : false
  s3_write_buckets_enabled = length(var.s3_write_buckets) > 0 ? true : false

  s3_enabled = local.s3_read_buckets_enabled || local.s3_write_buckets_enabled

  s3_read_bucket_arns = concat([
      for bucket in var.s3_read_buckets:
        "arn:aws:s3:::${bucket}"
    ],
    [
      for bucket in var.s3_read_buckets:
        "arn:aws:s3:::${bucket}/*"
    ])

  # TODO:
  # FLesh this out when supporting the creation of the bucket with this Terraform module.
  # Tricky right now, as we need to provide a 'write' user for the bucket and i'm in a time-pinch.
  # copyfiles_bucket = var.create_copyfiles_bucket ? [] : []

  # s3_read_bucket_arns = concat(
  #   var.s3_read_bucket_arns,
  #   length(local.copyfiles_bucket) > 0 ? [local.copyfiles_bucket[0]] : [],
  # )

  ###################
  # Extra IAM Policies
  ###################

  # If arbritrary policies are required, they can be added using this
  extra_iam_policies = var.extra_iam_policies


  ###################
  # EKS & Network
  ###################

  # Cluster name always needs to be provided as it's used by the aws_eks_cluster data source to look up cluster info
  eks_cluster_name            = var.eks_cluster_name

  aws_eks_cluster_data_proxy = var.unit_testing ? var.mock_data_aws_eks_cluster : data.aws_eks_cluster.this[0]
  aws_iam_openid_connect_provider_data_proxy = var.unit_testing ? var.mock_data_aws_iam_openid_connect_provider : data.aws_iam_openid_connect_provider.this[0]

  eks_cluster_oidc_provider_url  = var.eks_cluster_oidc_provider_url == null ? local.aws_eks_cluster_data_proxy.identity[0].oidc[0].issuer : var.eks_cluster_oidc_provider_url
  eks_cluster_oidc_provider_arn  = var.eks_cluster_oidc_provider_arn == null ? local.aws_iam_openid_connect_provider_data_proxy.arn : var.eks_cluster_oidc_provider_arn
  eks_cluster_endpoint           = var.eks_cluster_endpoint == null ? local.aws_eks_cluster_data_proxy.endpoint : var.eks_cluster_endpoint
  eks_cluster_ca_certificate     = var.eks_cluster_ca_certificate == null ? local.aws_eks_cluster_data_proxy.certificate_authority[0].data : var.eks_cluster_ca_certificate
  eks_cluster_version            = var.eks_cluster_version == null ? local.aws_eks_cluster_data_proxy.version : var.eks_cluster_version
  eks_cluster_security_group_id  = var.eks_cluster_security_group_id == null ? local.aws_eks_cluster_data_proxy.vpc_config[0].cluster_security_group_id : var.eks_cluster_security_group_id

  # DB networking
  # Determine VPC id of EKS cluster for database provisioning
  db_vpc_id                      = var.db_vpc_id == null ? local.aws_eks_cluster_data_proxy.vpc_config[0].vpc_id : var.db_vpc_id

  # Lambda Networking

  # private_subnet_ids = var.private_subnet_ids
  # private_subnet_ids = local.create_rds_user_mgmt_lambda ? var.private_subnet_ids : []
  private_subnet_ids = local.create_rds_user_mgmt_lambda ? local.all_db_subnets : []

  lambda_security_group_id = local.create_rds_user_mgmt_lambda ? module.lambda_security_group[0].security_group_id : null
  lambda_security_group_ids = can(local.lambda_security_group_id) ? [local.lambda_security_group_id] : []

}
