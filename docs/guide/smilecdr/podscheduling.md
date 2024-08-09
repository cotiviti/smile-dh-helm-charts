# Pod Scheduling

Kubernetes supports a number of mechanisms to control how pods are scheduled on to different worker nodes.

When deploying Smile CDR using this Helm Chart, sensible defaults are used to ensure that the Smile CDR pods are appropriately spread across failure domains.

For more information on assigning pods to nodes, study the official documentation [here](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/).

## Supported Pod Assignment Configurations

The following configurations can be directly provided in your Helm Values file.

* `nodeSelector`
* `affinity`
* `nodeName`
* `topologySpreadConstraints`

## Default Topology Constraints

By default, this Helm Chart will include a `topologySpreadConstraints` based on the examples given in the Kubernetes docs on [Topology Spread Constraints](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/)

These defaults will only take meaningful effect when your deployment is scaled to 3 replicas or higher.

### Topology Zone Constraint

The following default constraint will be configured:
```
topologySpreadConstraints:
- labelSelector:
    matchLabels:
      app.kubernetes.io/instance: release-name
      app.kubernetes.io/name: smilecdr
  matchLabelKeys:
  - pod-template-hash
  maxSkew: 1
  topologyKey: topology.kubernetes.io/zone
  whenUnsatisfiable: ScheduleAnyway
```

Pods from the same `replicaSet` will be forced to be scheduled in different topology zones. (e.g. Availability Zones in AWS parlance) This ensures high availability in the event of a zonal failure in the cloud provider's infrastructure.

With `maxSkew: 1` it is possible that with only 2 replicas, they may both be scheduled in the same zone.

### Kubernetes Node Constraint

The following default constraint will be configured:
```
topologySpreadConstraints:
- labelSelector:
    matchLabels:
      app.kubernetes.io/instance: release-name
      app.kubernetes.io/name: smilecdr
  matchLabelKeys:
  - pod-template-hash
  maxSkew: 1
  topologyKey: kubernetes.io/hostname
  whenUnsatisfiable: ScheduleAnyway
```

Pods from the same `replicaSet` will be forced to be scheduled on different Kubernetes Nodes. (i.e. Different hosts) This ensures high availability in the event of a host failure.

With `maxSkew: 1` it is possible that with only 2 replicas, they may both be scheduled on the same host. If there are insufficient hosts available to satisfy this constraint, then they will still be scheculed on a node based on other pod assignment strategies.

### Disabling Default Topology Constraints

The above examples are just sensible defaults to cover some common scenarios and to increase the availability of an out-of-the box deployment.

The subject of pod scheduling and allocation can get very complicated and there may be nuances or requirements in your architectural design that these defaults do not satisfy.

If you wish to provide your own, fine tuned, pod allocation strategies, then the above topology constraints can be disabled by adding the following in your values file:

```
disableDefaultTopologyConstraints: true
```
>**Note:** This can be added in the root context as a global setting, or in a `cdrNode` context if you are using [multiple CDR Nodes](./modules/cdrnode.md) and wish to set this on a per-cdrNode basis.

You may then provide your own configuration as described below.

## Custom Configuration

You can provide any of the following pod allocation configurations:

* `nodeSelector`
* `affinity`
* `nodeName`
* `topologySpreadConstraints`

As the configuration of pod allocation strategies can get very complicated depending on the architecture, this Helm Chart does not currently perform any validation or auto-configuration (Aside from the default `topologySpreadConstraints` mentioned above).

If you provide a configuration for `topologySpreadConstraints`, then the defaults will not be used.

Any provided configurations are passed through to the `podSpec` that is generated, without any alterations.

Configurations may be provided in the root context as a global setting, or in a `cdrNode` context if you are using [multiple CDR Nodes](./modules/cdrnode.md) and wish to set this on a per-cdrNode basis.

>**Warning:** Do not use these examples as-is. They are merely to demonstrate how to configure pod allocation strategies.

### Custom Example 1

A single CDR Node configuration using a new `affinity` rule and custom `topologySpreadConstraints`:

```
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: topology.kubernetes.io/zone
          operator: In
          values:
          - us-east-1a
          - us-east-1b
topologySpreadConstraints:
- labelSelector:
    matchLabels:
      app.kubernetes.io/instance: release-name
      app.kubernetes.io/name: smilecdr
  matchLabelKeys:
  - pod-template-hash
  maxSkew: 3
  topologyKey: kubernetes.io/hostname
  whenUnsatisfiable: DoNotSchedule
- labelSelector:
    matchLabels:
      app.kubernetes.io/instance: release-name
      app.kubernetes.io/name: smilecdr
  matchLabelKeys:
  - pod-template-hash
  maxSkew: 2
  topologyKey: topology.kubernetes.io/zone
  whenUnsatisfiable: DoNotSchedule
```

This will result in a deployment which will ensure that pods:
* Only run in the `us-east-1a` and `us-east-1b` availability zones
* Use the provided `topologySpreadConstraints`

### Custom Example 2

A multi CDR Node configuration with the following design:

* Global settings using a `nodeSelector` rule to use ***Spot*** instances and *does not* use the default `topologySpreadConstraints` config.
* Admin CDR Node using the global defaults.
* FHIR CDR Node using a different `nodeSelector` rule to use ***On Demand*** instances and *does* use the default `topologySpreadConstraints` config.


```
cdrNodes:
  masterdev:
    enabled: false

  admin:
    name: AdminNode
    enabled: true

  fhir:
    name: FhirNode
    enabled: true
    disableDefaultTopologyConstraints: false
    nodeSelector:
      karpenter.sh/capacity-type: on-demand

# GLobal defaults
disableDefaultTopologyConstraints: true

nodeSelector:
  karpenter.sh/capacity-type: spot
```

The resulting deployments would have `podSpecs` that include the following:

**Admin Node**
```
nodeSelector:
  karpenter.sh/capacity-type: spot
```

**FHIR Node**
```
nodeSelector:
  karpenter.sh/capacity-type: on-demand
topologySpreadConstraints:
- labelSelector:
    matchLabels:
      app.kubernetes.io/instance: release-name
      app.kubernetes.io/name: smilecdr
      smilecdr/nodeName: fhir
  matchLabelKeys:
  - pod-template-hash
  maxSkew: 1
  topologyKey: topology.kubernetes.io/zone
  whenUnsatisfiable: ScheduleAnyway
- labelSelector:
    matchLabels:
      app.kubernetes.io/instance: release-name
      app.kubernetes.io/name: smilecdr
      smilecdr/nodeName: fhir
  matchLabelKeys:
  - pod-template-hash
  maxSkew: 1
  topologyKey: kubernetes.io/hostname
  whenUnsatisfiable: ScheduleAnyway
```
