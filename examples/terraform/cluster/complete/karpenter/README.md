# Karpenter

This example Terraform project demonstrates how to provision an EKS cluster that is configured and ready to install Smile CDR using Terraform/Helm.

It can be configured to deploy a complete infrastructure, including a new VPC, or to an existing VPC.

## Highlights

The following configurations and components are included in this example.

* Optionally creates a new VPC with 3 subnet tiers, tagged per the documentation located [here](http://localhost:8000/smile-dh-helm-charts/quickstart-aws/existing-vpc/)
* Creates EKS cluster using curated [Amazon EKS Blueprints for Terraform](https://aws-ia.github.io/terraform-aws-eks-blueprints/) patterns.
* Uses [Karpenter](https://karpenter.sh/) to efficiently manage compute resources.
    * Default node group is only used to run the cluster addons and operators.
    * All workload pods will run on nodes provisioned by Karpenter
* Includes the following EKS addons:

    * [CoreDNS](https://coredns.io/)
    * [Amazon VPC CNI](https://github.com/aws/amazon-vpc-cni-k8s)
    * [kube-proxy](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-proxy/)
    * [AWS EBS CSI Driver](https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html)
    * [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.7/)
    * [Karpenter](https://karpenter.sh/)
    * [Secrets Store CSI Driver](https://secrets-store-csi-driver.sigs.k8s.io/)
    * [AWS Secretys Store CSI Driver Provider](https://github.com/aws/secrets-store-csi-driver-provider-aws)
    * [Cert Manager](https://cert-manager.io/)
    * [Metrics Server](https://github.com/kubernetes-sigs/metrics-server)
    * [Ingress-Nginx Controller](https://kubernetes.github.io/ingress-nginx/)

* Includes the following EKS default configurations

    * Encryption enabled by default for `etcd`
    * Encrypted GP3 storage enabled by default for Persistent Volumes

* Includes the following Kubernetes Operators

    * [Crunchy Data Postgres Operator](https://access.crunchydata.com/documentation/postgres-operator/latest)
    * [Strimzi Kafka Operator](https://strimzi.io/)

## Configure the project for your environment

By default, this project will not work until you update some required configurations. To do this, you need to edit the `locals` section in the `main.tf` file.
>**Note:** This project deliberately requires you configure via locals rather than passing in variables, because it is not intended to be used as a configurable module. It is only provided as a technical demonstration of how to deploy an EKS cluster suitable for deploying Smile CDR using the official Helm Chart.

### General Configuration

First, you need to provide the cluster name and the AWS region that you wish to deploy the EKS cluster to.

### Ingress Configuration

Provide a suitable ACM Certificate ARN

See the [documentation](https://smilecdr-public.gitlab.io/smile-dh-helm-charts/latest/quickstart-aws/eks-cluster/) for more info on configuring this project.

## Deploy

### Prerequisites
See [here](https://aws-ia.github.io/terraform-aws-eks-blueprints/getting-started/#prerequisites) for the prerequisites to deploy this example.

### Deployment Steps

```
terraform init
terraform apply -target="module.vpc"
terraform apply -target="module.eks"
terraform apply
```

## Validate

Now you can add the cluster to your local `kubectl` configuration by running the `configure_kubectl` that is returned.

```
aws eks --region us-east-1 update-kubeconfig --name MyClusterName
Added new context arn:aws:eks:us-east-1:012345678910:cluster/MyClusterName to ~/.kube/config
```

Using this context, you should now be able to inspect the cluster and view all of the core component pods.


## Destroy

>**Warning!** Before destroying this cluster, you need to de-provision any workloads first so that Karpenter can destroy created resources. If Karpenter is undeployed before it can destroy it's managed resources, then the dangling resources may cause the `terraform destroy` command to hang. Recovering from this situaton can be very troublesome.

```
terraform destroy -target module.eks_blueprints_addons_ingress
terraform destroy -target module.eks_blueprints_addons_core
terraform destroy -target module.eks
terraform destroy
```
