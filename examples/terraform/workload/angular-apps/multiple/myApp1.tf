# Rename the module to suit your application name
module "my_app_1_nginx_helm" {
  source = "aws-ia/eks-blueprints-addon/aws"
  version = "~> 1.1.1"

  chart            = "nginx"
  repository       = "oci://registry-1.docker.io/bitnamicharts/"
  chart_version    = "15.12.2" 

  # Change these for your app
  name              = "my-app1"

  # By default uses the same namespace as Smile CDR. You can change it if required
  namespace         = lower(local.name)

  values            = [
    file("helm/bitnami-nginx/global-default-values.yaml"),
    file("helm/bitnami-nginx/my-app1-values.yaml")
  ]

  set = [
    
    # Update the below settings so that the app can be retrieved from the container registry
    {
      name = "image.registry"
      value = "my-app1-container-registry" // e.g. for ECR: <aws-account-id>.dkr.ecr.<aws-region>.amazonaws.com
    },
    {
      name = "image.repository"
      value = "my-app1-container-repo"
    },
    {
      name = "image.tag"
      value = "latest" // Update to appropriate image tag for your application
    },
    {
      name = "image.pullPolicy"
      value = "Always"
    },
    # Configure hostname.
    {
      name = "ingress.hostname"
      value = "my-app1.${local.parent_domain}"
    }
  ]
}

# Update the hostname here to match `ingress.hostname` above
resource "aws_route53_record" "my_app1_dns_record" {
  zone_id = data.aws_route53_zone.this.zone_id

  name          = "my-app1.${local.parent_domain}"
  type          = "A"
  alias {
      name                   = data.aws_lb.ingress-nginx.dns_name
      zone_id                = data.aws_lb.ingress-nginx.zone_id
      evaluate_target_health = false
  }
}