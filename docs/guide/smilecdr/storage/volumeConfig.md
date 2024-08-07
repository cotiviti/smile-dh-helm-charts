# Configure Ephemeral Volumes
The `customerlib`, `classes`, `log` and `tmp` directories are all mounted using temporary *ephemeral* volumes that only exist for the duration of the Pod.

Currently they are backed by the underlying disk of the Kubernetes worker node that they are running on. Due to this, the default size limit for these volumes is kept to a minimum so as to reduce the disk requirements of the underlying worker node.

>**Note:** A future feature of this Helm Chart may allow for configuring [generic ephemeral volumes](https://kubernetes.io/docs/concepts/storage/ephemeral-volumes/#generic-ephemeral-volumes) which can utilized networked storage, thus eliminating the need for these volumes to require disk from the underlying worker node.

## Default Configuration
The following ephemeral volumes are defined by default to have the following default size limits:

| Name | Path | Default Size Limit | Read/Write | Notes |
|-|-|-|-|-|
| tmp | `/home/smile/smilecdr/tmp` | 1Mi | Y | Always mounted |
| log | `/home/smile/smilecdr/log` | 10Gi | Y | Always mounted |
| customerlib | `/home/smile/smilecdr/customerlib` | 500Mi | N | Note1 |
| classes | `/home/smile/smilecdr/classes` | 500Mi | N | Note1 |
| amq | `/home/smile/smilecdr/activemq-data` | 10Mi | Y | Note2 |

> Note 1: The `customerlib` and `classes` ephemeral volumes only get created if adding extra files using the [copyFiles](files.md) feature. Otherwise, the existing directories from the container image remain in place.

> Note 2: The ActiveMQ data ephemeral volume only gets created if the Smile CDR is run in embedded ActiveMQ mode. If an external message broker has been enabled, then this volume is not created.

## Increase size limit
The configured size limit is a 'soft' limit. This means that is is possible to continue writing more data to a volume, but if you do exceed the limit, Kubernetes will 'evict' the running pod. This may lead to unexpected termination of your running pod in the event that you write excessive data to these volumes.

In some circumstances, it may be required to increase the size limit for these volumes. For example:
* More space required for files being copied to `customerlib` or `classes` directories
* Using Smile CDR functionality that writes data to the `tmp` directory.

To allow for this, you can configure the ephemeral volume size limit as follows:

```yaml
volumeConfig:
  cdr:
    tmp:
      sizeLimit: 100Mi
    classes:
      sizeLimit: 1Gi
    customerlib:
      sizeLimit: 1Gi
    log:
      sizeLimit: 100Mi
    amq:
      sizeLimit: 20Mi
```

>**Warning:** When setting the size limit too high, the underlying host machine may run out of disk space, leading to instability of the Kubernetes worker node and any pods running on it. Use caution when increasing these values.
