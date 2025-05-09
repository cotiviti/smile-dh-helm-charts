################################################################################
# CrunchyData Postgres Operator (PGO)
################################################################################

module "eks_blueprints_addon_crunchypgo" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "~> 1.1.1"

  name             = "pgo"
  #   chart_version    = "5.5.0"
  #   repository       = "oci://registry.developers.crunchydata.com/crunchydata"
  #   description      = "The CrunchyData Postgres Operator for installing in-cluster Postgres database instances"
  # Unfortunately the official chart does not support affinity or tolerations. To circumvent this, we use a local
  # copy of the Helm Chart.
  # This is a temporary measure as we will eventually be switching to the CloudNativePG Postgres Operator.
  chart            = "./helm/crunchydata/pgo"
  description      = "Modified CrunchyData Postgres Operator for installing in-cluster Postgres database instances"
  namespace        = "pgo"
  create_namespace = true

  tags = local.tags

  values = [yamlencode(
    merge(
      local.core_node_group_assignment,
      {}
    )
  )]
}
