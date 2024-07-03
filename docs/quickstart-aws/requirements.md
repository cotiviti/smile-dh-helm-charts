
# Quickstart Requirements
There are a number of prerequisites that must be in place before deploying
Smile CDR using this Quickstart guide.

These dependencies are sufficient to get you started with deploying an instance for testing purposes.

* Access to a container repository with the required Smile CDR Docker images
    * e.g. `docker.smilecdr.com` or your own registry with a custom Docker image for Smile CDR
* Kubernetes Cluster that you have suitable administrative permissions on.
    * You will need permissions to create namespaces and maybe install Kubernetes add-ons
* Sufficient spare compute resources on the Kubernetes cluster.
    * Minimum spare of 1 vCPU and 4GB memory for a 1 pod install of just Smile CDR
* One of the following supported Ingress controllers:
    * [Nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/) (Preferred)
    * [AWS Load Balancer Controller](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html)
    * [Azure Application Gateway Ingress Controller](https://azure.github.io/application-gateway-kubernetes-ingress/)
* TLS certificate that can be provisioned on the load balancer used by the Ingress objects
    * e.g. AWS Certificate Manager.
* DNS entries pointing to load balancer.
    * e.g. [Amazon Route 53](https://aws.amazon.com/route53/)
* [CrunchyData Postgres Operator](https://access.crunchydata.com/documentation/postgres-operator/v5/)
    * Allows you to install a PostgreSQL cluster as a part of the Smile CDR deployment
    * This is used for the Quickstart as it is the easiest way to get up and running without
      having to provision an external database and configure credentials and connectivity
* Persistent Volume provider that can be used to create `PersistentVolume` resources for the database
