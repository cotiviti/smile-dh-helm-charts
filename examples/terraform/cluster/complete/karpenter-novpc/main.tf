# These are the local variables you NEED to set.
locals {
  name   = "MyClusterName"
  region = "us-west-2"
  vpc_id = "vpc-064b63b6d921d75d1"
  
  # Provide subnet discovery tag or override by providing subnet ids
  subnet_discovery_tags = {
    Tier = "Private"
  }
  subnet_ids = ["subnet-0e1d2b89ae0380cf9","subnet-00061dc2db7596621"]
  # subnet_ids = ["subnet-0abc123","subnet-0def456"]
  acm_cert_arn = "arn:aws:acm:us-east-1:012345678910:certificate/xxxx-yyyy-zzzz"
}

################################################################################
# Cluster
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.21.0"

  cluster_name                   = local.name
  cluster_version                = "1.28"
  cluster_endpoint_public_access = true

  vpc_id     = local.vpc_id
  subnet_ids = local.cluster_subnet_ids

  manage_aws_auth_configmap = true
  aws_auth_roles = [
    # We need to add in the Karpenter node IAM role for nodes launched by Karpenter
    {
      rolearn  = module.eks_blueprints_addons_core.karpenter.node_iam_role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
        "system:bootstrappers",
        "system:nodes",
      ]
    },
  ]

  eks_managed_node_groups = {
    core_node_group = {
      instance_types = ["m5.large"]

      ami_type = "BOTTLEROCKET_x86_64"
      platform = "bottlerocket"

      min_size     = 1
      max_size     = 2
      desired_size = 1
    }
  }

  tags = merge(local.tags, {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "karpenter.sh/discovery" = local.name
  })
}

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
  version = "~> 1.11"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  eks_addons = {
    coredns = {}
    vpc-cni    = {}
    kube-proxy = {}
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
    }

  }

  enable_karpenter = true
  karpenter_node = {
    # Use static name so that it matches what is defined in `karpenter.yaml` example manifest
    iam_role_use_name_prefix = false
  }

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    set = [
      {
        name  = "vpcId"
        value = local.vpc_id
      },
      {
        name  = "region"
        value = local.region
      },
    ]
  }

  enable_secrets_store_csi_driver = true
  secrets_store_csi_driver = {
    values  = [yamlencode(
      {
        syncSecret = {
          enabled = true
        }
        linux = {
          # This should probably be set as a default, as it's a Daemonset that is required on all nodes.
          # https://kubernetes.io/docs/tasks/administer-cluster/guaranteed-scheduling-critical-addon-pods/
          priorityClassName = "system-node-critical"
        }
      }
    )]
  }
  enable_secrets_store_csi_driver_provider_aws = true

  enable_cert_manager = true

  enable_metrics_server = true

  tags = local.tags
}

module "eks_blueprints_addon_karpenter_provisioner_config" {
  source = "aws-ia/eks-blueprints-addon/aws"
  version = "~> 1.1.1"

  name             = "karpenter-config"
  chart            = "./helm/karpenter-config"
  description      = "Provides provisioner configurations for Karpenter"
  namespace        = module.eks_blueprints_addons_core.karpenter.namespace
  create_namespace = false

  values = [yamlencode(
      {
        karpenterIamRole = module.eks_blueprints_addons_core.karpenter.node_iam_role_name
        clusterName = local.name
        azs = local.azs
      }
    )
  ]

  depends_on = [ module.eks_blueprints_addons_core ]

  tags = local.tags
}


# Required for the EBS CSI driver to be able to provision volumes
module "ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.33"

  role_name_prefix = format("%s-ebs-csi-driver-", substr(local.name,0,38 - 16))

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = local.tags
}

# These addons need to be provisioned separately from the Karpenter addon. While bringing the
# cluster UP will work with them being in the same module, destroying the cluster may fail due
# to Karpenter being unable to clean up K8s resources while pods are still running on provisioned
# compute resources

# module "eks_blueprints_addons_components" {

# }

# Ingress needs to be provisioned after the AWS Load Balancer Controller to
# Avoid dangling ALB resources during destroy.
module "eks_blueprints_addons_ingress" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.11"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # We want to wait for the ALB to be deployed first
  create_delay_dependencies = [module.eks_blueprints_addons_core.aws_load_balancer_controller.chart]

  eks_addons = {}

  enable_ingress_nginx = true
  ingress_nginx = {
    values      = [file("${path.module}/helm/ingress-nginx/values.yaml")]
    set = [
      # Set a pre-existing wildcard ACM certificate
      {
        name = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-cert"
        value = local.acm_cert_arn
      }
    ]
  }

  # depends_on = [
  #   module.eks_blueprints_addons_core
  # ] 

  tags = local.tags
}

################################################################################
# EBS Storage Classes
################################################################################

# Set the existing in-tree gp2 storage class to not be the default
resource "kubernetes_annotations" "gp2_default" {
  annotations = {
    "storageclass.kubernetes.io/is-default-class" : "false"
    "replaced-with" : module.eks_blueprints_addons_core.eks_addons.aws-ebs-csi-driver.addon_name
  }
  api_version = "storage.k8s.io/v1"
  kind        = "StorageClass"
  metadata {
    name = "gp2"
  }

  force = true

  # depends_on = [module.eks_blueprints_addons_core]
}

# Default storage class (encrypted)
resource "kubernetes_storage_class_v1" "ebs_csi_encrypted_gp3_storage_class" {
  metadata {
    name = "gp3-encrypted"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" : "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"
  parameters = {
    type      = "gp3"
    encrypted = true
    # kmsKeyId  = aws_kms_key.ebs_key.key_id
  }
  # depends_on = [kubernetes_annotations.gp2_default]
}

################################################################################
# Data Sources
################################################################################

provider "aws" {
  region = local.region
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

data "aws_availability_zones" "available" {}

data "aws_vpc" "vpc" {
  id = local.vpc_id
}

data "aws_subnets" "tagged" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }
  tags = coalesce(local.subnet_discovery_tags, {Tier="Private"})
}

data "aws_subnet" "existing" {
  for_each = toset(local.cluster_subnet_ids)
    id = each.value
}

output "debug_output" {
  description = "Various object outputs for debugging purposes"
  value = {
    dbvpcdetails = data.aws_vpc.vpc
    subnets = local.cluster_subnet_ids
    azs = local.azs
  }
}

locals {
  
  cluster_subnet_ids = coalesce(local.subnet_ids, data.aws_subnets.tagged.ids)
  azs = [
    for subnet in data.aws_subnet.existing:
      subnet.availability_zone
  ]
  
  tags = {
    EnvironmentName = local.name
    CreatedBy = "CloudFactory-tf"
    GitlabRepo = "gitlab.com/smilecdr-public/smile-dh-helm-charts"
  }
}