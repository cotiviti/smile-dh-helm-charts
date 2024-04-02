module "eks_blueprints_addon_crunchypgo" {
  source = "aws-ia/eks-blueprints-addon/aws"
  version = "~> 1.1.1"

  chart            = "pgo"
  chart_version    = "5.5.0"
  repository       = "oci://registry.developers.crunchydata.com/crunchydata"
  description      = "The CrunchyData Postgres Operator for installing in-cluster Postgres database instances"
  namespace        = "pgo"
  create_namespace = true

  tags = local.tags

  depends_on = [
    module.eks_blueprints_addon_karpenter_provisioner_config
  ] 
}