# The following data and locals blocks are required to determine the ingress-nginx details.
# This is required in order to create DNS entries in Route 53, which needs to point to the
# Network Load balancer created by ingress-nginx.
data "kubernetes_service" "ingress-nginx" {
  metadata {
    name = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }
}

locals {
  ingress_nginx_lb_fqdn = try(data.kubernetes_service.ingress-nginx.status.0.load_balancer.0.ingress.0.hostname,"")
  ingress_nginx_lb_hostname = split(".", local.ingress_nginx_lb_fqdn)[0]
  ingress_nginx_lb_name = length(local.ingress_nginx_lb_hostname) > 32 ? substr(local.ingress_nginx_lb_hostname, 0, 32) : local.ingress_nginx_lb_hostname
}

data "aws_lb" "ingress-nginx" {
  name = local.ingress_nginx_lb_name
}

data "aws_route53_zone" "this" {
  name  = local.parent_domain
}
