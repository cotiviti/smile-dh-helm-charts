## Install the Helm Chart
```shell
$ helm upgrade -i my-smile-env --devel -f my-values.yaml smiledh/smilecdr
```

**Smile, we're up and running! :)**

After about 2-3 minutes, all pods should be in the `Running` state with `1/1` containers in the `Ready` state.
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
You can try re-configuring it using the instructions in the [User Guide](../guide/smilecdr/index.md), or you can delete it like so:
```shell
$ helm delete my-smile-env
```
> **WARNING**: If you delete the helm release, the underlying `PersistentVolume` will also be deleted
and you will lose your database and backups. You can prevent this by using a custom `StorageClass` that sets the `ReclaimPolicy` to `Retain`.
