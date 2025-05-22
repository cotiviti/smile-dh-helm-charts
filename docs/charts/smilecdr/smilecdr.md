# Smile CDR

The Smile CDR Helm Chart provides a flexible and consistent method to deploy Smile CDR on a Kubernetes cluster.

It is provided by Smile Digital Health to help reduce the effort and complexity of installing Smile CDR
on Kubernetes. It has been well tested on Amazon EKS and has growing compatibility for Azure
AKS.

## Feature Matrix
The Smile CDR Helm Chart supports a number of features to help you install Smile CDR in a secure, reliable,
cost effective and scalable manner with operational efficiency in mind.

<!-- Included features fall into the following categories:

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
    * Features to help you operate effectively -->

### Application Features

This following table shows you the Smile CDR features that are currently supported by this Helm Chart ***"out-of-the-box"***, which platform (AWS EKS / Azure AKS) they are supported on and the required Smile CDR and Helm Chart versions:

|Smile CDR Feature|EKS|AKS|Notes| Smile CDR Version |Helm Chart Version|
|-----------------|---|-----|-----|-------------------|------------------|
|Install Smile CDR `2023.08` |:material-check:|:material-close:|Smile CDR `2023.05` is the minimum supported version.<br>[Helm Install Guide](../../guide/smilecdr/install.md)|`2023.08.R01`|`v1.0.0-pre92`|
|Minor version upgrades|:material-check:|:material-close:|Upgrade by overriding image tag.<br>[Smile CDR Upgrades](https://smilecdr.com/docs/installation/upgrading.html#upgrading-an-existing-installation)|`2023.08.R01`|`v1.0.0-pre92`|
|Flexible *CDR Node* cluster configurations|:material-check:|:material-close:|Configuration for single-node or multi-node Smile CDR cluster designs. [Cluster Configuration](../../guide/smilecdr/modules/cdrnode.md)|`2023.08.R01`|`v1.0.0-pre93`|
|Cluster Scaling|:material-check:|:material-close:|Horizontal Pod Autoscaling may be enabled. You need sufficient licenced core allocation if using autoscaling.<br>[Smile CDR Scaling](https://smilecdr.com/docs/clustering/designing_a_cluster.html#adding-and-removing-processes)|`2023.08.R01`|`v1.0.0-pre92`|
|Configuration of CDR Modules|:material-check:|:material-close:|All modules can be configured and updated with zero downtime.<br>[Module Configuration using Helm Chart](../../guide/smilecdr/modules/modules.md)|`2023.08.R01`|`v1.0.0-pre92`|
|Postgres Database|:material-check:|:material-close:|Supports multiple databases. i.e. for Clustermgr, Persistence, Audit etc.<br>[Database Configuration using Helm Chart](../../guide/smilecdr/database-overview.md)|`2023.08.R01`|`v1.0.0-pre92`|
|JVM Tuning|:material-check:|:material-close:|[Resource Tuning using Helm Chart](../../guide/smilecdr/tuning/resources.md)|`2023.08.R01`|`v1.0.0-pre92`|
|Kafka Message Broker|:material-check:|:material-close:|[Message Broker Configuration using Helm Chart](../../guide/smilecdr/messagebroker.md)|`2023.08.R01`|`v1.0.0-pre92`|
|Add files to `classpath` or `customerlib`|:material-check:|:material-close:|[Including Files using Helm Chart](../../guide/smilecdr/storage/files.md)|`2023.08.R01`|`v1.0.0-pre92`|
|HL7 v2.x with `HL7_OVER_HTTP`|:material-check:|:material-close:|[Configuring HL7 v2.x Endpoint using Helm Chart](../../guide/smilecdr/modules/hl7v2.md)|`2023.08.R01`|`v1.0.0-pre92`|
|License Module|:material-check:|:material-close:|[Configuring License using Helm Chart](../../guide/smilecdr/modules/license.md)|`2023.08.R01`|`v1.0.0-pre92`|


The following Smile CDR features are not currently supported:

| Smile CDR Feature | Notes | GitLab Issue |
|-------------------|-------|--------------|
|Install Smile CDR `2023.02` and lower | Core module configuration changes were made in `2023.05.R01`, so this Helm Chart does not officially support lower versions. See [CDR Versions](../../guide/smilecdr/cdrversions.md) section for more info|NA|
|Zero Downtime Upgrades|Support planned to be added. See Smile CDR Docs for info on Zero Downtime Upgrades [here](https://smilecdr.com/docs/installation/upgrading.html#upgrading-a-cluster-of-servers-with-zero-downtime)|[GitLab Issue](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/-/issues/17)|
|Pre-Seeding Users| [Smile CDR Docs](https://smilecdr.com/docs/installation/pre_seeding.html#users)|[GitLab Issue](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/-/issues/92)|
|Pre-Seeding OIDC Servers| [Smile CDR Docs](https://smilecdr.com/docs/installation/pre_seeding.html#oidc-servers)|[GitLab Issue](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/-/issues/92)|
|Pre-Seeding OIDC Clients| [Smile CDR Docs](https://smilecdr.com/docs/installation/pre_seeding.html#oidc-clients)|[GitLab Issue](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/-/issues/92)|
|Pre-Seeding OIDC Keystores| [Smile CDR Docs](https://smilecdr.com/docs/installation/pre_seeding.html#keystores)|[GitLab Issue](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/-/issues/92)|
|Pre-Seeding Packages| [Smile CDR Docs](https://smilecdr.com/docs/installation/pre_seeding.html#packages)|[GitLab Issue](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/-/issues/92)|
|Pre-Seeding FHIR Resources| [Smile CDR Docs](https://smilecdr.com/docs/installation/pre_seeding.html#packages)|[GitLab Issue](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/-/issues/92)|
|IAM Auth for RDS Databases| Support for IAM database auth to be added |[GitLab Issue](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/-/issues/82)|
|MSSQL Databases| Support for MS SQL databases to be added |[GitLab Issue](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/-/issues/93)|
|Oracle Databases| Support for Oracle databases to be added |[GitLab Issue](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/-/issues/93)|
|MongoDB Databases| Support for MongoDB databases to be added |[GitLab Issue](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/-/issues/91)|
|ActiveMQ Message Broker| Support not currently planned | NA |

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
* **NEW!!!** Enhanced pod security
    * Pods run as non-root, non-privileged
    * Privilege escalation disabled
    * Read-only root filesystem
    * All container security capabilities disabled
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
