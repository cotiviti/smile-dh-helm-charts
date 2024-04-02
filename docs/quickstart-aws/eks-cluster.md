# Prepare EKS Cluster

To simplify creation of a suitable EKS cluster, this guide uses a simple Terraform project that leverages the [Amazon EKS Blueprints for Terraform](https://aws-ia.github.io/terraform-aws-eks-blueprints/) patterns.

These patterns provide a well-curated baseline EKS configuration that can be customized based on the requirements for your environment.

## Terraform 'Quickstart' Project

A Terraform project is provided in the [examples](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/-/tree/pre-release/examples/terraform/cluster/complete) section of the [Smile CDR Helm Chart](https://gitlab.com/smilecdr-public/smile-dh-helm-charts) repository. It can be used to create a ***complete*** EKS cluster that contains all of the required components to use the Smile CDR Helm Chart.

### Included Components
The main components that are included in this Terraform Quickstart Project are as follows:

* **EKS Cluster** using best-practice defaults (e.g. etc encrypted by default)
* **Karpenter** for provisioning compute resources on-demand, rather than pre-provisioning worker nodes. Can take advantage of ***Spot*** instances and is more granular and efficient than Autoscaling Groups. [More Info](https://karpenter.sh/docs/)
* **AWS Load Balancer Controller** for managing AWS Load Balancer. [More Info](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.7/)
* **Nginx Ingress Controller** for managing Ingress resources. [More Info](https://kubernetes.github.io/ingress-nginx/)
* **Secrets Store CSI** for securely managing Secrets (i.e. DB credentials). [More Info](https://secrets-store-csi-driver.sigs.k8s.io/)
* **CrunchyData Postgres Operator** for managing in-cluster Postgres databases. [More Info](https://access.crunchydata.com/documentation/postgres-operator/latest)
* **Strimzi Kafka Controller** for managing in-cluster Kafka clusters. [More Info](https://strimzi.io/)
* Other supporting components that are not relevant to this guide.

### Quickstart variants
This Terraform project is available in three variants to help satisfy common use-cases.

* `karpenter` - Configures all of the above components, plus a new VPC.
* `karpenter-fargate` - Same as above, but uses Fargate for the core cluster components to save cost under certain scenarios
* `karpenter-novpc` - Same as the `karpenter` option above, but can be deployed to an existing VPC. Useful if you do not wish to create a VPC.

### Terraform State Management
By default, this Terraform Quickstart Project uses a local Terraform state file.

It's highly recommended to use a centrally managed remote state if you have one already available in your environment. If you do not have one and wish to configure one in the same AWS account that you plan to deploy to, then you can use the provided CDK project to provision an S3 bucket and DynamoDB table suitable for Terraform remote state management. This can be found in the [state-s3](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/-/tree/pre-release/examples/terraform/state-s3) section of the [Smile CDR Helm Chart](https://gitlab.com/smilecdr-public/smile-dh-helm-charts) repository.

## Deployment Steps
Let's follow the `karpenter` variant of the Terraform Quickstart Project...

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
Although this project will run without modification, you should update some of the Terraform `locals` to suit your environment.

At a minimum, you should configure the following:

* `name` - A unique name that will be used for your EKS cluster and any supporting resources (Default is `MyClusterName`)
* `region` - The AWS region where you wish to deploy the EKS cluster. (Default is `us-east-1`)
* `acm_cert_arn` - The ARN for a default ACM certificate that will be used by the AWS Network Load Balancer that will be used by the Nginx Ingress Controller.

>**Note:** It's advisable at this point to configure your Terraform remote state. For this guide, we will continue to use local state.

Edit the `main.tf` file. At the top of the file, you will see the following `locals` block that you should update.

```
locals {
  name   = "MyClusterName"
  region = "us-east-1"
  acm_cert_arn = "arn:aws:acm:us-east-1:012345678910:certificate/xxxx-yyyy-zzzz"
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

Before installing Smile CDR using the Helm Chart, you may still need to perform further configurations in your AWS account. Proceed to the [Prepare AWS Resources](./aws-resources.md) section.

### Destroy EKS Cluster
When deleting this cluster, it's important to destroy the resources in a specific order.
Failure to do this will likely leave the Terraform project in a 'stuck' state where it is unable to delete resources without tedious manual steps.

1. Delete any application workloads or operators deployed on the cluster
   ```
   terraform destroy -target module.eks_blueprints_addon_crunchypgo
   terraform destroy -target module.eks_blueprints_addon_strimzi
   terraform destroy -target module.eks_blueprints_addon_karpenter_provisioner_config
   ```
2. Destroy any ingress addons
   ```
   terraform destroy -target module.eks_blueprints_addons_ingress
   ```
3. Destroy the core EKS Blueprint Addons
   ```
   terraform destroy -target module.eks_blueprints_addons_core
   ```
4. Destroy the core EKS module
   ```
   terraform destroy -target module.eks
   ```    
5. Destroy the remaining resources
   ```
   terraform destroy
   ```