# Configuring Ingress
This chart enables flexible Kubernetes Ingress resource configuration, supporting multiple Ingress and IngressClass resources for versatile application traffic routing.

Currently supported controllers include Nginx Ingress, AWS Load Balancer, and Azure Application Gateway.

## Ingress Type
This chart uses a concept of ingress `Type` to determine what kind of Ingress Controller is being used. It should not be confused with the `IngressClass`.

The following ingress types are currently supported:

* `nginx-ingress` (Default)
* `aws-lbc-alb`
* `azure-agic`

This setting is used to help automatically configure the `Service` and `Ingress` resources so that the configured Ingress Controller can configure infrastructure resources appropriately.

The ingress type for any given ingress can be set with `ingresses.default.type: ingress-type`.

>**NOTE:** If migrating from Helm Chart versions older than `v1.0.0-pre.104`, you will need to adjust from the old config schema to the new one. This can be done by moving any configurations that were previously under `ingress.*` to `ingresses.default.*`. e.g. `ingress.type: aws-lbc-alb` would become `ingresses.default.type: aws-lbc-alb`

### Nginx Ingress
By default, this chart is configured to use the [Nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/). `ingresses.default.type` is already set to `nginx-ingress` so you do not need to do anything to use this Ingress Controller.

The behavior of the Nginx Ingress controller differs based on the cloud provider being used. When used in conjunction with the [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller), the Nginx Ingress will be backed by an AWS NLB (Network Load Balancer).

The `Service` objects will be set as `ClusterIP` rather than `NodePort`. This increases the security stance of the deployment as Kubernetes does not expose these services externally to the cluster. All traffic comes from the Nginx Ingress Controller pod, directly to the application pods.

#### TLS Encryption
By default the Nginx ingress uses a ***self-signed*** certificate. If this is sufficient for your needs (as the fronting AWS NLB does not need to verify the certificates), nothing else needs to be done.

If, however, you need to use a ***publicly-signed*** TLS certificate in the Nginx ingress (for example, using TLS passthrough on the fronting load balancer) then you can configure Nginx Ingress to use cert-manager and Let's Encrypt to automatically provision a suitable TLS certificate.

