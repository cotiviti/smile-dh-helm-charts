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
  # Use this to pin to a semantic version
  # version    = "~1.0.0"
  # Use this to use latest pre-release versions
  devel      = "true"

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
This Helm Chart supports multiple methods to securely provide access to container repositories.

| Method | Security | Difficulty | Notes |
|--------|----------|------------|-------|
|AWS ECR with IAM role|Highest|Medium|Recommended method if using ECR.<br>This is only an option if you have a workflow to host the Smile CDR image on your own ECR repository.<br>This has the highest security stance as long lived credentials are not required.<br>No K8s `Secret` objects need to be created or referenced.|
|Secrets Store CSI|High|Hardest|Recommended method if not using ECR.<br>You will need the SSCSI driver, an appropriate SSCSI provider, A secrets vault Secret and any IAM roles configured to access the secret|
|Kubernetes Secret|Medium|Medium|Need to manually set up Kubernetes Secret|
|Values File|Low|Easiest|K8s secret created by chart. Password is in your code (Bad)|

### AWS Elastic Container Registry
If you are using AWS ECR as your container registry, you can avoid storing long-lived credentials in secrets by using a suitable IAM role.

In order to use this method, the IAM role added to the Instance Profile of your Kubernetes worker nodes must include a policy that allows read access to your container registry. This mechanism does not use IRSA, so can only use the worker node's Instance Profile/IAM role.

### Private Registry
If you are pulling the Smile CDR docker image directly from `docker.smilecdr.com` or if you have custom Docker images that you build and publish on a private container registry that requires credentials, then you will need to provide them in a secure manner so that Kubernetes can pull the image.

In Kubernetes, this is done using a list of secret names in `pod.spec.imagePullSecrets`. These secrets reference the name of pre-existing `Secret` objects in the same namespace.

>**Note** For more information on using private container registries with
Kubernetes, see the official documentation [here](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/)

More details can be found in the [Secrets Handling](secrets.md) section of these docs.

### Configuring to use ECR Repository
In order for Kubernetes worker nodes to pull images from ECR, they must have an Instance Profile/IAM Role that has an IAM policy with the following actions allowed for your ECR Repository

>**TODO:** Add details of required IAM policy actions

```yaml
iamsnippet:
  here: yes yes
```

There are no extra steps after this, you do not need to specify any image pull secrets.

If you do define image pull secrets for other containe registries, this will not be affected. You do not need to remove them.
### Configuring Repo Credentials using Secrets Store CSI Driver
Before using this configuration in your values file, ensure that you have followed the appropriate section in the [Secrets Handling](secrets.md#secrets-store-csi-driver) guide to set up Secrets Store CSI, the AWS Provider, your AWS Secret, your IAM Role and configured the `ServiceAccount`.

Once you have done that, you need to add an item to the `image.imagePullSecrets` list like so like so:

```yaml
image:
  imagePullSecrets:
  - type: sscsi
    provider: aws
    secretArn: "arn:aws:secretsmanager:us-east-1:1234567890:secret:secretname"
serviceAccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/example-role-name"
```

### Configuring Repo Credentials using Kubernetes Secret
Before using this configuration, you need to create a Kubernetes `Secret` object of type `kubernetes.io/dockerconfigjson` using some external/manual mechanism. For more info on this, refer to the Kubernetes section in [Secrets Handling](secrets.md#kubernetes-secret).

Once this `Secret` object is created, you can add it in the same way that you would with a regular `imagePullSecrets` entry in the K8s [PodSpec](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#PodSpec):

It would look like this in your custom values file:
```yaml
image:
  imagePullSecrets:
  - name: myK8sSecretName
    # Optional if you wish to make it explicitly clear which credential type you are using in your code
    # type: k8sSecret
```

### Configuring Multiple Repo Credentials
If you need to connect to multiple container repositories, you can mix and match the above types in the list of `imagePullSecrets`

```yaml
image:
  imagePullSecrets:
  # Regular pre-existing `Secret` object
  - name: myK8sSecretName
    type: k8sSecret
  # Helm Chart will automatically create `Secret` objects for these:
  - type: sscsi
    provider: aws
    secretArn: "arn:aws:secretsmanager:us-east-1:1234567890:secret:secretname"
  - type: sscsi
    provider: aws
    # The secretArn must be uniqe
    secretArn: "arn:aws:secretsmanager:us-east-1:1234567890:secret:secretname2"
# Service Account is still required here as we are using Secrets Store CSI
serviceAccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/example-role-name"
```
