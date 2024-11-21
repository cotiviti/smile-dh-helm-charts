# Quickstart Using Existing VPC

If the default configuration is used, a VPC will be created for you and you may skip this section and proceed to [Deploy Smile CDR with Terraform](./deploy-terraform.md) section.

If you need to deploy to a pre-existing VPC, the following VPC configurations need to be reviewed

* Requires Private and Public Subnets
* Requires Subnets to be tagged for auto discovery
* Requires NAT Gateway

## Private & Public Subnets

This solution requires a VPC with both private and public subnets.

**Private subnets** will be used for all workload pods (or RDS deployments).

**Public subnets** are only used for the AWS Load Balancer that provides the public ingress path.

## Subnet Auto Discovery.

Subnet auto-discovery is used by multiple components of this solution and needs to be configured correctly to avoid hard-to-diagnose problems.

The following table shows all of the recommended subnet tags.

|Subnet Type|Tag Name|Tag Value|Purpose|Required|
|-|-|-|-|-|
| Public | Tier | Public | Selects subnets for EKS cluster to use if deployed in public subnet (Unsupported) | :material-close: |
| Public | kubernetes.io/role/elb | `1` or `` | Selects subnets for AWS LBC to deploy public load balancers | :material-check: |
| Private | Tier | Private | Selects subnets for EKS cluster to use if deployed in private subnet | :material-check: |
| Private | karpenter.sh/discovery | <`cluster-name`> | Selects subnets for Karpenter to create EC2 worker nodes | :material-check: |
| Private | kubernetes.io/role/internal-elb | `1` or `` | Selects subnets for AWS LBC to deploy internal load balancers | :material-close: |
| Database (Private) | Tier | Database | Dedicated private subnets for DB if required. | :material-close: |

> The optional tags are not required for this guide, but may be used in upcoming alternative options.

The following sections go into more detail on each use-case.

### EKS Subnets

By default the EKS module uses the following subnet tags to perform auto-discovery.

|Subnet Type|Tag Name|Tag Value|Configurable|
|-|-|-|-|
| Private | Tier | Private | :material-check: |
| Public | Tier | Public | :material-close: |

>**Note**: You can configure the Subnet Auto Discovery tags using `locals.private_subnet_discovery_tags` in your `main.tf` file.

If you are unable to use Subnet Auto Discovery, then you need to specify `existing_private_subnet_ids` in your `main.tf` file.

This is demonstrated in the highlighted sections in the below code.

```terraform hl_lines="14-16 18"
locals {
  name   = "MyClusterName"
  region = "us-east-1"

  ...

  vpc_id = "vpc-0abc123"

  ### Private Subnet Selection ###
  #
  # When using an existing VPC, you can either set the private subnets using
  # auto-discovery or you can manually configure them by providing subnet ids.
  # Refer to the QuickStart docs above for more information on subnet auto discovery.
  private_subnet_discovery_tags = {
    Tier = "Private"
  }

  existing_private_subnet_ids = ["subnet-0abc123","subnet-0def456"]

}
```

>**Note:** Currently this guide only supports deploying to a private subnet.

### Karpenter Provisioner

By default Karpenter uses the following resource tags to perform Auto Discovery of which subnets to place any created K8s worker nodes into. When configuring this, it's important that only the appropriate PRIVATE subnets are tagged.

|Subnet Type|Tag Name|Tag Value|Configurable|
|-|-|-|-|
| Private | karpenter.sh/discovery | <`cluster-name`> | :material-close: |

>**Note**: `<cluster-name>` refers to the name of the EKS cluster that you will be deploying.

If you are unable to use Subnet Auto Discovery, you can customize the Karpenter subnet selector terms by creating a new `EC2NodeClass` resource. This is not within the scope of this QuickStart guide. [More info](https://karpenter.sh/v0.32/concepts/nodeclasses/)

### AWS Load Balancer Controller

The AWS Load Balancer Controller uses the following resource tags to perform Auto Discovery of which subnets to place any Application/Network Load Balancers.

|Subnet Type|Tag Name|Tag Value|Configurable|
|-|-|-|-|
| Private | kubernetes.io/role/internal-elb | `1` or `` | :material-close: |
| Public | kubernetes.io/role/elb | `1` or `` | :material-close: |

The chosen subnet will depend on whether an `internet-facing` or `internal` load balancer is being provisioned.

>**Note:** It is not currently possible to alter the auto discovery behaviour for this. [See here for more info](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/deploy/subnet_discovery/)


### RDS Clusters

It's common in a multi-tiered architecture to isolate Data stores in their own subnet, away from application instances. If doing this, and if using the Smile CDR dependencies Terraform Module to manage your RDS instance, you can tag the appropriate Database subnets as follows to simplify subnet configuration:

|Subnet Type|Tag Name|Tag Value|Configurable|
|-|-|-|-|
| Database (Private) | Tier | Database | :material-close: |

## NAT Gateway

In order for components in the Private or Database subnets to access various resources, it's important that the VPC has a NAT Gateway provisioned in the public subnet, with appropriate routing tables configured.

If the NAT Gateway is not present, the following areas of the solution may fail

* K8s Worker Nodes unable to join cluster
* K8s Worker Nodes unable to pull docker images
* K8s Worker Nodes unable to talk to required AWS services
* RDS Management Lambda function unable to talk to required AWS services

Although it may be possible to design a solution that works entirely on a private subnet without a NAT Gateway, it is not within the scope of this QuickStart guide.
