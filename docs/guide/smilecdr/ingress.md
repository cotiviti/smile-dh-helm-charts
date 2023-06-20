# Configuring Ingress
This chart supports multiple Ingress options, currently including Nginx Ingress, AWS Load Balancer
Controller and Azure Application Gateway Controller.

## Ingress Type
Select the ingress type by setting `ingress.type` to the appropriate value. Doing this will automatically configure the `Service` and `Ingress` resources so that the chosen controller can configure infrastructure resources appropriately.

There are three ingress types currently supported:

* Nginx Ingress Controller (Default)
* AWS Load Balancer Controller
* Azure Application Gateway Controller

### Nginx Ingress
By default, this chart is configured to use the Nginx Ingress Controller. `ingress.type` is already set to `nginx-ingress` so you do not need to do anything to use this method.

When used in conjunction with the AWS Load Balancer Controller, the Nginx Ingress will be backed by an AWS NLB (Network Load Balancer).

The `Service` objects will be set as `ClusterIP` rather than `NodePort`. This increases the security stance of the deployment as Kubernetes does not expose these services externally to the cluster. All traffic comes from the Nginx Ingress pods directly to the application pods.

#### Dedicated Nginx Ingress
By default, this option uses the `nginx` ingress class. Any ingresses using this class will share the same underlying NLB.

If you need to use a dedicated NLB for this deployment you can do so by first creating a separate Nginx Ingress Controller with a different ingress class name. You can then specify this ingress class with `ingress.ingressClassNameOverride`.

### AWS Load Balancer Controller
To directly use the AWS Load Balancer Controller set `ingress.type` to `aws-lbc-alb`. By default, this option uses the `alb` ingress class.

This automatically adds appropriate default `Ingress` annotations for the AWS Load Balancer Controller. The controller will then create an AWS ALB (Application Load Balancer).

You will still need to add some extra annotations, such as `alb.ingress.kubernetes.io/certificate-arn`. See the [Extra Annotations](#extra-annotations) section below for more info.

>**Warning**: Be aware that the `Service` objects will be set as `NodePort` rather than  `ClusterIP`. This means that the application services will be made available externally to the cluster which may have security implications you need to be aware of.

#### Known Problems
There is currently a problem with the AWS Load Balancer Controller configuration where the health checks do not function correctly. This is somewhat mitigated by the fact that the `Service` objects are using `NodePort`. This will be addressed in a future release of this chart.

### Azure Application Gateway Controller
If you wish to use the Azure Application Gateway Controller, set `ingress.type` to `azure-appgw`. By default, this option uses the `azure/application-gateway` ingress class.

When using this method, the chart will automatically add `Ingress` annotations for the Azure Application Gateway Controller. The controller will then create an Azure Application Gateway to be used as ingress.

You will still need to add some extra annotations, such as `appgw.ingress.kubernetes.io/appgw-ssl-certificate`. See the [Extra Annotations](#extra-annotations) section below for more info.

>**Warning**: Be aware that the `Service` objects will be set as `NodePort` rather than  `ClusterIP`. This means that the application services will be made available externally to the cluster which may have security implications you need to be aware of.

## Extra Annotations
Depending on the ingress type you select, the chart will automatically add a set of default annotations that are appropriate for the ingress type being used.

However, it is not possible for the chart to automatically include all annotations as some need to be specified in your configuration.

To add any extra annotations, or override existing ones, include them in your values file like so:

```yaml
ingress:
  annotations:
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm::01234567890:certificate/abcdef
    alb.ingress.kubernetes.io/inbound-cidrs: 0.0.0.0
```

or
```yaml
ingress:
  annotations:
    appgw.ingress.kubernetes.io/appgw-ssl-certificate: mysslcert
```

## Ingress Class Name
This chart assumes the following class names for your ingress controllers

| Selected `ingress.type`  | Default `ingress.class`             |
| --------------- | --------------------------- |
| `nginx-ingress` | `nginx`                     |
| `aws-lbc-alb`   | `alb`                       |
| `azure-appgw`   | `azure/application-gateway` |

If you have configured your ingress with a different `IngressClass` name, you can override it using `ingress.ingressClassNameOverride`.

For example, if you had a dedicated Nginx Ingress Controller with the `IngressClass` of `nginx-dedicated`, you would include it in your values file like so:

```yaml
ingress:
  ingressClassNameOverride: nginx-dedicated
```

## Multiple Ingress Classes
It may be required to have multiple ingresses for your environment. For example, you may want some services available externally while others, such as the Admin Web Console, you only want to expose to a private network.

TODO: Insert diagram of this

Currently, this Helm Chart only supports a single ingress class so this is not possible. There is a planned feature to add this functionality.

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

When you configure your module like this, there will be no entry in the rules for the default ingress resource that is generated.

If your module is a FHIR Rest Endpoint module, the `base_url.fixed` setting will be automatically configured appropriately and there is no need for you to define this in your Helm Values file.

## Service Type
The appropriate type for the `Service` resources depend on which Ingress type is being used.
The default `Service` created by this chart is `ClusterIP`. This is the preferred option as it does not expose the Services externally to the cluster.

When using the AWS Load Balancer Controller, or Azure Application Gateway Controller, the service objects are instead set to `NodePort`.

This can be overriden using ```service.type``` in your values file, but it is not recommended and may cause unpredictable behaviour.

<!-- TODO: We may need to enable `target-type: ip` in the AWS Load Balancer Controller. If doing this, we will need to use pod readiness gates - https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/deploy/pod_readiness_gate/ . This will not work until healthchecks are functioning correctly. -->
