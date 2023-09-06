# Smile CDR Cluster Configuration
Smile CDR is designed to be installed with flexible cluster configurations,
as per the documentation [here](https://smilecdr.com/docs/clustering/designing_a_cluster.html).

Using this Helm Chart, it is possible to configure your Smile CDR cluster with a flexible
architecture design:

* **Single Node** All modules are contained in a single *Node* configuration.

* **Multi Node** Modules can be split amongst an arbritrary number of *Node*
configurations.

When using a multi node architecture, each *Node* will be deployed using separate Kubernetes
resources. All configurations, such as the number of replicas, resource requests & limits,
probes, autoscaling configurations, mapped files and CDR module configurations, can be configured
separately for each Node.

## Single Node Design
By default, Smile CDR will be installed with a *single-node* configuration. No special actions
are required to run Smile CDR with this configuration.

### Overriding Default NodeID
When using the default configuration, a single Smile CDR Node will be created with a `NodeID` of
`Masterdev`. If required this can be changed using one of two methods.

**Method 1 - Override name in default configuration**

This is the default configuration which results in `node.id` being set to `Masterdev`
```yaml
cdrNodes:
  masterdev:
    name: Masterdev
```

To override this name, simply alter the `name:` field in your `values.yaml` file.

The following configuration results in `node.id` being set to `MyNodeID`
```yaml
cdrNodes:
  masterdev:
    name: MyNodeID
```

**Method 2 - Disable default configuration**

The above mentioned settings use the `cdrNode.masterdev` YAML dictionary that is predefined in the
default `values.yaml` file.
This dictionary contains a number of default node settings as follows:
```yaml
cdrNodes:
  masterdev:
    name: Masterdev
    enabled: true
    config:
      locked: true
      troubleshooting: false
    security:
      strict: false
```

If you wish to start with a fresh node configuration, you can disable the default `cdrNodes.masterdev`
and configure your own item that does not inherit any default values.

Add the following snippet to your `values.yaml` file to disable the default configuration and define
your own node using the `mynode` key, with a `node.id` of `MyNode`
```yaml
cdrNodes:
  masterdev:
    enabled: false
  mynode:
    enabled: true
    name: MyNode
```

## Multi Node Design

>**WARNING:** Multi-Node configuration using this Helm Chart is still a new and developing feature.
It's not recommended at this time to use it in a production environment and should only be used for
evaluation purposes.

Building on the section above, it's simple to create a *multi-node* configuration by adding
multiple node specifications under the `cdrNodes` map entry.

### Sample Architecture
For this example, we will replicate the **Sample Architecture** described in the Smile CDR documentation
[here](https://smilecdr.com/docs/clustering/designing_a_cluster.html#sample-architecture)

![Sample Architecture](https://smilecdr.com/docs/images/clustering-designing_a_cluster-simple_cluster.svg)

### Basic Configuration
The below example configuration will install a Smile CDR cluster with two nodes, as per the above diagram.

>**Note:** Do ***NOT*** use this configuration, it is merely used to demonstrate the mechanisms available
for defining Smile CDR Nodes. Use it only as a guideline for configuring your own *multi-node* cluster.

```yaml
cdrNodes:
  masterdev:
    enabled: false
  admin:
    name: AdminNode
    enabled: true
    modules:
      clustermgr:
        # AdminNode overrides for Cluster Manager Module...
      admin_json:
        # JSON Admin API Module Spec...
      admin_web:
        # Web Admin Console Module Spec...
      # Disabling unused default modules.
      fhir_endpoint:
        enabled: false
      fhirweb_endpoint:
        enabled: false
      persistence:
        enabled: false
      subscription:
        enabled: false
      smart_auth:
        enabled: false
      package_registry:
        enabled: false
      audit:
        enabled: false
      license:
        enabled: false
      transaction:
        enabled: false
  fhir:
    name: FhirNode
    enabled: true
    resources:
      requests:
        cpu: "4"
      limits:
        memory: 8Gi
    modules:
      useDefaultModules: false
      clustermgr:
        # FhirNode overrides for Cluster Manager Module...
      persistence:
        # Persistence Module Spec...
      fhir_endpoint:
        # Fhir Endpoint Module Spec...

# Any configurations in the root context will be used as defaults by all enabled
# nodes in `cdrNodes`. Configurations in `cdrNodes` will have priority, so this
# is a useful mechanism for defining global defaults to reduce config duplication.
modules:
  clustermgr:
    # Global Cluster Manager Module Spec...
  local_security:
    # Global Security Module Spec...

resources:
  requests:
    cpu: "1"
  limits:
    memory: 4Gi
```

Various concepts from the above will be covered in the below sections.

### Configuration Inheritance
When defining a Node as per above, the Helm Chart will merge configurations from multiple locations
to determing the correct value for any given setting. This applies to any of the Helm Chart settings
that can be set in your `values.yaml` file.

Configuration values are effectively determined by using the first entry found when looking in the following locations in order:

1. Local Node spec in `cdrNodes` entry
2. Values file root context
3. Default values file

The result of this is that any settings in the root context of the values file can be used as a
mechanism for defining global defaults.

#### Example Explanation

In the example configuration above, we can see that this concept was utilized for specifying resource
usage quotas.

* The root context defined `resources.requests.cpu: 1` and `resources.limits.memory: 4Gi`. These values
become the default for all nodes
* The FhirNode overrides these values to `4` and `8Gi` respectively, thus overriding the global defaults.
* `replicaCount` has neither been defined in the root context, nor in the FhirNode Spec. As such, the value
for `replicaCount` will be determined from the default values file.
* There are modules defined both in the root context, as well as the Node specs under `cdrNodes`. This will
be discussed in the section below.

### Per-node Module Definitions
When using a multi-node configuration such as above there are multiple ways that you can configure the
modules for each node.

* **Use default modules** - Although this may work, **do not do this**, as all nodes would have the same set of modules,
negating the purpose of having a multi-node cluster in the first place ;)
* **Use default modules, but disable modules that are not required on a given node.** This is a reasonable option
if you wish to use the default module definitions. It could get confusing if you have a lot of module definitions
as it may become unclear which modules are defined where.
* **Disable default modules and define all required modules yourself.** This is probably the most complicated solution,
but offers improved manageability as all your modules will be defined in one location.

In either of the options above, the same inheritance process will be used to determine the final module congfiguration.

**Module Inheritance with Default Modules Enabled**

If you are using the default modules, module configurations will be determined in the following order:

1. Modules section of Node spec in `cdrNodes` entry
2. Modules section of root context
3. Default Modules file

**Module Inheritance with Default Modules Disabled**

If you have disabled the default modules, module configurations will be determined in the following order:

1. Modules section of Node spec in `cdrNodes` entry
2. Modules section of root context

#### Example Explanation
In the example configuration above, we can see that both of these methods were demonstrated.

**AdminNode** uses method 1, leaving default modules enabled.

* AdminNode leaves default modules enabled, but explicitly disables any modules that are not required in the node
* AdminNode uses global overrides for the `clustermgr` and `local_security` modules.
* AdminNode overrides values for the `clustermgr`, `admin_json` and `admin_web` modules locally.

**AdminNode** uses method 2, disabling the default modules.

* FhirNode disables default modules.
* FhirNode uses global defaults for the `clustermgr` and `local_security` modules.
* FhirNode overrides values for the `clustermgr`, `persistence` and `fhir_endpoint` modules locally.

In reality, you would likely choose one option or the other for consistency. Both were used here just for demonstration
purposes.

## Multi Node Considerations
When running Smile CDR in a multi-node configuration, there are some things to consider. Please study the
documentation for [designing a cluster](https://smilecdr.com/docs/clustering/designing_a_cluster.html)

### ClusterMgr Module Configuration
It is important that the configuration for the cluster manager module is mostly the same amongst the different nodes.

>**Note:** Despite the clustermgr configuration being identical, the Database configuration may differ slightly. See the
[Database Configuration](#database-configuration) section below.


### Batch Job Visibility
As per the documentation [here](https://smilecdr.com/docs/clustering/designing_a_cluster.html#multi-node-clusters-and-batch-jobs-status),
the Sample Architecture above will not have the ability to display Batch jobs in the Web Admin Console.

A solution to this is to also configure any `persistence` modules in your AdminNode (Or any such node that has the
`admin_web` module configured). If doing this, take special note of the considerations mentioned in the linked docs.

### Database Configuration
If multiple modules are configured to point to the same database, consider the following:

* Only one node should have the `schema_update_mode` set to `UPDATE`. All others should have it set to `NONE`
* When configuring multiple nodes/modules to point to the same persistence database (e.g. for viewing Batch Jobs
as mentioned [above](#batch-job-visibility)) then:
    * `suppress_scheduled_maintenance_jobs` should be set to true on all but one node
    * `read_only_mode.enabled` should be set to true on the AdminNode
    * The `maxidle` and `maxtotal` db connections can be reduced on the AdminNode

### Readiness Probes
With a default single node configuraton of Smile CDR, the Kubernetes readiness probe is set up to use the healthcheck of the
FHIR Endpoint module. Although this is a reasonable compromise when it comes to the question of "What do I monitor",
it falls short if you need to ensure that the Web Admin Console is always available.

With a multi-node configuration this issue is solved as you will now have a separate readiness probe configuration for
each node. This means your AdminNode could use the Web Admin Console healthcheck and your FhirNode could use the healthcheck
of the FHIR Endpoint.

With such a configuration, both the Web Admin Console and the FHIR Endpoint will gain resilience and self-healing benefits
from the Kubernetes control plane.

## Multi Node Example Configuration
Below is a realistic example configuration for a multi-node cluster. It's based on the Sample Architecture further
up in this page, but includes the following:

* Realistic comprehensive module configurations using global defaults
* Includes `audit`, `transaction` & `license` modules
* Includes ability to view Batch jobs from the Web Admin Console

#### `my-multi-node-values.yaml`
<details>
  <summary>Click to expand</summary>

```yaml
cdrNodes:
  masterdev:
    enabled: false
  admin:
    name: AdminNode
    enabled: true
    modules:
      clustermgr:
        config:
          db.schema_update_mode: UPDATE
      audit:
        config:
          db.schema_update_mode: UPDATE
      transaction:
        config:
          db.schema_update_mode: UPDATE
          # transactionlog.show_request_body.enabled: true
      persistence:
        config:
          suppress_scheduled_maintenance_jobs: true
          read_only_mode.enabled: true
          db.connectionpool.maxidle: 2
          db.connectionpool.maxtotal: 4
      admin_web:
        name: Web Admin
        enabled: true
        type: ADMIN_WEB
        enableReadinessProbe: true
        service:
          enabled: true
          svcName: admin-web
          hostName: default
        requires:
          SECURITY_IN_UP: local_security
        config:
          context_path: ""
          port: 9100
          # tls.enabled: false
          # https_forwarding_assumed: true
          # respect_forward_headers: true
      admin_json:
        name: JSON Admin Services
        enabled: false
        type: ADMIN_JSON
        service:
          enabled: true
          svcName: admin-json
        requires:
          SECURITY_IN_UP: local_security
        config:
          context_path: json-admin
          port: 9000
          tls.enabled: false
          anonymous.access.enabled: true
          security.http.basic.enabled: true
          https_forwarding_assumed: true
          respect_forward_headers: true
  fhir:
    name: FHIRNode
    enabled: true
    modules:
      persistence:
        config:
          db.schema_update_mode: UPDATE
      fhir_endpoint:
        name: FHIR Service
        enabled: true
        type: ENDPOINT_FHIR_REST
        enableReadinessProbe: true
        service:
          enabled: true
          svcName: fhir
          hostName: default
        requires:
          PERSISTENCE_ALL: persistence
          SECURITY_IN_UP: local_security
        config:
          context_path: fhir_request
          port: 8000

modules:
  useDefaultModules: false
  clustermgr:
    name: Shared Cluster Manager Configuration
    enabled: true
    config:
      db.driver: POSTGRES_9_4
      db.url: jdbc:postgresql://#{env['DB_URL']}:#{env['DB_PORT']}/#{env['DB_DATABASE']}?sslmode=require
      db.password: "#{env['DB_PASS']}"
      db.username: "#{env['DB_USER']}"
      db.schema_update_mode:  NONE
      audit_log.db.always_write_to_clustermgr: false
      audit_log.request_headers_to_store: Content-Type,Host
      transactionlog.enabled: false
      retain_transaction_log_days: 7

  local_security:
    name: Shared Local Storage Inbound Security
    enabled: true
    type: SECURITY_IN_LOCAL

  audit:
    name: Shared Audit DB Config
    enabled: true
    type: AUDIT_LOG_PERSISTENCE
    config:
      db.driver: POSTGRES_9_4
      db.url: jdbc:postgresql://#{env['DB_URL']}:#{env['DB_PORT']}/#{env['DB_DATABASE']}?sslmode=require
      db.password: "#{env['DB_PASS']}"
      db.username: "#{env['DB_USER']}"
      db.schema_update_mode:  NONE

  license:
    name: Shared License Module Config
    type: LICENSE
    enabled: true

  transaction:
    name: Shared Transaction Log DB
    enabled: true
    type: TRANSACTION_LOG_PERSISTENCE
    config:
      db.driver: POSTGRES_9_4
      db.url: jdbc:postgresql://#{env['DB_URL']}:#{env['DB_PORT']}/#{env['DB_DATABASE']}?sslmode=require
      db.username: "#{env['DB_USER']}"
      db.password: "#{env['DB_PASS']}"
      db.schema_update_mode: NONE

  persistence:
    name: Database Configuration
    enabled: true
    type: PERSISTENCE_R4
    config:
      db.driver: POSTGRES_9_4
      db.url: jdbc:postgresql://#{env['DB_URL']}:#{env['DB_PORT']}/#{env['DB_DATABASE']}?sslmode=require
      db.password: "#{env['DB_PASS']}"
      db.username: "#{env['DB_USER']}"
      db.schema_update_mode: NONE
```
</details>
