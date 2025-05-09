locals {
    name = "myDeploymentName"
    eks_cluster_name = "MyClusterName"
    cdr_regcred_secret_arn = null
    # cdr_regcred_secret_arn = "arn:aws:secretsmanager:<region>:012345678910:secret:shared/regcred/my.registry.com/username"
    parent_domain = "example.com"
    # If you are not able to create Route53 DNS entries, then set to false
    # You will then need to create your DNS entry manually.
    route53_create_record = true
    region="us-east-1"
}

module "smile_cdr_dependencies" {
  source = "git::https://gitlab.com/smilecdr-public/smile-dh-helm-charts//src/main/terraform/smile-cdr-deps?ref=terraform-module"
  name = local.name
  eks_cluster_name = local.eks_cluster_name
  cdr_regcred_secret_arn = local.cdr_regcred_secret_arn
  prod_mode = false

  # You can leave this as null and it will use the latest version of the Helm Chart.
  # Ideally, you should specify the Helm Chart version that you require
  # helm_chart_version = "1.1.1"

  helm_chart_values = [
    file("helm/smilecdr/values.yaml"),
  ]

  ################################################################################
  # RDS Configuration
  ################################################################################
  #
  # With the following sections of configuration, the Smile CDR Dependencies
  # Terraform module will create a new RDS instance and configure Smile CDR to
  # connect to it automatically.

  #################################
  ## RDS Instances Configuration ##
  #
  # This module supports creation multiple RDS instances. The below configuration
  # creates a single Aurora Postgres Serverless V2 database cluster.
  #
  # By default, subnet selection is performed in the following order in descending priority
  #
  # * Use subnets provided by `db_subnet_ids`
  # * Use custom auto-discovery provided by `db_subnet_discovery_tags`
  # * Use auto-discovery using `Tier = Database`
  # * Use auto-discovery using `Tier = Private`
  # * Use auto-discovery using `Tier = Public`
  #
  # If no subnets are configured or  auto-discovered, the module will return an error.

  db_instances = [
    {
      name   = "myRDSClusterName"
      engine = "aurora-postgresql-serverless-v2"
      serverless_configuration = {
        min_capacity = 0.5
        max_capacity = 4
      }
      ## Use alternate subnet discovery tags like so:
      # db_subnet_discovery_tags = {
      #  TagName = "TagValue"
      # }

      ## Explicitly configure Databse subnets like so:
      # db_subnet_ids = [
      #   "subnet-0abc123",
      #   "subnet-0def456"
      # ]

      # TODO: Implement this later on.
      ## Using an externally provisioned RDS instance
      # externally_provisioned = true

    }
  ]

  #######################################
  ## RDS Database & User Configuration ##
  #
  # This section is used to auto-configure databases, users, credential secrets and
  # Smile CDR configuration to use the database.
  #
  # To follow best practices, each database should use separate connection credentials which
  # is easily achived by adding multiple entries in the `db_users` list below.
  #
  # Each entry should use the following schema:
  #
  # `name` - Friendly name used for resource naming. If `cdr_modules` is not provided, this should match the Smile CDR module name that will be using this database user.
  # `cdr_modules` - List of Smile CDR modules that should use this database user. Defaults to a single entry with the value of `name`.
  # `dbusername` - The database user name.
  # `dbname` - The database name.
  # `db_instance_name` - The database instance that this user must use. Must refer to a database instance defined in `db_instances`.
  # `auth_type` - The authentication method to configure (`password`, `iam` or `secretsmanager`). Default `password`.

  db_users = [
    {
      name                = "clustermgr"
      dbusername          = "clustermgr"
      dbname              = "clustermgr"
      db_instance_name    = "SmileCluster"
    }, {
      name                = "persistence"
      dbusername          = "persistence"
      dbname              = "persistence"
      db_instance_name    = "SmileCluster"
    }, {
      name                = "audit"
      dbusername          = "audit"
      dbname              = "audit"
      db_instance_name    = "SmileCluster"
    }, {
      name                = "transaction"
      dbusername          = "transaction"
      dbname              = "transaction"
      db_instance_name    = "SmileCluster"
    }
  ]

  ################################################################################
  # Ingress Configuration
  ################################################################################

  ingress_config = {
    public = {
      route53_create_record = local.route53_create_record
      parent_domain = local.parent_domain
    }
  }
}

output "helm_release_notes" {
  value = module.smile_cdr_dependencies.helm_release_notes
}
