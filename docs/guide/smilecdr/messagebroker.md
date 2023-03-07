# Message Broker Configuration
Much like with the database configuration, you can use an externally provisioned message broker, or
you can have this chart provision Kafka for you if you have the Strimzi Operator installed in your
cluster.

## Configuring external message broker
Use the `messageBroker.external` section to configure an external message broker like so:

```yaml
messageBroker:
  external:
    enabled: true
    type: kafka
    config:
      connection:
        type: tls
        bootstrapAddress: kafka-example.myorg.com:9098
```

## Configuring Smile CDR Kafka settings
While you can configure any of the message broker settings available in the `clustermgr` module, some of them are defined automatically by this Helm Chart.

### TLS Connectivity
When connecting to Kafka clusters, it is advised to use TLS connections. If you provide a `bootstrapAddress` for a TLS enabled Kafka listener, then Smile CDR will be automatically configured to connect to it using TLS.

The connection type is specified using `messageBroker.external.config.connection.type`. If not provided, the default of `tls` will be used.

```yaml
messageBroker:
  external:
    config:
      connection:
        type: tls
```
If you wish to run without enabling encryption for testing purposes, you can also specify `plaintext`.

```yaml
messageBroker:
  external:
    config:
      connection:
        type: plaintext
```

>**Note:** You cannot use mTLS or IAM authentication methods if you disable TLS

#### Using Custom Certificate Authority
If your external Kafka cluster is configured with a TLS certificate that is signed with a public Certificate Authority (CA) then no further steps are required.

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

#### Configuring mTLS
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

### Topic Auto Creation
By default, the `auto.create.topics.enable` Kafka broker setting is often set to `true`. With this setting enabled, Kafka will automatically create topics when consumers or producers try to use a topic.

As a best practice, this setting should be changed to `false` in production environments. When doing this, any required topics should be created through some other process.

If your Kafka cluster has topic auto creation disabled, you should set the [`kafka.validate_topics_exist_before_use`](https://smilecdr.com/docs/configuration_categories/clustermgr_kafka.html#property-validate-kafka-topics-exist-before-use) option in Smile CDR. See [here](https://smilecdr.com/docs/installation/kafka.html) for more information on these Kafka settings in Smile CDR.

As a convenience, this option is auto-configured based on various settings. By default, if using an external Kafka cluster, this option is disabled and creating Subscriptions will work without any manual intervention.

#### Amazon MSK Serverless
Although Amazon MSK allows `auto.create.topics.enable` to be set to `true` (You need to use a [Custom Configuration[(https://docs.aws.amazon.com/msk/latest/developerguide/msk-configuration-properties.html)]), this is not the case for Amazon MSK Serverless. In this case, you must create topics using another mechanism. It is advisable in this case to also set the above mentioned topic validation option in Smile CDR.

#### Strimzi
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

* Connect to the Kafka Admin pod
```sh
./bin/kafka-consumer-groups.sh --describe --group smilecdr
```

>**Note:** You do not need to provide a config file or bootstrap address on the command-line as it is auto configured.

### Strimzi
If using the Strimzi Operator, you can define topics in a declarative fashion using the `messageBroker.topics` section.

```yaml
messageBroker:
  topics:
    batch2:
      name: "batch2.work.notification.Masterdev.persistence"
      partitions: 10
    subscription:
      name: "subscription.matching.Masterdev.persistence"
      partitions: 10
```

When using this method, the Helm Chart will create a `KafkaTopic` resource for each of the provided topics. The topics will then be created automatically by the Strimzi Topic Operator. The Kafka brokers will be configured with `auto.create.topics.enable` set to `false` as per best practice.

Using this method allows you to define the configuration of your topics in code for increased repeatability and reliability.

You can disable topic auto creation by Strimzi by setting `messageBroker.manageTopics` to `false`.

>**Note:** Please be aware that if you create topics directly in Kafka (either using the Admin Pod or if auto topic creation is enabled) then the Strimzi Topic Operator will create `KafkaTopic` resources to match the topics in the Strimzi-managed Kafka cluster.

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
    config:
      connection:
        type: tls
      authentication:
        type: tls
      version: "3.3.1"
      protocolVersion: "3.3"
      kafka:
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

For more details on how to configure Kafka using Strimzi, please consult the Strimzi Operator documentation [here](https://strimzi.io/docs/operators/latest/configuring.html)
