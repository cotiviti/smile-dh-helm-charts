# Module Configuration
Configuring modules is fairly straight forward, but somewhat different than the existing methods used for configuring Smile CDR which uses the `cdr-config-Master.properties` file.

This file is still used behind the scenes, but is automatically generate by the Helm Chart and cannot be modified directly.

> **NOTE**: When using Helm Charts, they become the 'single source of truth' for
your configuration. This means that repeatable, consistent deployments become a
breeze. It also means you should not edit your configuration options in the Smile CDR web
admin console.

You can define your modules in your main values file, or you can define them
in separate files and include them using the helm `-f` command. This is possible because Helm
[accepts multiple values files](https://helm.sh/docs/chart_template_guide/values_files/){:target="_blank"}

We recommend defining them in one or more separate files, as this allows you
to manage common settings as well as per-environment overlays. We will discuss this further
down in the Advanced Configuration section below.

## Mapping traditional Smile CDR configuration to Helm

Mapping existing configurations to values files is relatively straight forwards:
### Identify the module configuration parameter.
e.g. [Concurrent Bundle Validation](https://smilecdr.com/docs/configuration_categories/fhir_performance.html#property-concurrent-bundle-validation){:target="_blank"}
Config.properties format:
`module.persistence.config.dao_config.concurrent_bundle_validation = false`
### Specify them in the values yaml file format:
```yaml
modules:
  persistence:
    config:
      dao_config.concurrent_bundle_validation: "false"
```
The same effective mapping can be used for any module configurations supported by Smile CDR.

## Included pre-defined Module Definitions
This chart includes a set of pre-defined module configurations that closely matches the default `cdr-config-Master.properties` configuration that is included with Smile CDR.

Some of these module configurations are slightly different in order to better accommodate deploying in Kubernetes.
If you wish to review this default configuration, or use it as a baseline for your own custom set of module configurations, you can get it [here](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/-/blob/pre-release/src/main/charts/smilecdr/default-modules.yaml){:target="_blank"}

>**WARNING:** If you use a copy of the pre-defined modules, then be aware that future versions of this Helm Chart may introduce breaking changes that will require you to review changes in the default modules, so that you can update your custom module definitions.

## Configuring Endpoint Modules
Many Smile CDR modules provide services that can be consumed via some API. These modules implement listeners that expose them to other parts of your infrastructure.
In order for these `endpoint` modules to be exposed, additional Kubernetes resources need to be created in the cluster.

### Configure Service
This Helm Chart will configure these resources based on the configurations provided in the module's `service` configuration.

e.g. This snippet will create a `Service` resource and a `rule` in the default `Ingress` resource for the **Web Admin Console**:
```
modules:
  admin_web:
    service:
      enabled: true
      svcName: admin-web
      hostName: default
    config:
      port: 9100
```

* `moduleSpec.service.enabled` must be set to `true` to enable the service
* `moduleSpec.service.svcName` represents the name of the created resources and must be unique for each module
* `moduleSpec.service.hostName` can be overridden with an explicit host name. If the value `default` is used, it will derive the hostName from `specs.hostname`
* `moduleSpec.service.config.port` must be set to a unique value for each module that defines an ingress.

### Configure Ingress
As this Helm Chart supports multiple Ingress resources, you may need to specify which ingress is used by any modules that need to be exposed externally to the Kubernetes cluster.

See the [Ingress](../ingress.md) section for more information on Ingress Configurations.

#### Default Ingress Configuration
In a default Helm Chart installation, only a single Ingress resource is created and any modules with enabled `service` configurations will use this ingress by default. No extra module configuration is required in this scenario.

#### Custom Ingress Configuration
If you wish to use a non-default Ingress resource, then this needs to be specified on a per-module basis.

Before specifying any ingresses here, a [custom Ingress Configuration](../ingress.md#defining-custom-ingress-configurations) needs to be created.

In the following snippet, we will configure the **Web Admin Console** to use a custom internal Ingress resource and the **FHIR endpoint** to use a custom public Ingress resource. All other modules will use the default Ingress Resource.
#### `my-module-values.yaml`
```yaml
modules:
  admin_web:
    service:
      ingresses:
        myPrivateNginx:
          enabled: true
  fhir_endpoint:
    service:
      ingresses:
        myPublicNginx:
          enabled: true
```

>**NOTE:** When defining a custom ingress here, you do not need to explicitly disable the default ingress as it's disabled automatically.

## Module definition considerations
Here are some additional fields/considerations that need to be included in your module definitions files:

* Though not strictly required by the `yaml` spec, all values should be quoted.
  You may run into trouble with some values if you do not quote them.
  Specifically, values starting with `*` or `#` will fail if not quoted.
* The `module id` is taken from the yaml key name.
* Modules can be defined, but disabled. They need to be enabled with the `enabled: true` entry. Disabled modules will not be included in the generated `cdr-config-*.properties` file
* Modules other than the cluster manager need to define `type`. A list of module types is available [here](https://smilecdr.com/docs/product_reference/enumerated_types.html#module-types){:target="_blank"}
* Modules which expose an endpoint need to de defined with a `service` entry, which defines infrastructure resources that are required to access the module.
* DB credentials/details can be referenced from your module configurations via `DB_XXX` environment variables.

Any configurations you specify will merge with the defaults, priority going to the values file.

### Disabling included pre-defined module definitios
If you wish to disable any of the pre-defined default modules, you can do so individually, or you can disable all default modules and define your own from scratch.

If you do the latter, it may be easier to determine the exact modules you have defined just by looking at your values files.
>**NOTE:** If doing this, you may need to review upstream changes when moving to a newer version of the Helm Chart.

You can disable all default modules using:
```yaml
modules:
  useDefaultModules: false
```
You can reference the `default-modules.yaml` file as a reference by untarring the Helm Chart or viewing it [directly from the repository](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/-/blob/pre-release/src/main/charts/smilecdr/default-modules.yaml){:target="_blank"}.

Here is an example of what your module definition may look like when configuring
Smile CDR with the `clustermgr`, `persistence`, `local_security`,
`fhir_endpoint` and `admin_web` modules.
#### `my-module-values.yaml`
<details>
  <summary>Click to expand</summary>

```yaml
modules:
  useDefaultModules: false
  clustermgr:
    name: Cluster Manager Configuration
    enabled: true
    config:
      db.driver: POSTGRES_9_4
      db.url: jdbc:postgresql://#{env['DB_URL']}:#{env['DB_PORT']}/#{env['DB_DATABASE']}?sslmode=require
      db.password: "#{env['DB_PASS']}"
      db.username: "#{env['DB_USER']}"
  persistence:
    name: Database Configuration
    enabled: true
    type: PERSISTENCE_R4
    config:
      db.driver: POSTGRES_9_4
      db.url: jdbc:postgresql://#{env['DB_URL']}:#{env['DB_PORT']}/#{env['DB_DATABASE']}?sslmode=require
      db.password: "#{env['DB_PASS']}"
      db.username: "#{env['DB_USER']}"
  local_security:
    name: Local Storage Inbound Security
    enabled: true
    type: SECURITY_IN_LOCAL
    config:
      seed.users.file: classpath:/config_seeding/users.json
      password_encoding_type: BCRYPT_12_ROUND
  admin_web:
    name: Web Admin
    enabled: true
    type: ADMIN_WEB
    service:
      enabled: true
      svcName: admin-web
      hostName: default
    requires:
      SECURITY_IN_UP: local_security
    config:
      context_path: ""
      port: 9100
      tls.enabled: false
      https_forwarding_assumed: true
      respect_forward_headers: true
  fhir_endpoint:
    name: FHIR Service
    enabled: true
    type: ENDPOINT_FHIR_REST_R4
    service:
      enabled: true
      svcName: fhir
      hostName: default
    requires:
      PERSISTENCE_R4: persistence
      SECURITY_IN_UP: local_security
    config:
      context_path: fhir_request
      port: 8000
      base_url.fixed: default
```
</details>

### Define Readiness Probe
As Kubernetes only supports a single readiness probe per container, you need to define which endpoint module Kubernetes should use to consider the 'readiness' of your installation.

The default modules included with this chart are configured so that the `fhir_endpoint` module is used for the readiness probe. This is done by setting the `enableReadinessProbe` key to `true` in the module definition.

If you wish to use a different module for the readiness probe, you must disable it for the `fhir_endpoint` module and enable it for the module of your choice. e.g.
#### `my-module-values.yaml`
```yaml
modules:
  fhir_endpoint:
    enableReadinessProbe: false
  my_fhir_endpoint:
    enableReadinessProbe: true
    enabled: true
    ...
```
Alternatively, you may disable the included default modules as described above, and then enable the probe on one of your custom defined modules.

>**Note:** You must enable the readiness probe for exactly one endpoint module. If you specify none, or more than one, the Helm Chart will return an error.

## Install Smile CDR with extra modules definition files
When splitting your configuration into multiple `values` files, pass them in to your `helm upgrade` commandline like so:
```shell
$ helm upgrade -i my-smile-env --devel -f my-values.yaml -f my-module-values.yaml smiledh/smilecdr
```

## Experimental/Unsupported Features
There are scenarios where you may wish to update Smile CDR module configurations directly in the Web console.

* You need to do some realtime troubleshooting that requires live updates of module configuration
* You are working in a *development* environment and you do not have a suitable code pipeline in place to enable fast iteration of changes

In these cases, there are two settings that you can use to update configuration live in the Smile CDR Web Admin console.
Using these settings will alter the values of `node.config.locked` and `node.propertysource` in the resulting Smile CDR configuration.
Re
fer to the [Smile CDR Docs](https://smilecdr.com/docs/installation/installing_smile_cdr.html#module-property-source){:target="_blank"} for more info on Module Property Sources.

### Troubleshooting Mode

You may enable troubleshooting mode for a given Smile CDR Node as follows:
>**Note:** If you have defined a different `cdrNodes` configuration, please alter the code below accordingly.

```yaml
cdrNodes:
  masterdev:
    config:
      troubleshooting: true
```
Enabling this option lets you update module configurations in the console for troubleshooting/testing/experimenting.

* Your changes will be lost if the pod restarts or if another pod joins the cluster.
* It sets [`node.config.locked`](https://smilecdr.com/docs/installation/installing_smile_cdr.html#node-configuration-properties){:target="_blank"} to `false`
and sets [`node.propertysource`](https://smilecdr.com/docs/installation/installing_smile_cdr.html#module-property-source){:target="_blank"} to `PROPERTIES_UNLOCKED`

### Database Mode

The troubleshooting mode may not meet your requirements in some scenarios:

* You need these changes to persist for a longer time period and your underlying compute resources could be interrupted. For example:
    * You are using ephemeral compute resources such as AWS EC2 Spot instances which can go away with short notice.
    * Your infrastructure needs to be scaled down when not actively working on it.
* You wish to restart the Smile CDR pods while maintaining your manual configuration changes.
* New Kubernetes Pods may come online (If you are testing HPA or HA, for example.)

In these scenarios, it would be a more robust solution to regularly mirror your configuration changes to your Helm `values` file and reconcile.

In the event that this is not possible, and your manually entered configurations must persist in the above scenarios, you may use the `database` mode as follows:
>**Note:** If you have defined a different `cdrNodes` configuration, please alter the code below accordingly.

```yaml
cdrNodes:
  masterdev:
    config:
      database: true
```

When enabling this mode, consider the following:

* This is an ***experimental*** feature and is unsupported. Use at your own risk.
* It sets [`node.config.locked`](https://smilecdr.com/docs/installation/installing_smile_cdr.html#node-configuration-properties){:target="_blank"} to `false`
* It sets [`node.propertysource`](https://smilecdr.com/docs/installation/installing_smile_cdr.html#module-property-source){:target="_blank"} to `DATABASE`
* The Helm Chart will still create surrounding Kubernetes resources (Ingress, Service, Extra files, Mapped secrets etc) based on the contents of the Helm `values` file.
* If you add a new module from the Smile CDR Web console and that module has an endpoint configuration, you will **NOT** be able to access it. No Ingress or Service objects will be created unless you also create the module using the Helm Chart.
* Any changes made in the Smile CDR Web console that do not match the Helm `values` settings will lead to configuration drift that may cause unpredictable behaviour the next time you deploy the Helm Chart.
* In the event of such drift occurring, reverting this mode to `disabled` may then lead to unpredictable behaviour that could result in modules being incorrectly configured, resulting to critical system or data integrity faults.
>***!!!DO NOT USE THIS EXPERIMENTAL UNSUPPORTED FEATURE IN NON-DEVELOPMENT ENVIRONMENTS!!!***
