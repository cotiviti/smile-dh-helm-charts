################################################################################
# Strimzi Kafka Operator
################################################################################

module "eks_blueprints_addon_strimzi" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "~> 1.1.1"

  chart            = "strimzi-kafka-operator"
  chart_version    = "0.39.0"
  repository       = "oci://quay.io/strimzi-helm/"
  description      = "The Strimzi Operator for installing Kafka in-cluster"
  namespace        = "strimzi"
  create_namespace = true

  tags = local.tags

  values = [yamlencode(
    merge(
      local.core_node_group_assignment,
      {
        watchAnyNamespace = true,
        featureGates = "+UnidirectionalTopicOperator"
      }
    )
  )]
}
