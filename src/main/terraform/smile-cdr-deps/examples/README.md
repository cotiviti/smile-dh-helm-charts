


### Some notes from developing these examples

If you have a 'kubernetes_manifest' Terraform resource, you can't run the terraform if the eks cluster does not exist yet.
This presents in multiple scenarios:
1. Destroy time. If you do a targeted destroy, then after you destroy with -target module.eks, then you are no longer able to run the
tf at all as it cannot connect to k8s.

module.eks_blueprints_addons_core.data.aws_eks_addon_version.this["kube-proxy"]: Read complete after 1s [id=kube-proxy]

╷
│ Error: Failed to construct REST client
│
│   with kubernetes_manifest.karpenter_node_class,
│   on karpenter.tf line 1, in resource "kubernetes_manifest" "karpenter_node_class":
│    1: resource "kubernetes_manifest" "karpenter_node_class"
│
│ cannot create REST client: no client config
╵

2. Create time. It fails with those resources present.

It does mention this right in the docs:

```
Before you use this resource
This resource requires API access during planning time. This means the cluster has to be accessible at plan time and thus cannot be created in the same apply operation. We recommend only using this resource for custom resources or resources not yet fully supported by the provider.```

https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest#argument-reference

To avoid the above scenario, the required Karpenter manifests have been moved to a simple unpublished Helm Chart that is embedded in this example.
```

## TODO - Clarify the above. It may not behave the same if you configure the kubernetes provider with `token` instead of `exec`


### Creation of compute nodes using Spot Fleet

On some AWS accounts, Karpenter may fail to instantiate EC2 resources.

If the AWS account is old, you may get discover the following error if Karpenter is unable to create the Spot requests:

`Error: The provided credentials do not have permission to create the service-linked role for EC2 Spot Instances`

If this is the case, you may need to create the service linked role for Spot in that account.
* SO Question on this issue [here](https://stackoverflow.com/questions/64136679/error-the-provided-credentials-do-not-have-permission-to-create-the-service-lin)
* AWS docs on Spot instances [here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-requests.html#service-linked-roles-spot-instance-requests)
* Mentioned in the Karpenter Blueprints GitHub repo [here](https://github.com/aws-samples/karpenter-blueprints) as follows:

> Before you continue, you need to enable your AWS account to launch Spot instances if you haven't launch any yet. To do so, create the [service-linked role for Spot](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-requests.html#service-linked-roles-spot-instance-requests) by running the following command:
>
> ```aws iam create-service-linked-role --aws-service-name spot.amazonaws.com || true```
