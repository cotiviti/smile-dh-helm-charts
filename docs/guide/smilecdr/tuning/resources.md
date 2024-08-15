# Configuring Compute Resources

## Kubernetes Memory Requests vs Limits
`resources.requests.memory` will be set to the same value as `resources.limits.memory` unless you override it.

The values you should use for CPU resources will depend on the number of cores you are licenced for with Smile CDR.

Your total cores can be calculated by:

```replicas * resources.limits.cpu```

If you are using Horizontal Pod Autoscaling then it can be calculated by:

```autoscaling.maxReplicas * resources.limits.cpu```

## Pod Sizing
As Smile CDR is a high performance Java based application, special consideration needs to be given to the resource settings.

Typical cloud best practices suggest starting small and increasing resources as workload increases. We have tested Smile CDR in its default module configuration and determined that the max heap size should be no smaller than 2GB. When smaller than this, there are excessive GC events or heapspace errors in the JVM, which is not ideal.

When configuring more modules in Smile CDR, it may require more memory/cpu. If you split up the cluster into multiple nodes, then each node may be able to run with less memory/cpu, though total cluster may end up higher depending on your architecture. You will need to analyze resource usage in your configured environment to determine the ideal settings.

## JVM Auto Configuration
This Helm Chart will automatically configure the Smile CDR JVM settings based on the configured resource allocation. See the [JVM Configuration](jvm.md) for more information on this and how to configure it.

## Storage Configuration
Depending on the type of workload, you may need to adjust storage configuration. Please refer to the [Storage Configuration](../storage/volumeConfig.md) for more information.
