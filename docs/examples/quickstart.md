# Quickstart Configuration

This is the configuration used in the [Quickstart](../quickstart/index.md)

This will configure Smile CDR as follows:

* Default Smile CDR module configuration
* Ingress configured for `smilecdr.mycompany.com` using NginX Ingress
* Docker registry credentials passed in via values file (Don't do this!)
* Postgres DB automatically created

## Requirements

* Nginx Ingress Controller must be installed, with TLS certificate
* DNS for `smilecdr.mycompany.com` needs to be exist and be pointing to the load balancer used by Nginx Ingress
* CrunchyData Operator must be installed
* Credentials to an image repository with the official Smile CDR images.

## Values File
```yaml
specs:
  hostname: smilecdr.mycompany.com
image:
  repository: docker.smilecdr.com/smilecdr
  imagePullSecrets:
  - type: values
    registry: docker.smilecdr.com
    username: <DOCKER_USERNAME>
    password: <DOCKER_PASSWORD>
database:
  crunchypgo:
    enabled: true
    internal: true
```
