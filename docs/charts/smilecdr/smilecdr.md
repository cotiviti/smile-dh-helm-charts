# Smile CDR

The Smile CDR Helm Chart provides a flexible and consistent method to deploy Smile CDR on a Kubernetes cluster.

It is provided by Smile Digital Health to help reduce the effort and complexity of installing Smile CDR
on Kubernetes. It has been well tested on Amazon EKS and has growing compatibility for Azure
AKS.

## Features
This chart supports a number of features to help you install Smile CDR in a secure, reliable,
cost effective and scalable manner with operational efficiency in mind.

Included features fall into the following categories:

* [Application Features](#application-features)
    * Features directly related to the Smile CDR product
* [Infrastructure Features](#infrastructure-features)
    * Features related to deploying in Kubernetes
    * Optional automated provisioning of external components
* [Security Features](#security-features)
    * Features to ensure safe handling of data and credentials
* [Reliability Feature](#reliability-features)
    * Fault tolerance & HA features
* [Operational efficiency](#operational-efficiency-features)
    * Features to help you operate effectively


### Application Features
This chart supports the following Smile CDR features *"out-of-the-box"*:

* Uses the latest official Smile CDR Docker images
    * Also supports some previous Smile CDR versions
* ***Configuration-as-code*** management of all module definitions & settings
* Support for multiple databases (i.e. Separate DB for cluster manager and one or more persistence DB)
* Flexible JVM tuning with sane defaults
* Adding small files (Up to 1Mb each - i.e. config files, scripts ect)
* Kafka configuration
* Coming soon...
    * Flexible CDR Node configurations (i.e. [Smile CDR Cluster Design Sample Architecture](https://smilecdr.com/docs/clustering/designing_a_cluster.html#sample-architecture))
    * File loading support - This will allow you to include resources such as `.jar` files,
    long scripts etc into the Smile CDR pod, negating the need to build custom images or directly access the Pod
    * AWS IAM authentication for RDS databases
    * MongoDB support
    * User seeding
    * OIDC seeding

### Infrastructure Features
#### App Networking

* Automatic configuration of Kubernetes Services and Ingresses
* Coming soon...
    * Network Policies

#### Ingress

* TLS termination at load Balancer
* [Nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
* [AWS Load Balancer Controller](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html)
* [Azure Application Gateway Ingress Controller](https://azure.github.io/application-gateway-kubernetes-ingress/)
* Coming soon...
    * Multiple Ingress (e.g. internal and external, for different modules)
    * End-to-end TLS encryption
    * Support for other ingress controllers may be implemented as required

#### Dependency Provisioning
You can use this chart to configure and automatically deploy the following components.
If enabled, they will automatically be configured in a production-like configuration, although we do not
recommend using them in production environments at this time.

* Postgres Database - Uses the [CrunchyData Postgres Operator](https://access.crunchydata.com/documentation/postgres-operator/v5/)
* Kafka Cluster - Uses the [Strimzi Kafka Operator](https://strimzi.io/docs/operators/latest/overview.html)
* Coming soon...
    * MongoDB

> With these components installed in your Kubernetes cluster, you can provision an entire Smile CDR stack,
complete with persistent backed-up database and a Kafka cluster in about 5-10 mins.
May take longer if your K8s cluster needs to autoscale to create more worker nodes first.

### Security Features
It's no good having an easy to use Helm Chart if you cannot use it in a secure manner.
As such, we have included the following features when running on Amazon EKS (Other providers to follow):

* [IAM roles for service accounts](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)(AWS Only) -
  Smile CDR pods run with their own IAM role, independent and isolated from other workloads on the cluster.
* [Secrets Store CSI Driver](https://secrets-store-csi-driver.sigs.k8s.io/) - Store secrets in a secure vault, and not in your code.
    * [AWS SSCSI Provider](https://github.com/aws/secrets-store-csi-driver-provider-aws) -
    (Uses [AWS Secrets Manager](https://aws.amazon.com/secrets-manager/))
* Coming soon...
    * Execution role support in other cloud providers
    * Support for other [SSCSI providers](https://secrets-store-csi-driver.sigs.k8s.io/providers.html)
    * Pod Security Policies
    * [Security Groups For Pods](https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html)

### Reliability Features

* High availability when running 2 or more Pods
* Self healing - Failed pods get restarted
* Pod disruption budgets (Prevents accidental outages)

### Operational Efficiency Features

* Zero-downtime configuration changes (Using rolling deployments)
* Horizontal Auto-Scaling (Within bounds of Smile CDR licence) - to ensure cost effective use of compute resources
* Coming soon...
    * [Zero-downtime upgrades](https://smilecdr.com/docs/installation/upgrading.html#upgrading-a-cluster-of-servers-with-zero-downtime) with controllable manual/automatic schema upgrades
    * Management dashboard for consolidated logs and metrics gathering for all components in the deployment

## Changelog
