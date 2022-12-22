# Smile CDR

![Version: 1.0.0-pre.34](https://img.shields.io/badge/Version-1.0.0--pre.34-informational?style=flat-square) ![Smile CDR Version: 2022.11.R01](https://img.shields.io/badge/Smile%20CDR%20Version-2022.11.R01-informational?style=flat-square)

This chart provides a flexible and consistent process to deploy Smile CDR in a self-managed Kubernetes cluster.

It is provided by Smile Digital Health as a starting point for creating a reference implementation of Smile CDR on K8s.
It has been fully tested on Amazon EKS and has growing compatibility for Azure AKS.

## <p style="text-align:center">** PRE-RELEASE WARNING **</p>
This is ***PRE-RELEASE*** version 1.0.0-pre.34

As this is a pre-release version of this chart, there may be **breaking changes** introduced without notice.

Only use this version of the chart for evaluation or testing.

Before performing a `helm upgrade` on your release, first get the current version using
`helm list` and check the [Change Log](../../../CHANGELOG-PRE.md) for information on any
breaking changes you may need to prepare for.

## Features
This chart supports a number of features to help you install Smile CDR in a secure, reliable, cost effective and
scalable manner with operational efficiency in mind. The provided features span multiple disciplines:
* Application
* Infrastructure
* Security
* Reliability
* Operational efficiency

### Application Features
This chart supports the following Smile CDR features *"out-of-the-box"*:
* Uses the latest official Smile CDR Docker images
  * Also supports previous Smile CDR versions
* 'Configuration-as-code' management of all module definitions & settings
* Automatic configuration of Kubernetes Services and Ingresses
* Multiple databases supported (Separate DB for cluster manager and one or more persistence DB)
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
#### Ingress Options
* TLS termination at load Balancer
* [Nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
* [AWS Load Balancer Controller](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html)
* [Azure Application Gateway Ingress Controller](https://azure.github.io/application-gateway-kubernetes-ingress/)
* Coming soon...
  * Multiple Ingress (e.g. internal and external, for different modules)
  * End-to-end TLS encryption
  * Support for other ingress controllers may be implemented as required

### Security Features
It's no good having an easy to use Helm Chart if you cannot use it in a secure manner.
As such, we have included the following features when running on Amazon EKS (Other providers to follow):
* [IAM roles for service accounts](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) -
  Smile CDR pods run with their own IAM role, independent and isolated from other workloads on the cluster.
* [Secrets Store CSI Driver](https://secrets-store-csi-driver.sigs.k8s.io/) - Store secrets in a secure vault, and not in your code.
  * Currently only implemented with [AWS SSCSI Provider](https://github.com/aws/secrets-store-csi-driver-provider-aws) -
  (Uses [AWS Secrets Manager](https://aws.amazon.com/secrets-manager/))
  * Support for other [SSCSI providers](https://secrets-store-csi-driver.sigs.k8s.io/providers.html) may be implemented as required

### Reliability Features
* High Availability when running 2 or more Pods
* Self healing - Failed pods get restarted
* Pod disruption budgets (Prevents accidental outages)

### Operational Efficiency Features
* Zero-downtime configuration changes (Using rolling deployments)
* Horizontal Auto-Scaling (Within bounds of Smile CDR licence) - to ensure cost effective use of compute resources
* Coming soon...
  * [Zero-downtime upgrades](https://smilecdr.com/docs/installation/upgrading.html#upgrading-a-cluster-of-servers-with-zero-downtime) with controllable manual/automatic schema upgrades
  * Management dashboard for consolidated logs and metrics gathering for all components in the deployment

### Automated dependency provisioning
You can use this chart to configure and automatically deploy the following components.
If enabled, they will automatically be configured in a production-like configuration, although we do not
recommend using them in production environments at this time.

* Postgres Database - Using the [CrunchyData Postgres Operator](https://access.crunchydata.com/documentation/postgres-operator/v5/)
* Kafka Cluster - Using the [Strimzi Kafka Operator](https://strimzi.io/docs/operators/latest/overview.html)
* Coming soon...
  * MongoDB

> With these components installed in your Kubernetes cluster, you can provision an entire Smile CDR stack,
complete with persistent backed-up database and a Kafka cluster in about 5-10 mins.
May take longer if your K8s cluster needs to scale up nodes first.

# Getting Started
Although we try to make this chart easy to use, there are a number of prerequisites that must be in place before deploying.
Due to the complicated nature of configuring the product, and enforcing strong security practices, there is no ***quickstart***
option without ensuring some, or all, of these pre-requisites have been met.

## Prerequisites
In order to deploy Smile CDR using this chart, you will need the following:

### Minimum Requirements
These dependencies are sufficient to get you started with deploying an instance for testing purposes.
* Access to an OCI container repository with the required Smile CDR Docker images
* Kubernetes Cluster that you have suitable permissions for
* Sufficient spare compute resources on the Kubernetes cluster.
  * Minimum spare of 1 vCPU and 4GB memory for a 1 pod install of just Smile CDR
* An Ingress controller. One of:
  * [Nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
  * [AWS Load Balancer Controller](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html)
  * [Azure Application Gateway Ingress Controller](https://azure.github.io/application-gateway-kubernetes-ingress/)
* TLS certificate that can be provisioned on the load balancer used by the Ingress objects
* DNS entries pointing to load balancer. e.g. [Amazon Route 53](https://aws.amazon.com/route53/)
* Database. One of:
  * Externally provisioned database in the supported databases list [here](https://smilecdr.com/docs/getting_started/platform_requirements.html#database-requirements)
  * CrunchyData Postgres Operator installed in cluster. Instructions [here](https://access.crunchydata.com/documentation/postgres-operator/v5/)

### Recommended Requirements
These dependencies are recommended in order to follow security best practices. These are in addition to those listed above.
* Kubernetes/EKS/AKS cluster should be configured with best practices in mind.
  * [Kubernetes best practices](https://kubernetes.io/docs/home/)
  * [Amazon EKS best practices](https://aws.github.io/aws-eks-best-practices/)
  * [Azure AKS best practices](https://learn.microsoft.com/en-us/azure/aks/best-practices)
* Kubernetes cluster should, at the very least, have the following configurations
  * Encrypted `etcd`
  * Storage Class with encryption enabled if using Postgres or Kafka
  * Enforce all pods should set resource requests
* AWS IAM Role for the Smile CDR application.
  * Should follow the [principle of least privilege](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#grant-least-privilege) and only have access to required AWS services
* [Secrets Store CSI Driver](https://secrets-store-csi-driver.sigs.k8s.io/) + Provider
  * Only the [AWS Provider](https://github.com/aws/secrets-store-csi-driver-provider-aws) is supported at this time
  * AWS IAM Role needs access to read & decrypt the secrets in AWS Secrets Manager

### Extra Requirements
* [Strimzi Kafka Operator](https://strimzi.io/docs/operators/latest/overview.html)
  * Allows you to install a production ready Kafka cluster as a part of the Smile CDR deployment.

## Installation
### Install the Helm Chart repository:
Currently, the Helm Chart repository is hosted in Smile Digital Health's private GitLab account.
You will need a GitLab PAT (Personal Access Token) in order to install from this repository.
```shell
$ helm repo add --username <gitlab username> smilecdr https://gitlab.com/api/v4/projects/40759898/packages/helm/devel
$ helm repo update
```
### Create a Helm values file for your environment.
This chart will install a base set of modules similar to a default installation of Smile CDR.
Configuration of modules will be covered further down this guide.

To use this chart, you need a values file to set some mandatory fields to set the hostname, DB details
and image secrets location.

> **Note:** Try not to copy the default `values.yaml` file from the Helm Chart as a base. Even though this
will work, the default values file is very long, which can make it hard to track the actual changes
(vs default) that you have made to your environment. You also run the risk of overwriting upstream changes
to the default values file which could cause unpredictable failures during upgrades using `helm upgrade`.
Instead, try to start with a blank values file and only include the changes you need to make for your
environment. <!-- See the section on **Values File Techniques** for more information. -->

The following values file will work in any Kubernetes environment that has Nginx Ingress, CrunchyData PGO and a
suitable Persistent Volume storage provider (For the database). You will need to update values specific to your
environment and include credentials for a container repository that contains the Smile CDR Docker images.

#### `my-values.yaml`
```yaml
specs:
  hostname: smilecdr.mycompany.com
image:
  repository: docker.smilecdr.com/smilecdr
  credentials:
    type: values
    values:
    - registry: docker.smilecdr.com
      username: <DOCKER_USERNAME>
      password: <DOCKER_PASSWORD>
database:
  crunchypgo:
    enabled: true
    internal: true
```
> **WARNING**: This method of providing Docker credentials in the values file is only for
quick-start demonstration and should not be used in real environments with sensitive
credentials. You should use a secret provider such as k8s or AWS Secrets Manager.

### Install the Helm Chart
```shell
$ helm upgrade -i my-smile-env --devel -f my-values.yaml smilecdr/smilecdr
```

**Smile, we're up and running! :)**

After about 2-3 minutes, all pods should be in the `Running` state with 1/1 `Ready` containers.
```shell
$ kubectl get pods
NAME                                 READY   STATUS      RESTARTS        AGE
my-smile-env-pg-backup-xsc6-trp8d    0/1     Completed   0               2m29s
my-smile-env-pg-instance1-84cn-0     0/3     Pending     0               2m59s
my-smile-env-pg-instance1-9tkd-0     3/3     Running     0               2m59s
my-smile-env-pg-repo-host-0          1/1     Running     0               2m59s
my-smile-env-scdr-5b449f8749-6ksnc   1/1     Running     2 (2m28s ago)   2m59s
```
> **NOTE**: Don't be alarmed about the restarts. This was because the database was not ready yet.
This demonstrates how the pod self-healed by restarting until the DB became available.

At this point, your Smile CDR instance is up and can be accessed at the configured URL.
You can try re-configuring it using the instructions below, or you can delete it like so:
```shell
$ helm delete my-smile-env
```
> **WARNING**: If you delete the helm release, the underlying `PersistentVolume` will also be deleted
and you will lose your database and backups. You can prevent this by using a custom `StorageClass` that sets the `ReclaimPolicy` to `Retain`.

## Configuration
We have tried to make this Helm Chart very flexible so that you can configure
it to deploy Smile CDR in a way that works in your environment.

### Default configuration
Using the Helm values file described above, without any advanced configuration options, you will end up with:
* Smile CDR deployed in a default non-production ready configuration.
* Modules configured based on the Smile CDR default modules.
* A single Pod deployment. This is important as you should perform the initial
  install with a single node. If required, you can scale up after install is complete.
* Pod resources configured to use 1 vCPU and 4GB memory
* JVM autoconfigured to use 2GB max heap (50% of total Pod memory)
* 1 HA Postgres database, shared between the cluster manager and the persistence module
  * 2 Pods each use 1vCPU, 2GiB memory, 10GiB data volume, 10GiB backups volume

All of the above can be modified and tuned to suit your needs as will be described below.

### Image Credentials
In order to install Smile CDR using this chart, you need to provide credentials for a container
registry that contains the Smile CDR Docker image.

There are currently 3 ways to specify your OCI container registry credentials.

| Method | Security | Difficulty | Notes |
|--------|----------|------------|-------|
|Secrets Store CSI|High|Hardest|Recommended method. You will need the SSCSI driver, AWS Secrets Manager Secret and an IAM role|
|Kubernetes Secret|Medium|Medium|Need to manually set up Kubernetes Secret|
|Values File|Low|Easiest|K8s secret created by chart. Password is in your code (Bad)|

#### Secrets Store CSI Driver
Currently, this chart only supports the Secrets Store CSI Driver with the AWS Secrets Manager provider
To use this method, you need to:
* Create a secret in AWS Secrets Manager
* Create an IAM role that has read access to the secret and the KMS key used to encrypt it
  * This role will also be used for any other AWS services that the Smile CDR application will need to access, so name it accordingly, e.g. `smile-role`
* Create a trust policy for the IAM role so that it can be used with IRSA. Instructions [here](https://docs.aws.amazon.com/eks/latest/userguide/associate-service-account-role.html)
  * These instructions use the `eksctl` command which abstracts away some details into CloudFormation templates. Using something like Terraform would require different steps
* Enable the `ServiceAccount` and reference the IAM role in the annotations. See the section below about Service Account Configuration for more details
* Specify the `image.credentials.type` as `sscsi`
* Specify the `image.credentials.provider` as `aws`
* Specify the AWS Secret ARN in `image.credentials.secretarn`

#### Kubernetes Secret
To use this method, you need to:
* Create a Kubernetes secret of type `kubernetes.io/dockerconfigjson`
* Specify the `image.credentials.type` as `externalsecret`
* Reference the Secret name in `image.credentials.pullSecrets[0].name`

#### Values File
To use this method, you need to:
* Specify the `image.credentials.type` as `values`
* Under `image.credentials`, provide `repository`, `username` and `password`

> **Warning**: This method is not recommended as it puts passwords into your Helm Values file.
It can be hard to manage the security and rotation of passwords when being stored like this.

If you do not specify image credentials, the chart will fail to render any output and will return a
descriptive error instead

### Configure Resources
As Smile CDR is a high performance Java based application, special consideration needs
to be given to the resource settings and JVM tuning parameters.

Typical cloud best practices suggest starting small and increasing resources as workload increases.
We have tested Smile CDR in its default module configuration and determined that the max heap size
should be no smaller than 2GB. When smaller than this, there are excessive GC events which is not ideal.

> **NOTE**: If you reconfigure Smile CDR to have more modules, it may require more memory/cpu. If you
split up the cluster into multiple nodes, then each node may be able to run with less memory/cpu,
though total cluster may end up higher depending on your architecture.

When running Java applications in Kubernetes, the `requests.memory` should be set much higher than the
max heap size. Typically the Java heap size should be set to 50-75% of the total available memory.

This Helm Chart will take the specified `limits.memory` and use `jvm.memoryFactor` to calculate the
value for the Java heap size. By default, this value is `0.5`. With the default `limits.memory` of
4Gib, the chart sets Java `-Xmx` to `2048m`.

Setting this number higher will make more efficient use
of memory resources in your K8s cluster, but may increase the likelihood of `OOM Killed` errors.

If you were to set it to `1` your pod will be almost guaranteed to be killed with such an error, but it
will happen at an unpredictable time, once the currently allocated heap grows to a certain point. This
can be unpredictable, as it may fail in a few minutes, or a few hours/days/weeks/never depending on the
workload.

To reduce the likelihood of such unpredictable `OOM Killed` errors, we recommend setting `-Xms` to be the same
as `-Xmx`. This can be done by setting `jvm.xms` to `true`

`requests.memory` will be set to the same
value as `limits.memory` unless you override it.

The values used for CPU resources will depend on the number of cores you are licenced for. Your total
cores can be calculated by `replicas * requests.limits.cpu`, or `autoscaling.maxReplicas *
requests.limits.cpu` if you are using Horizontal Pod Autoscaling.

> **NOTE**: You can pass in extra JVM commandline options by adding them to the list `jvm.args`

### Database Configuration
To use this chart, you must configure a database. There are two ways to do this:
* Use or provision an external database (or databases) using existing techniques/processes in your
  organisation. Any external database can be referenced in this chart and Smile CDR will be configured
  to use it.
* As a quick-start convenience, support has been included to provision a PostgreSQL cluster locally in
  the Kubernetes cluster using the CrunchyData PostreSQL Operator. When enabling this option, the
  database(s) will be automatically created and Smile CDR will be configured to connect to it.

If you do not specify one or the other, the chart will fail to render any output and will return a
descriptive error instead

> **WARNING**: Due to the ephemeral and stateless nature of Kubernetes Pods, there is no use case
where it makes sense to provision Smile CDR using the internal H2 database. You are free to configure
your persistence module to do so, but every time the Pod restarts, it will start with an empty
database and will perform a fresh install of Smile CDR. In addition to this, if you were to configure multiple replicas,
each Pod would appear as its own distinct Smile CDR install. As such, you should not configure Smile CDR
in this fashion and you must instead provision some external database.

#### Referencing Externally Provisioned Databases
To reference a database that is external to the cluster, you will need:
* Network connectivity from the K8s cluster to your database.
* A secret containing the connection credentials in a structured Json format.
  * It is common practice to include all connection credentials in DB secrets, this way it becomes simple
  to manage the database without having to reconfigure Smile CDR. e.g. when 'restoring' an RDS instance, the
  DB cluster name will typically change. If this is kept inside the secret (As it is with RDS when using AWS
  Secrets Manager) then any such change will be automatically applied. See
  [here](https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_secret_json_structure.html#reference_secret_json_structure_rds-postgres)
  for info on the schema used by AWS for this purpose.
  * The secret can be a plain Kubernetes secret that you provision externally, or it can be a secret in a
  secure secrets vault. The latter is the preferred option for increased security and the ability to easily
  rotate credentials. At this time, only AWS Secrets Manager is supported via the Secrets Store CSI Driver.

If using AWS Secrets Manager, set the `credentials.type` to `sscsi` and `credentials.provider` to `aws`. If you have created a `Secret` object
in Kubernetes, set it to `externalsecret`.

##### Example Secret Configuration
Assuming you are using AWS Secrets Manager, and you have the `url`, `port', `user` and `password` keys
included in the secret, you should configure your secret as per the following yaml fragment.

If the included fields are different in the provided secret, they can be
specified with the `*Key` values to override the below defaults.

The below are just examples, to show how the fields can be specified in different ways. You need to
ensure that this matches the configuration of your secret and the fields it contains.
#### `my-values.yaml`
```yaml
database:
  external:
    enabled: true
    credentialsSource: sscsi-aws (or k8s)
    databases:
    - secretName: smilecdr
      module: clustermgr
      urlKey: url # this is the key name that holds the url/hostname in the secret
      portKey: port
      dbnameKey: dbname
      userKey: user
      passKey: password
```

If a required field is not included in the secret, you can specify it in your values file like so.

#### `my-values.yaml`
```yaml
- secretName: smilecdr
  module: clustermgr
  url: db-url # this is the actual url/hostname
  port: 5432
  dbname: dbname
  user: username
  passKey: password
```
> **NOTE**: You cannot override the passKey value. The password will always come from the
referenced secret.

#### Using CrunchyData PGO Databases
In order to use this feature, you will need to ensure that your K8s cluster has the CrunchyData PGO
already installed (Instructions [here](https://access.crunchydata.com/documentation/postgres-operator/v5/installation/)).
Simply enable this feature using the following yaml fragment for your database configuration:
#### `my-values.yaml`
```yaml
database:
  crunchypgo:
    enabled: true
    internal: true
```
This will create a 2 instance HA PostgreSQL cluster, each with 1cpu, 2GiB memory and 10GiB
storage. These defaults can be configured using `database.crunchypgo.config` keys. Backups are enabled
by default as it's a feature of the Operator.

#### Configuring Multiple Databases
This chart has support to use multiple databases. It is recommended to configure Smile CDR this way, with
a separate DB for the Cluster Manager and for any Persistence Modules.

The `module` key is important here as it tells the Helm Chart which module uses this database.
If there is only one database then it will be used for all modules.

If you provide multiple databases, the `module` key specified in each one is used to determine which
Smile CDR module it is used by.

With multiople databases, the above examples may look like this:

> **Note** The CrunchyData PGO is a little different in that it uses the concept of 'users' in the configuration
to configure multiple databases. That is why we are specifying multiple users below in the **CrunchyData PGO** example.

#### `my-values.yaml` (External Database)
```yaml
database:
  external:
    enabled: true
    credentialsSource: sscsi-aws (or k8s)
    databases:
    - secretName: smilecdr
      module: clustermgr
    - secretName: smilecdr-pers
      module: persistence
```
#### `my-values.yaml` (CrunchyData PGO)
```yaml
database:
  crunchypgo:
    enabled: true
    internal: true
    users:
    - name: smilecdr
      module: clustermgr
    - name: persistence
      module: persistence
```
In both of the above examples, the `clustermgr` and `persistence` modules will both automatically
have their own set of environment variables for DB connections as follows: `CLUSTERMGR_DB_*` and
`PERSISTENCE_DB_*`

> **NOTE**: You do NOT need to update these environment variable references in your module
configurations. When the `clustermgr` module definition references `DB_URL`, this will be
automatically mutated to `CLUSTERMGR_DB_URL`. This will happen automatically for any module that
references `DB_*` environment variables.

### Module Configuration
Configuring modules is fairly straight forward, but somewhat different
than the existing methods using the `cdr-config-Master.properties` file.
Note that this file is still used behind the scenes, but it is generated by the Helm Chart
and injected into the running pod using `ConfigMap`, `Volume` and `VolumeMount` resources.

> **NOTE**: When using Helm Charts, they become the 'single source of truth' for
your configuration. This means that repeatable, consistent deployments become a
breeze. It also means you should no longer edit your options in the Smile CDR web
admin console.

You can define your modules in your main values file, or you can define them
in separate files and include them using the `-f` command. This is possible because Helm
[accepts multiple values files](https://helm.sh/docs/chart_template_guide/values_files/)

We recommend defining them in one or more separate files, as this allows you
to manage common settings as well as per-environment overlays. We will discuss this further
down in the Advanced Configuration section below.

Mapping existing configurations to values files is relatively straight forwards:
#### Identify the module configuration parameter.
e.g. [Concurrent Bundle Validation](https://smilecdr.com/docs/configuration_categories/fhir_performance.html#property-concurrent-bundle-validation)
Config.properties format:
`module.persistence.config.dao_config.concurrent_bundle_validation = false`
#### Specify them in th values yaml file format:
```yaml
modules:
  persistence:
    config:
      dao_config.concurrent_bundle_validation: "false"
```
The same effective mapping can be used for any module configurations supported by Smile CDR.
#### Module definition considerations
Here are some additional fields/considerations that need to be included in your module definitions files:
* Though not strictly required by the `yaml` spec, all values should be quoted.
  You may run into trouble with some values if you do not quote them.
  Specifically, values starting with `*` or `#` will fail if not quoted.
* The `module id` is taken from the yaml key name.
* Modules can be defined, but disabled. They need to be enabled with the `enabled: true` entry.
* Modules other than the cluster manager need to define `type`. A list of module types is available [here](https://smilecdr.com/docs/product_reference/enumerated_types.html#module-types)
* Modules which expose an endpoint need to de defined with a `service` entry, which includes `enabled` and `svcName` entries.
* DB credentials/details can be referenced from your module configurations via `DB_XXX` environment variables.

Any configurations you specify will merge with the defaults, priority going to the values file.

#### Disabling included default module definitios
If you wish to disable any of the default modules, we recommend you disable all default modules and define
your own from scratch. This way it will be easier to determine the exact modules you have defined just by
looking at your values files.
You can disable all default modules using:
```yaml
modules:
  useDefaultModules: false
```
You use the `default-modules.yaml` file as a reference by untarring the Helm Chart.

Here is an example of what your module definition may look like when configuring
Smile CDR with the `clustermgr`, `persistence`, `local_security`,
`fhir_endpoint` and `admin_web` modules.
#### `my-module-values.yaml`
<details>
  <summary>Click to expand</summary>

```yaml
modules:
  useDefaultModules: false
  clustermgr:
    name: Cluster Manager Configuration
    enabled: true
    config:
      db.driver: POSTGRES_9_4
      db.url: jdbc:postgresql://#{env['DB_URL']}:#{env['DB_PORT']}/#{env['DB_DATABASE']}?sslmode=require
      db.password: "#{env['DB_PASS']}"
      db.username: "#{env['DB_USER']}"
  persistence:
    name: Database Configuration
    enabled: true
    type: PERSISTENCE_R4
    config:
      db.driver: POSTGRES_9_4
      db.url: jdbc:postgresql://#{env['DB_URL']}:#{env['DB_PORT']}/#{env['DB_DATABASE']}?sslmode=require
      db.password: "#{env['DB_PASS']}"
      db.username: "#{env['DB_USER']}"
  local_security:
    name: Local Storage Inbound Security
    enabled: true
    type: SECURITY_IN_LOCAL
    config:
      seed.users.file: classpath:/config_seeding/users.json
      password_encoding_type: BCRYPT_12_ROUND
  admin_web:
    name: Web Admin
    enabled: true
    type: ADMIN_WEB
    service:
      enabled: true
      svcName: admin-web
      hostName: default
    requires:
      SECURITY_IN_UP: local_security
    config:
      context_path: ""
      port: 9100
      tls.enabled: false
      https_forwarding_assumed: true
      respect_forward_headers: true
  fhir_endpoint:
    name: FHIR Service
    enabled: true
    type: ENDPOINT_FHIR_REST_R4
    service:
      enabled: true
      svcName: fhir
      hostName: default
    requires:
      PERSISTENCE_R4: persistence
      SECURITY_IN_UP: local_security
    config:
      context_path: fhir_request
      port: 8000
      base_url.fixed: default
```
</details>

### Install Smile CDR with extra modules definitions
```shell
$ helm upgrade -i my-smile-env --devel -f my-values.yaml -f my-module-values.yaml smilecdr/smilecdr
```

### Configuring Ingress
This chart supports multiple Ingress options, currently including Nginx Ingress, AWS Load Balancer
Controller and Azure Application Gateway Controller.

You can specify which to use with `ingress.type`.
#### Nginx Ingress
If installed in your K8s cluster, the Nginx Ingress can be configured by using `nginx-ingress`.

When using this method, the chart will automatically add `Ingress` annotations for the Nginx Ingress
controller.

When used in conjunction with the AWS Load Balancer Controller, the Nginx Ingress will be backed by an AWS
Network Load Balancer. By default, any ingresses defined will share this load balancer. If you need to separate
applications on the cluster to use separate load balancers, you can do so by creating separate Nginx Ingress
controllers each with their own ingress class name which you can then specify with `ingress.ingressClassNameOverride`

#### AWS Load Balancer Controller
If installed in your K8s cluster, the AWS Load Balancer Controller can be configured by using `aws-lbc-alb`.

When using this method, the chart will automatically add `Ingress` annotations for the AWS Load Balancer Controller.
The controller will then create an AWS Application Load Balancer

#### Azure Application Gateway Controller
If installed in your K8s cluster, the Azure Application Gateway Controller can be configured by using `azure-appgw`.

When using this method, the chart will automatically add `Ingress` annotations for the Azure Application Gateway Controller.
The controller will then create an Azure Application Gateway to be used as ingress.

### Mapping files
It is often required to add extra files into your Smile CDR instance. This could simply be to
provide updated configuration changes (e.g. `logback.xml`) or to provide scripts to extend the
functionality of Smile CDR.

Rather than having to build a new Smile CDR OCI container image with these files included, it is
possible to include them using this Helm Chart.
> **NOTE**: At this time, due to the way Kubernetes works, it is only possible to pass small (<1MiB) files into Smile CDR using This
method, so it is only suitable for configuration files and scripts. Larger files, such as `.jar`
files, other binaries or large datasets are not supported using this method. There will be a
solution for larger files in a future version of this chart.

To pass in files, there are two things you need to do:
1. Use a Helm commandline option to load the file into the deployment
2. Reference and configure the file in your values file.

To include a file in the deployment, use the following commandline option:
```bash
helm upgrade -i my-smile-env --devel -f my-values.yaml --set-file mappedFiles.logback\\.xml.data=logback.xml smilecdr/smilecdr
```
> **WARNING**: Pay special attention to the escaping required to include the period in the filename.
You need to use `\\.` when running this from a shell. This is just the way this works.

This will encode the file and load it into the provided values under the `mappedFiles.logback.xml.data`
key.
This needs to also be referenced from your values file so that the chart knows where to mount
the file in the Pod:
```yaml
mappedFiles:
  logback.xml:
    path: /home/smile/smilecdr/classes
```
As the result of the above, a `ConfigMap` will be created and mapped into the pod at
`/home/smile/smilecdr/classes/logback.xml` using `Volume` and `VolumeMount` resources. If the
contents of the file is changed, then it will be automatically picked up on the next deployment
(See Automatic Deployment of Config Changes below)

### Service Account Configuration
If you are using any features that need access to AWS resources, you should do so using IAM Roles
For Service Accounts. This allows you to attach AWS IAM roles to Kubernetes Service Accounts which
then get attached to Smile CDR Pods.

As a result of this, Smile CDR will be able to access AWS services without needing to pass in AWS
IAM User credentials.

To use this feature, you will need to enable the Service Account and reference the IAM role that it
should be connected to. Note that the IAM role being used needs to have the appropriate Trust Policy
set up so that it can be used by your Cluster. More info and instructions are available
[here](https://docs.aws.amazon.com/eks/latest/userguide/associate-service-account-role.html)

Once the IAM role is set up correctly, you would enable IRSA in your values file like so:
```yaml
serviceAccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/example-role-name
```

#### Options that require Service Account with IRSA
If you need to use any of the below options, then you will need to set up a service account with IRSA
as per the above instructions.
* Secrets Store CSI Driver with the AWS Provider (AWS Secrets Store)
* RDS authentication using IAM roles
* AWS HealthLake connector
* Accessing Amazon MSK (Managed Kafka)
* Accessing S3 buckets

### Message Broker Configuration
Much like with the database configuration, you can use an externally provisioned message broker, or
you can have this chart provision Kafka for you if you have the Strimzi Operator installed in your
cluster.

#### Configuring external message broker.
You can use the `messageBroker.external` section to configure an external message broker as so:
```yaml
messageBroker:
  external:
    enabled: true
    type: kafka
    bootstrapAddress: kafka-example.local
    tls: true
```
You can also do some of the message broker tuning in the `clustermgr` module. The configurations
provided in the `messageBroker` section above will override any in the module definition.

#### Provisioning Kafka with Strimzi
If you have the Strimzi operator installed in your cluster, you can use the following values file
fragment to automate provisioning of a Kafka cluster. Your Smile CDR instance will then be automatically
configured to use this HA Kafka cluster.
```yaml
messageBroker:
  strimzi:
    enabled: true
```
With the above configuration, you will have a production-like Kafka cluster with 3 ZooKeeper nodes
(each with 05cpu & 512MiB memory) 3 Kafka Broker nodes (each with 0.5cpu & 1GiB memory), each with
10GiB storage.

All of the Kafka configurations can be configured using `messageBroker.strimzi.config`.

## Deploying changes
When you deploy changes to the Smile CDR configuration or resources allocation (Amongst other
configurations), the `Deployment` Kubernetes resource will automatically perform a zero-outage
***Rolling Deployment***.

The default behaviour of this is to create one new Pod with the new configuration at a time. Once
each new Pod has successfully started up and is able to accept traffic, Kubernetes will start
routing requests to it and then terminate one of the pods with the older configuration.

The result of this is that the changes will be rolled out over the entire cluster in a controlled
fashion over a few minutes, without any downtime or outage.

This is a conservative rolling deployment model, but it means that if pods with the new configuration
fail to come up without error, then the existing deployment will remain unaffected.

### Automatic Deployment of Config Changes
Due to the way Kubernetes works, if a change does not directly affect a Deployment's Pod
definition then it will not create a deployment. This can cause uncertainty when making changes
as some module configurations will affect the surrounding infrastructure (e.g. an endpoint port/path,
or mounting a file into the Pod) whereas others may only affect module definitions inside Smile CDR.

In the latter case, there will be no update to the Deployment's Pod definition and no deployment will
occur. Typically, some member of an Operations team would then need to recycle the Pods manually to
force the updates.

To circumvent this problem, the Smile CDR Helm Chart automatically deploys all changes by uniquely
identifying any `ConfigMap` objects with a `sha256` hash of the contained data. This means that any
config changes (or changes to included files) will be picked up automatically and deployed without
outage due to the ***Rolling Deployment*** strategy in place.

> **NOTE**: An extra benefit of this technique is that if a new configuration has an error and the pods
fail to come up, then the existing Pods will still use the original configuration, even if they need
to be restarted.

This feature can be disabled if required by setting `autoDeploy` to `false`

If you are using this feature in conjunction with ArgoCD, then previous versions of the `ConfigMap`
will be deleted after you perform configuration changes. This interferes with the ability for the
existing `ReplicaSet` to scale or self-heal.
If running in ArgoCD, you should set `argocd.enabled` to true to prevent this issue.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| autoDeploy | bool | `true` | Enable or disable automatic deployment of changes to Smile CDR configuration |
| autoscaling.enabled | bool | `false` | Enable or disable autoscaling |
| autoscaling.maxReplicas | int | `4` | Depends on peak workload requirements and available licensing |
| autoscaling.minReplicas | int | `1` | Recommend 1 for dev environments, 2 for prod or 3 for HA prod |
| autoscaling.targetCPUUtilizationPercentage | int | `80` |  |
| database.crunchypgo.config.backupsSize | string | `"10Gi"` | PostgrSQL backups storage allocation |
| database.crunchypgo.config.instanceCPU | int | `1` | PostgrSQL cpu allocation |
| database.crunchypgo.config.instanceMemory | string | `"2Gi"` | PostgrSQL memory allocation |
| database.crunchypgo.config.instanceReplicas | int | `2` | Number of Postgres instances to run (For HA) |
| database.crunchypgo.config.instanceSize | string | `"10Gi"` | PostgrSQL storage allocation |
| database.crunchypgo.config.postgresVersion | int | `14` | PostgreSQL version to use |
| database.crunchypgo.enabled | bool | `false` | Enable database provisioned in-cluster via CrunchyData PGO |
| database.crunchypgo.internal | bool | `false` | Create the Postgres database as part of this Helm Chart |
| database.crunchypgo.users[0].module | string | `"clustermgr"` | Smile CDR module that will use this user/database |
| database.crunchypgo.users[0].name | string | `"smilecdr"` |  |
| database.external.credentials | object | `{}` |  |
| database.external.databases[0].dbnameKey | string | `"dbname"` |  |
| database.external.databases[0].module | string | `"clustermgr"` |  |
| database.external.databases[0].passKey | string | `"password"` |  |
| database.external.databases[0].portKey | string | `"port"` |  |
| database.external.databases[0].secretName | string | `"smilecdr"` |  |
| database.external.databases[0].urlKey | string | `"url"` |  |
| database.external.databases[0].userKey | string | `"user"` |  |
| database.external.enabled | bool | `false` | Enable database external to K8s cluster |
| image.credentials | object | `{}` | You must provide image credentials of type `sscsi`, `extsecret` or `values` |
| image.pullPolicy | string | `"IfNotPresent"` | Image Pull Policy |
| image.repository | string | `"docker.smilecdr.com/smilecdr"` | OCI repository with Smile CDR images |
| image.tag | string | `""` | Smile CDR version to install. Default is the chart appVersion. |
| ingress.enabled | bool | `true` | Enable Ingress |
| ingress.type | string | `"nginx-ingress"` | Ingress type (`nginx-ingress`,`aws-lbc-alb`,`azure-appgw`) |
| jvm.args | list | `["-Dsun.net.inetaddr.ttl=60","-Djava.security.egd=file:/dev/./urandom"]` | Set extra JVM args |
| jvm.memoryFactor | float | `0.5` | JVM HeapSize factor. `limits.memory` is multiplied this to calculate `-Xmx` |
| jvm.xms | bool | `true` | Set JVM heap `-Xms` == `-Xmx` |
| labels | object | `{}` | Extra labels to apply to all resources |
| mappedFiles | object | `{}` | Map of file definitions to map into the Smile CDR instance |
| messageBroker.channelPrefix | string | `"SCDR-ENV-"` | Topic Channel Prefix |
| messageBroker.external.bootstrapAddress | string | `"kafka-example.local"` | External message broker bootstrap address |
| messageBroker.external.enabled | bool | `false` | Enable external message broker |
| messageBroker.external.tls | bool | `true` | External message broker TLS support |
| messageBroker.external.type | string | `"kafka"` | External message broker type |
| messageBroker.strimzi.enabled | bool | `false` | Enable provisioning of Kafka using Strimzi Operator |
| modules.usedefaultmodules | bool | `true` | Enable or disable included default modules configuration |
| replicaCount | int | `1` | Number of replicas to deploy. Note that this setting is ignored if autoscaling is enabled. Should always start a new installation with 1 |
| resources.limits.memory | string | `"4Gi"` | Memory allocation |
| resources.requests.cpu | string | `"1"` | CPU Requests |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.create | bool | `false` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | Autogenerated if not set |
| specs.hostname | string | `"smilecdr-example.local"` | Hostname for Smile CDR instance |
| specs.rootPath | string | `"/"` |  |
