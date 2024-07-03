# Message Broker Configuration

This Helm Chart support configuring Smile CDR to work with a Kafka or ActiveMQ message broker as
described in the [Smile CDR documentation](https://smilecdr.com/docs/installation/message_broker.html)

While you can configure any of the message broker settings available in the `clustermgr` module, this process can
be complicated and error prone. This Helm Chart simplifies this process by automatically configuring Smile CDR
message broker and Kafka settings.

You can either configure Smile CDR to use a message broker that has already been provisioned, or if available, you can make
use of the Strimzi Operator to provision Kafka inside the K8s cluster.

## Configuring external message broker
Use the `messageBroker.external` section to configure an external message broker like so (in this example we use Kafka):

```yaml
messageBroker:
  external:
    enabled: true
    type: kafka
    config:
      ...
```

The remaining configuration differs for Kafka and ActiveMQ as described in the sections below.

## Configuring Kafka

To enable a default Kafka configuration, you will need to provide connection and authentication details. For more information on
the settings being used inside the Smile CDR configuration, please refer to the documentation [here](https://smilecdr.com/docs/installation/kafka.html)

### TLS Connectivity
When connecting to Kafka clusters, it is advised to use TLS connections. In a default configuration, Smile CDR will be configured to use TLS.

If you wish to run without enabling encryption (i.e. for testing purposes), you can also specify `plaintext` like so.

```yaml
messageBroker:
  external:
    config:
      connection:
        type: plaintext
```

>**Note:** You cannot use mTLS or IAM authentication methods if you disable TLS

#### Using Custom Certificate Authority
If your external Kafka cluster is configured with a TLS certificate that is signed with a public Certificate Authority (CA) then no further steps are required as the truststore that is included
in the Java distribution will be used.

However, if you need to provide a custom CA certificate, you can do so by providing a `caCert` configuration in the connection settings.

This certificate can be provided using either the `k8sSecret` or `sscsi` secret mechanisms. See the [secrets](../secrets.md) section for more info.

**Using `k8sSecret`**
```yaml
messageBroker:
  external:
    config:
      connection:
        type: tls
        caCert:
          type: k8sSecret
          secretName: my-kafka-ca-cert
```

**Using `sscsi`**
```yaml
messageBroker:
  external:
    config:
      connection:
        type: tls
        caCert:
          type: sscsi
          provider: aws
          secretArn: arn:aws:secretsmanager:us-east-1:012345678901:secret:kafkacacert
```
**CA Cert Secret Format**

The certificate passed in to the chart must have 2 values, with the appropriate keys.

| Key name | Key value |
|--------|----------|
|ca.p12|Trust store containing the CA certificate. Must be provided in the PKCS12 (`.p12`) format|
|ca.password|Password for verifying the contents of the trust store.|

### Authentication
This chart currently supports either Mutual TLS (mTLS) or IAM authentication, depending on the type of Kafka cluster that is being used.

| Cluster Type | mTLS | IAM |
|--------|----------|----------|
|External (Generic)|Y|N|
|Amazon MSK|Y (With Private CA)|Y|
|In-cluster (Strimzi)|Y (Default)|N|

>**Note:** Other authentication mechanisms may be added at a later date.

### mTLS Authentication
To configure mTLS authentication you need to do the following

* Configure Kafka cluster for mTLS.
* Have access to the client certificate for the configured user.
* Configure the connection type to use TLS (See [above](#tls-connectivity)).

Now you can provide the client certificate using `k8sSecret` or `sscsi` as follows:

**Using `k8sSecret`**
```yaml
messageBroker:
  external:
    config:
      connection:
        type: tls
        caCert:
          type: k8sSecret
          secretName: my-kafka-ca-cert
      authentication:
        type: tls
        userCert:
          type: k8sSecret
          secretName: my-kafka-client-cert
```

**Using `sscsi`**
```yaml
messageBroker:
  external:
    config:
      connection:
        type: tls
        caCert:
          type: sscsi
          provider: aws
          secretArn: arn:aws:secretsmanager:us-east-1:012345678901:secret:kafkacacert
      authentication:
        type: tls
        userCert:
          type: sscsi
          provider: aws
          secretArn: arn:aws:secretsmanager:us-east-1:012345678901:secret:kafkaclientcert
```

**User Cert Secret Format**

The user certificate passed in to the chart must have 2 values, with the appropriate keys.

| Key name | Key value |
|--------|----------|
|user.p12|Trust store containing the user certificate and private key. Must be provided in the PKCS12 (`.p12`) format|
|user.password|Password for decrypting the private key.|

### IAM Authentication (Amazon MSK only)
If you are using Amazon MSK as your message broker, IAM is the preferred method of authentication.

Before configuring Smile CDR to use this authentication method, you need to ensure that the following pre-requisites are in place:

* Configure IRSA for the Smile CDR application. See the [Service Accounts](../serviceaccount.md) section for more info on this.
* Ensure that your Smile CDR IAM role has a suitable MSK authorization policy attached. See the [AWS Documentation](https://docs.aws.amazon.com/msk/latest/developerguide/iam-access-control.html#create-iam-access-control-policies) for more information on how to create a suitable IAM authorization policy for MSK.

**Client Configuration**
The AWS documentation details the steps to configure clients to use IAM. This required configuration is automatically applied when enabling IAM in this Helm Chart and there is nothing further to do.

To enable IAM authentication:
```yaml
messageBroker:
  external:
    enabled: true
    config:
      connection:
        type: tls
        bootstrapAddress: my-msk-bootstrap-address1.amazon.com:9098
      authentication:
        type: iam
```

>**Note:** You do not need to provide a trust certificate as Amazon MSK uses endpoints with publically signed TLS certificates

If you plan to manually copy the required IAM authentication Jar file into a custom image, then you can disable the automatic file copying like so:
```yaml
messageBroker:
  external:
    enabled: true
    config:
      connection:
        type: tls
        bootstrapAddress: my-msk-bootstrap-address1.amazon.com:9098
      authentication:
        type: iam
        iamConfig:
          autoJarCopy: false
          # adminAutoJarCopy: false # Optional: See note below
```
>**Note:** If you are using the [Kafka Admin](#admin-pod) pod and you wish to also disable the automated jar copying for this, then you will need to provide a custom Kafka image.


### Consumer & Producer properties
Custom consumer properties and producer properties can be configured using the `messageBroker.clientConfiguration` section as follows:

```yaml
messageBroker:
  clientConfiguration:
    consumerProperties:
      max.poll.records: 20
    producerProperties: {}
```
>**Note:** By default, the consumer properties are configured with the Kafka documented defaults prior to Kafka 3.0

## Topic Auto Creation & Validation
This chart simplifies Kafka topic management by autoconfiguring topic related settings based on your message broker configuration.

**Topic Auto Creation**
By default, the `auto.create.topics.enable` option on Kafka clusters is often set to `true`. With this setting enabled, Kafka will automatically create topics when consumers or producers try to use a topic.

As a general Kafka best practice in production environments, topic auto creation should be disabled by setting this option to `false`. When configured this way, any required topics should be created through some other process.

**Topic Validation**
If topic auto creation is disabled in your Kafka cluster, the following option should also be set in Smile CDR:

[`kafka.validate_topics_exist_before_use`](https://smilecdr.com/docs/configuration_categories/clustermgr_kafka.html#property-validate-kafka-topics-exist-before-use)

This option prevents Smile CDR from trying to send messages to topics that do not exist, which will flood the logs with errors.

As a convenience, the `autoCreateTopics` and `validateTopics` options are auto-configured based on the Kafka configurations provided in your values file as per the below table.

|        Message Broker Config        | Topic Auto Creation | Validate Topics |
|-----------------------------------|:-------------------------:|:---:|
| `external.type: kafka`            | :material-check: | :material-close: |
| `external.type: msk`              | :material-close: | :material-check: |
| `external.type: msk-serverless`   | :material-close: | :material-check: |
| `strimzi.enabled` and `manageTopics: false` | :material-check: | :material-close: |
| `strimzi.enabled` and `manageTopics: true`  | :material-close: | :material-close: |

In certain circumstances, you may wish to override the auto-configured defaults above behaviour by setting `messageBroker.autoCreateTopics` and/or `messageBroker.validateTopics`.

>**Note:** You cannot override topic auto creation for Amazon MSK Serverless as it does not support topic auto creation.

See [here](https://smilecdr.com/docs/installation/kafka.html) for more information on these Kafka settings in Smile CDR.

### Amazon MSK
When creating an Amazon MSK cluster, topic auto creation is disabled by default, which is the recommended configuration for production environments.

If you wish to enable topi cauto creation for development or testing environments, you will need to do the following:

* Create an MSK Custom Configuration that sets `auto.create.topics.enable` to `true`
* Apply this configuration to your MSK cluster.
* Update your values file to override topic validation like so:
    ```yaml
    messageBroker:
      validateTopics: false
    ```

More information on MSK Custom Configurations is available on the [AWS Documentation](https://docs.aws.amazon.com/msk/latest/developerguide/msk-configuration-properties.html)

### Amazon MSK Serverless
Unlike provisioned Amazon MSK, the serverless variant does not allow for topic auto creation. When using Amazon MSK Serverless, you ***must*** create topics using another mechanism.

### Strimzi
If using the Strimzi Operator and configuring this Helm Chart to deploy the Kafka cluster, it is possible to also define the required topics in the values file. When doing this, the `auto.create.topics.enable` will be automatically set to `false` to prevent collisions between topics created by the broker and topics created by the Strimzi Operator. The `kafka.validate_topics_exist_before_use` Smile CDR configuration will also be set to `true`.

## Topic Pre-Provisioning
If you are using a Kafka cluster with `auto.create.topics.enable` to be set to `false` as mentioned above, then you will need to create the topics using some other process.
If you do not already have a process in place for creating Kafka topics, then there are a couple of options.

* Follow the official Kafka documentation for creating topics.</br>This usually involves using a workstation or server with the Kafka binaries and configuration to talk to your Kafka cluster. This can be a tricky process, depending on network security requirements and connectivity/authentication configuration.
* Use a declarative approach to Kafka topic management. Your topics will be defined in code and can be applied to the Kafka cluster in a highly repeatable fashion.

If using either of the above techniques, the default configuration of Smile CDR deployed by this Helm Chart will reqire the following two topics to be created:

* `batch2.work.notification.Masterdev.persistence`
* `subscription.matching.Masterdev.persistence`

If you change the `nodeId` (in `cdrNodes`) or alter the default module configuration, the above names may change and would need to be determined for your configuration.

As a convenience, this Helm Chart provides methods to help with this.

### Strimzi
If using the Strimzi Operator, initial `batch2` and `subscription` topics will automatically be created from the `KafkaTopic` CRDs that get created. You can add or override topics in a declarative fashion using the `messageBroker.topics` section.

>**Note:** You can disable topic management by the Helm Chart & Strimzi by setting `messageBroker.manageTopics` to `false`.

```yaml
messageBroker:
  manageTopics: true
  topics:
    batch2:
      name: "batch2.work.notification.Masterdev.persistence"
      partitions: 10
    subscription:
      name: "subscription.matching.Masterdev.persistence"
      partitions: 10
```

When using this method, the Helm Chart will create a `KafkaTopic` resource for each of the provided topics. Topic creation, configuration and deletion will then be managed by the Strimzi Topic Operator. The Kafka brokers will be configured with `auto.create.topics.enable` set to `false` as per best practice for production environments.

Using this method allows you to define the configuration of your Kafka topics in code for increased repeatability and reliability.

### Admin Pod
This ***experimental*** feature will let you create a `Kafka Admin` pod in the same namespace as your Smile CDR instance. It can be enabled as follows:

```yaml
messageBroker:
  adminPod:
    enabled: true
```

When enabled, there will be a new deployment created that creates a single ephemeral pod. This pod is automatically configured to use the same connectivity (Including required certificates) as the main Smile CDR pods.

You can use this pod to inspect the Kafka cluster, or perform tasks such as creating/deleting topics. This is a convenience feature that should only be used during the development phase and not be used in production environments.

* Connect to the Kafka Admin pod
```sh
kubectl exec -ti <admin-pod-name> -- sh
```

* Check available topics
```sh
./bin/kafka-topics.sh --list
```

* Check consumer groups
```sh
./bin/kafka-consumer-groups.sh --describe --group smilecdr
```

>**Note:** You do not need to provide a config file or bootstrap address on the command-line as it is auto configured.

## Provisioning Kafka with Strimzi
If you have the Strimzi Operator installed in your cluster, you can use the following values file
section to automate provisioning of a Kafka cluster. Your Smile CDR instance will then be automatically
configured to use this Kafka cluster.
```yaml
messageBroker:
  strimzi:
    enabled: true
```

### Configuring Kafka via Strimzi
With the configuration provided above, you will have a production-like Kafka cluster with the followinf configuration:

* 3 ZooKeeper nodes with the following specifications
    * 0.5cpu
    * 512MiB memory
    * 10GiB storage
* 3 Kafka Broker nodes with the following specifications
    * 0.5cpu
    * 1GiB memory
    * 10GiB storage
* TLS connection enabled by default
* mTLS authentication enabled by default

All of the Kafka configurations can be configured using `messageBroker.strimzi.config` like so:

```yaml
messageBroker:
  strimzi:
    enabled: true
    kafka:
      connection:
        type: tls
      authentication:
        type: tls
      version: "3.3.1"
      protocolVersion: "3.3"

      replicas: 4
      volumeSize: 20Gi
      resources:
        requests:
          cpu: 0.5
          memory: 4Gi
        limits:
          memory: 4Gi
    zookeeper:
      replicas: 2
      volumeSize: 10Gi
      resources:
        requests:
          cpu: 0.5
          memory: 512Mi
        limits:
          memory: 512Mi
```

### Deprecated Strimzi Schema
If you are updating from version v1.0.0-pre.106 of the Helm Chart or earlier, you will need to alter your Strimzi spec from the old schema below, which has been deprecated.

```yaml
messageBroker:
  strimzi:
    enabled: true
    config:
      connection:
        type: tls
      authentication:
        type: tls
      version: "3.3.1"
      protocolVersion: "3.3"
      kafka:
        replicas: 4
      zookeeper:
        replicas: 2
```

* Anything under `messageBroker.strimzi.config.kafka` should be moved to `messageBroker.strimzi.kafka`
* Anything under `messageBroker.strimzi.config.zookeeper` should be moved to `messageBroker.strimzi.zookeeper`
* Anything remaining under `messageBroker.strimzi.config` should be moved to `messageBroker.strimzi`

You will recieve a deprecation warning so that you have time to update your configurations before support for the old schema is removed.

For more details on how to configure Kafka using Strimzi, please consult the Strimzi Operator documentation [here](https://strimzi.io/docs/operators/latest/configuring.html)
