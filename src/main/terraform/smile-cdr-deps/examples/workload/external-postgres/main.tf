module "smile_cdr_dependencies" {
  source = "../../../"

  # This template is for creating Smile CDR environments in an EKS cluster.
  # For it to function correctly, the EKS cluster must include all dependencies, as described
  # in the `bootstrap` section of these examples.
  #
  # At a bare minimum, you only need to provide a new 'name' for your environment.
  # This will result in a new default Smile CDR install, available at https://<name>.example.com/
  #
  # For further details on how to configure a Smile CDR environment using the Smile CDR Helm Charts and
  # this sibling Terraform module, please refer to the documentation here:
  #  https://smilecdr-public.gitlab.io/smile-dh-helm-charts

  ################
  ### REQUIRED ###
  ################

  # Provide general settings for the environment you are building
  name = "myAppName"

  ################
  ### Optional ###
  ################

  # The auto-configured Kubernetes namespacewill be a lower-cased version of 'name' above, unless specified differently below
  # namespace = "myNamespace"

  ### Helm Configuration ###

  # These settings are not required to install Smile CDR, but will be needed in order to configure it
  # from the Terraform module

  helm_chart_values = [
    "${file("environment-values.yaml")}"
  ]

  # You can add individual overrides below. These will override any auto-generated values
  # as well as values defined in the provided values files.
  # helm_chart_values_set_overrides = {
  #   "path.to.override" = "string value"
  # }

  # This sets (or disables) some sensible defaults for production environments, such
  # as the number of replicas for various components. Enabled by default
  prod_mode = false

  # Deploy SmileCDR Helm Chart from Terraform. Enabled by default
  # helm_deploy = false

  # If you choose not to deploy directly from this module, you should use the Helm Values
  # output to provide the settings that should be included in your Helm Valiues file like so:
  # This will be the merged end-result from any Helm Chart values or overides that were passed in above.
  # This is disabled by default.
  # return_helm_values = true

  ################
  ## EKS Config ##
  ################

  # Everything below is using curated defaults specifically for the Sales Demo EKS cluster and do not
  # need to be altered unless special requirements deem it necessary.

  # ID & region for the EKS cluster to install to
  # This will be used to auto-discover various required EKS cluster attributes
  eks_cluster_name = "myClusterId"
  aws_region = "us-east-1"

  ##########################
  # IAM/IRSA Configuration #
  ##########################

  # This module will automatically create appropriate IAM roles, trust policies and
  # policy documents to access any required AWS services.
  # This is automatically enabled if any of the following are enabled:
  # * Secrets management
  # * RDS user management
  # * S3 bucket for file staging
  #
  # It can be explicitly enabled/disabled below if required
  # enable_irsa = false

  #########################
  # Secrets Configuration #
  #########################

  # Secrets KMS key settings
  # Use existing KMS key ARN for secrets. If not specified, one will be created automatically.
  # secrets_kms_key_arn = "secretKmsArn"
  # kms_deletion_window = 7

  # By default, this module will create an empty Secrets Manager Secret for the container registry credentials
  # After applying this Terraform, you must populate the secret with the appropriate credentials.
  #
  # Alternatively, if you already have a secret that you wish to use, you can disable the automatic secret generation
  # and use the existing secret by specifying the ARN and KMS key like so.

  # cdr_regcred_secret_arn = "arn:aws:secretsmanager:us-east-1:012345678910:secret:sharedRegcredSecret"

  # If the shared secret uses a custom KMS key, the ARN of the KMS key MUST be provided.
  # cdr_regcred_secret_kms_arn = "arn:aws:kms:us-east-1:012345678910:key/xxxx-yyyy-zzzz"

  # If you are using ECR, then you can disable the registry credentials secret functionality completely like so:
  # enable_cdr_regcred_secret = false

  # License secret

  # A license secret is not enabled by default and must be enabled if required.
  # enable_cdr_license_secret = true

  # If enabled, in a similar way to the Registry Credentials Secret, you can let it automatically create a new (empty) secret,
  # or specify the ARN for an existing one
  # cdr_license_secret_arn = "arn:aws:secretsmanager:us-east-1:012345678910:secret:my-cdr-license-secret"
  # cdr_license_secret_kms_arn = "arn:aws:kms:us-east-1:012345678910:key/xxxx-yyyy-zzzz"

  #########################
  # Ingress Configuration #
  #########################
  ingress_config = {
    public = {
      # Provide hostname for public endpoints. Will default to the main name provided to this module.
      # You can provide just a host name or an FQDN here.
      # hostname = "myCustomHostname"

      # Must provide parent domain if not specified in hostname (i.e. if hostname is auto-configured)
      parent_domain = "example.com"

      # Route53 is enabled by default. Disable like so:
      # route53_create_record = false
      # TODO: Maybe remove this as it seems redundant
      # The Route53 zone name is the same as the parent_domain.
      # It can be overridden like so (Not sure why you would want this, or if it will work):
      # route53_zone_name = "some.other.zone.name"
    }
  }

  ###########################################
  # Database configuration - External (RDS) #
  ###########################################

  # Networking info required for configuring database security groups
  # These configurations are auto-detected if the current aws cli session has access to the AWS API

  # db_vpc_id = "myvpc_id"
  # eks_cluster_security_group_id = "myNodeSGs"
  # db_subnet_ids = ["my_db_subnet_id-1","my_db_subnet_id-2"]
  # db_subnet_group_name = "test"

  # Enable automatic managment of RDS DB credentials. Enabled by default.
  # enable_cdr_rds_secrets = false

  # Defaults for RDS Database instances
  db_instance_defaults = {
    # engine = "aurora-postgresql-serverless-v2"

    # DB Subnets will be auto-discovered.

    # You can configure the auto-discovery mechanism using subnet tags like so:
    # db_subnet_discovery_tags = {
    #   Tier = "Database"
    # }

    # To disable auto-discovery, use the following:
    # db_subnet_discovery_enabled = false

    # If auto-discovery is disabled, or if no suitable subnets are discovered, you can explicitly define the subnets
    # db_subnet_ids = ["my_db_subnet_id-1","my_db_subnet_id-2"]

    # You can override db subnet group name that is created using any auto-discovered or provided subnets like this:
    # db_subnet_group_name = "temp"

    # If no subnets are defined, then this must be an existing DB Subnet Group, or the module will fail.

    # Autocreate databases (experimental)
    # Auto create and configure databases for the specified Smile CDR modules
    # autocreate_databases = {
    #   modules = [
    #     "clustermgr",
    #     "persistence",
    #     "audit",
    #     "transaction",
    #   ]
    #   defaults = {
    #     db_username_suffix = "-dbsuffix"
    #     db_name_suffix = "-dbsuffix"
    #   }
    # }
  }

  # This will create a managed databases (or databases) depending on the provided configuration
  db_instances = [
    {
      # Create a map item for each DB instance that should be created
      # Any attributes in db_instance_defaults can be overriden here

      # This is the only required attribute
      name = "smilecdr"

      # Enable public access to this RDS instance and restrict access to specific CIDR ranges
      # publicly_accessible = true
      # public_cidr_blocks = ["1.2.3.4/32"]

      # By default an AWS Secrets Manager secret will be created
      # You can use IAM auth instead like so:
      # default_auth_type = "iam"
    }
  ]

  # Users and databases configured here will automatically be created in the database
  # If none are defined, the Helm Configuration will fall-back to provisioning an in-cluster database
  # using CrunchyPGO
  db_users = [
    {
      # This should match the module name being used in the Helm Chart configuration
      name = "clustermgr"

      # You may override the module(s) that this DB connection will be used for
      # cdr_modules = [
      #   "clustermgr",
      #   "persistence"
      # ]

      # Defaults to same as 'name'
      dbusername = "cdr-clustemgr"
      # Defaults to same as 'name'
      dbname = "clustermgr"
      db_instance_name = "smilecdr"

      # Optional
      # force_secret_update = false
      # auth_type = "iam"
    },
    # Repeat for each database/module
    {
      name = "persistence"
      dbusername = "cdr-persistence"
      dbname = "persistence"
      db_instance_name = "smilecdr"
    },
    {
      name = "audit"
      dbusername = "cdr-auditdb"
      dbname = "audit"
      db_instance_name = "smilecdr"
    },
    {
      name = "transaction"
      dbusername = "cdr-txdb"
      dbname = "transaction"
      db_instance_name = "smilecdr"
    },
  ]
}

output "environment_details" {
  value = {
    url = format("https://%s/", module.smile_cdr_dependencies.url)
  }
}
