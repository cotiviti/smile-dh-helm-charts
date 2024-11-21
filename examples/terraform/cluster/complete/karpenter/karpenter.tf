locals {
  namespace = "karpenter"
}

################################################################################
# Controller & Node IAM roles, SQS Queue, Eventbridge Rules
################################################################################

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.24"

  cluster_name          = module.eks.cluster_name
  enable_v1_permissions = true
  namespace             = local.namespace

  # Name needs to match role name passed to the EC2NodeClass
#   node_iam_role_use_name_prefix   = false
#   node_iam_role_name              = local.name
  create_pod_identity_association = true

  tags = local.tags
}

################################################################################
# Helm charts
################################################################################

# Main Karpenter Deployment

resource "helm_release" "karpenter" {
  name                = "karpenter"
  namespace           = local.namespace
  create_namespace    = true
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  version             = "1.0.2"
  wait                = true
  skip_crds           = true

  values = [
    file("${path.module}/helm/karpenter/values.yaml"),
    <<-EOT
    nodeSelector:
      karpenter.sh/controller: 'true'
    settings:
      clusterName: ${module.eks.cluster_name}
      clusterEndpoint: ${module.eks.cluster_endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
    tolerations:
      - key: CriticalAddonsOnly
        operator: Exists
      - key: karpenter.sh/controller
        operator: Exists
        effect: NoSchedule
    webhook:
      enabled: false
    EOT
  ]

  lifecycle {
    ignore_changes = [
      repository_password
    ]
  }
}

# Manage Karpenter CRDs
# If updating from a previous release of Karpenter (below v1.0), you will get
# an `invalid ownership metadata` error.
# To resolve this, refer to the following before applying this chart
#
#  https://karpenter.sh/preview/troubleshooting/#helm-error-when-installing-the-karpenter-crd-chart
#
# In summary, run the following commands against the cluster:
#
#  kubectl label crd ec2nodeclasses.karpenter.k8s.aws nodepools.karpenter.sh nodeclaims.karpenter.sh app.kubernetes.io/managed-by=Helm --overwrite
#
#  KARPENTER_NAMESPACE=karpenter
#  kubectl annotate crd ec2nodeclasses.karpenter.k8s.aws nodepools.karpenter.sh nodeclaims.karpenter.sh meta.helm.sh/release-name=karpenter-crd --overwrite
#  kubectl annotate crd ec2nodeclasses.karpenter.k8s.aws nodepools.karpenter.sh nodeclaims.karpenter.sh meta.helm.sh/release-namespace="${KARPENTER_NAMESPACE}" --overwrite


resource "helm_release" "update_karpenter_crds" {
  name                = "karpenter-crd"
  namespace           = local.namespace
  create_namespace    = true
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter-crd"
  version             = "1.0.8"
  wait                = true

  lifecycle {
    ignore_changes = [
      repository_password
    ]
  }
}

module "eks_blueprints_addon_karpenter_provisioner_config" {
  source = "aws-ia/eks-blueprints-addon/aws"
  version = "~> 1.1.1"

  name             = "karpenter-config"
  chart            = "./helm/karpenter-config"
  description      = "Provides provisioner configurations for Karpenter"
  namespace        = module.karpenter.namespace
  wait             = true

  create_namespace = false

  values = [yamlencode(
      {
        # karpenterIamRole = module.eks_blueprints_addons_core.karpenter.node_iam_role_name
        karpenterIamRole = module.karpenter.node_iam_role_name
        clusterName = local.name
        azs = local.azs
        forceUpdate = "2"
      }
    )
  ]

  depends_on = [ helm_release.karpenter ]

  tags = local.tags
}