For a detailed explanation of how this solution works, refer to the [ingress-nginx](https://kubernetes.github.io/ingress-nginx/user-guide/tls/#automated-certificate-management-with-cert-manager) and [cert-manager](https://cert-manager.io/docs/tutorials/acme/nginx-ingress/) documentation.

This can currently be configured using the Helm Chart using two methods

##### Option 1
**Create Let's Encrypt Staging `Issuer` Resource**

**Step 1**

Use the below `values.yaml` snippet to enable the Helm Chart to generate a Let's Encrypt issuer.
```
tls:
  certificateIssuers:
    default:
      enabled: true
      signingMethod: public-signed
      acmeSpec:
        email: test@example2.com
```

**Step 2**

Update your ingress configuration to enable TLS and use the issuer configuration defined above.
```
ingresses:
  default:
    tlsConfig:
      enabled: true
      issuerConfiguration: default
```

##### Option 2
**Use pre-existing `Issuer` Resource**

**Step 1**

Create a suitable public-signing `Issuer` resource. Refer to the cert-manager documentation for instructions on doing this.

In the rest of this example, we will assume that this existing `Issuer` resource is named `my-existing-lets-encrypt-issuer`

**Step 2**

Use the below `values.yaml` snippet to define the pre-existing Issuer in a way that it can be used by multiple sections of the Helm Chart.
```
tls:
  certificateIssuers:
    myExistingLetsEncryptIssuer:
      enabled: true
      signingMethod: public-signed
      existingIssuer: my-existing-lets-encrypt-issuer
```
>**Note:** Although the above is not technically mandatory for Ingress TLS configuration, it's advisable to use this mechanism.
By doing so, the same issuer can easily be used to create other certificates that can be used in the Smile CDR deployment.

**Step 3**

Update your ingress configuration to enable TLS and use the issuer defined above. Note that you can either reference the above-defined `tls.certificateIssuers` configuration,
or you can directly reference the pre-existing `Issuer` resource that you created.
```
ingresses:
  default:
    tlsConfig:
      enabled: true
      issuerConfiguration: myExistingLetsEncryptIssuer
      # If directly referencing the pre-existing `Issuer` resource that you created, use the following instead
      # existingIssuer: my-existing-lets-encrypt-issuer
```

>**Note:** For brevity, these examples do not enable back-end encryption to the Smile CDR pods. Please see the [TLS Encryption](./tls-encryption.md) section for more information on enabling back-end encryption, configuring Issuers, Certificates and using them in Smile CDR.

##### BYO Certificate
At this time, the Helm Chart does not support providing your own externally-provisioned TLS certificate. This feature will be added at a future date.

#### Dedicated Nginx Ingress
By default, this option uses the `nginx` ingress class. If multiple ingresses all use the same default IngressClass, then they will share the same underlying NLB.

If you need to use a dedicated (or multiple) NLBs for this deployment, you can do so by first creating any required Nginx Ingress Controllers with a different IngressClass name. You can then specify this ingress class with `ingresses.default.ingressClassNameOverride`.

### AWS Load Balancer Controller
To directly use the AWS Load Balancer Controller set `ingresses.default.type` to `aws-lbc-alb`. By default, this option uses the `alb` ingress class.

This automatically adds appropriate default `Ingress` annotations for the AWS Load Balancer Controller. The controller will then create an AWS ALB (Application Load Balancer).

You will still need to add some extra annotations, such as `alb.ingress.kubernetes.io/certificate-arn`. See the [Extra Annotations](#extra-annotations) section below for more info.

>**Warning**: Be aware that the `Service` objects will be set as `NodePort` rather than  `ClusterIP`. This means that the application services will be made available externally to the cluster which may have security implications you need to be aware of.

#### Known Problems
There is currently a problem with the AWS Load Balancer Controller configuration where the health checks do not function as expected. This is somewhat mitigated by the fact that the `Service` objects are using `NodePort`. This will be addressed in a future release of this chart.

### Azure Application Gateway Ingress Controller
If you wish to use the Azure Application Gateway Ingress Controller (AGIC), set `ingresses.default.type` to `azure-agic`. By default, this option uses the `azure/application-gateway` ingress class.

When using this method, the chart will automatically add `Ingress` annotations for the Azure Application Gateway Controller. The controller will then create an Azure Application Gateway to be used as ingress.

You will still need to add some extra annotations, such as `appgw.ingress.kubernetes.io/appgw-ssl-certificate`. See the [Extra Annotations](#extra-annotations) section below for more info.

>**Warning**: Be aware that the `Service` objects will be set as `NodePort` rather than  `ClusterIP`. This means that the application services will be made available externally to the cluster which may have security implications you need to be aware of.

## Multiple Ingress Resources
This chart allows for configurations using an arbitrary number of ingress resources and ingress classes.

This enables the implementation of architectures that require multiple routes for accessing for your environment. For example, you may require some services available publicly while others, such as the Admin Web Console, may only permit access from a private network.


### Default Ingress
In order to simplify deployment of certain architectures, this chart supports the concept of a 'default' Ingress resource.

The default Ingress resource will be used for any Smile CDR modules that have not explicitly defined `service.ingresses` in their configuration.

#### The pre-defined Default Ingress Configuration
If no changes are made to the `ingresses` section of your Helm Values, a pre-defined Ingress Configuration is created, that effectively looks like this:
```
ingresses:
  default:
    enabled: true
    type: nginx-ingress
    defaultIngress: true
    ingressClassName: nginx
```
With the above pre-defined ingress, any module with an endpoint-enabled service will have rules injected into the `Ingress` resource created by this configuration.

#### The `defaultIngress` setting
This setting tells an Ingress resource to serve as the active *default ingress*. This setting can only be enabled for a single Ingress Configuration at a time.

If you are defining a custom default Ingress Configuration and do not wish to use the pre-defined one, you need to disable it like so:

```
ingresses:
  default:
    enabled: false
  myCustomDefaultIngress
    enabled: true
    type: nginx-ingress
    defaultIngress: true
    ...
```

>**NOTE:** If there are no Ingress Configurations with this setting enabled, then any Smile CDR modules that ***HAVE NOT*** explicitly defined `service.ingresses` in their configuration will not be exposed externally to the K8s cluster.


#### Configuring the pre-defined Default Ingress Configuration
The pre-defined Ingress Configuration can be reconfigured as follows:
```
ingresses:
  default:
    type: azure-agic
```

#### Disabling the pre-defined Default Ingress Configuration
If you are creating multiple custom Ingress Configurations, you may wish to disable the pre-defined default ingress. This can be done as follows:
```
ingresses:
  default:
    enabled: false
```
>**NOTE:** If you disable the default ingress, then you must define at least one alternative Ingress Configuration if you wish to allow access from outside the Kubernetes cluster.

### Defining Custom Ingress Configurations
To allow for complex ingress architectures, you may define an arbitrary number of Ingress Configurations like so
```
ingresses:
  default:
    enabled: false
  myPrivateNginx:
    enabled: true
    type: nginx-ingress
    defaultIngress: true
  myPublicNginx:
    enabled: true
    type: nginx-ingress
    ingressClassNameOverride: nginx-public

# These two are just to demonstrate using the
#  AWS Load Balancer Controller for Ingress

  myPrivateALB:
    enabled: true
    type: aws-lbc-alb
    annotations:
      alb.ingress.kubernetes.io/scheme: internal
  myPublicALB:
    enabled: true
    type: aws-lbc-alb
    annotations:
      alb.ingress.kubernetes.io/scheme: internet-facing

```
In the above example we are:

* Disabling the default Ingress Configuration (We do this, because we will be defining a new default Ingress Configuration)
* Creating a `myPrivateNginx` default Ingress Configuration.
  * Using `defaultIngress` creates the default Ingress resource. This will be used by any Smile CDR modules that do not explicitly define `service.ingresses`.
  * The Ingress resource will use the Nginx Ingress Controller via the `ingressClass` resource named `nginx`
* Creating a `myPublicNginx` Ingress Configuration.
  * This ingress will not be used unless a module specifies that it should use this ingress.
  * The Ingress resource will use the Nginx Ingress Controller via the `ingressClass` resource named `nginx-public`. This additional Nginx Ingress Controller will need to be deployed before trying to use this configuration.

The following two are just to demonstrate how you would use the AWS Load Balancer Controller as an alternative mechanism.

* Creating a `myPrivateALB` Ingress Configuration.
  * This will use the AWS Load Balancer Controller with an IngressClassName of `alb`.
  * It uses AWS Load Balancer Controller annotations to set this ingress to use an internal only AWS Application Load Balancer.
* Creating a `myPublicALB` Ingress Configuration.
  * This will use the Nginx Ingress controller with an IngressClassName of `alb`.
  * It uses AWS Load Balancer Controller annotations to set this ingress to use an internet facing AWS Application Load Balancer.

>**NOTE:** There are no restrictions on mixing the `type` for Ingress Configurations. For example, you may have some Ingress Configurations use `nginx-ingress` and others use `aws-lbc-alb`.

### Configure Ingress for Modules
Smile CDR modules will automatically be configured to use whichever ingress has the `defaultIngress` setting enabled.

If you do not want a module to use the default Ingress resource, or if there is no default Ingress Configuration defined, then you need to explicitly configure the `service.ingresses` for any Smile CDR modules that need to be accessed from outside the Kubernetes cluster.

To configure a Smile CDR module to use a specific ingress, specify it in the `moduleSpec.service.ingresses` map as follows:
```
modules:
  fhirweb_endpoint:
    service:
      hostName: myFhirwebHost.example.com
      ingresses:
        myPublicNginx:
          enabled: true
```
In the above example we are telling the module named `fhirweb_endpoint` to use the `myPublicNginx` ingress specified previously mentioned. With the sample 'Multiple Ingress' configurations provided in on this page, all Smile CDR modules will only be accessible via the `myPrivateNginx` ingress, except for the `fhirweb_endpoint` module which will be available via the public access route.

>**NOTE:** Although you can configure a module to use multiple Ingress resources, be careful doing this unless you are using a split-dns configuration that preserves the host name for all ingresses.

> Having an endpoint be accessible via multiple hostnames can cause issues with incorrect links to resources generated by the application. It's advisable to only have a given module be accessible via a single ingress/hostname.

## Extra Annotations
Depending on the ingress type you select, the chart will automatically add a set of default annotations that are appropriate for the ingress type being used.

However, it is not possible for the chart to automatically include all annotations as some need to be specified in your configuration.

To add any extra annotations, or override existing ones, include them in your values file like so:

```yaml
ingresses:
  default:
    annotations:
      alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm::01234567890:certificate/abcdef
      alb.ingress.kubernetes.io/inbound-cidrs: ['0.0.0.0/0']
```

or
```yaml
ingresses:
  default:
    annotations:
      appgw.ingress.kubernetes.io/appgw-ssl-certificate: mysslcert
```

## Ingress Class Name
This chart uses the following default class names for the different ingress types

| Selected `ingresses.default.type`  | Default `ingressClassName`             |
| --------------- | --------------------------- |
| `nginx-ingress` | `nginx`                     |
| `aws-lbc-alb`   | `alb`                       |
| `azure-agic`    | `azure/application-gateway` |

If you have configured your Ingress Controller with a different `ingressClass` name, you can override it using `ingresses.default.ingressClassNameOverride`.

For example, if you had a dedicated Nginx Ingress Controller with the `IngressClass` of `nginx-dedicated`, you would include it in your values file like so:

```yaml
ingresses:
  default:
    ingressClassNameOverride: nginx-dedicated
```

## Disabling Ingress
In some scenarios, you may wish to disable external ingress for certain modules. For example, if you have a FHIR Rest Endpoint module that is behind a FHIR Gateway module, you may not want to expose the FHIR Rest endpoint externally to the cluster.

In this case, you can disable the ingress for a given service like so:
```yaml
modules:
  fhir_endpoint:
    service:
      ingresses:
        default:
          enabled: false
```

Configuring your module like this will prevent any rules from being added to the default Ingress resource that is generated.

If your module is a FHIR Rest Endpoint module, the `base_url.fixed` setting will be automatically configured appropriately and there is no need for you set this in your `moduleSpec.config`.

## Service Type
The appropriate type for the `Service` resources depend on which Ingress type is being used.
The default `Service` created by this chart is `ClusterIP`. This is the preferred option as it does not expose the Services externally to the cluster.

When using the AWS Load Balancer Controller, or Azure Application Gateway Controller, the service objects are instead set to `NodePort`.

This can be overridden using `service.type` in your values file, but it is not recommended and may cause unpredictable behaviour.

<!-- TODO: We may need to enable `target-type: ip` in the AWS Load Balancer Controller. If doing this, we will need to use pod readiness gates - https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/deploy/pod_readiness_gate/ . This will not work until healthchecks are functioning correctly. -->
