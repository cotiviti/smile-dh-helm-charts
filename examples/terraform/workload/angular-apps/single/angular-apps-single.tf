# Rename the module to suit your application name
module "my_app_nginx_helm" {
  source = "aws-ia/eks-blueprints-addon/aws"
  version = "~> 1.1.1"

  chart            = "nginx"
  repository       = "oci://registry-1.docker.io/bitnamicharts/"
  chart_version    = "15.12.2" 

  # Change these for your app
  name              = "my-app"

  # By default uses the same namespace as Smile CDR. You can change it if required
  namespace         = lower(local.name)

  values            = [local.bitnami_values]

  set = [
    
    # Update the below settings so that the app can be retrieved from the container registry
    {
      name = "image.registry"
      value = "my-app-container-registry" // e.g. for ECR: <aws-account-id>.dkr.ecr.<aws-region>.amazonaws.com
    },
    {
      name = "image.repository"
      value = "my-app-container-repo"
    },
    {
      name = "image.tag"
      value = "latest" // Update to appropriate image tag for your application
    },
    {
      name = "image.pullPolicy"
      value = "Always"
    },

    # Ingress will be auto configured below
    {
      name = "ingress.hostname"
      value = "${local.bitnami_app_name}.${local.parent_domain}"
    },
    # Configure ingress to use nginx ingress
    {
      name = "ingress.enabled"
      value = "true"
    },
    {
      name = "ingress.ingressClassName"
      value = "nginx"
    },
    {
      name = "ingress.path"
      value = "/"
    },
    {
      name = "service.type"
      value = "ClusterIP"
    },
  ]
}

# Configure your application configuration usinbg these locals
locals {
  # This is where you can provide configuration details for the Angular App.
  # Anything set in `bitnami_app_config` will end up being deployed in the nginx container at the
  # following configurable location:
  # `/app/config/config.json`
  bitnami_app_name = "my-app"
  bitnami_app_config = {
    # Example config using the Angular Apps domain name
    frontendUrl =  "https://${local.bitnami_app_name}.${local.parent_domain}",
    # Example configs using the backend Smile CDR domain name
    backendUrl = "https://${local.name}.${local.parent_domain}/fhir_request",
    issuerUrl = "https://${local.name}.${local.parent_domain}/smartauth",
    # Manually set any other required configurations...
    clientId = "my-client-id"
  }

  # If required, the config file location can be updated here:
  bitnami_app_config_path = "/app/config/"
  bitnami_app_config_file = "config.json"
}

# The following locals block does not need to be updated.
# It helps auto-generate the appropriate yaml values to pass in to the Helm Chart for
# configuring the Angular app.
locals {
  bitnami_extra_deploy = [
    {
      apiVersion = "v1"
      kind = "ConfigMap"
      metadata = {
        name = "${local.bitnami_app_name}-siteconfig"
      }
        
      data = {
        config_json = jsonencode(local.bitnami_app_config)
      }
    }   
  ]
  bitnami_extra_volumes = [
    {
      name =  "appconfig"
      configMap = {
        name: "${local.bitnami_app_name}-siteconfig"
      }
    }

  ]
  bitnami_extra_volume_mounts = [
    {
      mountPath = "${local.bitnami_app_config_path}/${local.bitnami_app_config_file}"
      name = "appconfig"
      subPath = "config_json"
    }
  ]

  bitnami_values = yamlencode({
    extraDeploy = local.bitnami_extra_deploy
    extraVolumes = local.bitnami_extra_volumes
    extraVolumeMounts = local.bitnami_extra_volume_mounts
  })
}


# The following data and locals blocks are required to determine the ingress-nginx details.
# This is required in order to create the DNS entry in Route 53, which needs to point to the
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

resource "aws_route53_record" "my_app_dns_recordg" {
  zone_id = data.aws_route53_zone.this.zone_id

  name          = "my-app.${local.parent_domain}"
  type          = "A"
  alias {
      name                   = data.aws_lb.ingress-nginx.dns_name
      zone_id                = data.aws_lb.ingress-nginx.zone_id
      evaluate_target_health = false
  }
}
