################################################################################
# EKS Blueprints Addons
################################################################################

# Due to dependency issues, these EKS Blueprint Addons need to be created and destroyed sequentially
# In order to do this, they must be defined in separate EKS Blueprints Addons modules
#
# Some problems that arise if they are all bundled together
#
# 1. Deleting Karpenter before deleting addons that use compute that was provisioned by Karpenter
#    In this case, destroying the Karpenter addon may fail as it cannot delete nodes, nodeclaims,
#    nodepools and EKSNodeClasses as those resources are still in use. If this happens, the cluster
#    may be left in a broken and inconsistent state that can be very hard to recover from.
#
# 2. Deleting the AWS Load Balancer Controller addon before deleting any ingress objects
#    For example, deleting it before deleting the nginx-ingress controller will result in dangling
#    AWS Load Balancer resources that need to be cleaned up manually. This increases management
#    overhead and potentially increases costs as AWS resources are left unused.
#
#    The same applies if any applications have been installed that use the AWS Load Balancer Controller
#    to provision load balancers.
#
# As a result of the above, the cluster must be destroyed in a very controlled manner:
#
# 1. Destroy any applications or operators installed on the cluster
# 2. Destroy any ingress addons (terraform destroy -target module.eks_blueprints_addons_ingress)
# 4. Destroy the core EKS Blueprint Addons (terraform destroy -target module.eks_blueprints_addons_core)

module "eks_blueprints_addons_core" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.19"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  eks_addons = {
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
      preserve                 = false

      # The aws-ebs-csi-driver is configured a little differently to the core-dns addon. See:
      # https://stackoverflow.com/questions/78932976/how-do-i-configure-the-terraform-aws-eks-addon-aws-ebs-csi-driver-volumeattachli
      configuration_values = jsonencode({
        controller = merge(
          local.core_node_group_assignment,
          {
            replicaCount = 1
        })
      })
    }
  }

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    values = [yamlencode(
      merge(
        local.core_node_group_assignment,
        {
          replicaCount = 1
          region       = local.region
          vpcId        = local.vpc_id
          # Disabling this webhook as it can cause race conditions when creating the Cert Manager
          enableServiceMutatorWebhook = false
      })
    )]
  }

  enable_secrets_store_csi_driver = true
  secrets_store_csi_driver = {
    values = [yamlencode(
      {
        syncSecret = {
          enabled = true
        }
        
        enableSecretRotation = true
        
        linux = {
          # This should probably be set as a default, as it's a Daemonset that is required on all nodes.
          # https://kubernetes.io/docs/tasks/administer-cluster/guaranteed-scheduling-critical-addon-pods/
          priorityClassName = "system-node-critical"
        }
      }
    )]
  }

  enable_secrets_store_csi_driver_provider_aws = true
  secrets_store_csi_driver_provider_aws = {
    values = [yamlencode(
      {
         tolerations = [
          {
            operator = "Exists"
          }
         ]
      }
    )]
  }

  enable_metrics_server = true
  metrics_server = {
    values = [yamlencode(
      merge(
        local.core_node_group_assignment,
        {
          replicaCount = 1
      })
    )]
  }

  tags = local.tags
}

# These addons need to be provisioned separately from the Karpenter addon. While bringing the
# cluster UP will work with them being in the same module, destroying the cluster may fail due
# to Karpenter being unable to clean up K8s resources while pods are still running on provisioned
# compute resources


# Ingress needs to be provisioned after the AWS Load Balancer Controller to
# Avoid dangling ALB resources during destroy.
module "eks_blueprints_addons_ingress" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.19"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # We want to wait for the ALB to be deployed first
  create_delay_dependencies = [module.eks_blueprints_addons_core.aws_load_balancer_controller.chart]

  eks_addons = {}

  enable_ingress_nginx = local.enable_nginx_ingress
  ingress_nginx = {
    values = [
      file("${path.module}/helm/ingress-nginx/values.yaml"),
      yamlencode({
        controller = merge(
          local.core_node_group_assignment,
          {
            service = {
              annotations = local.nginx_service_extra_annotations
            }
          },
        )
      })

    ]
  }

  enable_cert_manager = true
  cert_manager = {
    chart_version = "v1.16.1"
    values = [yamlencode(
      merge(
        local.core_node_group_assignment,
        {
          cainjector      = local.core_node_group_assignment,
          startupapicheck = local.core_node_group_assignment,
          webhook         = local.core_node_group_assignment,
        },
        {
          replicaCount              = 1
          enableCertificateOwnerRef = true
      })
    )]
  }

  # This causes the DAG to explode. Planning takes many minutes, so do not uncomment this.
  # depends_on = [ module.eks_blueprints_addons_core ]

  tags = local.tags
}

################################################################################
# EKS Blueprint Addons related Locals
################################################################################
#
#

locals {

  nginx_tls_annotations = local.nginx_ingress.enable_tls ? {
    "service.beta.kubernetes.io/aws-load-balancer-ssl-cert"               = local.nginx_ingress.acm_cert_arn
    "service.beta.kubernetes.io/aws-load-balancer-ssl-negotiation-policy" = "ELBSecurityPolicy-TLS-1-1-2017-01"
    "service.beta.kubernetes.io/aws-load-balancer-ssl-ports"              = "https"
  } : {}

  nginx_annotations = {
    "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
  }

  nginx_service_extra_annotations = merge(
    local.nginx_tls_annotations,
    local.nginx_annotations
  )

}
