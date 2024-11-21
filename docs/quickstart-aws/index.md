# AWS Quickstart
This guide shows how to install Smile CDR on Amazon EKS using the Helm Chart.

It is intended only as a guideline on how to perform the installation and should not be used for production deployments. There are many factors to take into consideration when installing Smile CDR to suit your requirements, which is outside the scope of this Quickstart guide.

## Quickstart Architecture Overview

The architecture for this quickstart follows a minimal deployment architecture that is suitable to demonstrate the process of deploying Smile CDR using the Helm Charts and the associated Terraform Dependencies module.

Although not intended for production deployments, security best-practices are in place as deploying with good security posture is one of the core design goals of Helm Charts

### Prerequisites

In order to follow this guide and be able to access the resulting Smile CDR instance, you will need:

* Access to the official Smile CDR docker image (either a service account for `docker.smilecdr.com`, or a custom image in ECR)
* The following resources need to be already available in your AWS account:
    * **Route 53 hosted zone** You need to be able to add entries to a subdomain that you own
    * **TLS certificate in AWS Certificate Manager** Required for TLS termination of the domain. This can either be managed by ACM or manually imported if provisioned elsewhere.

## Deploy Dependencies With Terraform

Before installing Smile CDR securely on Amazon EKS, two main areas of dependencies are required.

### Infrastructure Dependencies

An Amazon EKS cluster with associated infrastructure. As the infrastructure requirements for various use-cases and organizational standards can differ wildly, it is out of scope to have a solution that will cover all scenarios.

For the purposes of this QuickStart guide, an example Terraform project will be used to deploy these components and provide a high-level view of the approach you may take in your own organization.

### Environment Dependencies

Each deployment of Smile CDR will have its own set of dependencies related to Security, Agility and Accessibility. As these can be tricky to set up manually, this guide will use a ***Smile CDR Dependencies*** Terraform module that has been created by Smile Digital Health for this purpose.


## Quickstart Steps
These quickstart instructions are split into 3 main sections:

### Prepare EKS Cluster

The [Prepare EKS Cluster](./eks-cluster.md) section shows how to install a new EKS cluster or prepare an existing EKS cluster to be ready to install Smile CDR using the Helm Chart.

For the purposes of this QuickStart guide, an example Terraform project will be used to deploy these components and provide a high-level view of the approach you may take in your own organization.

An Amazon EKS cluster with associated infrastructure is required. As the infrastructure requirements for various use-cases and organizational standards can differ wildly, it is out of scope to have a solution that will cover all scenarios.

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
