# Basic Modules Configuration

This example demonstrates simple reconfiguration of Smile CDR modules.

It is based on the [minimal](minimal.md) example.

This will configure Smile CDR as follows:

* Modified Smile CDR module configuraton
  * We will only modify `dao_config.inline_resource_storage_below_size` for the persistence database
* Ingress configured for `smilecdr.mycompany.com` using NginX Ingress
* Docker registry credentials passed in via Secret Store CSI Driver using AWS Secrets Manager
* Postgres DB automatically created

## Requirements

* Nginx Ingress Controller must be installed, with TLS certificate
* DNS for `smilecdr.mycompany.com` needs to be exist and be pointing to the load balancer used by Nginx Ingress
* CrunchyData Operator must be installed
* Image repository credentials stored in AWS Secrets Manager
* AWS IAM Role configured to access AWS Secrets Manager

## Values File
```yaml
specs:
  hostname: smilecdr.mycompany.com

image:
  repository: docker.smilecdr.com/smilecdr
  imagePullSecrets:
  - type: sscsi
    provider: aws
    secretArn: "arn:aws:secretsmanager:us-east-1:1234567890:secret:secretname"

serviceAccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/example-role-name"

database:
  crunchypgo:
    enabled: true
    internal: true

modules:
  persistence:
    config:
      dao_config.inline_resource_storage_below_size: 4000
```
