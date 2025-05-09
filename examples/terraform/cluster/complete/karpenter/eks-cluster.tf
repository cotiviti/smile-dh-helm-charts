################################################################################
# EKS Cluster
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.29.0"

  cluster_name    = local.name
  cluster_version = "1.31"

  enable_cluster_creator_admin_permissions = true
  cluster_endpoint_public_access           = true

  cluster_addons = {
    coredns = {
      configuration_values = jsonencode(merge(
        local.core_node_group_assignment,
        {
          replicaCount = 1
        }
        ))
    }

    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  vpc_id     = local.vpc_id
  subnet_ids = local.cluster_subnet_ids

  # authentication_mode = "API"

  eks_managed_node_groups = {
    core_node_group = {
      name           = "${local.name}-core"
      ami_type       = "BOTTLEROCKET_x86_64"
      instance_types = ["m5.large"]

      min_size     = 1
      max_size     = 3
      desired_size = 1

      labels = {
        # Used to ensure Karpenter runs on nodes that it does not manage
        "karpenter.sh/controller" = "true"
      }

      taints = {
        # The pods that do not tolerate this taint should run on nodes
        # created by Karpenter
        karpenter = {
          key    = "karpenter.sh/controller"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }

  tags = merge(local.tags, {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "karpenter.sh/discovery" = local.name
  })
}

################################################################################
# EKS Specific Locals
################################################################################

locals {
  # provider::aws::arn_parse gives an error about missing newlines...
  # core_node_group_name = provider::aws::arn_parse("${module.eks.eks_managed_node_groups.core_node_group.node_group_arn}")

  core_node_group_name = split(":", module.eks.eks_managed_node_groups.core_node_group.node_group_id)[1]
  core_node_group_assignment = {
    tolerations = [
      # Allow addon to run on the same nodes as the Karpenter controller
      # for use during cluster creation when Karpenter nodes do not yet exist
      {
        key    = "karpenter.sh/controller"
        value  = "true"
        effect = "NoSchedule"
      }
    ],
    affinity = {
      # Force addon to run on the same nodes as the Karpenter controller
      # for making better use of core node group resources rather than deploying
      # new instances for these services
      nodeAffinity = {
        requiredDuringSchedulingIgnoredDuringExecution = {
          nodeSelectorTerms = [
            {
              matchExpressions = [
                {
                  key      = "eks.amazonaws.com/nodegroup"
                  operator = "In"
                  values = [
                    local.core_node_group_name
                  ]
                }
              ]
            }
          ]
        }
      }
    }
  }
}
