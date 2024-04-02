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

# Helm Template resource used for rendering chart notes as the helm_release resource does not support it.
data "helm_template" "smilecdr" {
  count      = var.helm_deploy ? 1 : 0
  name       = local.helm_release_name
  namespace  = local.helm_namespace

  repository = local.helm_repository
  chart      = local.helm_chart
  version    = local.helm_chart_version
  devel      = local.helm_chart_devel

  values     = local.helm_chart_values

  dynamic "set" {
    for_each = local.helm_chart_values_set_overrides

    content {
      name  = set.key
      value = set.value
    }
  }
}
