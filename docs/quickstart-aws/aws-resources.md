# Prepare AWS Resources

Before deploying Smile CDR using this Terraform Module and Helm Chart, you will still need to create some resources.

Due to the nature of these resources, it's not feasible to include them in any automations at this time.

## Private Container Registry Credentials

As the Smile CDR container images are hosted on a private container registry, credentials are required by Kubernetes so that it can pull images before starting pods. There are multiple options for exposing the Smile CDR images to your EKS cluster.

If you use the Smile Digital Health container repository, or if you copy the Smile CDR images to your own password-protected container registry, then you will need to create a `dockerconfigjson` style secret in AWS Secrets Manager.

There are two ways that this can be achieved.

### Account-wide shared repository secret
If you pr-provision an AWS Secrets Manager secret in the same AWS account, then you can provide the ARN of this secret when you configure your environment in the following section.

The Terraform module will automatically add this Secret to the IAM Policies used by the Smile CDR pods.

### Per environment repository secret
If you do not specify an AWS Secrets Manager Secret ARN, an empty secret will be automatically created in the same region.

In this case, you will need to manually update the secret in the AWS Console before the Smile CDR pods will be able to pull the image and start.

### Repository Secret Format

In either of the above scenarios, the secret should use the standard `dockerconfigjson` format that is used by Kubernetes. More information on this is available [here](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/)

To create suitable output to paste into the secret, you can run the following command locally:

```
kubectl create secret docker-registry regcred --dry-run=client --docker-server=my.registry.com --docker-username=username --docker-password=password --docker-email=email@example.com -oyaml --output="jsonpath={.data.\.dockerconfigjson}" | base64 --decode
```

This will output the following, which can be pasted directly into an AWS Secrets Manager secret under the `dockerconfigjson` key.

```
{"auths":{"my.registry.com":{"username":"username","password":"password","email":"email@example.com","auth":"dXNlcm5hbWU6cGFzc3dvcmQ="}}}
```

## Amazon ECR

If you choose to copy the Smile CDR images to Amazon ECR, you do not need to create any Secrets Manager secrets as authentication is performed using IAM Policies attached to IAM Roles used by the Pods.

## DNS Configuration

If you wish to have the Terraform module automatically create DNS entries for your new environments, then you will need to have a Route53 Hosted Zone in the same AWS account that you are deploying Smile CDR inside.
