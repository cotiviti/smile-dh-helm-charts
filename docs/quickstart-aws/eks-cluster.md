# Prepare EKS Cluster

This guide will help you set up an EKS cluster with configurations and components that are required to easily install Smile CDR.

## Terraform 'Quickstart' Project

To simplify the process, an example Terraform project has been provided to simplify creation of the EKS cluster and required components.

This example project leverages concepts and components from the [Amazon EKS Blueprints for Terraform](https://aws-ia.github.io/terraform-aws-eks-blueprints/) patterns and the [Amazon EKS Blueprints Addons](https://aws-ia.github.io/terraform-aws-eks-blueprints-addons/main/) addons. These patterns and addons provide a well-curated baseline EKS configuration that can be used as a guideline when designing and implementing your own environment.

We will use the example Terraform project from the [examples](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/-/tree/pre-release/examples/terraform/cluster/complete/karpenter) section of the [Smile CDR Helm Chart](https://gitlab.com/smilecdr-public/smile-dh-helm-charts) repository. It can be used to create a complete EKS cluster that contains all of the required components to deploy Smile CDR using the Helm Chart.

>Note: We do not recommend using this Terraform project outside of learning/demo type scenarios. This is not supported code and is only provided to support this QuickStart guide.

### Included Components
The main components that are included in this Terraform Quickstart Project:

* **Amazon VPC** - A VPC will be created that is auto-configured to work with the rest of the guide.
  >**Warning!** If you wish to use a pre-existing VPC, there are extra configurations that need to be verified beforehand. Refer to the [Prepare Existing VPC](./existing-vpc.md) section of this guide.

* **Amazon EKS Cluster** - An Amazon Elastic Kubernets Service (EKS) cluster will be deployed, following best-practices. It will use the following features:
    * **Karpenter Node Management** - Just-in-time node provisioning using cost effective spot EC2 instances. [More Info](https://karpenter.sh/docs/)
    * **AWS Load Balancer Controller** - Automatically creates Amazon Elastic Load Balancers to enable ingress [More Info](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
    * **Nginx Ingress Controller** for managing Ingress resources. [More Info](https://kubernetes.github.io/ingress-nginx/)
    * **Secrets Store CSI** - Securely integrate secrets stored in Amazon Secrets Manager (i.e. DB credentials). [More Info](https://secrets-store-csi-driver.sigs.k8s.io/)
    * **CrunchyData Postgres Operator** - Provision Postgres Databases in the EKS cluster. [More Info](https://access.crunchydata.com/documentation/postgres-operator/latest)
    * **Strimzi Kafka Operator** - Provision Kafka Clusters in the EKS cluster. [More Info](https://strimzi.io/)

* **S3 Endpoint** - Certain features of the Smile CDR Helm Chart make use of S3 buckets. This S3 Endpoint improves efficiency of such solitions.

### Terraform State Management
By default, this Terraform Quickstart Project uses a local Terraform state file.

It's highly recommended to use a centrally managed remote state if you have one already available in your environment. If you do not have one and wish to configure one in the same AWS account that you plan to deploy to, then you can use the provided CDK project to provision an S3 bucket and DynamoDB table suitable for Terraform remote state management. This can be found in the [state-s3](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/-/tree/pre-release/examples/terraform/state-s3) section of the [Smile CDR Helm Chart](https://gitlab.com/smilecdr-public/smile-dh-helm-charts) repository.

## Deployment Steps
Let's walk through the process of deploying an EKS cluster using this Terraform QuickStart project...

### Download Terraform Quickstart Project
In a terminal, change to a suitable folder to manage your project.
```
mkdir -p ~/my-sdh-eks/
cd ~/my-sdh-eks
```

Clone the Terraform Quickstart Project
```
git clone --depth 1 https://gitlab.com/smilecdr-public/smile-dh-helm-charts.git
```

Optionally make a copy of the project to work from
```
cp -rp smile-dh-helm-charts/examples/terraform/cluster/complete/karpenter cluster
cd cluster
```

### Configure the project for your environment
By default, this project will not run until you update some required configurations. To do this, you need to edit the `locals` section in the `main.tf` file.

>**Note:** This project deliberately requires you configure via locals rather than passing in variables, because it is not intended to be used as a configurable module. It is only provided as a technical demonstration of how to deploy an EKS cluster suitable for deploying Smile CDR using the official Helm Chart.

At a minimum, you should configure the following:

* `name` - A unique name that will be used for your EKS cluster and any supporting resources (Default is `MyClusterName`)
* `region` - The AWS region where you wish to deploy the EKS cluster. (Default is `us-east-1`)
* `nginx_ingress.acm_cert_arn` - The ARN for a default ACM certificate that will be used by the AWS Network Load Balancer that will be used by the Nginx Ingress Controller.

#### VPC configuration
If you wish to let the project create the VPC for you, no further configuration is required.

If you wish to use an already-existing VPC you will need to do the following

* Set `existing_vpc_id` to the VPC Id of the existing VPC
* Follow the [Existing VPC](./existing-vpc.md) chapter which will guide you on configuration requirements on the existing VPC.

#### Ingress Configuration

As mentioned in the [AWS Dependencies](./aws-dependencies.md#amazon-certificate-manager-certificate) section, you need to provide a suitable TLS certificsate via ACM. Do this by setting `nginx_ingress.acm_cert_arn`.

>**Note:** It's advisable at this point to configure your Terraform remote state as described [above](#terraform-state-management). For this guide, we will continue to use local state.

At the top of the `main.tf` file, you will see the following `locals` block that you should update.

```terraform hl_lines="7 12-16"
locals {
  name   = "MyClusterName"
  region = "us-east-1"
  enable_nginx_ingress = true
  nginx_ingress = {
    enable_tls = true
    acm_cert_arn = "arn:aws:acm:us-east-1:012345678910:certificate/xxxx-yyyy-zzzz"
  }

  ...

  existing_vpc_id = null
  private_subnet_discovery_tags = {
    Tier = "Private"
  }
  existing_private_subnet_ids = null
}
```

### Prepare Terraform Project
Make sure that you have valid AWS credentials loaded and that you are able to authenticate against the AWS API.

```
aws sts get-caller-identity
{
    "UserId": "AROAXAABBCCDDEEFFGG",
    "Account": "012345678910",
    "Arn": "arn:aws:sts::012345678910:role/MyAdminRole"
}
```
Double check that you are using the correct AWS account and have a suitable IAM role/user that has Administrative privileges.

Initialize the Terraform Project
```
terraform init
```

After all of the Terraform modules have been installed, you should see the following message:
```
Terraform has been successfully initialized!
```

### Deploy Cluster
Now you can plan, review and apply the Terraform project to create the EKS cluster and the required components.

```
terraform plan
# Review the output to see what resources will be created.

terraform apply

Plan: 110 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + configure_kubectl = "aws eks --region us-east-1 update-kubeconfig --name MyClusterName"

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```

Now is the time to grab that cuppa, as this process will take about 45 mins!

Once completed, you should see output as follows:

```
Apply complete! Resources: 11 added, 0 changed, 2 destroyed.

Outputs:

configure_kubectl = "aws eks --region us-east-1 update-kubeconfig --name MyClusterName"
```

### Verify EKS Cluster

Now you can add the cluster to your local `kubectl` configuration by running the `configure_kubectl` that is returned.

```
aws eks --region us-east-1 update-kubeconfig --name MyClusterName
Added new context arn:aws:eks:us-east-1:012345678910:cluster/MyClusterName to ~/.kube/config
```

Using this context, you should now be able to inspect the cluster and view all of the core component pods.

### Deploy Workloads

Your cluster is now ready and applications can be deployed.

Before installing Smile CDR using the Helm Chart, you may still need to perform further configurations in your AWS account. Review the [Prepare AWS Resources](./aws-dependencies.md) section to ensure that all required dependencies are present.

## Destroy EKS Cluster
When deleting this cluster, it's important to destroy the resources in a specific order.
Failure to do this will likely leave the Terraform project in a 'stuck' state where it is unable to delete resources without tedious manual steps.

>**Note:** Delete any application workloads deployed on the cluster before proceeding with these steps

1. Destroy any ingress addons
   ```
   terraform destroy -target module.eks_blueprints_addons_ingress
   ```
   This is an important step. If we were to delete the core addons (Which includes the load balancer controller), then we may end up with dangling ELB resources.
   By deleting the ingress addons first, we can be sure that the load balancers are deleted.

2. Destroy the core EKS Blueprint Addons
   ```
   terraform destroy -target module.eks_blueprints_addons_core
   ```
3. Destroy the core EKS module
   ```
   terraform destroy -target module.eks
   ```
4. Destroy the remaining resources
   ```
   terraform destroy
   ```
