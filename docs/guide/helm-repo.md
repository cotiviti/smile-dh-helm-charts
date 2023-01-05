## Configure Helm Repository:

Before you can use the Smile Digital Health Helm Charts, you need to configure your
deployment tool to point to the repository where the charts are hosted.

This will differ, depending on the method you will be using to deplpy the charts.

### Native Helm
The simplest way to get up and running is by using the native `helm` commands.

Add the repository like so.

```shell
$ helm repo add smiledh https://gitlab.com/api/v4/projects/40759898/packages/helm/devel
$ helm repo update
```

> **Note** It is also possible to run the `helm install` command by pointing directly to the repository.
In this case, there is no need to run the `helm repo` commands above.

### Terraform
If installing the chart using Terraform, you may have a resource definition like so:

```
resource "helm_release" "example" {
  name       = "my-smilecdr-release"
  repository = "https://gitlab.com/api/v4/projects/40759898/packages/helm/devel"
  chart      = "smilecdr"
  version    = "~1.0.0"

  values = [
    "${file("my-values.yaml")}"
  ]

  set {
    name  = "values.override"
    value = "value"
  }
}
```

See the [Terraform Helm Provider](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) for more info on this.

### ArgoCD
If installing in ArgoCD using an `Application` Custom Resource, you will need to create a custom 'Umbrella Chart' for your deployment so that you can pass in your values file (And any other files).

To do this, you would create a configuration directory with your configuration files as well as a `Chart.yaml` file that may look like this:

```yaml
apiVersion: v2
name: umbrella-smilecdr
description: An Umbrella Helm chart to deploy the Smile CDR Helm Chart

# This Umbrella Helm Chart can be used to deploy Smile CDR in ArgoCD while
# passing in your values files.

type: application
version: 1.0.0

# Remember, when passing values files in to dependency charts, the entire yaml map needs to be
# moved to a root key that matches the `name` of the dependency.
dependencies:
- name: smilecdr
  version: "~1.0.0-pre.10"
  repository: "https://gitlab.com/api/v4/projects/40759898/packages/helm/devel"
```

## Provide Repo Credentials
As Smile CDR is not a free product, it is not possible to use it from our
container repository without providing credentials.

The same may be the case if you have custom Docker images for Smile CDR that you have built yourself and published to your own private container registry.

In either case, you will need to provide credentials that can be used by Kubernetes to pull the image.

In Kubernetes, to pull from a private container registry, you need to provide
the `imagePullSecrets` stanza in the `Pod` spec. To do this, you need a Kubernetes
`Secret` object in the same namespace.

>**Note** For more information on using private container registries with
Kubernetes, see the official documentation [here](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/)

As described in the [Secrets Handling](secrets.md) section of these docs, we support multiple methods to provide secrets.

### Configuring Repo Credentials using Secrets Store CSI Driver
Before using this configuration in your values file, ensure that you have followed the appropriate section in the [Secrets Handling](secrets.md#secrets-store-csi-driver) guide to set up Secrets Store CSI, the AWS Provider, your AWS Secret, your IAM Role and configured the `ServiceAccount`.

Once you have done that, you can enable it like so:

* Specify the `image.credentials.type` as `sscsi`
* Specify the `image.credentials.provider` as `aws`
* Specify the AWS Secret ARN in `image.credentials.secretarn`

It would look like this:
```yaml
image:
  credentials:
    type: sscsi
    provider: aws
    secretarn: "arn:aws:secretsmanager:us-east-1:1234567890:secret:secretname"
serviceAccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/example-role-name"
```

### Configuring Repo Credentials using Kubernetes Secret
Before using this configuration, you need to create a Kubernetes `secret` of type `kubernetes.io/dockerconfigjson`. For more info on this, refer to the Kubernetes section in [Secrets Handling](secrets.md#kubernetes-secret).

Once your Kubernetes `Secret` object is created, you can use it like so:

* Specify the `image.credentials.type` as `externalsecret`
* Reference the Secret name in `image.credentials.pullSecrets[0].name`

It would look like this in your custom values file:
```yaml
image:
  credentials:
    type: externalsecret
    pullSecrets:
    - name: mysecretname
```
