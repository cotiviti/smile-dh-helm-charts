# Installing Smile CDR

## Prepare Values File
To use the Smile CDR helm Chart, you will need to create a values file with some mandatory fields provided.

Refer to the section on [Values Files Management](../../guide/values-files-management/) for more info on how to organise your values files. You can start out with one of the values files in the Examples section, or create your own from scratch using techniques from the configuration section.

For the remainder of this section, we will assume the same values file that was used in the QuickStart guide.
## Install the Helm Chart
With your custom values file(s) you install as follows:
```shell
$ helm upgrade -i my-smile-env --devel -f my-values.yaml smiledh/smilecdr
```

**Smile, we're up and running! :)**

If your cluster has spare capacity available, all pods should be in the `Running` state after about 2-3 minutes.
If your cluster needs to auto-scale to provision enough resources, it may take longer while the K8s worker nodes get created.
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
You can try re-configuring it using the instructions in the [User Guide](../../guide/smilecdr/), or you can delete it like so:
```shell
$ helm delete my-smile-env
```
> **WARNING**: If you delete the helm release, the underlying `PersistentVolume` will also be deleted
and you will lose your database and backups. You can prevent this by using a custom `StorageClass` that sets the `ReclaimPolicy` to `Retain`.
