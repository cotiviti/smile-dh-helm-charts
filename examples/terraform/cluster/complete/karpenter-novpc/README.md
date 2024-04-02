# Karpenter with existing VPC

This example Terraform project demonstrates how to provision an EKS cluster that is configured and ready to install Smile CDR using Terraform/Helm.

It requires an existing VPC. If you wish to install into a new VPC, then see the `karpenter` example.

## Example Highlights

The following configurations and components are included in this example.

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

## Deploy

### Prerequisites
See [here](https://aws-ia.github.io/terraform-aws-eks-blueprints/getting-started/#prerequisites) for the prerequisites to deploy this example.

### Deployment Steps

```
terraform init
terraform apply -target="module.eks"
terraform apply
```

## Validate

>*TODO:* Add validation steps


## Destroy

>**Warning!** Before destroying this cluster, you need to de-provision any workloads first so that Karpenter can destroy created resources. If Karpenter is undeployed before it can destroy it's managed resources, then the dangling resources may cause the `terraform destroy` command to hang. Recovering from this situaton can be very troublesome.

```
terraform destroy -target="module.eks_blueprints_addons"
terraform destroy
```
