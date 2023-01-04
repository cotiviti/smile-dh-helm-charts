
# Requirements and Dependencies
There are a number of prerequisites that must be in place before deploying Smile CDR using this Helm Chart.
Due to the complicated nature of configuring the product, and enforcing strong security practices, there is no ***quickstart***
option without ensuring some, or all, of these pre-requisites have been met.

## Minimum Requirements
These dependencies are sufficient to get you started with deploying an instance for testing purposes.

* Access to a container repository with the required Smile CDR Docker images
    * e.g. `docker.smilecdr.com` or your own registry with a custom Docker image for Smile CDR
* Kubernetes Cluster that you have suitable administrative permissions on.
    * You will need permissions to create namespaces and maybe install Kubernetes add-ons
* Sufficient spare compute resources on the Kubernetes cluster.
    * Minimum spare of 1 vCPU and 4GB memory for a 1 pod install of just Smile CDR
* One of the following supported Ingress controllers:
    * [Nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/) (Preferred)
    * [AWS Load Balancer Controller](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html)
    * [Azure Application Gateway Ingress Controller](https://azure.github.io/application-gateway-kubernetes-ingress/)
* TLS certificate that can be provisioned on the load balancer used by the Ingress objects
    * e.g. AWS Certificate Manager.
* DNS entries pointing to load balancer.
    * e.g. [Amazon Route 53](https://aws.amazon.com/route53/)
* One of the following supported database options:
    * Externally provisioned database in the official Smile CDR supported databases list [here](https://smilecdr.com/docs/getting_started/platform_requirements.html#database-requirements)
    * CrunchyData Postgres Operator installed in cluster. See [Extra Requirements](#extra-requirements) below if you follow this option.

## Recommended Requirements
These dependencies are recommended in order to follow security best practices. These are in addition to those listed above.

* Kubernetes/EKS/AKS cluster should be configured with best practices in mind.
    * [Kubernetes best practices](https://kubernetes.io/docs/home/)
    * [Amazon EKS best practices](https://aws.github.io/aws-eks-best-practices/)
    * [Azure AKS best practices](https://learn.microsoft.com/en-us/azure/aks/best-practices)
* Kubernetes cluster should, at the very least, have the following configurations
    * Secret Encryption ([EKS Secret Encryption](https://docs.aws.amazon.com/eks/latest/userguide/enable-kms.html))
    * Storage Class with encryption enabled if using persistent storage (PostgreSQL or Kafka)
    * Enforce all pods should set resource requests
* AWS IAM Role for the Smile CDR application.
    * Should follow the [principle of least privilege](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#grant-least-privilege) and only have access to required AWS services
* [Secrets Store CSI Driver](https://secrets-store-csi-driver.sigs.k8s.io/) + Provider
    * Only the [AWS Provider](https://github.com/aws/secrets-store-csi-driver-provider-aws) is supported at this time
    * AWS IAM Role needs access to read & decrypt the secrets in AWS Secrets Manager

## Extra Requirements

* [Strimzi Kafka Operator](https://strimzi.io/docs/operators/latest/overview.html)
    * Allows you to install a production ready Kafka cluster as a part of the Smile CDR deployment.
* [CrunchyData Postgres Operator](https://access.crunchydata.com/documentation/postgres-operator/v5/)
    * Allows you to install a PostgreSQL cluster as a part of the Smile CDR deployment.
