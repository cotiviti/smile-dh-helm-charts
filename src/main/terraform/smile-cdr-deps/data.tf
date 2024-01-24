# IMPORTANT
# Each data source must have a proxy and a "mock_data" variable defined so that offline unit tests can be run
data "aws_eks_cluster" "this" {
  count = var.unit_testing ? 0:1
  name = local.eks_cluster_name
}

data "aws_iam_openid_connect_provider" "this" {
  count = var.unit_testing ? 0:1
  url = local.aws_eks_cluster_data_proxy.identity[0].oidc[0].issuer
}

data "aws_vpc" "db_vpc" {
  id = local.db_vpc_id
}

data "aws_route53_zone" "this" {
  count = var.ingress_config.public.route53_create_record ? 1 : 0
  name  = local.route53_zone_name
}

data "kubernetes_service" "ingress-nginx" {
  count = var.ingress_config.public.route53_create_record ? 1 : 0
  metadata {
    name = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }
}

data "aws_lb" "ingress-nginx" {
  count = var.ingress_config.public.route53_create_record ? 1 : 0
  name = local.ingress_nginx_lb_name
}

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
