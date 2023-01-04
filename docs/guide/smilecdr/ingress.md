# Configuring Ingress
This chart supports multiple Ingress options, currently including Nginx Ingress, AWS Load Balancer
Controller and Azure Application Gateway Controller.

By setting `ingress.type` to the appropriate value, this chart will automatically add annotations to the `Ingress` resource so that the chosen controller can configure infrastructure resources appropriately.

## Nginx Ingress
If the Nginx Ingress Controller is installed in your K8s cluster, Smile CDR can be configured to use it by setting `ingress.type` to `nginx-ingress`

When used in conjunction with the AWS Load Balancer Controller, the Nginx Ingress will be backed by an AWS
Network Load Balancer. By default, any ingresses defined will share this load balancer. If you need to separate
applications on the cluster to use separate load balancers, you can do so by creating separate Nginx Ingress
controllers each with their own ingress class name which you can then specify with `ingress.ingressClassNameOverride`

#### AWS Load Balancer Controller
If installed in your K8s cluster, the AWS Load Balancer Controller can be configured by using `aws-lbc-alb`.

When using this method, the chart will automatically add `Ingress` annotations for the AWS Load Balancer Controller.
The controller will then create an AWS Application Load Balancer

#### Azure Application Gateway Controller
If installed in your K8s cluster, the Azure Application Gateway Controller can be configured by using `azure-appgw`.

When using this method, the chart will automatically add `Ingress` annotations for the Azure Application Gateway Controller.
The controller will then create an Azure Application Gateway to be used as ingress.
