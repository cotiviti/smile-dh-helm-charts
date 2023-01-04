# Deploying changes

When you make changes to the Helm Chart configuration, you need to apply them using the `helm update` command. This chart has been designed in such a way that there should not be any outages during updates.

There are multiple components that a configuration can affect. Broadly, it can affect the configuration of the Smile CDR app itself, or it can affect the surrounding infrastructure.

In the event that a configuration change affects the Smile CDR application, then this chart will update any configuration files and create new application pods with zero-outage.

## Rolling Deployments
We achieve zero-outage by making use of Rolling Deployments in Kubernetes.
The rolling deployment has been configured to create one new Pod with the new configuration at a time. Once each new Pod has successfully started up and is able to accept traffic, Kubernetes will start
routing requests to it and then terminate one of the pods with the older configuration.

The result of this is that the changes will be rolled out over the entire cluster in a controlled
fashion over a few minutes, without any downtime or outage.

This is a conservative rolling deployment model, but it means that if pods with the new configuration
fail to come up without error, then the existing deployment will remain unaffected.

### Making a config change with Rolling Deployments
There is nothing you need to do to make use of this rolling deployment mechanism. If your chart configuration changes include something that will update the Smile CDR configuration, and if you have a sufficient number of replicas, then this will happen automatically.

All changes other than those listed here will cause a rolling deployment of the application

* `replicaCount` or `autoScaling` changes
* `ingress` configuration - i.e. switching to a different ingress provider.
* CrunchyPGO database infrastructure configuration
    * Updating `users` config WILL cause a rolling deployment
* Strimzi Kafka infrastructure resource configuration
    * Updating protocol/connection config will cause a rolling deployment

The method used to apply your updates will depend on how you have deployed the Helm Chart. If you have used a code reconciliation system or some other automation, you should not need to do anything.

If using native Helm commands, you would use the same command you used to install the chart, like so:

```helm upgrade -i my-smile-env -f my-values.yaml smiledh/smilecdr```

## Automatic Deployment of Config Changes
Normally, changes that do not directly affect the Pod definition of a Deployment in Kubernetes will not trigger a deployment. Typically, this means that manual recycling of Pods may be required to force updates.

To ensure that all changes are automatically deployed, the Smile CDR Helm Chart uses a unique `sha256` hash to identify any `ConfigMap` objects. This means that any configuration changes will be detected and automatically deployed without interruption using the Rolling Deployment strategy.

> **NOTE**: An extra benefit of this technique is that if a new configuration has an error and the pods fail to come up, then the existing Pods will still use their original configuration, even if they need to be restarted.

This feature can be disabled if required by setting `autoDeploy` to `false`

## ArgoCD Considerations
If you ArgoCD to deploy your charts, then this mechanism would cause previous versions of the `ConfigMap` to be deleted after you perform configuration changes. This interferes with the ability for the existing `ReplicaSet` to scale or self-heal.
To avoid this issue, you should set `argocd.enabled` to true to prevent this issue. By doing this, it will add annotations to any `ConfigMap` resources that are identified by their hash, so that ArgoCD does not prune the resources.

## Long Running Processes
Although these techniques will avoid any disruption to the application availability, any long running processes may be interrupted. Remember to design any workflows to be able to handle unexpected disruption, using retry mechanisms for any tasks that do not complete correctly due to transient infrastructure interruption.
