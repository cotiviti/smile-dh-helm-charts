# Multiple External DB Configuration

This example demonstrates using multiple external Postgres Databases.

It is based on the [minimal](minimal.md) example.

This will configure Smile CDR as follows:

* Default Smile CDR module configuraton
* Ingress configured for `smilecdr.mycompany.com` using NginX Ingress
* Docker registry credentials passed in via Secret Store CSI Driver using AWS Secrets Manager
* External database credentials and connection info passed in via Secret Store CSI Driver using AWS Secrets Manager
* Separate databases for Cluster Manager, Audit logs and default Persistence module

## Requirements

* Nginx Ingress Controller must be installed, with TLS certificate
* DNS for `smilecdr.mycompany.com` needs to be exist and be pointing to the load balancer used by Nginx Ingress
* Image repository credentials stored in AWS Secrets Manager
* AWS IAM Role configured to access AWS Secrets Manager
* Multiple external Postgres databases provisioned and accessible from the Kubernetes cluster
* Database credentials stored in AWS Secrets Manager using the [published Json structure](https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_secret_json_structure.html#reference_secret_json_structure_rds-postgres)

## Values File
```yaml
specs:
  hostname: smilecdr.mycompany.com

serviceAccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/example-role-name"

image:
  repository: docker.smilecdr.com/smilecdr
  credentials:
    type: sscsi
    provider: aws
    secretarn: "arn:aws:secretsmanager:us-east-1:1234567890:secret:secretname"

database:
  external:
    enabled: true
    credentials:
      type: sscsi
      provider: aws
    databases:
    - secretName: clustermgrSecret
      secretArn: "arn:aws:secretsmanager:us-east-1:1234567890:secret:clustermgrSecret"
      module: clustermgr
    - secretName: auditSecret
      secretArn: "arn:aws:secretsmanager:us-east-1:1234567890:secret:auditSecret"
      module: audit
    - secretName: persistenceSecret
      secretArn: "arn:aws:secretsmanager:us-east-1:1234567890:secret:persistenceSecret"
      module: persistence
```
