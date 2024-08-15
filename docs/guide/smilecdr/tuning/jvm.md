# Configuring Smile CDR JVM

## JVM Auto Configuration
The Smile CDR Helm Chart performs some automatic configuration of the Smile CDR JVM by generating and including the `JVMARGS` environment that is used by the `smilecdr` startup script.

This is done so that the following settings can be automatically configured:

* **JVM Heap Parameters** - Based upon the configured `resources.requests.memory` and `resources.limits.memory` settings
* **JVM Temporary directory location** - Hard coded to `/home/smile/smilecdr/tmp` which is mounted as an ephemeral read-write volume.
* **JVM extra arguments** - Some extra jvm arguments are provided by default so match those added by the `/home/smile/smilecdr/bin/setenv` script. You may also add extra JVM arguments (See below)

Due to this, it is not possible to manually configure the `JVMARGS` environment variable using the [`extraEnvVars`](../envvars.md) configuration. However it is still possible to alter the behaviour of the heap auto-configuration as well as adding additional JVM arguments.

### JVM Heap Auto Sizing
When running Java applications in Kubernetes, the max heap size should be lower than `resources.limits.memory`. This is due to the fact that the JVM uses memory for multiple purposes, not just the heap.

The exact difference between the max heap and the available memory is not an exact science and will depend on the kind of workload you are running. As combinations of Smile CDR are almost unlimited, it is hard to determine a on-size-fits-all approach to this sizing.

For a default installation of Smile CDR, without making any configuration changes, the Java heap size should be set to about 50-75% of the total available memory in the pod (i.e. `resources.limits.memory`).

#### JVM Memory Factor
The auto-generated value for the heap size is determined by multiplying the `resources.limits.memory` setting by the `jvm.memoryFactor`. By default, this value is set conservatively to `0.5`. With the default `resources.limits.memory` value of 4Gib, the chart sets Java `-Xmx` to `2048m`. This default results in less efficient use of the available memory, but the chance of running into an OOM (Out-Of-Memory) eviction is extremely minimal.

By using this memory factor mechanism, you are able to easily perform vertical scaling tasks (i.e. re-configure the pod to use a higher `resources.limits.memory`) without needing to manually calculate and reconfigure the max heap. This increases the operational efficiency when running Smile CDR in a scalable fashion.

If you need to adjust the max heap space relative to the `resources.limits.memory` setting, then you can do so by adjusting this value. like so:

```yaml
jvm:
  memoryFactor: 0.8
```
With the default `resources.limits.memory` value of 4Gib, this value would cause the chart to set Java `-Xmx3276m` .

Adjusting this value should be done with caution as the closer you get to `1`, the higher the likelihood that the pod will use all of the available memory, causing Kubernetes to terminate it with an `OOM Killed` error.

Using metrics and analyzing your workload is necessary to find the right balance to efficiently make use of the available memory without getting pod terminations.

#### Setting Heap Minimum Size
If you were to set `jvm.memoryFactor` to `1` your pod is almost guaranteed to be terminated with an `OOM Killed` error, but it will happen at an unpredictable time as the heap slowly grows to a certain point.

This can increase difficulty of troubleshooting due to the unpredictable timing. It may fail in a few minutes, or a few hours/days/weeks/never depending on the workload characteristics.

To reduce the likelihood of such unpredictable `OOM Killed` errors, the minimum heap setting (`-Xms`) is automatically set to be the same value as `-Xmx`.
If this needs to be disabled, you can do so by by setting `jvm.xms` to `false`

### JVM Arguments
By default, the `JVMARGS` environment will contain those settings mentioned above, as well as some extra arguments from the `setenv` script.

If you need to pass in more arguments to the JVM, you can do so using the `jvm.args` section as follows:

```yaml
jvm:
  args:
    -Dmyarg=myvalue
```
