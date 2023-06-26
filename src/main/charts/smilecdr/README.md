# Smile CDR

![Version: 1.0.0-pre.85](https://img.shields.io/badge/Version-1.0.0--pre.85-informational?style=flat-square) ![Smile CDR Version: 2023.05.R02](https://img.shields.io/badge/Smile%20CDR%20Version-2023.05.R02-informational?style=flat-square)

This chart provides a flexible and consistent process to deploy Smile CDR in a self-managed Kubernetes cluster.

It is provided by Smile Digital Health as a starting point for creating a reference implementation of Smile CDR on K8s.
It has been fully tested on Amazon EKS and has growing compatibility for Azure AKS.

## ** PRE-RELEASE WARNING **
This is ***PRE-RELEASE*** version 1.0.0-pre.85

As this is a pre-release version of this chart, there may be **breaking changes** introduced without notice.

Only use this version of the chart for evaluation or testing.

Before performing a `helm upgrade` on your release, first get the current version using
`helm list` and check the [Change Log](../../../CHANGELOG-PRE.md) for information on any
breaking changes you may need to prepare for.

## Features

* Uses the latest official Smile CDR Docker images
  * Also supports previous Smile CDR versions
* 'Configuration-as-code' management of all Smile CDR module definitions & settings
* Automatic configuration of Kubernetes Services and Ingresses
* Multiple databases supported (Separate DB for cluster manager and one or more persistence DB)
* Flexible JVM tuning with sane defaults
* Adding extra files to the deployment without building new images
* Kafka configuration
* Multiple ingress options with TLS termination at load Balancer
    * [Nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
    * [AWS Load Balancer Controller](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html)
    * [Azure Application Gateway Ingress Controller](https://azure.github.io/application-gateway-kubernetes-ingress/)
* [IAM roles for service accounts](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) -
  Smile CDR pods run with their own IAM role, independent and isolated from other workloads on the cluster.
* [Secrets Store CSI Driver](https://secrets-store-csi-driver.sigs.k8s.io/) - Store secrets in a secure vault, and not in your code.
    * Currently only implemented with [AWS SSCSI Provider](https://github.com/aws/secrets-store-csi-driver-provider-aws) -
    (Uses [AWS Secrets Manager](https://aws.amazon.com/secrets-manager/))
    * Support for other [SSCSI providers](https://secrets-store-csi-driver.sigs.k8s.io/providers.html) may be implemented as required
* Fault Tolerance & High Availability when running 2 or more Pods
* Zero-downtime configuration changes
* Horizontal Auto-Scaling (Within bounds of Smile CDR license) - to ensure cost effective use of compute resources

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
For a guide on how to get up and running, see the Quickstart section in the main [documentation](https://smilecdr-public.gitlab.io/smile-dh-helm-charts)

# Default Values

The below section gives an overview of the default values available. Consult the docs for more detailed information.
## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| autoDeploy | bool | `true` | Enable or disable automatic deployment of changes to Smile CDR configuration |
| autoscaling.enabled | bool | `false` | Enable or disable autoscaling |
| autoscaling.maxReplicas | int | `4` | Depends on peak workload requirements and available licensing |
| autoscaling.minReplicas | int | `1` | Recommend 1 for dev environments, 2 for prod or 3 for HA prod |
| autoscaling.targetCPUUtilizationPercentage | int | `80` |  |
| copyFiles.config.awscli.image | string | `"amazon/aws-cli:2.11.25"` |  |
| copyFiles.config.awscli.runAsUser | int | `1000` |  |
| copyFiles.config.curl.image | string | `"curlimages/curl:8.1.2"` |  |
| copyFiles.config.curl.runAsUser | int | `100` |  |
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
| database.crunchypgo.users[1].module | string | `"audit"` |  |
| database.crunchypgo.users[1].name | string | `"audit"` |  |
| database.crunchypgo.users[2].module | string | `"transaction"` |  |
| database.crunchypgo.users[2].name | string | `"transaction"` |  |
| database.crunchypgo.users[3].module | string | `"persistence"` |  |
| database.crunchypgo.users[3].name | string | `"persistence"` |  |
| database.external.credentials | object | `{}` |  |
| database.external.databases[0].dbnameKey | string | `"dbname"` |  |
| database.external.databases[0].module | string | `"clustermgr"` |  |
| database.external.databases[0].passKey | string | `"password"` |  |
| database.external.databases[0].portKey | string | `"port"` |  |
| database.external.databases[0].secretName | string | `"smilecdr"` |  |
| database.external.databases[0].urlKey | string | `"url"` |  |
| database.external.databases[0].userKey | string | `"user"` |  |
| database.external.enabled | bool | `false` | Enable database external to K8s cluster |
| extraEnvVars | list | `[]` |  |
| extraVolumeMounts | object | `{}` |  |
| extraVolumes | object | `{}` |  |
| image.imagePullSecrets | list | `[]` | You may leave undefined if using ECR and your worker nodes have instance profiles with an appropriate IAM role to access the registry. |
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
| messageBroker.adminPod.enabled | bool | `false` |  |
| messageBroker.clientConfiguration.consumerProperties."heartbeat.interval.ms" | int | `3000` |  |
| messageBroker.clientConfiguration.consumerProperties."max.poll.interval.ms" | int | `300000` |  |
| messageBroker.clientConfiguration.consumerProperties."max.poll.records" | int | `20` |  |
| messageBroker.clientConfiguration.consumerProperties."session.timeout.ms" | int | `10000` |  |
| messageBroker.clientConfiguration.producerProperties | object | `{}` |  |
| messageBroker.external.config.authentication.type | string | `"tls"` |  |
| messageBroker.external.config.authentication.userCert | object | `{}` |  |
| messageBroker.external.config.connection.caCert | object | `{}` | Mandatory: External message broker bootstrap address bootstrapAddress: kafka-example1.local, kafka-example2.local |
| messageBroker.external.config.connection.type | string | `"tls"` |  |
| messageBroker.external.enabled | bool | `false` |  |
| messageBroker.external.type | string | `"kafka"` | External message broker type |
| messageBroker.manageTopics | bool | `true` |  |
| messageBroker.strimzi.enabled | bool | `false` | Enable provisioning of Kafka using Strimzi Operator |
| messageBroker.topics.batch2.name | string | `"batch2.work.notification.Masterdev.persistence"` |  |
| messageBroker.topics.batch2.partitions | int | `10` |  |
| messageBroker.topics.subscription.name | string | `"subscription.matching.Masterdev.persistence"` |  |
| messageBroker.topics.subscription.partitions | int | `10` |  |
| modules.useDefaultModules | bool | `true` | Enable or disable included default modules configuration |
| replicaCount | int | `1` | Number of replicas to deploy. Note that this setting is ignored if autoscaling is enabled. Should always start a new installation with 1 |
| resources.limits.memory | string | `"4Gi"` | Memory allocation |
| resources.requests.cpu | string | `"1"` | CPU Requests |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.create | bool | `false` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | Autogenerated if not set |
| specs.hostname | string | `"smilecdr-example.local"` | Hostname for Smile CDR instance |
| specs.rootPath | string | `"/"` |  |
