# Configuring Compute Resources

## Kubernetes Memory Requests vs Limits
`requests.memory` will be set to the same value as `limits.memory` unless you override it.

The values you should use for CPU resources will depend on the number of cores you are licenced for with Smile CDR. Your total cores can be calculated by `replicas * requests.limits.cpu`, or `autoscaling.maxReplicas * requests.limits.cpu` if you are using Horizontal Pod Autoscaling.

## JVM Sizing
As Smile CDR is a high performance Java based application, special consideration needs
to be given to the resource settings and JVM tuning parameters.

Typical cloud best practices suggest starting small and increasing resources as workload increases.
We have tested Smile CDR in its default module configuration and determined that the max heap size
should be no smaller than 2GB. When smaller than this, there are excessive GC events which is not ideal.

> **NOTE**: If you reconfigure Smile CDR to have more modules, it may require more memory/cpu. If you
split up the cluster into multiple nodes, then each node may be able to run with less memory/cpu,
though total cluster may end up higher depending on your architecture.

### JVM Heap Auto Sizing
When running Java applications in Kubernetes, the `requests.memory` should be set much higher than the
max heap size. Typically the Java heap size should be set to 50-75% of the total available memory.

This Helm Chart will take the specified `limits.memory` and use `jvm.memoryFactor` to calculate the
value for the Java heap size. By default, this value is `0.5`. With the default `limits.memory` of
4Gib, the chart sets Java `-Xmx` to `2048m`.

Setting this number higher will make more efficient use of memory resources in your K8s cluster, but may increase the likelihood of `OOM Killed` errors.

## Setting Heap Minimum Size
If you were to set `jvm.memoryFactor` to `1` your pod is almost guaranteed to be killed with such an error, but it will happen at an unpredictable time, once the currently allocated heap grows to a certain point. This can increase difficulty of troubleshooting due to the unpredictable timing. It may fail in a few minutes, or a few hours/days/weeks/never depending on the workload characteristics.

To reduce the likelihood of such unpredictable `OOM Killed` errors, we recommend setting `-Xms` to be the same
as `-Xmx`. This can be done by setting `jvm.xms` to `true`

> **NOTE**: You can pass in extra JVM commandline options by adding them to the list `jvm.args`
