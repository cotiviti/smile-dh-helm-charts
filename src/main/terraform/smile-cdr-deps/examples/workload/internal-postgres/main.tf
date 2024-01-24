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

  ########################################
  # Database configuration - Crunchy PGO #
  ########################################

  # If `db_instances` and `db_users` are left undefined, no RDS instances will be provisioned.
  # In this case, an in-cluster Postgres database will be provisioned using the Crunchy PGO operator.

}

output "environment_details" {
  value = {
    url = format("https://%s/", module.smile_cdr_dependencies.url)
  }
}
