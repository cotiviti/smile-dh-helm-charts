# AWS Quickstart
This section of the documentation shows how to install Smile CDR on Amazon EKS using the Helm Chart.

## Preparing Dependencies
When installing Smile CDR securely on Amazon EKS, a number of dependencies need to be in place beforehand. These include, but are not limited to:

* Kubernetes cluster
* Various controllers/operators installed on Kubernetes cluster
* Various AWS resources such as IAM roles, secrets, S3 buckets, DNS entries etc.

### Terraform Module
To simplify the provisioning of these dependencies, Smile Digital Health provides a ***Smile CDR Dependencies*** Terraform module that eases the deployment and management of these dependencies.

This quickstart uses some example Terraform configurations that use this module to easily provision required dependencies with minimal manual configurations.

>**Note:** If installing Smile CDR without using this Terraform module, there may be a lot more effort required to determine and configure all of the required dependencies.

## Quickstart Steps
These quickstart instructions are split into 3 main sections:

### Prepare EKS Cluster
The [Prepare EKS Cluster](./eks-cluster.md) section shows how to install a new EKS cluster or prepare an existing EKS cluster to be ready to install Smile CDR using the Helm Chart.

If you already have an EKS cluster ready to go, you may skip this section and move on to the Smile Dependencies section.

### Prepare AWS Resources
The [Prepare AWS Resources](./aws-resources.md) section details the AWS resources that need to be provisioned in your AWS account in order to deploy Smile CDR using the Helm Chart.

Once you have these dependencies in place, you can proceed to deploying Smile CDR using the Terraform module and Helm Chart

### Deploy Smile CDR with Terraform
The [Deploy Smile CDR with Terraform](./deploy-terraform.md) section shows how to deploy Smile CDR via the provided Terraform module.

If choosing to deploy directly with the Helm Chart instead, you will first need to deploy the Smile CDR dependency resources into your AWS account through other means. More details on these can be found in the [Requirements](../guide/smilecdr/requirements.md) section of the [Smile CDR Helm Chart User Guide](../guide/smilecdr/index.md).
>**Note:** This method is out of scope for this quickstart guide.

## What's Next?
You may use this quickstart as a basis for your deployment. Please look through the advanced deplopyments in the [User Guide](../guide/smilecdr/index.md) and [Examples](../examples/index.md) sections to design a solution that works for your architecture.
