locals {

  # Crunchy PGO
  #

  crunchy_pgo_enabled = try(var.crunchy_pgo_config.enabled, null) == null ? (length(var.db_users) == 0 ? true:false) : var.crunchy_pgo_config.enabled
  crunchy_pgo_backrest_enabled = local.crunchy_pgo_enabled && try(var.crunchy_pgo_config.pgbackrest.enabled, false)

  crunchy_pgo_backrest_s3_enabled = local.crunchy_pgo_backrest_enabled && var.crunchy_pgo_config.pgbackrest.s3.enabled
  crunchy_pgo_backrest_s3_create_bucket = try(var.crunchy_pgo_config.pgbackrest.s3.enabled,false) && !try(var.crunchy_pgo_config.pgbackrest.s3.use_existing_bucket,false)
  crunchy_pgo_backrest_s3_create_bucket_name = lower(coalesce(
    try("${var.crunchy_pgo_config.pgbackrest.s3.bucket_name_prefix}-${local.resourcenames_suffix}",null),
    var.crunchy_pgo_config.pgbackrest.s3.bucket_name,
    "${local.name}-pgbackrest-${local.resourcenames_suffix}"
  ))

  crunchy_pgo_backrest_s3_bucket_name = local.crunchy_pgo_backrest_s3_create_bucket ? local.crunchy_pgo_backrest_s3_create_bucket_name : var.crunchy_pgo_config.pgbackrest.s3.bucket_name

  crunchy_pgo_backrest_s3_bucket_arn = try(module.s3_bucket_pgo_backrest[0].s3_bucket_arn, data.aws_s3_bucket.s3_bucket_pgo_backrest[0].arn, null)
  crunchy_pgo_backrest_s3_region = try(module.s3_bucket_pgo_backrest[0].s3_bucket_region, data.aws_s3_bucket.s3_bucket_pgo_backrest[0].region, null)
  crunchy_pgo_backrest_s3_endpoint = try(module.s3_bucket_pgo_backrest[0].s3_bucket_bucket_regional_domain_name, data.aws_s3_bucket.s3_bucket_pgo_backrest[0].bucket_regional_domain_name, null)
  crunchy_pgo_backrest_s3_prefix = var.crunchy_pgo_config.pgbackrest.s3.bucket_prefix
  crunchy_pgo_backrest_s3_reponame = coalesce(var.crunchy_pgo_config.pgbackrest.s3.reponame,"repo${var.crunchy_pgo_config.pgbackrest.s3.reponumber}","repo1")

  crunchy_pgo_helm_config = local.crunchy_pgo_enabled && try(var.crunchy_pgo_config.helm_autoconf,false) ? {
    database = {
      crunchypgo = {
        enabled = "true"
        internal = "true"
        config = merge(
          {
            instanceReplicas = var.prod_mode ? 2 : 1
          },
          local.crunchy_pgo_backrest_helm_config
        )
      }
    }
  }:null

  crunchy_pgo_backrest_helm_config = local.crunchy_pgo_backrest_enabled ? merge(
    local.pgo_iam_role_enabled ? {
      metadata = {
        annotations = {
          "eks.amazonaws.com/role-arn" = local.pgo_iam_role_arn
        }
      }
    }:null,
    local.crunchy_pgo_backrest_s3_enabled ? {
      # This is not currently used by the Helm Chart, but may be
      # once we move away from the 'list' based approach.
      s3 = {
        repo      = local.crunchy_pgo_backrest_s3_reponame
        bucket    = local.crunchy_pgo_backrest_s3_bucket_name
        endpoint  = trimprefix(local.crunchy_pgo_backrest_s3_endpoint, "${local.crunchy_pgo_backrest_s3_bucket_name}.")
        region    = local.crunchy_pgo_backrest_s3_region
        prefix    = local.crunchy_pgo_backrest_s3_prefix
      }
    }:null,
    {
      pgBackRestConfig = merge(local.crunchy_pgo_backrest_global, local.crunchy_pgo_backrest_configuration, local.crunchy_pgo_backrest_repos, coalesce(local.crunchy_pgo_backrest_manual_s3, local.crunchy_pgo_backrest_manual_volume,{}))
    },
    local.crunchy_pgo_restore_configuration != null ? {
      restore = local.crunchy_pgo_restore_configuration
    }:null
  ):null

  crunchy_pgo_retention_settings = merge(
    local.crunchy_pgo_backrest_s3_enabled ? merge(
      try(
        {
          "${local.crunchy_pgo_backrest_s3_reponame}-retention-full" = try(tostring(var.crunchy_pgo_config.pgbackrest.s3.retention_full),null)
        },null
      ),
      try(
        {
          "${local.crunchy_pgo_backrest_s3_reponame}-retention-incremental" = try(tostring(var.crunchy_pgo_config.pgbackrest.s3.retention_incremental),null)
        },null
      ),
      try(
        {
          "${local.crunchy_pgo_backrest_s3_reponame}-retention-differential" = try(tostring(var.crunchy_pgo_config.pgbackrest.s3.retention_differential),null)
        },null
      )
    ):null,
    # repo1 global settings
    merge(
      try(var.crunchy_pgo_config.pgbackrest.volume.retention_full,null) != null ? {
          "repo1-retention-full" = tostring(var.crunchy_pgo_config.pgbackrest.volume.retention_full)
      } : null,
      try(var.crunchy_pgo_config.pgbackrest.volume.retention_incremental,null) != null ? {
          "repo1-retention-incremental" = tostring(var.crunchy_pgo_config.pgbackrest.volume.retention_incremental)
      } : null,
      try(var.crunchy_pgo_config.pgbackrest.volume.retention_differential,null) != null ? {
          "repo1-retention-differential" = tostring(var.crunchy_pgo_config.pgbackrest.volume.retention_differential)
      } : null
    )
  )

  crunchy_pgo_backrest_global = length(local.crunchy_pgo_retention_settings) > 0 ? {
    global = local.crunchy_pgo_retention_settings
   }:null

  crunchy_pgo_backrest_configuration = var.crunchy_pgo_config.pgbackrest.s3.enabled ? {
    configuration  = [
                {
                  secret = {
                    name = lower("${local.helm_release_name}-pgbackrest-secret")
                  }
                }
              ]
  }:{}

  crunchy_pgo_backrest_schedules  = try(var.crunchy_pgo_config.pgbackrest.schedules,null) != null ? {
    schedules = merge(
      try(var.crunchy_pgo_config.pgbackrest.schedules.full,null) != null ? {
        full    = var.crunchy_pgo_config.pgbackrest.schedules.full
      }:null,
      try(var.crunchy_pgo_config.pgbackrest.schedules.incremental,null) != null ? {
        incremental    = var.crunchy_pgo_config.pgbackrest.schedules.incremental
      }:null,
      try(var.crunchy_pgo_config.pgbackrest.schedules.differential,null) != null ? {
        differential    = var.crunchy_pgo_config.pgbackrest.schedules.differential
      }:null,
    )
  }:null

  crunchy_pgo_backrest_repos = merge(
    var.crunchy_pgo_config.pgbackrest.s3.enabled ? {
      repos = [
              merge({
                  name = coalesce(var.crunchy_pgo_config.pgbackrest.s3.reponame,"repo${var.crunchy_pgo_config.pgbackrest.s3.reponumber}","repo1")
                  s3   = {
                    bucket    = local.crunchy_pgo_backrest_s3_bucket_name
                    endpoint  = try(trimprefix(local.crunchy_pgo_backrest_s3_endpoint, "${local.crunchy_pgo_backrest_s3_bucket_name}."),null)
                    region    = local.crunchy_pgo_backrest_s3_region
                  }
                },
                local.crunchy_pgo_backrest_schedules
              )
            ]
    }:{},
    !var.crunchy_pgo_config.pgbackrest.s3.enabled ? {
      repos = [
              merge({
                  name = "repo1"
                  volume = {
                    volumeClaimSpec = {
                      accessModes = ["ReadWriteOnce"]
                      resources = {
                        requests = {
                          storage = try(var.crunchy_pgo_config.pgbackrest.volume.backupsSize,"1Gi")
                        }
                      }
                    }
                  }
                },
                local.crunchy_pgo_backrest_schedules
              )
            ]
    }:{}
  )

  crunchy_pgo_backrest_manual_s3 = var.crunchy_pgo_config.pgbackrest.s3.enabled && (var.crunchy_pgo_config.pgbackrest.s3.manual_backup != null) ? {
    manual  = {
      repoName = local.crunchy_pgo_backrest_s3_reponame
      options = [
          "--type=${var.crunchy_pgo_config.pgbackrest.s3.manual_backup}"
      ]
    }
  }:null

  crunchy_pgo_backrest_manual_volume = (try(var.crunchy_pgo_config.pgbackrest.volume.manual_backup,null) != null) ? {
    manual  = {
      repoName = "repo1"
      options = [
          "--type=${var.crunchy_pgo_config.pgbackrest.volume.manual_backup}"
      ]
    }
  }:null

  crunchy_pgo_restore_configuration = var.crunchy_pgo_config.restore != null ? {
    enabled = try(var.crunchy_pgo_config.restore.enabled,false)
    repoName = var.crunchy_pgo_config.restore.source == "s3" ? local.crunchy_pgo_backrest_s3_reponame : "repo1"
    options = [
        "--type=${try(var.crunchy_pgo_config.restore.type,"time")}",
        "--target=\"${try(var.crunchy_pgo_config.restore.restore_time,"")}\""
    ]
  }:null

  pgo_instance_sa_name = "${local.helm_release_name}-pg-instance"
  pgo_pgbackrest_sa_name = "${local.helm_release_name}-pg-pgbackrest"
  pgo_namespace_service_accounts = [
      "${local.helm_namespace}:${local.pgo_instance_sa_name}",
      "${local.helm_namespace}:${local.pgo_pgbackrest_sa_name}"
    ]

  # IAM for Crunchy PGO S3 backups
  # Enable if:
  # * Using Crunchy PGO
  # * Using S3 for backup
  #
  # IRSA has to be used in this case, or error. We are not providing long lived credentials for this.
  pgo_iam_role_enabled = local.crunchy_pgo_enabled && try(var.crunchy_pgo_config.pgbackrest.s3.enabled, false)
  pgo_iam_role = try(module.pgo_irsa_role[0], null)
  pgo_iam_role_arn = try(local.pgo_iam_role.iam_role_arn, null)
  pgo_irsa_role_name = "${local.name}-crunchypgo-${local.resourcenames_suffix}"

}
