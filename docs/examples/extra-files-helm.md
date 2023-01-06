# Adding Files Using Helm

This example demonstrates passing in extra files to the deployment via the Helm Chart.

It is based on the [minimal](minimal.md) example.

This will configure Smile CDR as follows:

* Default Smile CDR module configuraton
* Ingress configured for `smilecdr.mycompany.com` using NginX Ingress
* Docker registry credentials passed in via Secret Store CSI Driver using AWS Secrets Manager
* Postgres DB automatically created
* Custom `logback.xml` file will be included in the `classes` directory in Smile CDR

## Requirements

* Nginx Ingress Controller must be installed, with TLS certificate
* DNS for `smilecdr.mycompany.com` needs to be exist and be pointing to the load balancer used by Nginx Ingress
* CrunchyData Operator must be installed
* Image repository credentials stored in AWS Secrets Manager
* AWS IAM Role configured to access AWS Secrets Manager
* Customized `logback.xml` file available in your configuration repo/folder

## Values File
```yaml
specs:
  hostname: smilecdr.mycompany.com

image:
  repository: docker.smilecdr.com/smilecdr
  credentials:
    type: sscsi
    provider: aws
    secretarn: "arn:aws:secretsmanager:us-east-1:1234567890:secret:secretname"

serviceAccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/example-role-name"

database:
  crunchypgo:
    enabled: true
    internal: true

mappedFiles:
  logback.xml:
    type: configMap
    path: /home/smile/smilecdr/classes
```

## Extra Install Steps
To use this feature, you must update your `helm upgrade` command to include `--set-file mappedFiles.logback\\.xml.data=logback.xml`
