# Message Broker Configuration
Much like with the database configuration, you can use an externally provisioned message broker, or
you can have this chart provision Kafka for you if you have the Strimzi Operator installed in your
cluster.

## Configuring external message broker.
You can use the `messageBroker.external` section to configure an external message broker like so:
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

## Provisioning Kafka with Strimzi
If you have the Strimzi Operator installed in your cluster, you can use the following values file
section to automate provisioning of a Kafka cluster. Your Smile CDR instance will then be automatically
configured to use this HA Kafka cluster.
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

All of the Kafka configurations can be configured using `messageBroker.strimzi.config` like so:

```yaml
messageBroker:
  strimzi:
    enabled: true
    config:
      version: "3.3.1"
      protocolVersion: "3.3"
      tls: true
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
