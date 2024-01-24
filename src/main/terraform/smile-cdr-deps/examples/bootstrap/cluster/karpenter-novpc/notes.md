Take note of when the ebs csi is created, and by what...



This is just balls... If you have a 'kubernetes_manifest' resource, you can't run the terraform if the eks cluster does not exist yet.
This presents in multiple scenarios:
1. Destroy time. If you do a targeted destroy, then after you destroy with -target module.eks, then you are no longer able to run the
tf at all as it cannot connect to k8s.

module.eks_blueprints_addons_core.data.aws_eks_addon_version.this["kube-proxy"]: Read complete after 1s [id=kube-proxy]

╷
│ Error: Failed to construct REST client
│
│   with kubernetes_manifest.karpenter_node_class,
│   on karpenter.tf line 1, in resource "kubernetes_manifest" "karpenter_node_class":
│    1: resource "kubernetes_manifest" "karpenter_node_class" {
│
│ cannot create REST client: no client config
╵

2. Create time. It fails with those resources present.

It does mention this right in the docs:

```Before you use this resource
This resource requires API access during planning time. This means the cluster has to be accessible at plan time and thus cannot be created in the same apply operation. We recommend only using this resource for custom resources or resources not yet fully supported by the provider.```

https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest#argument-reference

We may need to move some of this to another tf module





If the AWS account is old, you may need to create the service linked role for spot fleets
https://stackoverflow.com/questions/64136679/error-the-provided-credentials-do-not-have-permission-to-create-the-service-lin
