provider "helm" {

  kubernetes {
    host                   = local.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(local.eks_cluster_ca_certificate)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", var.eks_cluster_name]
      command     = "aws"
    }
  }
}

resource "helm_release" "smilecdr" {
  count      = var.helm_deploy ? 1 : 0
  name       = local.helm_release_name
  namespace  = local.helm_namespace
  create_namespace = true

  repository = local.helm_repository
  chart      = local.helm_chart
  version    = local.helm_chart_version
  devel      = local.helm_chart_devel

  timeout    = 600

  max_history = 5

  values     = local.helm_chart_values

  dynamic "set" {
    for_each = local.helm_chart_values_set_overrides

    content {
      name  = set.key
      value = set.value
    }
  }
}
